#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <dirent.h>
#include <ctype.h>

#define PATH_MAX_LEN 1024

// Utility: Ensure directory exists
static void ensure_dir(const char *path) {
    char temp[PATH_MAX_LEN];
    snprintf(temp, sizeof(temp), "%s", path);
    size_t len = strlen(temp);
    if (len == 0) return;
    if (temp[len - 1] == '/') temp[len - 1] = '\0';
    for (char *p = temp + 1; *p; p++) {
        if (*p == '/') {
            *p = '\0';
            mkdir(temp, 0755);
            *p = '/';
        }
    }
    mkdir(temp, 0755);
}

// Utility: Copy binary file from src to dst
static int copy_file(const char *src, const char *dst) {
    FILE *in = fopen(src, "rb");
    if (!in) return 0;
    
    char dst_dir[PATH_MAX_LEN];
    snprintf(dst_dir, sizeof(dst_dir), "%s", dst);
    char *last_slash = strrchr(dst_dir, '/');
    if (last_slash) {
        *last_slash = '\0';
        ensure_dir(dst_dir);
    }
    
    FILE *out = fopen(dst, "wb");
    if (!out) {
        fclose(in);
        return 0;
    }
    
    char buf[8192];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), in)) > 0) {
        fwrite(buf, 1, n, out);
    }
    
    fclose(in);
    fclose(out);
    return 1;
}

// Helper to update key=value in an INI section or create if missing
static void set_ini_key(const char *ini_path, const char *section, const char *key, const char *val) {
    FILE *f = fopen(ini_path, "r");
    if (!f) {
        FILE *out = fopen(ini_path, "w");
        if (out) {
            fprintf(out, "[%s]\n%s=%s\n", section, key, val);
            fclose(out);
        }
        return;
    }

    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);

    char *content = malloc(sz + 1);
    if (!content) { fclose(f); return; }
    fread(content, 1, sz, f);
    content[sz] = '\0';
    fclose(f);

    char target_key[256];
    snprintf(target_key, sizeof(target_key), "%s=", key);
    char *pos = strstr(content, target_key);

    if (pos) {
        FILE *out = fopen(ini_path, "w");
        if (out) {
            fwrite(content, 1, pos - content, out);
            fprintf(out, "%s=%s", key, val);
            char *line_end = strchr(pos, '\n');
            if (line_end) fputs(line_end, out);
            fclose(out);
        }
    } else {
        FILE *out = fopen(ini_path, "a");
        if (out) {
            fprintf(out, "\n[%s]\n%s=%s\n", section, key, val);
            fclose(out);
        }
    }
    free(content);
}

