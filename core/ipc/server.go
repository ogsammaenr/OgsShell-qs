package ipc

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log/slog"
	"net"
	"ogsShell/core/logger"
	"os"
	"sync"
)

type ActionHandler func(action Action) error

// Server: IPC Socket sunucumuzu ve bağlı istemcileri yönetir.
type Server struct {
	socketPath    string
	listener      net.Listener
	mu            sync.RWMutex
	clients       map[net.Conn]bool
	log           *slog.Logger
	actionHandler ActionHandler
}

// NewServer: Yeni bir IPC sunucu örneği oluşturur.
func NewServer(socketPath string) *Server {
	return &Server{
		socketPath: socketPath,
		clients:    make(map[net.Conn]bool),
		log:        logger.Module("IPC"),
	}
}

// Start: Socket sunucusunu dinlemeye alı¶ ve gelen istemcileri karşılar.
func (s *Server) Start() error {
	// ölü socket dosyalarını temizle
	if err := os.Remove(s.socketPath); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("eski socket silinemedi: %w", err)
	}

	// unix socket dinleyicisini bağla
	l, err := net.Listen("unix", s.socketPath)
	if err != nil {
		return fmt.Errorf("socket dinlenemedi: %w", err)
	}
	s.listener = l

	for {
		conn, err := s.listener.Accept()
		if err != nil {
			return err
		}
		go s.handleClient(conn)
	}
}

func (s *Server) SetActionHandler(handler ActionHandler) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.actionHandler = handler
}

func (s *Server) handleClient(conn net.Conn) {
	// İstemci bağlantısı kapandığında socket kaynaklarını işletim sistemine iade et
	s.addClient(conn)
	defer func() {
		s.removeClient(conn)
		conn.Close()
	}()

	s.log.Info("Yeni istemci bağlandı", "remote_addr", conn.RemoteAddr().String())

	// Socket akışı satır satır (\n) okumak için scanner başlatıyoruz
	scanner := bufio.NewScanner(conn)

	for scanner.Scan() {
		rawBytes := scanner.Bytes()
		if len(rawBytes) == 0 {
			continue
		}

		var action Action

		if err := json.Unmarshal(rawBytes, &action); err != nil {
			s.log.Error("Geçersiz Action paketi", "err", err)
			continue
		}
		s.log.Info("Action alındı", "name", action.Name)

		s.mu.RLock()
		handler := s.actionHandler
		s.mu.RUnlock()

		if handler != nil {
			if err := handler(action); err != nil {
				s.log.Error("ActionCalıştırma hatası", "name", action.Name, "err", err)
			}
		}
	}

	if err := scanner.Err(); err != nil {
		s.log.Error("İstemci okuma hatası", "err", err)
	}
}

func (s *Server) addClient(conn net.Conn) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.clients[conn] = true
}

func (s *Server) removeClient(conn net.Conn) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.clients, conn)
}

// Broadcast: Tüm bağlı istemcilere Newline-Delimited JSON formatında event yayınlar.
func (s *Server) Broadcast(event Event) error {
	// Event struct'ını json byte dizisine dönüştürüyoruz
	data, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("event marshal hatası : %W", err)
	}

	// Mesaj sınırını belirtmek için sonuna yeni satır ekliyoruz
	data = append(data, '\n')

	// İstemci listesini okuma kilidi (RLock) altında güvenle gez
	s.mu.RLock()
	defer s.mu.RUnlock()

	for conn := range s.clients {
		// Bağlantıya yazma işlemi başarısız olursa istemci koptu demektir
		if _, err := conn.Write(data); err != nil {
			s.log.Warn("İstemciye yazma başarısız", "err", err)
		}
	}
	return nil
}
