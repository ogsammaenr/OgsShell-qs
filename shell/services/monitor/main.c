#include "monitor.h"
#include "sys_info.h"
#include "hw_controls.h"
#include "media_notif.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <time.h>

SystemState state = {
    .cpu_temp = 0,
    .cpu_usage = 0,
    .ram_usage = 0,
    .wifi_connected = 0,
    .wifi_ssid = "",
    .bluetooth_status = "off",
    .brightness = 0,
    .volume = 0,
    .audio_muted = 0,
    .notification_count = 0,
    .media_status = "Stopped",
    .media_title = "",
    .media_artist = "",
    .media_art_url = "",
    .gpu_usage = 0,
    .gpu_temp = 0,
    .net_speed = "0.0 KB/s",
    .keyboard_layout = "TR"
};

pthread_mutex_t state_mutex = PTHREAD_MUTEX_INITIALIZER;

void print_escaped_string(const char *str) {
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

void print_state() {
    pthread_mutex_lock(&state_mutex);
    printf("{\"cpu_temp\": %d, \"cpu_usage\": %d, \"ram_usage\": %d, \"wifi_connected\": %s, \"wifi_ssid\": \"",
           state.cpu_temp,
           state.cpu_usage,
           state.ram_usage,
           state.wifi_connected ? "true" : "false"
    );
    print_escaped_string(state.wifi_ssid);
    printf("\", \"bluetooth_status\": \"%s\", \"brightness\": %d, \"volume\": %d, \"audio_muted\": %s, ",
           state.bluetooth_status,
           state.brightness,
           state.volume,
           state.audio_muted ? "true" : "false"
    );
    printf("\"notification_count\": %d, \"media_status\": \"%s\", \"media_title\": \"",
           state.notification_count,
           state.media_status
    );
    print_escaped_string(state.media_title);
    printf("\", \"media_artist\": \"");
    print_escaped_string(state.media_artist);
    printf("\", \"media_art_url\": \"");
    print_escaped_string(state.media_art_url);
    printf("\", \"gpu_usage\": %d, \"gpu_temp\": %d, \"net_speed\": \"%s\", \"keyboard_layout\": \"%s\"}\n",
           state.gpu_usage,
           state.gpu_temp,
           state.net_speed,
           state.keyboard_layout);
    pthread_mutex_unlock(&state_mutex);
}

void* follow_media_thread(void *arg) {
    (void)arg;
    while (1) {
        FILE *p = popen("playerctl metadata --follow --format '{{status}}|||{{title}}|||{{artist}}|||{{mpris:artUrl}}' 2>/dev/null", "r");
        if (!p) {
            sleep(2);
            continue;
        }
        char line[1024];
        while (fgets(line, sizeof(line), p)) {
            size_t len = strlen(line);
            if (len > 0 && line[len - 1] == '\n') {
                line[len - 1] = '\0';
            }
            
            char status[64] = {0};
            char title[256] = {0};
            char artist[256] = {0};
            char art_url[512] = {0};
            
            char *p1 = strstr(line, "|||");
            if (p1) {
                *p1 = '\0';
                strncpy(status, line, sizeof(status) - 1);
                
                char *title_start = p1 + 3;
                char *p2 = strstr(title_start, "|||");
                if (p2) {
                    *p2 = '\0';
                    strncpy(title, title_start, sizeof(title) - 1);
                    
                    char *artist_start = p2 + 3;
                    char *p3 = strstr(artist_start, "|||");
                    if (p3) {
                        *p3 = '\0';
                        strncpy(artist, artist_start, sizeof(artist) - 1);
                        
                        char *art_start = p3 + 3;
                        strncpy(art_url, art_start, sizeof(art_url) - 1);
                    } else {
                        strncpy(artist, artist_start, sizeof(artist) - 1);
                    }
                } else {
                    strncpy(title, title_start, sizeof(title) - 1);
                }
            } else {
                strncpy(status, line, sizeof(status) - 1);
            }
            
            pthread_mutex_lock(&state_mutex);
            strncpy(state.media_status, status, sizeof(state.media_status) - 1);
            strncpy(state.media_title, title, sizeof(state.media_title) - 1);
            strncpy(state.media_artist, artist, sizeof(state.media_artist) - 1);
            strncpy(state.media_art_url, art_url, sizeof(state.media_art_url) - 1);
            pthread_mutex_unlock(&state_mutex);
            
            print_state();
        }
        pclose(p);
        
        pthread_mutex_lock(&state_mutex);
        strcpy(state.media_status, "Stopped");
        state.media_title[0] = '\0';
        state.media_artist[0] = '\0';
        state.media_art_url[0] = '\0';
        pthread_mutex_unlock(&state_mutex);
        print_state();
        
        sleep(2);
    }
    return NULL;
}

void* follow_volume_thread(void *arg) {
    (void)arg;
    int use_fallback = 0;
    while (1) {
        if (use_fallback) {
            int new_vol = 0, new_muted = 0;
            get_audio_volume(&new_vol, &new_muted);
            
            int changed = 0;
            pthread_mutex_lock(&state_mutex);
            if (state.volume != new_vol || state.audio_muted != new_muted) {
                state.volume = new_vol;
                state.audio_muted = new_muted;
                changed = 1;
            }
            pthread_mutex_unlock(&state_mutex);
            
            if (changed) {
                print_state();
            }
            usleep(300000); // Poll every 300ms
            continue;
        }

        FILE *p = popen("pactl subscribe 2>/dev/null", "r");
        if (!p) {
            use_fallback = 1;
            continue;
        }
        
        char line[256];
        time_t start_time = time(NULL);
        
        while (fgets(line, sizeof(line), p)) {
            if (strstr(line, "sink") || strstr(line, "change")) {
                int new_vol = 0, new_muted = 0;
                get_audio_volume(&new_vol, &new_muted);
                
                pthread_mutex_lock(&state_mutex);
                state.volume = new_vol;
                state.audio_muted = new_muted;
                pthread_mutex_unlock(&state_mutex);
                
                print_state();
            }
        }
        pclose(p);
        
        if (time(NULL) - start_time < 1) {
            use_fallback = 1;
        } else {
            sleep(1);
        }
    }
    return NULL;
}

void* poll_brightness_thread(void *arg) {
    (void)arg;
    int last_brightness = -1;
    while (1) {
        int br = get_brightness();
        if (br != last_brightness) {
            last_brightness = br;
            pthread_mutex_lock(&state_mutex);
            state.brightness = br;
            pthread_mutex_unlock(&state_mutex);
            print_state();
        }
        usleep(200000); // 0.2 seconds
    }
    return NULL;
}

void* poll_system_stats_thread(void *arg) {
    (void)arg;
    long long prev_idle = 0, prev_total = 0;
    get_cpu_times(&prev_idle, &prev_total);
    
    long long prev_bytes = get_net_bytes();
    struct timespec prev_time;
    clock_gettime(CLOCK_MONOTONIC, &prev_time);
    
    while (1) {
        int temp = get_cpu_temp();
        int ram = get_ram_usage();
        const char *bt = get_bluetooth_status();
        char ssid[128] = {0};
        int wifi_conn = get_wifi_status(ssid, sizeof(ssid));
        char layout[32] = {0};
        get_keyboard_layout(layout, sizeof(layout));
        int notif_count = get_notification_count();
        
        long long idle = 0, total = 0;
        get_cpu_times(&idle, &total);
        long long total_diff = total - prev_total;
        long long idle_diff = idle - prev_idle;
        int cpu_usage = 0;
        if (total_diff > 0) {
            cpu_usage = (int)((total_diff - idle_diff) * 100 / total_diff);
        }
        prev_idle = idle;
        prev_total = total;
        
        int gpu_use = 0, gpu_t = 0;
        get_gpu_stats(&gpu_use, &gpu_t);
        
        long long current_bytes = get_net_bytes();
        struct timespec now;
        clock_gettime(CLOCK_MONOTONIC, &now);
        double dt = (now.tv_sec - prev_time.tv_sec) + (now.tv_nsec - prev_time.tv_nsec) / 1e9;
        
        double speed_kbps = 0.0;
        if (dt > 0.0) {
            long long bytes_diff = current_bytes - prev_bytes;
            if (bytes_diff < 0) bytes_diff = 0;
            speed_kbps = (bytes_diff / dt) / 1024.0;
        }
        char n_speed[32] = {0};
        format_net_speed(speed_kbps, n_speed, sizeof(n_speed));
        
        prev_bytes = current_bytes;
        prev_time = now;
        
        pthread_mutex_lock(&state_mutex);
        state.cpu_temp = temp;
        state.cpu_usage = cpu_usage;
        state.ram_usage = ram;
        strncpy(state.bluetooth_status, bt, sizeof(state.bluetooth_status) - 1);
        state.wifi_connected = wifi_conn;
        strncpy(state.wifi_ssid, ssid, sizeof(state.wifi_ssid) - 1);
        strncpy(state.keyboard_layout, layout, sizeof(state.keyboard_layout) - 1);
        state.notification_count = notif_count;
        state.gpu_usage = gpu_use;
        state.gpu_temp = gpu_t;
        strncpy(state.net_speed, n_speed, sizeof(state.net_speed) - 1);
        pthread_mutex_unlock(&state_mutex);
        
        print_state();
        
        usleep(1500000); // 1.5 seconds
    }
    return NULL;
}

int main() {
    setvbuf(stdout, NULL, _IONBF, 0);

    int vol = 0, muted = 0;
    get_audio_volume(&vol, &muted);
    
    char media_status[64] = {0};
    char media_title[256] = {0};
    char media_artist[256] = {0};
    char media_art_url[512] = {0};
    get_media_info(media_status, sizeof(media_status), media_title, sizeof(media_title), media_artist, sizeof(media_artist), media_art_url, sizeof(media_art_url));

    int gpu_use = 0, gpu_t = 0;
    get_gpu_stats(&gpu_use, &gpu_t);

    pthread_mutex_lock(&state_mutex);
    state.volume = vol;
    state.audio_muted = muted;
    state.cpu_temp = get_cpu_temp();
    state.ram_usage = get_ram_usage();
    strncpy(state.bluetooth_status, get_bluetooth_status(), sizeof(state.bluetooth_status) - 1);
    char ssid[128] = {0};
    state.wifi_connected = get_wifi_status(ssid, sizeof(ssid));
    strncpy(state.wifi_ssid, ssid, sizeof(state.wifi_ssid) - 1);
    state.brightness = get_brightness();
    get_keyboard_layout(state.keyboard_layout, sizeof(state.keyboard_layout));
    state.notification_count = get_notification_count();
    
    strncpy(state.media_status, media_status, sizeof(state.media_status) - 1);
    strncpy(state.media_title, media_title, sizeof(state.media_title) - 1);
    strncpy(state.media_artist, media_artist, sizeof(state.media_artist) - 1);
    strncpy(state.media_art_url, media_art_url, sizeof(state.media_art_url) - 1);

    state.gpu_usage = gpu_use;
    state.gpu_temp = gpu_t;
    strcpy(state.net_speed, "0.0 KB/s");
    pthread_mutex_unlock(&state_mutex);

    print_state();

    pthread_t thread_media, thread_volume, thread_brightness, thread_stats;

    pthread_create(&thread_media, NULL, follow_media_thread, NULL);
    pthread_create(&thread_volume, NULL, follow_volume_thread, NULL);
    pthread_create(&thread_brightness, NULL, poll_brightness_thread, NULL);
    pthread_create(&thread_stats, NULL, poll_system_stats_thread, NULL);

    pthread_join(thread_media, NULL);
    pthread_join(thread_volume, NULL);
    pthread_join(thread_brightness, NULL);
    pthread_join(thread_stats, NULL);

    return 0;
}