// 1. Sync Qt5, Qt6, Dolphin, KDE Apps (Clearing & Updating Per-App Theme Locks + plasma-apply-colorscheme)
static void sync_qt(const char *theme_id, const char *pdir, const char *home) {
    char src_qt[PATH_MAX_LEN];
    char src_kdeglobals[PATH_MAX_LEN];
    snprintf(src_qt, sizeof(src_qt), "%s/shared/app_configs/qt/%s.conf", pdir, theme_id);
    snprintf(src_kdeglobals, sizeof(src_kdeglobals), "%s/shared/app_configs/dolphin/%s.kdeglobals", pdir, theme_id);

    const char *scheme_name = "OgsNord";
    if (strcmp(theme_id, "catppuccin") == 0) scheme_name = "OgsCatppuccin";
    else if (strcmp(theme_id, "nord") == 0) scheme_name = "OgsNord";
    else if (strcmp(theme_id, "tokyonight") == 0) scheme_name = "OgsTokyoNight";
    else if (strcmp(theme_id, "everforest") == 0) scheme_name = "OgsEverforest";
    else if (strcmp(theme_id, "gruvbox") == 0) scheme_name = "OgsGruvbox";
    else if (strcmp(theme_id, "monochrome") == 0) scheme_name = "OgsMonochrome";

    // A. Deploy KDE color scheme file to ~/.local/share/color-schemes/ and ~/.config/kdeglobals
    char kde_schemes_dir[PATH_MAX_LEN];
    char color_scheme_dst[PATH_MAX_LEN];
    char dst_kdeglobals[PATH_MAX_LEN];

    snprintf(kde_schemes_dir, sizeof(kde_schemes_dir), "%s/.local/share/color-schemes", home);
    snprintf(color_scheme_dst, sizeof(color_scheme_dst), "%s/%s.colors", kde_schemes_dir, scheme_name);
    snprintf(dst_kdeglobals, sizeof(dst_kdeglobals), "%s/.config/kdeglobals", home);

    ensure_dir(kde_schemes_dir);
    copy_file(src_kdeglobals, color_scheme_dst);
    copy_file(src_kdeglobals, dst_kdeglobals);

    // B. Clear & Update per-application KDE theme locks (dolphinrc, katerc, okularrc, etc.)
    const char *kde_app_rcs[] = {
        "dolphinrc", "katerc", "okularrc", "kdenliverc", "konsolerc", NULL
    };
    for (int i = 0; kde_app_rcs[i] != NULL; i++) {
        char app_rc_path[PATH_MAX_LEN];
        snprintf(app_rc_path, sizeof(app_rc_path), "%s/.config/%s", home, kde_app_rcs[i]);
        set_ini_key(app_rc_path, "UiSettings", "ColorScheme", scheme_name);
    }

    char kdedefaults_path[PATH_MAX_LEN];
    snprintf(kdedefaults_path, sizeof(kdedefaults_path), "%s/.config/kdedefaults/kdeglobals", home);
    set_ini_key(kdedefaults_path, "General", "ColorScheme", scheme_name);

    // C. Update qt5ct and qt6ct to use clean Breeze widget style with custom palette
    for (int ver = 5; ver <= 6; ver++) {
        char ct_dir[PATH_MAX_LEN];
        char style_colors[PATH_MAX_LEN];
        char color_file[PATH_MAX_LEN];
        char conf_file[PATH_MAX_LEN];

        snprintf(ct_dir, sizeof(ct_dir), "%s/.config/qt%dct", home, ver);
        snprintf(style_colors, sizeof(style_colors), "%s/style-colors.conf", ct_dir);
        snprintf(color_file, sizeof(color_file), "%s/colors/%s.conf", ct_dir, theme_id);
        snprintf(conf_file, sizeof(conf_file), "%s/qt%dct.conf", ct_dir, ver);

        ensure_dir(ct_dir);
        copy_file(src_qt, style_colors);
        copy_file(src_qt, color_file);

        set_ini_key(conf_file, "Appearance", "style", "Breeze");
        set_ini_key(conf_file, "Appearance", "custom_palette", "true");
        set_ini_key(conf_file, "Appearance", "color_scheme_path", color_file);
    }

    // D. Clean up Kvantum overrides if present
    char kv_conf[PATH_MAX_LEN];
    snprintf(kv_conf, sizeof(kv_conf), "%s/.config/Kvantum/kvantum.kvconfig", home);
    FILE *kf = fopen(kv_conf, "w");
    if (kf) {
        fprintf(kf, "[General]\ntheme=KvAdaptaDark\n\n[Applications]\n");
        fclose(kf);
    }

    // E. Execute official KDE plasma-apply-colorscheme CLI and broadcast comprehensive live DBus notifications
    char cmd[2048];
    snprintf(cmd, sizeof(cmd),
        "plasma-apply-colorscheme %s 2>/dev/null || true; "
        "kwriteconfig6 --file kdeglobals --group General --key ColorScheme %s 2>/dev/null || true; "
        "kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme %s 2>/dev/null || true; "
        "kwriteconfig5 --file kdeglobals --group General --key ColorScheme %s 2>/dev/null || true; "
        "dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:2 int32:0 2>/dev/null || true; "
        "qdbus org.kde.KGlobalSettings /KGlobalSettings notifyChange 2 0 2>/dev/null || true; "
        "qdbus6 org.kde.KGlobalSettings /KGlobalSettings notifyChange 2 0 2>/dev/null || true; "
        "gdbus emit --session --object-path /kdeglobals --signal org.kde.kconfig.notify 2>/dev/null || true; "
        "dbus-send --session --type=signal /KWin org.kde.KWin.reloadConfig 2>/dev/null || true",
        scheme_name, scheme_name, scheme_name, scheme_name);
    system(cmd);
}

