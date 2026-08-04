#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <unistd.h>
#include <pwd.h>

#define MAX_APPS 500
#define CACHE_VERSION_HEADER "# OGSSHELL_CACHE_V2"

typedef struct {
    char desktop_path[512];
    long long mtime;
    char name[256];
    char exec[512];
    char icon[512];
    char keywords[1200];
    int launch_count;
    char description[256];
    char category[64];
    int verified;
} AppEntry;

AppEntry apps[MAX_APPS];
int app_count = 0;

const char* get_home_dir() {
    const char *home = getenv("HOME");
    if (!home) {
        struct passwd *pw = getpwuid(getuid());
        if (pw) {
            home = pw->pw_dir;
        }
    }
    return home;
}

void strip_newline(char *str) {
    size_t len = strlen(str);
    while (len > 0 && (str[len - 1] == '\n' || str[len - 1] == '\r')) {
        str[len - 1] = '\0';
        len--;
    }
}

void load_cache(const char *cache_path) {
    FILE *f = fopen(cache_path, "r");
    if (!f) return;

    char line[1024];
    // Check cache header version
    if (!fgets(line, sizeof(line), f)) {
        fclose(f);
        return;
    }
    strip_newline(line);
    if (strcmp(line, CACHE_VERSION_HEADER) != 0) {
        // Cache version mismatch! Discard old cache to force rescan with new icon resolution
        fclose(f);
        return;
    }

    while (app_count < MAX_APPS) {
        if (!fgets(line, sizeof(line), f)) break;
        strip_newline(line);
        if (strlen(line) == 0) continue;

        AppEntry *entry = &apps[app_count];
        strcpy(entry->desktop_path, line);

        if (!fgets(line, sizeof(line), f)) break;
        strip_newline(line);
        entry->mtime = atoll(line);

        if (!fgets(line, sizeof(line), f)) break;
        strip_newline(line);
        strcpy(entry->name, line);

        if (!fgets(line, sizeof(line), f)) break;
        strip_newline(line);
        strcpy(entry->exec, line);

        if (!fgets(line, sizeof(line), f)) break;
        strip_newline(line);
        strcpy(entry->icon, line);

        if (!fgets(line, sizeof(line), f)) break;
        strip_newline(line);
        strcpy(entry->keywords, line);

        if (!fgets(line, sizeof(line), f)) break;
        strip_newline(line);
        entry->launch_count = atoi(line);

        if (!fgets(line, sizeof(line), f)) break;
        strip_newline(line);
        strcpy(entry->description, line);

        if (!fgets(line, sizeof(line), f)) break;
        strip_newline(line);
        strcpy(entry->category, line);

        // Read separator (---)
        if (!fgets(line, sizeof(line), f)) break;
        strip_newline(line);
        if (strcmp(line, "---") != 0) {
            // Cache format mismatch! Discard cache and rebuild
            app_count = 0;
            break;
        }

        entry->verified = 0;
        app_count++;
    }
    fclose(f);
}

void save_cache(const char *cache_path) {
    char dir_path[512];
    strcpy(dir_path, cache_path);
    char *last_slash = strrchr(dir_path, '/');
    if (last_slash) {
        *last_slash = '\0';
        mkdir(dir_path, 0700);
    }

    FILE *f = fopen(cache_path, "w");
    if (!f) return;

    fprintf(f, "%s\n", CACHE_VERSION_HEADER);

    for (int i = 0; i < app_count; i++) {
        AppEntry *entry = &apps[i];
        fprintf(f, "%s\n%lld\n%s\n%s\n%s\n%s\n%d\n%s\n%s\n---\n", 
                entry->desktop_path, entry->mtime, entry->name, entry->exec, entry->icon, entry->keywords, entry->launch_count, entry->description, entry->category);
    }
fclose(f);
}

int check_icon_file(const char *path) {
    struct stat st;
    if (stat(path, &st) == 0 && S_ISREG(st.st_mode)) {
        return 1;
    }
    return 0;
}

int try_icon_file(const char *dir, const char *stem, const char *ext, char *resolved_path) {
    char path[1024];
    snprintf(path, sizeof(path), "%s/%s%s", dir, stem, ext);
    if (check_icon_file(path)) {
        strcpy(resolved_path, path);
        return 1;
    }
    return 0;
}

