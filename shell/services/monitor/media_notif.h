#ifndef MEDIA_NOTIF_H
#define MEDIA_NOTIF_H

#include <stddef.h>

int get_notification_count();
void get_media_info(char *status_out, size_t max_status, char *title_out, size_t max_title, char *artist_out, size_t max_artist, char *art_out, size_t max_art);

#endif // MEDIA_NOTIF_H