// 2. Sync Kitty Terminal
static void sync_kitty(const char *theme_id, const char *pdir, const char *home) {
    char src[PATH_MAX_LEN];
    char kitty_dir[PATH_MAX_LEN];
    char dst[PATH_MAX_LEN];
    char kitty_conf[PATH_MAX_LEN];

    snprintf(src, sizeof(src), "%s/shared/app_configs/kitty/%s.conf", pdir, theme_id);
    snprintf(kitty_dir, sizeof(kitty_dir), "%s/.config/kitty", home);
    snprintf(dst, sizeof(dst), "%s/current-theme.conf", kitty_dir);
    snprintf(kitty_conf, sizeof(kitty_conf), "%s/kitty.conf", kitty_dir);

    ensure_dir(kitty_dir);
    if (copy_file(src, dst)) {
        FILE *kf = fopen(kitty_conf, "a+");
        if (kf) {
            fseek(kf, 0, SEEK_SET);
            char line[256];
            int has_include = 0;
            while (fgets(line, sizeof(line), kf)) {
                if (strstr(line, "current-theme.conf")) {
                    has_include = 1;
                    break;
                }
            }
            if (!has_include) {
                fprintf(kf, "\ninclude current-theme.conf\n");
            }
            fclose(kf);
        }
        system("killall -SIGUSR1 kitty 2>/dev/null || true");
    }
}

// 3. Sync Zed Editor (Editor + File Tree Panel)
static void sync_zed(const char *theme_id, const char *pdir, const char *home) {
    char src[PATH_MAX_LEN];
    char zed_themes_dir[PATH_MAX_LEN];
    char dst_theme[PATH_MAX_LEN];
    char settings_path[PATH_MAX_LEN];

    snprintf(src, sizeof(src), "%s/shared/app_configs/zed/%s.json", pdir, theme_id);
    snprintf(zed_themes_dir, sizeof(zed_themes_dir), "%s/.config/zed/themes", home);
    snprintf(dst_theme, sizeof(dst_theme), "%s/%s.json", zed_themes_dir, theme_id);
    snprintf(settings_path, sizeof(settings_path), "%s/.config/zed/settings.json", home);

    ensure_dir(zed_themes_dir);
    copy_file(src, dst_theme);

    const char *zed_theme_name = "Nord";
    if (strcmp(theme_id, "catppuccin") == 0) zed_theme_name = "Catppuccin Mocha";
    else if (strcmp(theme_id, "nord") == 0) zed_theme_name = "Nord";
    else if (strcmp(theme_id, "tokyonight") == 0) zed_theme_name = "Tokyo Night";
    else if (strcmp(theme_id, "everforest") == 0) zed_theme_name = "Everforest Dark Hard";
    else if (strcmp(theme_id, "gruvbox") == 0) zed_theme_name = "Gruvbox Dark";
    else if (strcmp(theme_id, "monochrome") == 0) zed_theme_name = "Monochrome High Contrast";

    FILE *f = fopen(settings_path, "r");
    if (!f) return;
    
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);

    char *content = malloc(sz + 1);
    if (!content) { fclose(f); return; }
    fread(content, 1, sz, f);
    content[sz] = '\0';
    fclose(f);

    char *theme_pos = strstr(content, "\"theme\"");
    if (theme_pos) {
        char *colon = strchr(theme_pos, ':');
        if (colon) {
            char *quote1 = strchr(colon, '"');
            if (quote1) {
                char *quote2 = strchr(quote1 + 1, '"');
                if (quote2) {
                    FILE *out = fopen(settings_path, "w");
                    if (out) {
                        fwrite(content, 1, quote1 - content, out);
                        fprintf(out, "\"%s\"", zed_theme_name);
                        fputs(quote2 + 1, out);
                        fclose(out);
                    }
                }
            }
        }
    }
    free(content);
}