int try_theme_subdirs(const char *theme_dir, const char *stem, char *resolved_path) {
    const char *subdirs[] = {
        "scalable/apps",
        "scalable-extra/apps",
        "1024x1024/apps",
        "512x512/apps",
        "256x256/apps",
        "192x192/apps",
        "128x128/apps",
        "96x96/apps",
        "64x64/apps",
        "48x48/apps",
        "32x32/apps",
        "24x24/apps",
        "16x16/apps",
        "scalable/categories",
        "256x256/categories",
        "128x128/categories",
        "64x64/categories",
        "48x48/categories"
    };
    int subdir_count = sizeof(subdirs) / sizeof(subdirs[0]);
    const char *exts[] = {".svg", ".png", ".xpm"};

    for (int s = 0; s < subdir_count; s++) {
        char full_sub[1024];
        snprintf(full_sub, sizeof(full_sub), "%s/%s", theme_dir, subdirs[s]);

        for (int e = 0; e < 3; e++) {
            if (try_icon_file(full_sub, stem, exts[e], resolved_path)) {
                return 1;
            }
        }
    }
    return 0;
}

void resolve_icon(const char *raw_icon, char *resolved_path) {
    resolved_path[0] = '\0';
    if (!raw_icon || strlen(raw_icon) == 0) return;

    char icon_stem[256];
    strcpy(icon_stem, raw_icon);

    if (raw_icon[0] == '/') {
        if (check_icon_file(raw_icon)) {
            const char *ext = strrchr(raw_icon, '.');
            if (ext && (strcmp(ext, ".svg") == 0 || strstr(raw_icon, "256x256") || strstr(raw_icon, "512x512") || strstr(raw_icon, "scalable"))) {
                strcpy(resolved_path, raw_icon);
                return;
            }
        }
        const char *last_slash = strrchr(raw_icon, '/');
        if (last_slash) {
            strcpy(icon_stem, last_slash + 1);
        }
    }

    char *dot = strrchr(icon_stem, '.');
    if (dot && (strcmp(dot, ".png") == 0 || strcmp(dot, ".svg") == 0 || strcmp(dot, ".xpm") == 0)) {
        *dot = '\0';
    }

    const char *home = get_home_dir();

    // 1. Check user icon themes (~/.local/share/icons and ~/.icons)
    if (home) {
        char base_dirs[2][512];
        snprintf(base_dirs[0], 512, "%s/.local/share/icons", home);
        snprintf(base_dirs[1], 512, "%s/.icons", home);

        for (int b = 0; b < 2; b++) {
            DIR *dir = opendir(base_dirs[b]);
            if (!dir) continue;

            struct dirent *entry;
            while ((entry = readdir(dir)) != NULL) {
                if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) continue;

                char theme_dir[1024];
                snprintf(theme_dir, sizeof(theme_dir), "%s/%s", base_dirs[b], entry->d_name);

                struct stat st;
                if (stat(theme_dir, &st) == 0 && S_ISDIR(st.st_mode)) {
                    if (try_theme_subdirs(theme_dir, icon_stem, resolved_path)) {
                        closedir(dir);
                        return;
                    }
                }
            }
            closedir(dir);
        }
    }

    // 2. Check /usr/share/icons/hicolor directly first (standard app icon location)
    if (try_theme_subdirs("/usr/share/icons/hicolor", icon_stem, resolved_path)) {
        return;
    }

    // 3. Check other system themes under /usr/share/icons
    DIR *sys_dir = opendir("/usr/share/icons");
    if (sys_dir) {
        struct dirent *entry;
        while ((entry = readdir(sys_dir)) != NULL) {
            if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0 || strcmp(entry->d_name, "hicolor") == 0) continue;

            char theme_dir[1024];
            snprintf(theme_dir, sizeof(theme_dir), "/usr/share/icons/%s", entry->d_name);

            struct stat st;
            if (stat(theme_dir, &st) == 0 && S_ISDIR(st.st_mode)) {
                if (try_theme_subdirs(theme_dir, icon_stem, resolved_path)) {
                    closedir(sys_dir);
                    return;
                }
            }
        }
        closedir(sys_dir);
    }

    // 4. Check /usr/share/pixmaps fallback
    const char *exts[] = {".svg", ".png", ".xpm"};
    for (int e = 0; e < 3; e++) {
        if (try_icon_file("/usr/share/pixmaps", icon_stem, exts[e], resolved_path)) {
            return;
        }
    }

    if (raw_icon[0] == '/' && check_icon_file(raw_icon)) {
        strcpy(resolved_path, raw_icon);
    }
}

