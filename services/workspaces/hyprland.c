#include "hyprland.h"
#include "workspaces.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <sys/types.h>

int connect_hyprland_socket() {
    char *signature = getenv("HYPRLAND_INSTANCE_SIGNATURE");
    if (!signature) return -1;
    
    char socket_path[512];
    char *xdg_runtime = getenv("XDG_RUNTIME_DIR");
    if (!xdg_runtime) {
        xdg_runtime = "/run/user/1000";
    }
    
    snprintf(socket_path, sizeof(socket_path), "%s/hypr/%s/.socket2.sock", xdg_runtime, signature);
    
    struct stat st;
    if (stat(socket_path, &st) != 0) {
        snprintf(socket_path, sizeof(socket_path), "/tmp/hypr/%s/.socket2.sock", signature);
    }
    
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return -1;
    
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);
    
    if (connect(fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }
    return fd;
}

void listen_hyprland_events() {
    print_workspaces_state();
    fflush(stdout);

    while (1) {
        int fd = connect_hyprland_socket();
        if (fd < 0) {
            sleep(1);
            continue;
        }
        
        print_workspaces_state();
        fflush(stdout);
        
        char buffer[8192] = {0};
        int buffer_len = 0;
        char temp[4096];
        
        while (1) {
            int n = recv(fd, temp, sizeof(temp) - 1, 0);
            if (n <= 0) {
                break;
            }
            temp[n] = '\0';
            
            if (buffer_len + n < sizeof(buffer)) {
                memcpy(buffer + buffer_len, temp, n);
                buffer_len += n;
                buffer[buffer_len] = '\0';
            } else {
                buffer_len = 0;
                buffer[0] = '\0';
            }
            
            char *line_start = buffer;
            char *newline;
            while ((newline = strchr(line_start, '\n')) != NULL) {
                *newline = '\0';
                char *line = line_start;
                
                if (strstr(line, "workspace") || 
                    strstr(line, "focusedmon") || 
                    strstr(line, "createworkspace") || 
                    strstr(line, "destroyworkspace") || 
                    strstr(line, "activewindow") || 
                    strstr(line, "movewindow") ||
                    strstr(line, "openwindow") ||
                    strstr(line, "closewindow")) {
                    
                    print_workspaces_state();
                    fflush(stdout);
                }
                
                line_start = newline + 1;
            }
            
            int consumed = line_start - buffer;
            if (consumed > 0) {
                memmove(buffer, line_start, buffer_len - consumed);
                buffer_len -= consumed;
                buffer[buffer_len] = '\0';
            }
        }
        close(fd);
        sleep(1);
    }
}
