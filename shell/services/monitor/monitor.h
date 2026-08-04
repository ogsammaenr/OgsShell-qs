#ifndef MONITOR_H
#define MONITOR_H

#include <pthread.h>
#include <stddef.h>

typedef struct {
    int cpu_temp;
    int cpu_usage;
    int ram_usage;
    int wifi_connected;
    char wifi_ssid[128];
    char bluetooth_status[32];
    int brightness;
    int volume;
    int audio_muted;
    int notification_count;
    char media_status[64];
    char media_title[256];
    char media_artist[256];
    char media_art_url[512];
    int gpu_usage;
    int gpu_temp;
    char net_speed[32];
    char keyboard_layout[32];
} SystemState;

extern SystemState state;
extern pthread_mutex_t state_mutex;

void print_escaped_string(const char *str);
void print_state();

#endif // MONITOR_H
