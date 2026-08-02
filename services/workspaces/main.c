#include "workspaces.h"
#include "hyprland.h"
#include "notification.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

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

void print_workspaces_state() {
    FILE *pm = popen("hyprctl monitors -j | jq -c '.' 2>/dev/null", "r");
    if (!pm) return;
    char monitors_buf[16384] = {0};
    char line[1024];
    while (fgets(line, sizeof(line), pm)) {
        strcat(monitors_buf, line);
    }
    pclose(pm);

    FILE *pw = popen("hyprctl workspaces -j | jq -c 'sort_by(.id)' 2>/dev/null", "r");
    if (!pw) return;
    char workspaces_buf[16384] = {0};
    while (fgets(line, sizeof(line), pw)) {
        strcat(workspaces_buf, line);
    }
    pclose(pw);

    FILE *pc = popen("hyprctl clients -j | jq -c '.' 2>/dev/null", "r");
    static char clients_buf[65536] = {0};
    clients_buf[0] = '\0';
    if (pc) {
        while (fgets(line, sizeof(line), pc)) {
            if (strlen(clients_buf) + strlen(line) < sizeof(clients_buf) - 1) {
                strcat(clients_buf, line);
            }
        }
        pclose(pc);
    }

    size_t len_m = strlen(monitors_buf);
    if (len_m > 0 && monitors_buf[len_m - 1] == '\n') monitors_buf[len_m - 1] = '\0';
    size_t len_w = strlen(workspaces_buf);
    if (len_w > 0 && workspaces_buf[len_w - 1] == '\n') workspaces_buf[len_w - 1] = '\0';
    size_t len_c = strlen(clients_buf);
    if (len_c > 0 && clients_buf[len_c - 1] == '\n') clients_buf[len_c - 1] = '\0';

    if (strlen(monitors_buf) == 0 || monitors_buf[0] != '[') {
        strcpy(monitors_buf, "[]");
    }
    if (strlen(workspaces_buf) == 0 || workspaces_buf[0] != '[') {
        strcpy(workspaces_buf, "[]");
    }
    if (strlen(clients_buf) == 0 || clients_buf[0] != '[') {
        strcpy(clients_buf, "[]");
    }

    printf("{\"monitors\": %s, \"workspaces\": %s, \"clients\": %s}\n", monitors_buf, workspaces_buf, clients_buf);
}

int main() {
    setvbuf(stdout, NULL, _IONBF, 0);

    pthread_t thread_id;
    if (pthread_create(&thread_id, NULL, listen_notifications_thread, NULL) != 0) {
        perror("pthread_create failed");
        return 1;
    }
    pthread_detach(thread_id);

    listen_hyprland_events();

    return 0;
}