// 4. Sync Zen Browser across ALL profiles
static void sync_zen(const char *theme_id, const char *pdir, const char *home) {
    char zen_dir[PATH_MAX_LEN];
    snprintf(zen_dir, sizeof(zen_dir), "%s/.zen", home);
    char src_css[PATH_MAX_LEN];
    snprintf(src_css, sizeof(src_css), "%s/shared/app_configs/zen/%s.css", pdir, theme_id);

    DIR *d = opendir(zen_dir);
    if (!d) return;

    struct dirent *entry;
    while ((entry = readdir(d)) != NULL) {
        if (entry->d_type == DT_DIR && strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
            char chrome_dir[PATH_MAX_LEN];
            snprintf(chrome_dir, sizeof(chrome_dir), "%s/%s/chrome", zen_dir, entry->d_name);
            
            char check_file[PATH_MAX_LEN];
            snprintf(check_file, sizeof(check_file), "%s/%s/prefs.js", zen_dir, entry->d_name);
            if (access(check_file, F_OK) == 0 || strstr(entry->d_name, "Default")) {
                ensure_dir(chrome_dir);
                char dst_css[PATH_MAX_LEN];
                char dst_content_css[PATH_MAX_LEN];
                snprintf(dst_css, sizeof(dst_css), "%s/userChrome.css", chrome_dir);
                snprintf(dst_content_css, sizeof(dst_content_css), "%s/userContent.css", chrome_dir);

                copy_file(src_css, dst_css);
                copy_file(src_css, dst_content_css);
            }
        }
    }
    closedir(d);
}

// 5. Sync GTK3 & GTK4
static void sync_gtk(const char *theme_id, const char *pdir, const char *home) {
    char src_ini[PATH_MAX_LEN];
    char src_css[PATH_MAX_LEN];
    char dst_gtk3_ini[PATH_MAX_LEN];
    char dst_gtk4_ini[PATH_MAX_LEN];
    char dst_gtk3_css[PATH_MAX_LEN];
    char dst_gtk4_css[PATH_MAX_LEN];

    snprintf(src_ini, sizeof(src_ini), "%s/shared/app_configs/gtk/%s.ini", pdir, theme_id);
    snprintf(src_css, sizeof(src_css), "%s/shared/app_configs/gtk/%s.css", pdir, theme_id);

    snprintf(dst_gtk3_ini, sizeof(dst_gtk3_ini), "%s/.config/gtk-3.0/settings.ini", home);
    snprintf(dst_gtk4_ini, sizeof(dst_gtk4_ini), "%s/.config/gtk-4.0/settings.ini", home);

    snprintf(dst_gtk3_css, sizeof(dst_gtk3_css), "%s/.config/gtk-3.0/gtk.css", home);
    snprintf(dst_gtk4_css, sizeof(dst_gtk4_css), "%s/.config/gtk-4.0/gtk.css", home);

    copy_file(src_ini, dst_gtk3_ini);
    copy_file(src_ini, dst_gtk4_ini);
    copy_file(src_css, dst_gtk3_css);
    copy_file(src_css, dst_gtk4_css);

    const char *gtk_theme = (strcmp(theme_id, "nord") == 0) ? "Nordic" : "adw-gtk3-dark";
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null; gsettings set org.gnome.desktop.interface gtk-theme '%s' 2>/dev/null", gtk_theme);
    system(cmd);
}

