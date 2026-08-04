#include "sys_info.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <glob.h>
#include <time.h>

int get_cpu_temp() {
    glob_t g;
    int temp = 0;
    if (glob("/sys/class/thermal/thermal_zone*", 0, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; ++i) {
            char type_path[256];
            snprintf(type_path, sizeof(type_path), "%s/type", g.gl_pathv[i]);
            FILE *f = fopen(type_path, "r");
            if (f) {
                char type[128];
                if (fscanf(f, "%127s", type) == 1 && strcmp(type, "x86_pkg_temp") == 0) {
                    fclose(f);
                    char temp_path[256];
                    snprintf(temp_path, sizeof(temp_path), "%s/temp", g.gl_pathv[i]);
                    FILE *tf = fopen(temp_path, "r");
                    if (tf) {
                        int raw_temp;
                        if (fscanf(tf, "%d", &raw_temp) == 1) {
                            temp = raw_temp / 1000;
                        }
                        fclose(tf);
                        globfree(&g);
                        return temp;
                    }
                    break;
                }
                fclose(f);
            }
        }
        for (size_t i = 0; i < g.gl_pathc; ++i) {
            char type_path[256];
            snprintf(type_path, sizeof(type_path), "%s/type", g.gl_pathv[i]);
            FILE *f = fopen(type_path, "r");
            if (f) {
                char type[128];
                if (fscanf(f, "%127s", type) == 1 && strcmp(type, "TCPU") == 0) {
                    fclose(f);
                    char temp_path[256];
                    snprintf(temp_path, sizeof(temp_path), "%s/temp", g.gl_pathv[i]);
                    FILE *tf = fopen(temp_path, "r");
                    if (tf) {
                        int raw_temp;
                        if (fscanf(tf, "%d", &raw_temp) == 1) {
                            temp = raw_temp / 1000;
                        }
                        fclose(tf);
                        globfree(&g);
                        return temp;
                    }
                    break;
                }
                fclose(f);
            }
        }
        globfree(&g);
    }
    FILE *f = fopen("/sys/class/thermal/thermal_zone0/temp", "r");
    if (f) {
        int raw_temp;
        if (fscanf(f, "%d", &raw_temp) == 1) {
            temp = raw_temp / 1000;
        }
        fclose(f);
    }
    return temp;
}

int get_ram_usage() {
    FILE *f = fopen("/proc/meminfo", "r");
    if (!f) return 0;
    long long total = 0, avail = 0;
    char line[256];
    while (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "MemTotal:", 9) == 0) {
            sscanf(line + 9, "%lld", &total);
        } else if (strncmp(line, "MemAvailable:", 13) == 0) {
            sscanf(line + 13, "%lld", &avail);
        }
    }
    fclose(f);
    if (total > 0) {
        return (int)((total - avail) * 100 / total);
    }
    return 0;
}

void get_cpu_times(long long *idle, long long *total) {
    FILE *f = fopen("/proc/stat", "r");
    if (!f) {
        *idle = 0;
        *total = 0;
        return;
    }
    char name[32];
    long long user, nice, system, idle_time, iowait, irq, softirq, steal;
    if (fscanf(f, "%s %lld %lld %lld %lld %lld %lld %lld %lld",
               name, &user, &nice, &system, &idle_time, &iowait, &irq, &softirq, &steal) >= 9) {
        *idle = idle_time + iowait;
        *total = *idle + user + nice + system + irq + softirq + steal;
    } else {
        *idle = 0;
        *total = 0;
    }
    fclose(f);
}

void get_gpu_stats(int *usage, int *temp) {
    *usage = 0;
    *temp = 0;
    FILE *p = popen("nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null", "r");
    if (p) {
        int u = 0, t = 0;
        if (fscanf(p, "%d, %d", &u, &t) == 2) {
            *usage = u;
            *temp = t;
        }
        pclose(p);
    }
}

long long get_net_bytes() {
    FILE *f = fopen("/proc/net/dev", "r");
    if (!f) return 0;
    
    char line[256];
    long long total_bytes = 0;
    fgets(line, sizeof(line), f);
    fgets(line, sizeof(line), f);
    
    while (fgets(line, sizeof(line), f)) {
        char iface[32];
        long long rx_bytes = 0, tx_bytes = 0;
        if (sscanf(line, " %31[^:]: %lld %*d %*d %*d %*d %*d %*d %*d %lld", iface, &rx_bytes, &tx_bytes) >= 3) {
            char *trimmed = iface;
            while (*trimmed == ' ') trimmed++;
            
            if (strcmp(trimmed, "lo") != 0 && strncmp(trimmed, "docker", 6) != 0) {
                total_bytes += rx_bytes + tx_bytes;
            }
        }
    }
    fclose(f);
    return total_bytes;
}

void format_net_speed(double speed_kbps, char *out, size_t max_len) {
    if (speed_kbps < 100.0) {
        snprintf(out, max_len, "%.1f KB/s", speed_kbps);
    } else if (speed_kbps < 1024.0) {
        snprintf(out, max_len, "%.0f KB/s", speed_kbps);
    } else {
        snprintf(out, max_len, "%.1f MB/s", speed_kbps / 1024.0);
    }
}
