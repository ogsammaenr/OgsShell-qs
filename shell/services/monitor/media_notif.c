#include "media_notif.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int get_notification_count() {
    int count = 0;
    FILE *p = popen("swaync-client -c 2>/dev/null", "r");
    if (p) {
        if (fscanf(p, "%d", &count) != 1) {
            count = 0;
        }
        pclose(p);
    }
    return count;
}

void get_media_info(char *status_out, size_t max_status, char *title_out, size_t max_title, char *artist_out, size_t max_artist, char *art_out, size_t max_art) {
    status_out[0] = '\0';
    title_out[0] = '\0';
    artist_out[0] = '\0';
    art_out[0] = '\0';
    
    FILE *p = popen("playerctl metadata --format '{{status}}|||{{title}}|||{{artist}}|||{{mpris:artUrl}}' 2>/dev/null", "r");
    if (p) {
        char line[1024] = {0};
        if (fgets(line, sizeof(line), p)) {
            size_t len = strlen(line);
            if (len > 0 && line[len - 1] == '\n') {
                line[len - 1] = '\0';
            }
            
            char *p1 = strstr(line, "|||");
            if (p1) {
                *p1 = '\0';
                strncpy(status_out, line, max_status);
                
                char *title_start = p1 + 3;
                char *p2 = strstr(title_start, "|||");
                if (p2) {
                    *p2 = '\0';
                    strncpy(title_out, title_start, max_title);
                    
                    char *artist_start = p2 + 3;
                    char *p3 = strstr(artist_start, "|||");
                    if (p3) {
                        *p3 = '\0';
                        strncpy(artist_out, artist_start, max_artist);
                        
                        char *art_start = p3 + 3;
                        strncpy(art_out, art_start, max_art);
                    } else {
                        strncpy(artist_out, artist_start, max_artist);
                    }
                } else {
                    strncpy(title_out, title_start, max_title);
                }
            }
        }
        pclose(p);
    }
}