void clean_exec(char *exec) {
    char *src = exec;
    char *dst = exec;
    while (*src) {
        if (*src == '%' && *(src + 1) != '\0') {
            src += 2;
        } else {
            *dst++ = *src++;
        }
    }
    *dst = '\0';

    // Trim trailing whitespace
    size_t len = strlen(exec);
    while (len > 0 && (exec[len - 1] == ' ' || exec[len - 1] == '\t')) {
        exec[len - 1] = '\0';
        len--;
    }
}

int parse_desktop_file(const char *filepath, char *name, char *exec, char *icon, char *generic_name, char *keywords_raw, char *comment, char *categories_raw) {
    FILE *f = fopen(filepath, "r");
    if (!f) return 0;

    char line[1024];
    int in_desktop_entry = 0;
    int has_name = 0, has_exec = 0, has_icon = 0, has_comment = 0, has_categories = 0;
    int no_display = 0;

    name[0] = '\0';
    exec[0] = '\0';
    icon[0] = '\0';
    generic_name[0] = '\0';
    keywords_raw[0] = '\0';
    comment[0] = '\0';
    categories_raw[0] = '\0';

    while (fgets(line, sizeof(line), f)) {
        size_t len = strlen(line);
        while (len > 0 && (line[len-1] == '\n' || line[len-1] == '\r')) {
            line[len-1] = '\0';
            len--;
        }

        // Section header
        if (line[0] == '[') {
            if (strcmp(line, "[Desktop Entry]") == 0) {
                in_desktop_entry = 1;
            } else {
                in_desktop_entry = 0;
            }
            continue;
        }

        if (!in_desktop_entry) continue;

        // Skip NoDisplay
        if (strncmp(line, "NoDisplay=", 10) == 0) {
            char *val = line + 10;
            if (strcasecmp(val, "true") == 0 || strcmp(val, "1") == 0) {
                no_display = 1;
            }
        }

        // Get Name (ignore localized version like Name[tr]=)
        if (strncmp(line, "Name=", 5) == 0 && !has_name) {
            char *eq = strchr(line, '=');
            char *bracket = strchr(line, '[');
            if (!bracket || bracket > eq) {
                strcpy(name, eq + 1);
                has_name = 1;
            }
        }

        // Get Exec
        if (strncmp(line, "Exec=", 5) == 0 && !has_exec) {
            char *eq = strchr(line, '=');
            char *bracket = strchr(line, '[');
            if (!bracket || bracket > eq) {
                strcpy(exec, eq + 1);
                has_exec = 1;
            }
        }

        // Get Icon
        if (strncmp(line, "Icon=", 5) == 0 && !has_icon) {
            char *eq = strchr(line, '=');
            char *bracket = strchr(line, '[');
            if (!bracket || bracket > eq) {
                strcpy(icon, eq + 1);
                has_icon = 1;
            }
        }

        // Get GenericName
        if (strncmp(line, "GenericName=", 12) == 0) {
            char *eq = strchr(line, '=');
            char *bracket = strchr(line, '[');
            if (!bracket || bracket > eq) {
                strcpy(generic_name, eq + 1);
            }
        }

        // Get Keywords
        if (strncmp(line, "Keywords=", 9) == 0) {
            char *eq = strchr(line, '=');
            char *bracket = strchr(line, '[');
            if (!bracket || bracket > eq) {
                strcpy(keywords_raw, eq + 1);
            }
        }

        // Get Comment
        if (strncmp(line, "Comment=", 8) == 0 && !has_comment) {
            char *eq = strchr(line, '=');
            char *bracket = strchr(line, '[');
            if (!bracket || bracket > eq) {
                strcpy(comment, eq + 1);
                has_comment = 1;
            }
        }

        // Get Categories
        if (strncmp(line, "Categories=", 11) == 0 && !has_categories) {
            char *eq = strchr(line, '=');
            char *bracket = strchr(line, '[');
            if (!bracket || bracket > eq) {
                strcpy(categories_raw, eq + 1);
                has_categories = 1;
            }
        }
    }

    fclose(f);

    if (no_display) return 0;
    return (has_name && has_exec);
}

