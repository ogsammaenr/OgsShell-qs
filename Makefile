CC = gcc
CFLAGS = -Wall -Wextra -O2 -pthread

PDIR = $(HOME)/WorkSpace/projects/OgsShell-qs

MONITOR_SRC = $(PDIR)/services/monitor/main.c $(PDIR)/services/monitor/sys_info.c $(PDIR)/services/monitor/hw_controls.c $(PDIR)/services/monitor/media_notif.c
MONITOR_OUT = $(PDIR)/monitor

WORKSPACES_SRC = $(PDIR)/services/workspaces/main.c $(PDIR)/services/workspaces/hyprland.c $(PDIR)/services/workspaces/notification.c
WORKSPACES_OUT = $(PDIR)/workspaces

LAUNCHER_SRC = $(PDIR)/services/app_launcher_helper.c
LAUNCHER_OUT = $(PDIR)/services/app_launcher_helper

WALLPAPER_SRC = $(PDIR)/services/wallpaper_helper.c
WALLPAPER_OUT = $(PDIR)/services/wallpaper_helper

THEME_SYNC_SRC = $(PDIR)/services/theme_sync_helper.c
THEME_SYNC_OUT = $(PDIR)/services/theme_sync_helper

all: $(MONITOR_OUT) $(WORKSPACES_OUT) $(LAUNCHER_OUT) $(WALLPAPER_OUT) $(THEME_SYNC_OUT)

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
