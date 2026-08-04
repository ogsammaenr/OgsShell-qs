#ifndef HW_CONTROLS_H
#define HW_CONTROLS_H

#include <stddef.h>

const char* get_bluetooth_status();
int get_brightness();
int get_wifi_status(char *ssid_out, size_t max_len);
void get_audio_volume(int *volume, int *muted);
void get_keyboard_layout(char *layout_out, size_t max_len);

#endif // HW_CONTROLS_H