// 6. Sync Neovim (LazyVim, Lua Colorschemes & Live RPC Broadcast)
static void sync_nvim(const char *theme_id, const char *pdir, const char *home) {
    char src[PATH_MAX_LEN];
    char nvim_colors_dir[PATH_MAX_LEN];
    char dst_colorscheme[PATH_MAX_LEN];
    char theme_lua[PATH_MAX_LEN];

    const char *scheme_name = "OgsNord";
    if (strcmp(theme_id, "catppuccin") == 0) scheme_name = "OgsCatppuccin";
    else if (strcmp(theme_id, "nord") == 0) scheme_name = "OgsNord";
    else if (strcmp(theme_id, "tokyonight") == 0) scheme_name = "OgsTokyoNight";
    else if (strcmp(theme_id, "everforest") == 0) scheme_name = "OgsEverforest";
    else if (strcmp(theme_id, "gruvbox") == 0) scheme_name = "OgsGruvbox";
    else if (strcmp(theme_id, "monochrome") == 0) scheme_name = "OgsMonochrome";

    snprintf(src, sizeof(src), "%s/shared/app_configs/nvim/%s.lua", pdir, theme_id);
    snprintf(nvim_colors_dir, sizeof(nvim_colors_dir), "%s/.config/nvim/colors", home);
    snprintf(dst_colorscheme, sizeof(dst_colorscheme), "%s/%s.lua", nvim_colors_dir, scheme_name);
    snprintf(theme_lua, sizeof(theme_lua), "%s/.config/nvim/lua/plugins/theme.lua", home);

    ensure_dir(nvim_colors_dir);
    copy_file(src, dst_colorscheme);

    FILE *f = fopen(theme_lua, "r");
    if (f) {
        fseek(f, 0, SEEK_END);
        long sz = ftell(f);
        fseek(f, 0, SEEK_SET);

        char *content = malloc(sz + 1);
        if (content) {
            fread(content, 1, sz, f);
            content[sz] = '\0';
            fclose(f);

            char *cs_pos = strstr(content, "colorscheme =");
            if (cs_pos) {
                char *quote1 = strchr(cs_pos, '"');
                if (!quote1) quote1 = strchr(cs_pos, '\'');
                if (quote1) {
                    char quote_char = *quote1;
                    char *quote2 = strchr(quote1 + 1, quote_char);
                    if (quote2) {
                        FILE *out = fopen(theme_lua, "w");
                        if (out) {
                            fwrite(content, 1, quote1 - content, out);
                            fprintf(out, "%c%s%c", quote_char, scheme_name, quote_char);
                            fputs(quote2 + 1, out);
                            fclose(out);
                        }
                    }
                }
            }
            free(content);
        } else {
            fclose(f);
        }
    }

    // Broadcast live colorscheme command to all active Neovim server sockets
    const char *xdg_runtime = getenv("XDG_RUNTIME_DIR");
    char socket_dir[PATH_MAX_LEN];
    if (xdg_runtime) {
        snprintf(socket_dir, sizeof(socket_dir), "%s", xdg_runtime);
    } else {
        snprintf(socket_dir, sizeof(socket_dir), "/run/user/1000");
    }

    DIR *d = opendir(socket_dir);
    if (d) {
        struct dirent *entry;
        while ((entry = readdir(d)) != NULL) {
            if (strncmp(entry->d_name, "nvim.", 5) == 0) {
                char cmd[512];
                snprintf(cmd, sizeof(cmd), "nvim --server %s/%s --remote-send '<C-\\><C-N>:colorscheme %s<CR>' 2>/dev/null || true", socket_dir, entry->d_name, scheme_name);
                system(cmd);
            }
        }
        closedir(d);
    }
}

