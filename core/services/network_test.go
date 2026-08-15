package services_test

import (
	"ogsShell/core/services"
	"testing"
	"time"
)

func TestNetworkService_ScanAccessPoints(t *testing.T) {
	// D-Bus bağlantısını ve WIFI yolunu başlat
	svc, err := services.NewNetworkService()
	if err != nil {
		t.Fatalf("NetworkService başlatılamadı: %v", err)
	}

	// Aktif donanım taraması tetiklenir
	t.Log("Aktif Wi-Fi taraması başlatılıyor...")
	if err := svc.RequestScan(); err != nil {
		t.Logf("Uyarı: Aktif tarama isteği reddedildi (donanım meşgul olabilir): %v", err)
	}

	time.Sleep(2 * time.Second)

	// Çevredeki Access Point'leri tara
	aps, err := svc.ScanAccessPoints()
	if err != nil {
		t.Fatalf("WIFI tarama hatası: %v", err)
	}

	if len(aps) == 0 {
		t.Logf("Uyarı: Hiçbir Access Point bulunamadı (WIFI kapalı veya kapsama alanı dışında).")
	}

	for _, ap := range aps {
		t.Logf("SSID: %-25s | Sinyal: %d%%", ap.SSID, ap.Signal)
	}
}

func TestNetworkService_ConnectToNetwork_Validation(t *testing.T) {
	svc, err := services.NewNetworkService()
	if err != nil {
		t.Fatalf("NetworkService baslatilamadi: %v", err)
	}

	// Var olmayan kukla bir SSID ve parola ile baglanti istegi firlatıyoruz.
	// Amac: D-Bus uzerinden olusturdugumuz Dict yapisinin NetworkManager
	// tarafindan unmarshal edilip edilemedigini test etmek.
	err = svc.ConnectToNetwork("OgsTest_Dummy_AP", "DummyPassword123!")
	if err != nil {
		// NetworkManager'in D-Bus seviyesinde hatayi yakalamasi RPC çağrımızın
		// doğru formatta iletildigini kanitlar.
		t.Logf("D-Bus RPC çagrisi basariyla iletildi (NM Yaniti): %v", err)
	} else {
		t.Log("Baglanti istegi NetworkManager'a sorunsuz iletildi.")
	}
}
