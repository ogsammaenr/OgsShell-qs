#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <ctype.h>

#define MAX_PATH 1024
#define MAX_FILES 2048

typedef struct {
    char path[MAX_PATH];
    char filename[256];
    char name[256];
} ImageFile;

static int is_image_file(const char *filename) {
    const char *dot = strrchr(filename, '.');
    if (!dot) return 0;
    if (strcasecmp(dot, ".jpg") == 0 ||
        strcasecmp(dot, ".jpeg") == 0 ||
        strcasecmp(dot, ".png") == 0 ||
        strcasecmp(dot, ".webp") == 0) {
        return 1;
    }
    return 0;
}

static int compare_images(const void *a, const void *b) {
    const ImageFile *ia = (const ImageFile *)a;
    const ImageFile *ib = (const ImageFile *)b;
    return strcmp(ia->path, ib->path);
}

static void get_display_name(const char *filename, char *out_name, size_t max_len) {
    const char *dot = strrchr(filename, '.');
    size_t len = dot ? (size_t)(dot - filename) : strlen(filename);
    if (len >= max_len) len = max_len - 1;
    
    for (size_t i = 0; i < len; i++) {
        if (filename[i] == '_') out_name[i] = ' ';
        else out_name[i] = filename[i];
    }
    out_name[len] = '\0';
}

static int scan_dir_recursive(const char *dir_path, ImageFile *files, int *count, int depth) {
    if (depth > 2 || *count >= MAX_FILES) return 0;

    DIR *d = opendir(dir_path);
    if (!d) return 0;

    struct dirent *dir;
    while ((dir = readdir(d)) != NULL) {
        if (strcmp(dir->d_name, ".") == 0 || strcmp(dir->d_name, "..") == 0)
            continue;

        char full_path[MAX_PATH];
        snprintf(full_path, sizeof(full_path), "%s/%s", dir_path, dir->d_name);

        struct stat st;
        if (stat(full_path, &st) == 0) {
            if (S_ISDIR(st.st_mode)) {
                scan_dir_recursive(full_path, files, count, depth + 1);
            } else if (S_ISREG(st.st_mode) && is_image_file(dir->d_name)) {
                if (*count < MAX_FILES) {
                    snprintf(files[*count].path, sizeof(files[*count].path), "%s", full_path);
                    snprintf(files[*count].filename, sizeof(files[*count].filename), "%s", dir->d_name);
                    get_display_name(dir->d_name, files[*count].name, sizeof(files[*count].name));
                    (*count)++;
                }
            }
        }
    }
    closedir(d);
    return *count;
}

static void escape_json_string(const char *in, char *out, size_t max_len) {
    size_t j = 0;
    for (size_t i = 0; in[i] != '\0' && j + 2 < max_len; i++) {
        if (in[i] == '"' || in[i] == '\\') {
            out[j++] = '\\';
            out[j++] = in[i];
        } else {
            out[j++] = in[i];
        }
    }
    out[j] = '\0';
}

static int cmd_scan(const char *folder_name) {
    const char *home = getenv("HOME");
    if (!home) home = "/home/excalibur";

    char target_dir[MAX_PATH];
    snprintf(target_dir, sizeof(target_dir), "%s/Pictures/Wallpapers/%s", home, folder_name ? folder_name : "Nord");

    ImageFile *files = malloc(sizeof(ImageFile) * MAX_FILES);
    if (!files) return 1;

    int count = 0;
    scan_dir_recursive(target_dir, files, &count, 0);

    // Fallback to default directory if 0 images found
    if (count == 0) {
        snprintf(target_dir, sizeof(target_dir), "%s/Pictures/Wallpapers/default", home);
        scan_dir_recursive(target_dir, files, &count, 0);
    }

    if (count > 0) {
        qsort(files, count, sizeof(ImageFile), compare_images);
    }

    printf("[");
    for (int i = 0; i < count; i++) {
        char esc_path[MAX_PATH * 2];
        char esc_filename[512];
        char esc_name[512];

        escape_json_string(files[i].path, esc_path, sizeof(esc_path));
        escape_json_string(files[i].filename, esc_filename, sizeof(esc_filename));
        escape_json_string(files[i].name, esc_name, sizeof(esc_name));

        printf("{\"path\":\"%s\",\"filename\":\"%s\",\"name\":\"%s\"}%s",
               esc_path, esc_filename, esc_name, (i < count - 1) ? "," : "");
    }
    printf("]\n");

    free(files);
    return 0;
}