// 7. Sync Tmux (Live plugin rerun + client refresh)
static void sync_tmux(const char *theme_id, const char *pdir, const char *home) {
    char src[PATH_MAX_LEN];
    char tmux_dir[PATH_MAX_LEN];
    char dst_conf[PATH_MAX_LEN];

    snprintf(src, sizeof(src), "%s/shared/app_configs/tmux/%s.conf", pdir, theme_id);
    snprintf(tmux_dir, sizeof(tmux_dir), "%s/.tmux", home);
    snprintf(dst_conf, sizeof(dst_conf), "%s/current-theme.conf", tmux_dir);

    ensure_dir(tmux_dir);
    if (copy_file(src, dst_conf)) {
        char cmd[1024];
        snprintf(cmd, sizeof(cmd),
            "tmux source-file %s 2>/dev/null; "
            "%s/.tmux/plugins/minimal-tmux-status/minimal.tmux 2>/dev/null; "
            "tmux refresh-client -S 2>/dev/null || true",
            dst_conf, home);
        system(cmd);
    }
}

// Helper to update color_theme = "..." in btop.conf
static void set_btop_theme(const char *btop_conf, const char *theme_val) {
    FILE *f = fopen(btop_conf, "r");
    if (!f) {
        FILE *out = fopen(btop_conf, "w");
        if (out) {
            fprintf(out, "color_theme = \"%s\"\n", theme_val);
            fclose(out);
        }
        return;
    }

    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);

    char *content = malloc(sz + 1);
    if (!content) { fclose(f); return; }
    fread(content, 1, sz, f);
    content[sz] = '\0';
    fclose(f);

    char *pos = strstr(content, "color_theme =");
    if (!pos) pos = strstr(content, "color_theme=");

    if (pos) {
        FILE *out = fopen(btop_conf, "w");
        if (out) {
            fwrite(content, 1, pos - content, out);
            fprintf(out, "color_theme = \"%s\"", theme_val);
            char *line_end = strchr(pos, '\n');
            if (line_end) fputs(line_end, out);
            else fprintf(out, "\n");
            fclose(out);
        }
    } else {
        FILE *out = fopen(btop_conf, "a");
        if (out) {
            fprintf(out, "\ncolor_theme = \"%s\"\n", theme_val);
            fclose(out);
        }
    }
    free(content);
}

// 8. Sync btop System Monitor
static void sync_btop(const char *theme_id, const char *pdir, const char *home) {
    char src[PATH_MAX_LEN];
    char btop_dir[PATH_MAX_LEN];
    char btop_themes_dir[PATH_MAX_LEN];
    char dst_theme[PATH_MAX_LEN];
    char btop_conf[PATH_MAX_LEN];

    snprintf(src, sizeof(src), "%s/shared/app_configs/btop/%s.theme", pdir, theme_id);
    snprintf(btop_dir, sizeof(btop_dir), "%s/.config/btop", home);
    snprintf(btop_themes_dir, sizeof(btop_themes_dir), "%s/themes", btop_dir);
    snprintf(dst_theme, sizeof(dst_theme), "%s/%s.theme", btop_themes_dir, theme_id);
    snprintf(btop_conf, sizeof(btop_conf), "%s/btop.conf", btop_dir);

    ensure_dir(btop_themes_dir);
    if (copy_file(src, dst_theme)) {
        set_btop_theme(btop_conf, dst_theme);
        system("pkill -SIGUSR2 btop 2>/dev/null || true");
    }
}

