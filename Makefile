# Root Makefile for OgsShell-qs workspace

all: build-core build-keyring

build-core:
	mkdir -p bin
	cd core && CGO_CFLAGS="$${CGO_CFLAGS:-} -Wno-deprecated-declarations" go build -o ../bin/ogsshell-core .

build-keyring:
	mkdir -p bin
	$(MAKE) -C services/keyring_prompter

run-core: build-core build-keyring
	./bin/ogsshell-core

run-shell: build-core build-keyring
	./scripts/ogsshell.sh run

reload:
	./scripts/ogsshell.sh reload

run-settings:
	python3 settings_app/main.py

clean:
	rm -rf bin/ogsshell-core bin/ogsshell-keyring-prompter
	$(MAKE) -C services/keyring_prompter clean

.PHONY: all build-core build-keyring run-core run-shell reload run-settings clean