int is_duplicate_exec(const char *exec, const char *current_path) {
    for (int i = 0; i < app_count; i++) {
        if (strcmp(apps[i].exec, exec) == 0 && strcmp(apps[i].desktop_path, current_path) != 0) {
            return 1;
        }
    }
    return 0;
}

void scan_directory(const char *dir_path) {
    DIR *dir = opendir(dir_path);
    if (!dir) return;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        // Only process .desktop files
        char *ext = strrchr(entry->d_name, '.');
        if (!ext || strcmp(ext, ".desktop") != 0) {
            continue;
        }

        char filepath[1024];
        snprintf(filepath, sizeof(filepath), "%s/%s", dir_path, entry->d_name);

        struct stat st;
        if (stat(filepath, &st) == 0 && S_ISREG(st.st_mode)) {
            int cache_index = -1;
            for (int i = 0; i < app_count; i++) {
                if (strcmp(apps[i].desktop_path, filepath) == 0) {
                    cache_index = i;
                    break;
                }
            }

            if (cache_index != -1 && apps[cache_index].mtime == (long long)st.st_mtime) {
                // Exact match from cache, mtime identical. No file read needed!
                apps[cache_index].verified = 1;
            } else {
                // Modified or new file! Parse the file
                char name[256], exec[512], icon[256], generic_name[256], keywords_raw[256], comment[256], categories_raw[512];
                if (parse_desktop_file(filepath, name, exec, icon, generic_name, keywords_raw, comment, categories_raw)) {
                    clean_exec(exec);

                    if (is_duplicate_exec(exec, filepath)) {
                        continue;
                    }

                    char icon_path[1024];
                    resolve_icon(icon, icon_path);

                    // Extract filename basename (e.g. gimp from gimp.desktop)
                    char basename[128] = "";
                    const char *slash = strrchr(filepath, '/');
                    if (slash) {
                        strcpy(basename, slash + 1);
                        char *dot = strrchr(basename, '.');
                        if (dot) *dot = '\0';
                    }

                    // Convert semicolons to spaces in Keywords
                    char *semi = keywords_raw;
                    while ((semi = strchr(semi, ';'))) {
                        *semi = ' ';
                    }

                    // Build combined keywords search key
                    char combined_keywords[1200];
                    snprintf(combined_keywords, sizeof(combined_keywords), "%s %s %s %s",
                             exec, basename, generic_name, keywords_raw);

                    // Map categories to Turkish display categories
                    char mapped_category[64] = "Diğer";
                    if (strstr(categories_raw, "Development")) {
                        strcpy(mapped_category, "Geliştirme");
                    } else if (strstr(categories_raw, "Game")) {
                        strcpy(mapped_category, "Oyunlar");
                    } else if (strstr(categories_raw, "Graphics")) {
                        strcpy(mapped_category, "Grafik");
                    } else if (strstr(categories_raw, "Network")) {
                        strcpy(mapped_category, "İnternet");
                    } else if (strstr(categories_raw, "Office")) {
                        strcpy(mapped_category, "Ofis");
                    } else if (strstr(categories_raw, "Settings")) {
                        strcpy(mapped_category, "Ayarlar");
                    } else if (strstr(categories_raw, "System")) {
                        strcpy(mapped_category, "Sistem");
                    } else if (strstr(categories_raw, "AudioVideo") || strstr(categories_raw, "Audio") || strstr(categories_raw, "Video")) {
                        strcpy(mapped_category, "Multimedya");
                    } else if (strstr(categories_raw, "Utility")) {
                        strcpy(mapped_category, "Araçlar");
                    }

                    if (cache_index != -1) {
                        // Update existing entry
                        AppEntry *app = &apps[cache_index];
                        app->mtime = (long long)st.st_mtime;
                        strcpy(app->name, name);
                        strcpy(app->exec, exec);
                        strcpy(app->icon, icon_path);
                        strcpy(app->keywords, combined_keywords);
                        strcpy(app->description, generic_name);
                        strcpy(app->category, mapped_category);
                        app->verified = 1;
                    } else if (app_count < MAX_APPS) {
                        // Insert new entry
                        AppEntry *app = &apps[app_count];
                        strcpy(app->desktop_path, filepath);
                        app->mtime = (long long)st.st_mtime;
                        strcpy(app->name, name);
                        strcpy(app->exec, exec);
                        strcpy(app->icon, icon_path);
                        strcpy(app->keywords, combined_keywords);
                        strcpy(app->description, generic_name);
                        strcpy(app->category, mapped_category);
                        app->launch_count = 0;
                        app->verified = 1;
                        app_count++;
                    }
                }
            }
        }
    }
    closedir(dir);
}