// Ensure "useQuickCss": true and "enabledThemes": ["ogsshell.theme.css"] in Vesktop settings.json
static void ensure_vesktop_settings_json(const char *json_path) {
    FILE *f = fopen(json_path, "r");
    if (!f) {
        FILE *out = fopen(json_path, "w");
        if (out) {
            fprintf(out, "{\n  \"useQuickCss\": true,\n  \"enabledThemes\": [\n    \"ogsshell.theme.css\"\n  ]\n}\n");
            fclose(out);
        }
        return;
    }

    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);

    char *content = malloc(sz + 1);
    if (!content) { fclose(f); return; }
    fread(content, 1, sz, f);
    content[sz] = '\0';
    fclose(f);

    int modified = 0;

    // 1. Check useQuickCss
    if (strstr(content, "\"useQuickCss\": false") || strstr(content, "\"useQuickCss\":false")) {
        char *pos = strstr(content, "\"useQuickCss\": false");
        if (!pos) pos = strstr(content, "\"useQuickCss\":false");
        if (pos) {
            char *val = strstr(pos, "false");
            if (val) {
                val[0] = 't'; val[1] = 'r'; val[2] = 'u'; val[3] = 'e'; val[4] = ' ';
                modified = 1;
            }
        }
    }

    // 2. Check enabledThemes
    if (!strstr(content, "ogsshell.theme.css")) {
        char *pos = strstr(content, "\"enabledThemes\": [");
        if (!pos) pos = strstr(content, "\"enabledThemes\":[");
        if (pos) {
            char *bracket = strchr(pos, '[');
            if (bracket) {
                size_t head_len = (bracket + 1) - content;
                size_t tail_len = strlen(bracket + 1);
                char *new_content = malloc(head_len + strlen("\"ogsshell.theme.css\"") + 10 + tail_len + 1);
                if (new_content) {
                    strncpy(new_content, content, head_len);
                    new_content[head_len] = '\0';
                    strcat(new_content, "\n    \"ogsshell.theme.css\"");
                    if (bracket[1] != ']' && bracket[1] != '\n' && bracket[1] != ' ') {
                        strcat(new_content, ", ");
                    }
                    strcat(new_content, bracket + 1);
                    free(content);
                    content = new_content;
                    modified = 1;
                }
            }
        }
    }

    if (modified) {
        FILE *out = fopen(json_path, "w");
        if (out) {
            fputs(content, out);
            fclose(out);
        }
    }
    free(content);
}

// 9. Sync Vesktop (Discord Client)
static void sync_vesktop(const char *theme_id, const char *pdir, const char *home) {
    char src[PATH_MAX_LEN];
    snprintf(src, sizeof(src), "%s/shared/app_configs/vesktop/%s.css", pdir, theme_id);

    const char *paths[] = {
        "/.config/vesktop",
        "/.var/app/dev.vencord.Vesktop/config/vesktop",
        NULL
    };

    for (int i = 0; paths[i] != NULL; i++) {
        char base_dir[PATH_MAX_LEN];
        snprintf(base_dir, sizeof(base_dir), "%s%s", home, paths[i]);
        if (access(base_dir, F_OK) != 0) continue;

        char settings_dir[PATH_MAX_LEN], themes_dir[PATH_MAX_LEN];
        char quick_css[PATH_MAX_LEN], theme_css[PATH_MAX_LEN], settings_json[PATH_MAX_LEN];

        snprintf(settings_dir, sizeof(settings_dir), "%s/settings", base_dir);
        snprintf(themes_dir, sizeof(themes_dir), "%s/themes", base_dir);
        snprintf(quick_css, sizeof(quick_css), "%s/quickCss.css", settings_dir);
        snprintf(theme_css, sizeof(theme_css), "%s/ogsshell.theme.css", themes_dir);
        snprintf(settings_json, sizeof(settings_json), "%s/settings.json", settings_dir);

        ensure_dir(settings_dir);
        ensure_dir(themes_dir);

        copy_file(src, quick_css);
        copy_file(src, theme_css);
        ensure_vesktop_settings_json(settings_json);
    }
}

