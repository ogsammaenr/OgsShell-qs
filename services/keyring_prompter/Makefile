CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -D_GNU_SOURCE
PKG_DEPS := gcr-3 gio-unix-2.0 json-glib-1.0

PKG_CFLAGS := $(shell pkg-config --cflags $(PKG_DEPS))
PKG_LIBS := $(shell pkg-config --libs $(PKG_DEPS))

TARGET := ../../bin/ogsshell-keyring-prompter
SRCS := main.c prompter_prompt.c
OBJS := $(SRCS:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	@mkdir -p ../../bin
	$(CC) $(CFLAGS) $(OBJS) -o $(TARGET) $(PKG_LIBS)

%.o: %.c
	$(CC) $(CFLAGS) $(PKG_CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean
