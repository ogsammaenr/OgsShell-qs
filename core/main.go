package main

import (
	"context"
	"encoding/json"
	"fmt"
	"ogsShell/core/ipc"
	"ogsShell/core/logger"
	"ogsShell/core/monitors"
	"ogsShell/core/services/alarm"
	"ogsShell/core/services/bluetooth"
	"ogsShell/core/services/calendar"
	"ogsShell/core/services/clipboard"
	"ogsShell/core/services/keyboard"
	"ogsShell/core/services/launcher"
	"ogsShell/core/services/launcher/entry"
	"ogsShell/core/services/notifications"
	"ogsShell/core/services/theme"
	"ogsShell/core/services/theme/adapters"
	"ogsShell/core/services/wifi"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"
)

type ConnectWifiPayload struct {
	SSID     string `json:"ssid"`
	Password string `json:"password,omitempty"`
	Hidden   bool   `json:"hidden,omitempty"`
}

type GetSecretsPayload struct {
	SSIDOrUUID string `json:"ssid_or_uuid"`
}

type UpdateSecretsPayload struct {
	SSIDOrUUID string `json:"ssid_or_uuid"`
	Password   string `json:"password"`
}

type SetWifiEnabledPayload struct {
	Enabled bool `json:"enabled"`
}

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()

	// Logger başlat
	logger.Init()
	log := logger.Module("MAIN")

	// Socket yolunu belirle (/run/user/1000/ogs_shell.sock)
	runtimeDir := os.Getenv("XDG_RUNTIME_DIR")
	if runtimeDir == "" {
		runtimeDir = os.TempDir()
	}
	socketPath := filepath.Join(runtimeDir, "ogs_shell.sock")

	// IPC Server örneği oluştur
	server := ipc.NewServer(socketPath)

	// Modüler WifiManager istemcisini başlat
	var wifiMgr wifi.WifiManager
	dbusClient, err := wifi.NewDefaultDBusWifiClient()
	if err != nil {
		log.Warn("D-Bus Wi-Fi donanımı bulunamadı (Mock istemci devreye alınıyor)", "err", err)
		wifiMgr = wifi.NewMockWifiClient()
	} else {
		defer dbusClient.Close()
		wifiMgr = dbusClient
		log.Info("D-Bus NetworkManager Wi-Fi istemcisi başarıyla bağlandı")
	}

	// Modüler BluetoothManager istemcisini başlat
	var btMgr bluetooth.BluetoothManager
	btClient, err := bluetooth.NewDefaultDBusClient()
	if err != nil {
		log.Warn("D-Bus Bluetooth donanımı bulunamadı (Mock istemci devreye alınıyor)", "err", err)
		btMgr = bluetooth.NewMockBluetoothClient()
	} else {
		defer btClient.Close()
		btMgr = btClient
		log.Info("D-Bus BlueZ Bluetooth istemcisi başarıyla bağlandı")
	}

	// Kalıcı AlarmManager servisini başlat
	alarmMgr, err := alarm.NewDefaultAlarmManager()
	if err != nil {
		log.Error("Alarm servisi başlatılamadı", "err", err)
	} else {
		defer alarmMgr.Close()
		alarmMgr.SetTriggerCallback(func(a alarm.Alarm) {
			log.Info("⏰ ALARM ÇALIYOR!", "id", a.ID, "label", a.Label, "time", a.Time)
			payloadBytes, _ := json.Marshal(alarm.AlarmTriggeredPayload{
				ID:    a.ID,
				Label: a.Label,
				Time:  a.Time,
			})
			_ = server.Broadcast(ipc.Event{
				Type:    "alarm_triggered",
				Payload: payloadBytes,
			})
		})
		alarmMgr.SetUpdateCallback(func(alarms []alarm.Alarm) {
			payloadBytes, _ := json.Marshal(alarms)
			_ = server.Broadcast(ipc.Event{
				Type:    "alarms_update",
				Payload: payloadBytes,
			})
		})
		alarmMgr.Start(ctx)
		log.Info("Alarm servisi başarıyla başlatıldı")
	}

	// Kalıcı CalendarManager servisini başlat
	calendarMgr, err := calendar.NewDefaultCalendarManager()
	if err != nil {
		log.Error("Takvim servisi başlatılamadı", "err", err)
	} else {
		defer calendarMgr.Close()
		calendarMgr.SetReminderCallback(func(p calendar.CalendarReminderTriggeredPayload) {
			log.Info("📅 TAKVİM HATIRLATMASI!", "id", p.ID, "title", p.Title, "date", p.Date, "time", p.Time)
			payloadBytes, _ := json.Marshal(p)
			_ = server.Broadcast(ipc.Event{
				Type:    "calendar_reminder_triggered",
				Payload: payloadBytes,
			})
		})
		calendarMgr.SetEventsUpdateCallback(func(events []calendar.CalendarEvent) {
			payloadBytes, _ := json.Marshal(events)
			_ = server.Broadcast(ipc.Event{
				Type:    "calendar_events_update",
				Payload: payloadBytes,
			})
		})
		calendarMgr.Start(ctx)
		log.Info("Takvim ve tatil servisi başarıyla başlatıldı")
	}

	// Kalıcı NotificationManager servisini başlat
	notifMgr, err := notifications.NewDefaultNotificationManager("", "")
	if err != nil {
		log.Error("Bildirim servisi başlatılamadı", "err", err)
	} else {
		defer notifMgr.Close()
		notifMgr.SetUpdateCallback(func(notifs []notifications.Notification) {
			payloadBytes, _ := json.Marshal(notifs)
			_ = server.Broadcast(ipc.Event{
				Type:    "notifications_update",
				Payload: payloadBytes,
			})
		})
		notifMgr.SetDNDCallback(func(dnd bool) {
			payloadBytes, _ := json.Marshal(map[string]bool{"dnd_enabled": dnd})
			_ = server.Broadcast(ipc.Event{
				Type:    "dnd_update",
				Payload: payloadBytes,
			})
		})
		notifMgr.SetRulesCallback(func(rules []notifications.NotificationRule) {
			payloadBytes, _ := json.Marshal(rules)
			_ = server.Broadcast(ipc.Event{
				Type:    "notification_rules_update",
				Payload: payloadBytes,
			})
		})
		notifMgr.Start(ctx)
		log.Info("Bildirim ve DND yöneticisi başarıyla başlatıldı")
	}

	// Kalıcı ClipboardManager servisini başlat
	clipMgr, err := clipboard.NewDefaultClipboardManager("")
	if err != nil {
		log.Error("Pano servisi başlatılamadı", "err", err)
	} else {
		defer clipMgr.Close()
		clipMgr.SetUpdateCallback(func(items []clipboard.ClipboardItem) {
			payloadBytes, _ := json.Marshal(items)
			_ = server.Broadcast(ipc.Event{
				Type:    "clipboard_update",
				Payload: payloadBytes,
			})
		})
		clipMgr.SetCopiedCallback(func(item clipboard.ClipboardItem) {
			payloadBytes, _ := json.Marshal(clipboard.ClipboardItemCopiedPayload{
				ID:      item.ID,
				Preview: item.Preview,
				Type:    item.Type,
			})
			_ = server.Broadcast(ipc.Event{
				Type:    "clipboard_item_copied",
				Payload: payloadBytes,
			})
		})
		clipMgr.SetPinnedCallback(func(items []clipboard.PinnedItem) {
			payloadBytes, _ := json.Marshal(items)
			_ = server.Broadcast(ipc.Event{
				Type:    "pinned_clipboard_update",
				Payload: payloadBytes,
			})
		})
		clipMgr.Start(ctx)
		log.Info("Pano yöneticisi başarıyla başlatıldı")
	}

	// Klavye düzeni yöneticisini başlat
	kbMgr, err := keyboard.NewDefaultKeyboardManager()
	if err != nil {
		log.Error("Klavye servisi başlatılamadı", "err", err)
	} else {
		defer kbMgr.Close()
		kbMgr.SetUpdateCallback(func(state *keyboard.KeyboardState) {
			payloadBytes, _ := json.Marshal(state)
			_ = server.Broadcast(ipc.Event{
				Type:    "keyboard_layout_update",
				Payload: payloadBytes,
			})
		})
		kbMgr.Start(ctx)
		log.Info("Klavye düzeni yöneticisi başarıyla başlatıldı")
	}

	// Sistem geneli tema yöneticisini başlat
	var wallpaperAdapter *adapters.WallpaperAdapter
	themeMgr, err := theme.NewDefaultThemeManager("", "")
	if err != nil {
		log.Error("Tema servisi başlatılamadı", "err", err)
	} else {
		defer themeMgr.Close()
		wallpaperAdapter = adapters.NewWallpaperAdapter()
		// Adaptörleri kaydet
		themeMgr.RegisterAdapters(
			adapters.NewHyprlandAdapter(),
			adapters.NewKittyAdapter(),
			adapters.NewZedAdapter(),
			adapters.NewVesktopAdapter(),
			adapters.NewNvimAdapter(),
			adapters.NewDolphinQtAdapter(),
			adapters.NewBtopAdapter(),
			adapters.NewGtkAdapter(),
			adapters.NewTmuxAdapter(),
			adapters.NewIntelliJAdapter(),
			wallpaperAdapter,
		)
		themeMgr.SetUpdateCallback(func(state *theme.ThemeState) {
			payloadBytes, _ := json.Marshal(state)
			_ = server.Broadcast(ipc.Event{
				Type:    "theme_update",
				Payload: payloadBytes,
			})
		})
		themeMgr.Start(ctx)
		log.Info("Tema yöneticisi ve adaptörleri başarıyla başlatıldı")
	}

	// Uygulama Arama ve Başlatma (Launcher) servisini başlat
	launcherMgr, err := launcher.NewDefaultLauncherManager("", nil)
	if err != nil {
		log.Error("Launcher servisi başlatılamadı", "err", err)
	} else {
		defer launcherMgr.Close()
		launcherMgr.SetUpdateCallback(func(apps []entry.AppEntry) {
			payloadBytes, _ := json.Marshal(apps)
			_ = server.Broadcast(ipc.Event{
				Type:    "app_list_data",
				Payload: payloadBytes,
			})
		})
		launcherMgr.Start(ctx)
		log.Info("Launcher servisi başarıyla başlatıldı")
	}

	// Socket üzerinden gelecek RPC komutlarını işleyecek Handler
	server.SetActionHandler(func(action ipc.Action) error {
		switch action.Name {
		case "get_calendar_month":
			if calendarMgr == nil {
				return fmt.Errorf("takvim servisi devrede değil")
			}
			var p calendar.GetCalendarMonthPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			monthData := calendarMgr.GetMonthData(p.Year, p.Month)
			payloadBytes, _ := json.Marshal(monthData)
			return server.Broadcast(ipc.Event{
				Type:    "calendar_month_data",
				Payload: payloadBytes,
			})

		case "add_calendar_event":
			if calendarMgr == nil {
				return fmt.Errorf("takvim servisi devrede değil")
			}
			var p calendar.AddCalendarEventPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("add_calendar_event args çözülemedi: %w", err)
			}
			created, err := calendarMgr.AddEvent(calendar.CalendarEvent{
				Title:               p.Title,
				Description:         p.Description,
				Date:                p.Date,
				Time:                p.Time,
				AllDay:              p.AllDay,
				Color:               p.Color,
				NotifyBeforeMinutes: p.NotifyBeforeMinutes,
			})
			if err != nil {
				return fmt.Errorf("etkinlik eklenemedi: %w", err)
			}
			log.Info("Yeni takvim etkinliği eklendi", "id", created.ID, "title", created.Title)
			return nil

		case "update_calendar_event":
			if calendarMgr == nil {
				return fmt.Errorf("takvim servisi devrede değil")
			}
			var p calendar.UpdateCalendarEventPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("update_calendar_event args çözülemedi: %w", err)
			}
			_, err := calendarMgr.UpdateEvent(p)
			return err

		case "delete_calendar_event":
			if calendarMgr == nil {
				return fmt.Errorf("takvim servisi devrede değil")
			}
			var p calendar.DeleteCalendarEventPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("delete_calendar_event args çözülemedi: %w", err)
			}
			return calendarMgr.DeleteEvent(p.ID)

		case "toggle_calendar_event":
			if calendarMgr == nil {
				return fmt.Errorf("takvim servisi devrede değil")
			}
			var p calendar.ToggleCalendarEventPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("toggle_calendar_event args çözülemedi: %w", err)
			}
			_, err := calendarMgr.ToggleEventCompleted(p.ID, p.Completed)
			return err

		case "get_holidays":
			if calendarMgr == nil {
				return fmt.Errorf("takvim servisi devrede değil")
			}
			var p calendar.GetHolidaysPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			holidays := calendarMgr.GetHolidays(p.Year)
			payloadBytes, _ := json.Marshal(holidays)
			return server.Broadcast(ipc.Event{
				Type:    "holidays_data",
				Payload: payloadBytes,
			})

		case "sync_holidays":
			if calendarMgr == nil {
				return fmt.Errorf("takvim servisi devrede değil")
			}
			var p calendar.GetHolidaysPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			go func(year int) {
				holidays, err := calendarMgr.SyncHolidays(ctx, year)
				if err == nil {
					payloadBytes, _ := json.Marshal(holidays)
					_ = server.Broadcast(ipc.Event{
						Type:    "holidays_data",
						Payload: payloadBytes,
					})
					now := time.Now()
					monthData := calendarMgr.GetMonthData(now.Year(), int(now.Month()))
					mDataBytes, _ := json.Marshal(monthData)
					_ = server.Broadcast(ipc.Event{
						Type:    "calendar_month_data",
						Payload: mDataBytes,
					})
				}
			}(p.Year)
			return nil
		case "add_alarm":
			if alarmMgr == nil {
				return fmt.Errorf("alarm servisi devrede değil")
			}
			var p alarm.AddAlarmPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("add_alarm args çözülemedi: %w", err)
			}
			enabled := true
			if p.Enabled != nil {
				enabled = *p.Enabled
			}
			created, err := alarmMgr.AddAlarm(alarm.Alarm{
				Time:      p.Time,
				Days:      p.Days,
				Label:     p.Label,
				Enabled:   enabled,
				SoundPath: p.SoundPath,
			})
			if err != nil {
				return fmt.Errorf("alarm eklenemedi: %w", err)
			}
			log.Info("Yeni alarm eklendi", "id", created.ID, "time", created.Time, "label", created.Label)
			return nil

		case "delete_alarm":
			if alarmMgr == nil {
				return fmt.Errorf("alarm servisi devrede değil")
			}
			var p alarm.DeleteAlarmPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("delete_alarm args çözülemedi: %w", err)
			}
			log.Info("Alarm siliniyor", "id", p.ID)
			return alarmMgr.DeleteAlarm(p.ID)

		case "toggle_alarm":
			if alarmMgr == nil {
				return fmt.Errorf("alarm servisi devrede değil")
			}
			var p alarm.ToggleAlarmPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("toggle_alarm args çözülemedi: %w", err)
			}
			log.Info("Alarm durumu değiştiriliyor", "id", p.ID)
			_, err := alarmMgr.ToggleAlarm(p.ID, p.Enabled)
			return err

		case "snooze_alarm":
			if alarmMgr == nil {
				return fmt.Errorf("alarm servisi devrede değil")
			}
			var p alarm.SnoozeAlarmPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			log.Info("Alarm erteleniyor", "id", p.ID, "minutes", p.Minutes)
			_, err := alarmMgr.SnoozeAlarm(p.ID, p.Minutes)
			return err

		case "dismiss_alarm":
			if alarmMgr == nil {
				return fmt.Errorf("alarm servisi devrede değil")
			}
			var p alarm.DismissAlarmPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			log.Info("Alarm kapatılıyor / durduruluyor", "id", p.ID)
			return alarmMgr.DismissAlarm(p.ID)

		case "get_alarms":
			if alarmMgr == nil {
				return fmt.Errorf("alarm servisi devrede değil")
			}
			alarms := alarmMgr.GetAlarms()
			payloadBytes, _ := json.Marshal(alarms)
			return server.Broadcast(ipc.Event{
				Type:    "alarms_update",
				Payload: payloadBytes,
			})
		case "toggle_bluetooth":
			var p bluetooth.ToggleBluetoothPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			if p.Enabled != nil {
				log.Info("Bluetooth gücü ayarlanıyor", "enabled", *p.Enabled)
				return btMgr.SetPowered(ctx, *p.Enabled)
			}
			log.Info("Bluetooth gücü değiştiriliyor (toggle)")
			return btMgr.TogglePower(ctx)

		case "connect_bluetooth":
			var p bluetooth.ConnectBluetoothPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("connect_bluetooth args çözülemedi: %w", err)
			}
			log.Info("Bluetooth bağlantı isteği", "mac", p.MAC)
			return btMgr.ConnectDevice(ctx, p.MAC)

		case "disconnect_bluetooth":
			var p bluetooth.DisconnectBluetoothPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("disconnect_bluetooth args çözülemedi: %w", err)
			}
			log.Info("Bluetooth bağlantı kesme isteği", "mac", p.MAC)
			return btMgr.DisconnectDevice(ctx, p.MAC)

		case "start_bluetooth_scan":
			log.Info("Bluetooth 15s tarama başlatılıyor")
			return btMgr.StartDiscoveryWithTimeout(ctx, 15*time.Second)

		case "stop_bluetooth_scan":
			log.Info("Bluetooth tarama durduruluyor")
			return btMgr.StopDiscovery(ctx)

		case "get_bluetooth_state":
			state, err := btMgr.GetState(ctx)
			if err != nil {
				return err
			}
			payloadBytes, _ := json.Marshal(state)
			return server.Broadcast(ipc.Event{
				Type:    "bluetooth_update",
				Payload: payloadBytes,
			})
		case "scan_wifi":
			log.Info("Wi-Fi tarama isteği alındı")
			go func() {
				_ = wifiMgr.RequestScan(ctx)
			}()
			aps, err := wifiMgr.ScanNetworks(ctx)
			if err != nil {
				return fmt.Errorf("tarama hatası: %w", err)
			}
			payloadBytes, _ := json.Marshal(aps)
			_ = server.Broadcast(ipc.Event{
				Type:    "wifi_update",
				Payload: payloadBytes,
			})
			return server.Broadcast(ipc.Event{
				Type:    "wifi_scan_results",
				Payload: payloadBytes,
			})

		case "get_saved_wifi_profiles":
			log.Info("Kayıtlı Wi-Fi profilleri isteniyor")
			profiles, err := wifiMgr.GetSavedProfiles(ctx)
			if err != nil {
				return fmt.Errorf("profiller listelenemedi: %w", err)
			}
			payloadBytes, _ := json.Marshal(profiles)
			return server.Broadcast(ipc.Event{
				Type:    "saved_wifi_profiles",
				Payload: payloadBytes,
			})

		case "get_wifi_secrets":
			var p GetSecretsPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("get_wifi_secrets args çözülemedi: %w", err)
			}
			log.Info("Wi-Fi şifre bilgisi isteniyor", "target", p.SSIDOrUUID)
			sec, err := wifiMgr.GetProfileSecrets(ctx, p.SSIDOrUUID)
			if err != nil {
				return fmt.Errorf("şifre okunamadı: %w", err)
			}
			payloadBytes, _ := json.Marshal(sec)
			return server.Broadcast(ipc.Event{
				Type:    "wifi_secrets",
				Payload: payloadBytes,
			})

		case "connect_wifi":
			var p ConnectWifiPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("connect_wifi args çözülemedi: %w", err)
			}
			log.Info("Wi-Fi bağlantı isteği tetikleniyor", "ssid", p.SSID)
			return wifiMgr.Connect(ctx, wifi.ConnectRequest{
				SSID:     p.SSID,
				Password: p.Password,
				Hidden:   p.Hidden,
			})

		case "disconnect_wifi":
			log.Info("Wi-Fi kesme isteği tetikleniyor")
			return wifiMgr.Disconnect(ctx)

		case "update_wifi_secrets":
			var p UpdateSecretsPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("update_wifi_secrets args çözülemedi: %w", err)
			}
			log.Info("Wi-Fi şifre güncelleme isteği", "target", p.SSIDOrUUID)
			return wifiMgr.UpdateProfileSecrets(ctx, p.SSIDOrUUID, p.Password)

		case "delete_wifi_profile", "forget_wifi":
			var p GetSecretsPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("delete_wifi_profile args çözülemedi: %w", err)
			}
			log.Info("Wi-Fi profili siliniyor", "target", p.SSIDOrUUID)
			return wifiMgr.DeleteProfile(ctx, p.SSIDOrUUID)

		case "set_wifi_enabled":
			var p SetWifiEnabledPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("set_wifi_enabled args çözülemedi: %w", err)
			}
			log.Info("Wi-Fi gücü değiştiriliyor", "enabled", p.Enabled)
			return wifiMgr.SetWifiEnabled(ctx, p.Enabled)

		case "get_active_wifi":
			info, err := wifiMgr.GetActiveConnection(ctx)
			if err != nil {
				return err
			}
			payloadBytes, _ := json.Marshal(info)
			return server.Broadcast(ipc.Event{
				Type:    "active_wifi_info",
				Payload: payloadBytes,
			})

		case "add_notification":
			if notifMgr == nil {
				return fmt.Errorf("bildirim servisi devrede değil")
			}
			var p notifications.AddNotificationPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("add_notification args çözülemedi: %w", err)
			}
			created, shouldPopup, reason, err := notifMgr.ProcessIncoming(p)
			if err != nil {
				return fmt.Errorf("bildirim işlenemedi: %w", err)
			}
			if created != nil {
				respBytes, _ := json.Marshal(notifications.NotificationReceivedPayload{
					Notification: *created,
					ShouldPopup:  shouldPopup,
					Reason:       reason,
				})
				return server.Broadcast(ipc.Event{
					Type:    "notification_received",
					Payload: respBytes,
				})
			}
			return nil

		case "get_notifications":
			if notifMgr == nil {
				return fmt.Errorf("bildirim servisi devrede değil")
			}
			notifs := notifMgr.GetNotifications()
			payloadBytes, _ := json.Marshal(notifs)
			return server.Broadcast(ipc.Event{
				Type:    "notifications_update",
				Payload: payloadBytes,
			})

		case "delete_notification":
			if notifMgr == nil {
				return fmt.Errorf("bildirim servisi devrede değil")
			}
			var p notifications.DeleteNotificationPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("delete_notification args çözülemedi: %w", err)
			}
			return notifMgr.DeleteNotification(p.ID)

		case "clear_notifications":
			if notifMgr == nil {
				return fmt.Errorf("bildirim servisi devrede değil")
			}
			return notifMgr.ClearAll()

		case "mark_notification_read":
			if notifMgr == nil {
				return fmt.Errorf("bildirim servisi devrede değil")
			}
			var p notifications.MarkReadPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			if p.All || p.ID == "" {
				return notifMgr.MarkAllAsRead()
			}
			return notifMgr.MarkAsRead(p.ID)

		case "toggle_dnd":
			if notifMgr == nil {
				return fmt.Errorf("bildirim servisi devrede değil")
			}
			var p notifications.ToggleDNDPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			dnd := notifMgr.ToggleDND(p.Enabled)
			payloadBytes, _ := json.Marshal(map[string]bool{"dnd_enabled": dnd})
			return server.Broadcast(ipc.Event{
				Type:    "dnd_update",
				Payload: payloadBytes,
			})

		case "get_dnd_state":
			if notifMgr == nil {
				return fmt.Errorf("bildirim servisi devrede değil")
			}
			dnd := notifMgr.IsDND()
			payloadBytes, _ := json.Marshal(map[string]bool{"dnd_enabled": dnd})
			return server.Broadcast(ipc.Event{
				Type:    "dnd_update",
				Payload: payloadBytes,
			})

		case "set_notification_rule":
			if notifMgr == nil {
				return fmt.Errorf("bildirim servisi devrede değil")
			}
			var p notifications.SetRulePayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("set_notification_rule args çözülemedi: %w", err)
			}
			sound := false
			if p.SoundEnabled != nil {
				sound = *p.SoundEnabled
			}
			return notifMgr.SetRule(notifications.NotificationRule{
				AppName:      p.AppName,
				Mode:         p.Mode,
				SoundEnabled: sound,
			})

		case "delete_notification_rule":
			if notifMgr == nil {
				return fmt.Errorf("bildirim servisi devrede değil")
			}
			var p notifications.DeleteRulePayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("delete_notification_rule args çözülemedi: %w", err)
			}
			return notifMgr.DeleteRule(p.AppName)

		case "get_notification_rules":
			if notifMgr == nil {
				return fmt.Errorf("bildirim servisi devrede değil")
			}
			rules := notifMgr.GetRules()
			payloadBytes, _ := json.Marshal(rules)
			return server.Broadcast(ipc.Event{
				Type:    "notification_rules_update",
				Payload: payloadBytes,
			})

		case "get_clipboard_history":
			if clipMgr == nil {
				return fmt.Errorf("pano servisi devrede değil")
			}
			var p clipboard.GetHistoryPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			items, err := clipMgr.GetHistory(p.Limit, p.Query)
			if err != nil {
				return fmt.Errorf("pano geçmişi alınamadı: %w", err)
			}
			payloadBytes, _ := json.Marshal(items)
			return server.Broadcast(ipc.Event{
				Type:    "clipboard_update",
				Payload: payloadBytes,
			})

		case "copy_clipboard_item":
			if clipMgr == nil {
				return fmt.Errorf("pano servisi devrede değil")
			}
			var p clipboard.CopyItemPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("copy_clipboard_item args çözülemedi: %w", err)
			}
			return clipMgr.CopyItem(p.ID, p.Text)

		case "get_clipboard_content":
			if clipMgr == nil {
				return fmt.Errorf("pano servisi devrede değil")
			}
			var p clipboard.GetItemContentPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("get_clipboard_content args çözülemedi: %w", err)
			}
			content, err := clipMgr.GetItemContent(p.ID)
			if err != nil {
				return fmt.Errorf("pano içeriği çözülemedi: %w", err)
			}
			payloadBytes, _ := json.Marshal(clipboard.ItemContentResponse{
				ID:      p.ID,
				Content: content,
				Type:    "text",
			})
			return server.Broadcast(ipc.Event{
				Type:    "clipboard_content_data",
				Payload: payloadBytes,
			})

		case "delete_clipboard_item":
			if clipMgr == nil {
				return fmt.Errorf("pano servisi devrede değil")
			}
			var p clipboard.DeleteItemPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("delete_clipboard_item args çözülemedi: %w", err)
			}
			return clipMgr.DeleteItem(p.ID)

		case "clear_clipboard_history":
			if clipMgr == nil {
				return fmt.Errorf("pano servisi devrede değil")
			}
			return clipMgr.ClearHistory()

		case "pin_clipboard_item":
			if clipMgr == nil {
				return fmt.Errorf("pano servisi devrede değil")
			}
			var p clipboard.PinItemPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("pin_clipboard_item args çözülemedi: %w", err)
			}
			_, err := clipMgr.PinItem(p.ID, p.Text, p.Label)
			return err

		case "unpin_clipboard_item":
			if clipMgr == nil {
				return fmt.Errorf("pano servisi devrede değil")
			}
			var p clipboard.UnpinItemPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("unpin_clipboard_item args çözülemedi: %w", err)
			}
			return clipMgr.UnpinItem(p.ID)

		case "get_pinned_clipboard_items":
			if clipMgr == nil {
				return fmt.Errorf("pano servisi devrede değil")
			}
			pinned := clipMgr.GetPinned()
			payloadBytes, _ := json.Marshal(pinned)
			return server.Broadcast(ipc.Event{
				Type:    "pinned_clipboard_update",
				Payload: payloadBytes,
			})

		case "get_keyboard_layout":
			if kbMgr == nil {
				return fmt.Errorf("klavye servisi devrede değil")
			}
			state, err := kbMgr.GetState()
			if err != nil {
				return fmt.Errorf("klavye durumu alınamadı: %w", err)
			}
			payloadBytes, _ := json.Marshal(state)
			return server.Broadcast(ipc.Event{
				Type:    "keyboard_layout_update",
				Payload: payloadBytes,
			})

		case "switch_keyboard_layout":
			if kbMgr == nil {
				return fmt.Errorf("klavye servisi devrede değil")
			}
			var p keyboard.SwitchLayoutPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			state, err := kbMgr.SwitchLayout(p.Target, p.Device)
			if err != nil {
				return fmt.Errorf("klavye düzeni değiştirilemedi: %w", err)
			}
			payloadBytes, _ := json.Marshal(state)
			return server.Broadcast(ipc.Event{
				Type:    "keyboard_layout_update",
				Payload: payloadBytes,
			})

		case "set_configured_layouts":
			if kbMgr == nil {
				return fmt.Errorf("klavye servisi devrede değil")
			}
			var p keyboard.SetConfiguredLayoutsPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("set_configured_layouts args çözülemedi: %w", err)
			}
			state, err := kbMgr.SetConfiguredLayouts(p.Layouts, p.Variants)
			if err != nil {
				return fmt.Errorf("klavye düzenleri ayarlanamadı: %w", err)
			}
			payloadBytes, _ := json.Marshal(state)
			return server.Broadcast(ipc.Event{
				Type:    "keyboard_layout_update",
				Payload: payloadBytes,
			})

		case "get_available_system_layouts":
			if kbMgr == nil {
				return fmt.Errorf("klavye servisi devrede değil")
			}
			available := kbMgr.GetAvailableLayouts()
			payloadBytes, _ := json.Marshal(available)
			return server.Broadcast(ipc.Event{
				Type:    "available_layouts_data",
				Payload: payloadBytes,
			})

		case "get_theme_state":
			if themeMgr == nil {
				return fmt.Errorf("tema servisi devrede değil")
			}
			state, err := themeMgr.GetState()
			if err != nil {
				return fmt.Errorf("tema durumu alınamadı: %w", err)
			}
			payloadBytes, _ := json.Marshal(state)
			return server.Broadcast(ipc.Event{
				Type:    "theme_update",
				Payload: payloadBytes,
			})

		case "get_available_themes":
			if themeMgr == nil {
				return fmt.Errorf("tema servisi devrede değil")
			}
			themes := themeMgr.GetAvailableThemes()
			payloadBytes, _ := json.Marshal(themes)
			return server.Broadcast(ipc.Event{
				Type:    "available_themes_data",
				Payload: payloadBytes,
			})

		case "set_active_theme":
			if themeMgr == nil {
				return fmt.Errorf("tema servisi devrede değil")
			}
			var p theme.SetThemePayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("set_active_theme args çözülemedi: %w", err)
			}
			_, err := themeMgr.SetActiveTheme(p.ThemeID)
			return err

		case "save_custom_theme":
			return fmt.Errorf("özel tema ekleme devre dışı; temalar shared/themes/themes.json ile yönetilmektedir")

		case "delete_custom_theme":
			return fmt.Errorf("özel tema silme devre dışı; temalar shared/themes/themes.json ile yönetilmektedir")

		case "toggle_theme_adapter":
			if themeMgr == nil {
				return fmt.Errorf("tema servisi devrede değil")
			}
			var p theme.ToggleAdapterPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("toggle_theme_adapter args çözülemedi: %w", err)
			}
			return themeMgr.ToggleAdapter(p.AdapterID, p.Enabled)

		case "get_theme_wallpapers":
			if wallpaperAdapter == nil {
				return fmt.Errorf("wallpaper adaptörü devrede değil")
			}
			var p theme.GetThemeWallpapersPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			themeID := p.ThemeID
			if themeID == "" && themeMgr != nil {
				state, _ := themeMgr.GetState()
				if state != nil && state.ActiveTheme != nil {
					themeID = state.ActiveTheme.ID
				}
			}
			if themeID == "" {
				themeID = "everforest"
			}
			wallpapers, active, err := wallpaperAdapter.GetThemeWallpapers(themeID)
			if err != nil {
				return fmt.Errorf("duvar kağıtları alınamadı: %w", err)
			}
			payloadBytes, _ := json.Marshal(theme.ThemeWallpapersResponse{
				ThemeID:         themeID,
				ActiveWallpaper: active,
				Wallpapers:      wallpapers,
			})
			return server.Broadcast(ipc.Event{
				Type:    "theme_wallpapers_data",
				Payload: payloadBytes,
			})

		case "set_wallpaper":
			if wallpaperAdapter == nil {
				return fmt.Errorf("wallpaper adaptörü devrede değil")
			}
			var p theme.SetWallpaperPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("set_wallpaper args çözülemedi: %w", err)
			}
			if p.ThemeID == "" && themeMgr != nil {
				state, _ := themeMgr.GetState()
				if state != nil && state.ActiveTheme != nil {
					p.ThemeID = state.ActiveTheme.ID
				}
			}
			if err := wallpaperAdapter.SetSpecificWallpaper(p.ThemeID, p.WallpaperPath); err != nil {
				return err
			}
			wallpapers, active, _ := wallpaperAdapter.GetThemeWallpapers(p.ThemeID)
			payloadBytes, _ := json.Marshal(theme.ThemeWallpapersResponse{
				ThemeID:         p.ThemeID,
				ActiveWallpaper: active,
				Wallpapers:      wallpapers,
			})
			return server.Broadcast(ipc.Event{
				Type:    "theme_wallpapers_data",
				Payload: payloadBytes,
			})

		case "next_wallpaper":
			if wallpaperAdapter == nil {
				return fmt.Errorf("wallpaper adaptörü devrede değil")
			}
			var p theme.NextWallpaperPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			themeID := p.ThemeID
			if themeID == "" && themeMgr != nil {
				state, _ := themeMgr.GetState()
				if state != nil && state.ActiveTheme != nil {
					themeID = state.ActiveTheme.ID
				}
			}
			if themeID == "" {
				themeID = "everforest"
			}
			nextPath, err := wallpaperAdapter.NextWallpaper(themeID)
			if err != nil {
				return err
			}
			wallpapers, _, _ := wallpaperAdapter.GetThemeWallpapers(themeID)
			payloadBytes, _ := json.Marshal(theme.ThemeWallpapersResponse{
				ThemeID:         themeID,
				ActiveWallpaper: nextPath,
				Wallpapers:      wallpapers,
			})
			return server.Broadcast(ipc.Event{
				Type:    "theme_wallpapers_data",
				Payload: payloadBytes,
			})

		case "search_apps":
			if launcherMgr == nil {
				return fmt.Errorf("launcher servisi devrede değil")
			}
			var p entry.SearchQueryPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			results := launcherMgr.Search(p.Query, p.Limit)
			respPayload := entry.AppSearchResultPayload{
				Query:   p.Query,
				Results: results,
				Total:   len(results),
			}
			payloadBytes, _ := json.Marshal(respPayload)
			return server.Broadcast(ipc.Event{
				Type:    "app_search_results",
				Payload: payloadBytes,
			})

		case "list_apps":
			if launcherMgr == nil {
				return fmt.Errorf("launcher servisi devrede değil")
			}
			var p entry.ListAppsPayload
			if len(action.Args) > 0 {
				_ = json.Unmarshal(action.Args, &p)
			}
			apps := launcherMgr.List(p.Limit)
			payloadBytes, _ := json.Marshal(apps)
			return server.Broadcast(ipc.Event{
				Type:    "app_list_data",
				Payload: payloadBytes,
			})

		case "launch_app":
			if launcherMgr == nil {
				return fmt.Errorf("launcher servisi devrede değil")
			}
			var p entry.LaunchAppPayload
			if err := json.Unmarshal(action.Args, &p); err != nil {
				return fmt.Errorf("launch_app args çözülemedi: %w", err)
			}
			err := launcherMgr.Launch(p.ID, p.Exec)
			launchResult := entry.AppLaunchedPayload{
				ID:      p.ID,
				Success: err == nil,
			}
			if err != nil {
				launchResult.Error = err.Error()
			} else if app, ok := launcherMgr.GetAppByID(p.ID); ok {
				launchResult.Name = app.Name
			}
			payloadBytes, _ := json.Marshal(launchResult)
			_ = server.Broadcast(ipc.Event{
				Type:    "app_launched",
				Payload: payloadBytes,
			})
			return err

		case "reindex_apps":
			if launcherMgr == nil {
				return fmt.Errorf("launcher servisi devrede değil")
			}
			launcherMgr.Reindex()
			apps := launcherMgr.List(0)
			payloadBytes, _ := json.Marshal(apps)
			return server.Broadcast(ipc.Event{
				Type:    "app_list_data",
				Payload: payloadBytes,
			})

		case "toggle_launcher":
			log.Info("Uygulama başlatıcı tetiklendi (toggle_launcher)")
			return server.Broadcast(ipc.Event{
				Type:    "toggle_launcher",
				Payload: []byte("{}"),
			})

		case "open_launcher":
			log.Info("Uygulama başlatıcı açılıyor (open_launcher)")
			return server.Broadcast(ipc.Event{
				Type:    "open_launcher",
				Payload: []byte("{}"),
			})

		case "close_launcher":
			log.Info("Uygulama başlatıcı kapatılıyor (close_launcher)")
			return server.Broadcast(ipc.Event{
				Type:    "close_launcher",
				Payload: []byte("{}"),
			})
		}

		return nil
	})

	// Server'ı ayrı bir Goroutine'de başlat
	go func() {
		log.Info("IPC Sunucusu başlatılıyor... ", "socket", socketPath)
		if err := server.Start(); err != nil {
			log.Error("IPC Sunucusu hatası", "err", err)
		}
	}()

	monitorMgr := monitors.NewManager(server, btMgr)
	monitorMgr.Start(ctx)
	defer monitorMgr.Stop()

	<-ctx.Done()
	log.Info("süreç durduruluyor... ")

	// Socket dosyasını temizle
	_ = os.Remove(socketPath)
}
