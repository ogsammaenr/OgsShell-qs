#include "hw_controls.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <glob.h>
#include <dirent.h>

const char* get_bluetooth_status() {
    glob_t g;
    int powered = 0;
    if (glob("/sys/class/rfkill/rfkill*", 0, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; ++i) {
            char type_path[256];
            snprintf(type_path, sizeof(type_path), "%s/type", g.gl_pathv[i]);
            FILE *f = fopen(type_path, "r");
            if (f) {
                char type[128];
                if (fscanf(f, "%127s", type) == 1 && strcmp(type, "bluetooth") == 0) {
                    fclose(f);
                    char state_path[256];
                    snprintf(state_path, sizeof(state_path), "%s/state", g.gl_pathv[i]);
                    FILE *sf = fopen(state_path, "r");
                    if (sf) {
                        int state_val = 0;
                        if (fscanf(sf, "%d", &state_val) == 1 && state_val == 1) {
                            powered = 1;
                        }
                        fclose(sf);
                    }
                    break;
                }
                fclose(f);
            }
        }
        globfree(&g);
    }
    
    if (!powered) return "off";
    
    if (glob("/sys/class/bluetooth/hci*", 0, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; ++i) {
            DIR *dir = opendir(g.gl_pathv[i]);
            if (dir) {
                struct dirent *entry;
                while ((entry = readdir(dir)) != NULL) {
                    if (strncmp(entry->d_name, "dev_", 4) == 0) {
                        closedir(dir);
                        globfree(&g);
                        return "connected";
                    }
                }
                closedir(dir);
            }
        }
        globfree(&g);
    }
    
    return "on";
}

int get_brightness() {
    glob_t g;
    int pct = 0;
    if (glob("/sys/class/backlight/*", 0, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; ++i) {
            char b_path[256], m_path[256];
            snprintf(b_path, sizeof(b_path), "%s/brightness", g.gl_pathv[i]);
            snprintf(m_path, sizeof(m_path), "%s/max_brightness", g.gl_pathv[i]);
            FILE *bf = fopen(b_path, "r");
            FILE *mf = fopen(m_path, "r");
            if (bf && mf) {
                int val, max;
                if (fscanf(bf, "%d", &val) == 1 && fscanf(mf, "%d", &max) == 1 && max > 0) {
                    pct = val * 100 / max;
                    fclose(bf);
                    fclose(mf);
                    break;
                }
            }
            if (bf) fclose(bf);
            if (mf) fclose(mf);
        }
        globfree(&g);
    }
    return pct;
}

int get_wifi_status(char *ssid_out, size_t max_len) {
    ssid_out[0] = '\0';
    
    FILE *f = fopen("/sys/class/net/wlan0/operstate", "r");
    if (!f) return 0;
    char state_val[64] = {0};
    if (fscanf(f, "%63s", state_val) != 1) {
        fclose(f);
        return 0;
    }
    fclose(f);
    
    int carrier = 0;
    FILE *cf = fopen("/sys/class/net/wlan0/carrier", "r");
    if (cf) {
        if (fscanf(cf, "%d", &carrier) != 1) {
            carrier = 0;
        }
        fclose(cf);
    }
    
    if (strcmp(state_val, "up") == 0 || carrier == 1) {
        FILE *p = popen("iwgetid -r wlan0 2>/dev/null", "r");
        if (p) {
            if (fgets(ssid_out, max_len, p)) {
                size_t len = strlen(ssid_out);
                if (len > 0 && ssid_out[len - 1] == '\n') {
                    ssid_out[len - 1] = '\0';
                }
            }
            pclose(p);
        }
        if (strlen(ssid_out) == 0) {
            strncpy(ssid_out, "Connected", max_len);
        }
        return 1;
    }
    return 0;
}

void get_audio_volume(int *volume, int *muted) {
    *volume = 0;
    *muted = 0;
    
    FILE *p = popen("amixer sget Master 2>/dev/null", "r");
    if (!p) return;
    
    char line[256];
    while (fgets(line, sizeof(line), p)) {
        char *p_vol = strchr(line, '[');
        if (p_vol) {
            int val;
            if (sscanf(p_vol + 1, "%d%%", &val) == 1) {
                *volume = val;
            }
            char *p_mute = strchr(p_vol + 1, '[');
            if (p_mute) {
                if (strncmp(p_mute + 1, "off", 3) == 0) {
                    *muted = 1;
                } else if (strncmp(p_mute + 1, "on", 2) == 0) {
                    *muted = 0;
                }
            }
        }
    }
    pclose(p);
}

void get_keyboard_layout(char *layout_out, size_t max_len) {
    strncpy(layout_out, "TR", max_len);
    FILE *p = popen("hyprctl devices 2>/dev/null", "r");
    if (!p) return;
    char line[256];
    char current_keymap[128] = {0};
    int is_main = 0;
    while (fgets(line, sizeof(line), p)) {
        if (strstr(line, "Keyboard at")) {
            if (is_main && current_keymap[0] != '\0') {
                break;
            }
            is_main = 0;
            current_keymap[0] = '\0';
        }
        char *keymap_ptr = strstr(line, "active keymap: ");
        if (keymap_ptr) {
            strncpy(current_keymap, keymap_ptr + 15, sizeof(current_keymap) - 1);
            size_t len = strlen(current_keymap);
            if (len > 0 && current_keymap[len - 1] == '\n') {
                current_keymap[len - 1] = '\0';
            }
        }
        if (strstr(line, "main: yes")) {
            is_main = 1;
        }
    }
    pclose(p);

    if (current_keymap[0] != '\0') {
        if (strstr(current_keymap, "Turkish")) {
            strncpy(layout_out, "TR", max_len);
        } else if (strstr(current_keymap, "English") || strstr(current_keymap, "US")) {
            strncpy(layout_out, "EN", max_len);
        } else {
            strncpy(layout_out, current_keymap, max_len);
        }
    }
}
