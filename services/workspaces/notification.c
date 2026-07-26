#include "notification.h"
#include "workspaces.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>

void* listen_notifications_thread(void *arg) {
    (void)arg;
    while (1) {
        FILE *p = popen("dbus-monitor \"interface='org.freedesktop.Notifications',member='Notify'\" 2>/dev/null", "r");
        if (!p) {
            sleep(2);
            continue;
        }
        
        char line[1024];
        int state_val = 0;
        char app_name[256] = {0};
        char summary[512] = {0};
        char body[1024] = {0};
        
        while (fgets(line, sizeof(line), p)) {
            char *trimmed = line;
            while (*trimmed == ' ' || *trimmed == '\t' || *trimmed == '\r' || *trimmed == '\n') {
                trimmed++;
            }
            size_t tlen = strlen(trimmed);
            while (tlen > 0 && (trimmed[tlen - 1] == '\r' || trimmed[tlen - 1] == '\n')) {
                trimmed[tlen - 1] = '\0';
                tlen--;
            }
            
            if (strstr(trimmed, "interface=org.freedesktop.Notifications; member=Notify")) {
                state_val = 1;
                app_name[0] = '\0';
                summary[0] = '\0';
                body[0] = '\0';
                continue;
            }
            
            if (state_val == 1) {
                if (strncmp(trimmed, "string \"", 8) == 0) {
                    size_t len = strlen(trimmed);
                    if (len > 9) {
                        strncpy(app_name, trimmed + 8, len - 9);
                        app_name[len - 9] = '\0';
                    }
                    state_val = 2;
                }
            } else if (state_val == 2) {
                if (strncmp(trimmed, "uint32 ", 7) == 0) {
                    state_val = 3;
                }
            } else if (state_val == 3) {
                if (strncmp(trimmed, "string \"", 8) == 0) {
                    state_val = 4;
                }
            } else if (state_val == 4) {
                if (strncmp(trimmed, "string \"", 8) == 0) {
                    size_t len = strlen(trimmed);
                    if (len > 9) {
                        strncpy(summary, trimmed + 8, len - 9);
                        summary[len - 9] = '\0';
                    }
                    state_val = 5;
                }
            } else if (state_val == 5) {
                if (strncmp(trimmed, "string \"", 8) == 0) {
                    size_t len = strlen(trimmed);
                    if (len > 9) {
                        strncpy(body, trimmed + 8, len - 9);
                        body[len - 9] = '\0';
                    }
                    
                    printf("{\"notification\": {\"title\": \"");
                    print_escaped_string(summary);
                    printf("\", \"body\": \"");
                    print_escaped_string(body);
                    printf("\", \"app\": \"");
                    print_escaped_string(app_name);
                    printf("\", \"timestamp\": %ld}}\n", (long)time(NULL));
                    fflush(stdout);
                    
                    state_val = 0;
                }
            }
        }
        pclose(p);
        sleep(2);
    }
    return NULL;
}
