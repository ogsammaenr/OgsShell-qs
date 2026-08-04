# Root Makefile for OgsShell-qs workspace

all: build-shell

build-shell:
	$(MAKE) -C shell

run-shell: build-shell
	./shell/reload.sh

run-settings:
	python3 settings_app/main.py

clean:
	$(MAKE) -C shell clean

.PHONY: all build-shell run-shell run-settings clean