static int cmd_set(const char *theme_id, const char *wallpaper_path) {
    if (!theme_id || !wallpaper_path || access(wallpaper_path, F_OK) != 0) {
        return 1;
    }

    const char *home = getenv("HOME");
    if (!home) home = "/home/excalibur";

    char state_dir[4096];
    snprintf(state_dir, sizeof(state_dir), "%s/.config/ogsshell/state", home);

    char mkdir_cmd[8192];
    snprintf(mkdir_cmd, sizeof(mkdir_cmd), "mkdir -p \"%s\"", state_dir);
    (void)system(mkdir_cmd);

    char saved_theme_file[8192];
    snprintf(saved_theme_file, sizeof(saved_theme_file), "%s/wallpaper_%s", state_dir, theme_id);

    FILE *f1 = fopen(saved_theme_file, "w");
    if (f1) {
        fputs(wallpaper_path, f1);
        fclose(f1);
    }

    char saved_global_file[8192];
    snprintf(saved_global_file, sizeof(saved_global_file), "%s/wallpaper", state_dir);

    FILE *f2 = fopen(saved_global_file, "w");
    if (f2) {
        fputs(wallpaper_path, f2);
        fclose(f2);
    }

    char exec_cmd[MAX_PATH * 2 + 128];
    snprintf(exec_cmd, sizeof(exec_cmd),
             "pgrep -x awww-daemon >/dev/null || (awww-daemon & sleep 0.3); "
             "awww img \"%s\" -a --transition-type random --transition-step 90 --transition-fps 60 2>/dev/null",
             wallpaper_path);

    (void)system(exec_cmd);
    return 0;
}

static int cmd_restore(const char *theme_id, const char *folder_name) {
    if (!theme_id) return 1;

    const char *home = getenv("HOME");
    if (!home) home = "/home/excalibur";

    char saved_file[MAX_PATH];
    snprintf(saved_file, sizeof(saved_file), "%s/.config/ogsshell/state/wallpaper_%s", home, theme_id);

    char saved_path[MAX_PATH] = {0};
    FILE *f = fopen(saved_file, "r");
    if (!f) {
        snprintf(saved_file, sizeof(saved_file), "%s/.config/ogsshell/wallpaper_%s", home, theme_id);
        f = fopen(saved_file, "r");
    }
    if (f) {
        if (fgets(saved_path, sizeof(saved_path), f)) {
            size_t len = strlen(saved_path);
            while (len > 0 && (saved_path[len - 1] == '\n' || saved_path[len - 1] == '\r')) {
                saved_path[--len] = '\0';
            }
        }
        fclose(f);
    }

    if (saved_path[0] != '\0' && access(saved_path, F_OK) == 0) {
        return cmd_set(theme_id, saved_path);
    }

    // No saved wallpaper for theme: scan directory and pick the first available wallpaper
    char target_dir[MAX_PATH];
    snprintf(target_dir, sizeof(target_dir), "%s/Pictures/Wallpapers/%s", home, folder_name ? folder_name : "Nord");

    ImageFile *files = malloc(sizeof(ImageFile) * MAX_FILES);
    if (!files) return 1;

    int count = 0;
    scan_dir_recursive(target_dir, files, &count, 0);

    if (count == 0) {
        snprintf(target_dir, sizeof(target_dir), "%s/Pictures/Wallpapers/default", home);
        scan_dir_recursive(target_dir, files, &count, 0);
    }

    if (count > 0) {
        qsort(files, count, sizeof(ImageFile), compare_images);
        cmd_set(theme_id, files[0].path);
    }

    free(files);
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s --scan <folder> | --set <theme_id> <path> | --restore <theme_id> [folder]\n", argv[0]);
        return 1;
    }

    if (strcmp(argv[1], "--scan") == 0) {
        const char *folder = (argc >= 3) ? argv[2] : "Nord";
        return cmd_scan(folder);
    } else if (strcmp(argv[1], "--set") == 0) {
        if (argc < 4) {
            fprintf(stderr, "Usage: %s --set <theme_id> <path>\n", argv[0]);
            return 1;
        }
        return cmd_set(argv[2], argv[3]);
    } else if (strcmp(argv[1], "--restore") == 0) {
        if (argc < 3) {
            fprintf(stderr, "Usage: %s --restore <theme_id> [folder]\n", argv[0]);
            return 1;
        }
        const char *folder = (argc >= 4) ? argv[3] : argv[2];
        return cmd_restore(argv[2], folder);
    }

    fprintf(stderr, "Unknown command: %s\n", argv[1]);
    return 1;
}
