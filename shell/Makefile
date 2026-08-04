CC = gcc
CFLAGS = -Wall -Wextra -O2 -pthread

SDIR = $(CURDIR)
BIN_DIR = $(SDIR)/../bin

MONITOR_SRC = $(SDIR)/services/monitor/main.c $(SDIR)/services/monitor/sys_info.c $(SDIR)/services/monitor/hw_controls.c $(SDIR)/services/monitor/media_notif.c
MONITOR_OUT = $(BIN_DIR)/monitor

WORKSPACES_SRC = $(SDIR)/services/workspaces/main.c $(SDIR)/services/workspaces/hyprland.c $(SDIR)/services/workspaces/notification.c
WORKSPACES_OUT = $(BIN_DIR)/workspaces

LAUNCHER_SRC = $(SDIR)/services/app_launcher_helper.c
LAUNCHER_OUT = $(BIN_DIR)/app_launcher_helper

WALLPAPER_SRC = $(SDIR)/services/wallpaper_helper.c
WALLPAPER_OUT = $(BIN_DIR)/wallpaper_helper

THEME_SYNC_SRC = $(SDIR)/services/theme_sync_helper.c
THEME_SYNC_OUT = $(BIN_DIR)/theme_sync_helper

all: $(BIN_DIR) $(MONITOR_OUT) $(WORKSPACES_OUT) $(LAUNCHER_OUT) $(WALLPAPER_OUT) $(THEME_SYNC_OUT)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(MONITOR_OUT): $(MONITOR_SRC)
	$(CC) $(CFLAGS) -Iservices/monitor $(MONITOR_SRC) -o $(MONITOR_OUT)

$(WORKSPACES_OUT): $(WORKSPACES_SRC)
	$(CC) $(CFLAGS) -Iservices/workspaces $(WORKSPACES_SRC) -o $(WORKSPACES_OUT)

$(LAUNCHER_OUT): $(LAUNCHER_SRC)
	$(CC) $(CFLAGS) $(LAUNCHER_SRC) -o $(LAUNCHER_OUT)

$(WALLPAPER_OUT): $(WALLPAPER_SRC)
	$(CC) $(CFLAGS) $(WALLPAPER_SRC) -o $(WALLPAPER_OUT)

$(THEME_SYNC_OUT): $(THEME_SYNC_SRC)
	$(CC) $(CFLAGS) $(THEME_SYNC_SRC) -o $(THEME_SYNC_OUT)

clean:
	rm -f $(MONITOR_OUT) $(WORKSPACES_OUT) $(LAUNCHER_OUT) $(WALLPAPER_OUT) $(THEME_SYNC_OUT)

.PHONY: all clean
