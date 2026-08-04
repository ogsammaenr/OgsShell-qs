#ifndef SYS_INFO_H
#define SYS_INFO_H

#include <stddef.h>

int get_cpu_temp();
int get_ram_usage();
void get_cpu_times(long long *idle, long long *total);
void get_gpu_stats(int *usage, int *temp);
long long get_net_bytes();
void format_net_speed(double speed_kbps, char *out, size_t max_len);

#endif // SYS_INFO_H
