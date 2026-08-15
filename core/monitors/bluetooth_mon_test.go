package monitors

import (
	"context"
	"encoding/json"
	"net"
	"ogsShell/core/ipc"
	"ogsShell/core/services/bluetooth"
	"path/filepath"
	"testing"
	"time"
)

func TestBluetoothMonitor_Broadcast(t *testing.T) {
	tmpDir := t.TempDir()
	sockPath := filepath.Join(tmpDir, "test_bt.sock")

	server := ipc.NewServer(sockPath)
	go func() {
		_ = server.Start()
	}()
	time.Sleep(50 * time.Millisecond)

	mockBt := bluetooth.NewMockBluetoothClient()
	defer mockBt.Close()

	btMon := NewBluetoothMonitor(server, mockBt)

	// Connect client to listen for events
	conn, err := net.Dial("unix", sockPath)
	if err != nil {
		t.Fatalf("failed to dial socket: %v", err)
	}
	defer conn.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go btMon.Start(ctx)

	// Read initial broadcast (immediate push)
	decoder := json.NewDecoder(conn)
	var evt ipc.Event
	if err := decoder.Decode(&evt); err != nil {
		t.Fatalf("failed to decode initial event: %v", err)
	}

	if evt.Type != "bluetooth_update" {
		t.Errorf("expected event type bluetooth_update, got %s", evt.Type)
	}

	var state bluetooth.BluetoothState
	if err := json.Unmarshal(evt.Payload, &state); err != nil {
		t.Fatalf("failed to unmarshal payload: %v", err)
	}

	if !state.AdapterPowered {
		t.Errorf("expected adapter to be powered")
	}

	// Trigger toggle and verify debounced update event is received
	if err := mockBt.TogglePower(ctx); err != nil {
		t.Fatalf("failed to toggle power: %v", err)
	}

	if err := decoder.Decode(&evt); err != nil {
		t.Fatalf("failed to decode updated event: %v", err)
	}

	var state2 bluetooth.BluetoothState
	if err := json.Unmarshal(evt.Payload, &state2); err != nil {
		t.Fatalf("failed to unmarshal payload: %v", err)
	}

	if state2.AdapterPowered {
		t.Errorf("expected adapter to be powered off after toggle")
	}
}

func TestBluetoothMonitor_DebounceBurst(t *testing.T) {
	tmpDir := t.TempDir()
	sockPath := filepath.Join(tmpDir, "test_bt_debounce.sock")

	server := ipc.NewServer(sockPath)
	go func() {
		_ = server.Start()
	}()
	time.Sleep(50 * time.Millisecond)

	mockBt := bluetooth.NewMockBluetoothClient()
	defer mockBt.Close()

	btMon := NewBluetoothMonitor(server, mockBt)

	conn, err := net.Dial("unix", sockPath)
	if err != nil {
		t.Fatalf("failed to dial socket: %v", err)
	}
	defer conn.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go btMon.Start(ctx)

	decoder := json.NewDecoder(conn)
	var evt ipc.Event
	// Drain initial broadcast
	if err := decoder.Decode(&evt); err != nil {
		t.Fatalf("failed to decode initial event: %v", err)
	}

	// Fire multiple rapid updates within 100ms
	for i := 0; i < 5; i++ {
		_ = mockBt.TogglePower(ctx)
		time.Sleep(20 * time.Millisecond)
	}

	// Should receive only one consolidated event after the 500ms debounce period
	if err := decoder.Decode(&evt); err != nil {
		t.Fatalf("failed to decode debounced event: %v", err)
	}

	if evt.Type != "bluetooth_update" {
		t.Errorf("expected bluetooth_update, got %s", evt.Type)
	}
}