void print_json_escaped(const char *str) {
    while (*str) {
        if (*str == '"') {
            printf("\\\"");
        } else if (*str == '\\') {
            printf("\\\\");
        } else if (*str == '\n') {
            printf("\\n");
        } else if (*str == '\r') {
            printf("\\r");
        } else if (*str == '\t') {
            printf("\\t");
        } else {
            putchar(*str);
        }
        str++;
    }
}

int compare_apps(const void *a, const void *b) {
    const AppEntry *appA = (const AppEntry *)a;
    const AppEntry *appB = (const AppEntry *)b;
    
    if (appA->launch_count != appB->launch_count) {
        return appB->launch_count - appA->launch_count; // descending
    }
    return strcasecmp(appA->name, appB->name); // alphabetical ascending
}

int main(int argc, char **argv) {
    // Resolve cache file path
    char cache_path[1024];
    const char *xdg_cache = getenv("XDG_CACHE_HOME");
    const char *home = get_home_dir();

    if (xdg_cache && strlen(xdg_cache) > 0) {
        snprintf(cache_path, sizeof(cache_path), "%s/ogsshell-apps.cache", xdg_cache);
    } else if (home) {
        snprintf(cache_path, sizeof(cache_path), "%s/.cache/ogsshell-apps.cache", home);
    } else {
        snprintf(cache_path, sizeof(cache_path), "/tmp/ogsshell-apps.cache");
    }

    // Check if we are running in --launch notification mode
    if (argc >= 3 && strcmp(argv[1], "--launch") == 0) {
        load_cache(cache_path);
        const char *target_path = argv[2];
        int found = 0;
        for (int i = 0; i < app_count; i++) {
            if (strcmp(apps[i].desktop_path, target_path) == 0) {
                apps[i].launch_count++;
                found = 1;
                break;
            }
        }
        if (found) {
            save_cache(cache_path);
        }
        return 0;
    }

    // 1. Read existing cache
    load_cache(cache_path);
    int initial_app_count = app_count;

    // 2. Scan system folders
    if (home) {
        char local_apps[1024];
        snprintf(local_apps, sizeof(local_apps), "%s/.local/share/applications", home);
        scan_directory(local_apps);
    }
    scan_directory("/usr/share/applications");
    scan_directory("/usr/local/share/applications");

    // 3. Filter out deleted apps (keep only verified ones)
    int valid_count = 0;
    int changed = 0;

    for (int i = 0; i < app_count; i++) {
        if (apps[i].verified) {
            if (i != valid_count) {
                apps[valid_count] = apps[i];
            }
            valid_count++;
        } else {
            changed = 1;
        }
    }

    if (valid_count != app_count || changed) {
        changed = 1;
    }
    app_count = valid_count;

    if (app_count != initial_app_count) {
        changed = 1;
    }

    // Sort apps by launch_count descending, then by name
    qsort(apps, app_count, sizeof(AppEntry), compare_apps);

    // 4. Save cache back if changes occurred
    if (changed) {
        save_cache(cache_path);
    }

    // 5. Print JSON array to stdout (including desktop_path and launch_count)
    printf("[");
    for (int i = 0; i < app_count; i++) {
        printf("{\"name\":\"");
        print_json_escaped(apps[i].name);
        printf("\",\"exec\":\"");
        print_json_escaped(apps[i].exec);
        printf("\",\"icon\":\"");
        print_json_escaped(apps[i].icon);
        printf("\",\"search_keys\":\"");
        print_json_escaped(apps[i].keywords);
        printf("\",\"desktop_path\":\"");
        print_json_escaped(apps[i].desktop_path);
        printf("\",\"launch_count\":%d", apps[i].launch_count);
        printf(",\"description\":\"");
        print_json_escaped(apps[i].description);
        printf("\",\"category\":\"");
        print_json_escaped(apps[i].category);
        printf("\"}");
        if (i < app_count - 1) {
            printf(",");
        }
    }
    printf("]\n");

    return 0;
}