// 10. Sync IntelliJ IDEA & JetBrains IDEs across all installation directories
static void sync_intellij(const char *theme_id, const char *pdir, const char *home) {
    char jb_dir[PATH_MAX_LEN];
    snprintf(jb_dir, sizeof(jb_dir), "%s/.config/JetBrains", home);

    DIR *d = opendir(jb_dir);
    if (!d) return;

    char src_icls[PATH_MAX_LEN];
    snprintf(src_icls, sizeof(src_icls), "%s/shared/app_configs/intellij/%s.icls", pdir, theme_id);

    const char *scheme_name = "OgsNord";
    if (strcmp(theme_id, "catppuccin") == 0) scheme_name = "OgsCatppuccin";
    else if (strcmp(theme_id, "nord") == 0) scheme_name = "OgsNord";
    else if (strcmp(theme_id, "tokyonight") == 0) scheme_name = "OgsTokyoNight";
    else if (strcmp(theme_id, "everforest") == 0) scheme_name = "OgsEverforest";
    else if (strcmp(theme_id, "gruvbox") == 0) scheme_name = "OgsGruvbox";
    else if (strcmp(theme_id, "monochrome") == 0) scheme_name = "OgsMonochrome";

    struct dirent *entry;
    while ((entry = readdir(d)) != NULL) {
        if (entry->d_type == DT_DIR && entry->d_name[0] != '.') {
            char colors_dir[PATH_MAX_LEN];
            snprintf(colors_dir, sizeof(colors_dir), "%s/%s/colors", jb_dir, entry->d_name);
            ensure_dir(colors_dir);

            char dst_icls[PATH_MAX_LEN];
            snprintf(dst_icls, sizeof(dst_icls), "%s/%s.icls", colors_dir, scheme_name);
            copy_file(src_icls, dst_icls);

            char options_dir[PATH_MAX_LEN];
            snprintf(options_dir, sizeof(options_dir), "%s/%s/options", jb_dir, entry->d_name);
            ensure_dir(options_dir);

            char colors_path[PATH_MAX_LEN];
            snprintf(colors_path, sizeof(colors_path), "%s/colors.scheme.xml", options_dir);
            FILE *fc = fopen(colors_path, "w");
            if (fc) {
                fprintf(fc, "<application>\n  <component name=\"EditorColorsManagerImpl\">\n    <global_color_scheme name=\"%s\" />\n  </component>\n</application>\n", scheme_name);
                fclose(fc);
            }

            char laf_path[PATH_MAX_LEN];
            snprintf(laf_path, sizeof(laf_path), "%s/laf.xml", options_dir);
            FILE *fl = fopen(laf_path, "w");
            if (fl) {
                fprintf(fl, "<application>\n  <component name=\"LafManager\">\n    <laf themeId=\"12345678-9123-4567-8a73-14af69073eae\" />\n  </component>\n</application>\n");
                fclose(fl);
            }
        }
    }
    closedir(d);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <theme_id>\n", argv[0]);
        return 1;
    }

    const char *theme_id = argv[1];
    const char *home = getenv("HOME");
    if (!home) home = "/home/excalibur";

    char pdir[PATH_MAX_LEN] = "/home/excalibur/WorkSpace/projects/OgsShell-qs";
    char exe_path[PATH_MAX_LEN];
    ssize_t len = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
    if (len != -1) {
        exe_path[len] = '\0';
        char *last_slash = strrchr(exe_path, '/');
        if (last_slash) {
            *last_slash = '\0'; // e.g. .../bin
            if (strstr(last_slash, "/services") != NULL) {
                char *parent_slash = strrchr(exe_path, '/');
                if (parent_slash) *parent_slash = '\0';
            }
            char *parent_slash = strrchr(exe_path, '/');
            if (parent_slash && (strcmp(parent_slash + 1, "bin") == 0 || strcmp(parent_slash + 1, "shell") == 0)) {
                *parent_slash = '\0';
            }
            snprintf(pdir, sizeof(pdir), "%s", exe_path);
        }
    }

    sync_qt(theme_id, pdir, home);
    sync_kitty(theme_id, pdir, home);
    sync_zed(theme_id, pdir, home);
    sync_zen(theme_id, pdir, home);
    sync_gtk(theme_id, pdir, home);
    sync_nvim(theme_id, pdir, home);
    sync_tmux(theme_id, pdir, home);
    sync_btop(theme_id, pdir, home);
    sync_vesktop(theme_id, pdir, home);
    sync_intellij(theme_id, pdir, home);

    return 0;
}
