# Root Makefile for OgsShell-qs workspace

all: build-core

build-core:
	mkdir -p bin
	cd core && CGO_CFLAGS="$${CGO_CFLAGS:-} -Wno-deprecated-declarations" go build -o ../bin/ogsshell-core .

run-core: build-core
	./bin/ogsshell-core

run-shell: build-core
	./scripts/ogsshell.sh run

reload:
	./scripts/ogsshell.sh reload

run-settings:
	python3 settings_app/main.py

clean:
	rm -rf bin/ogsshell-core

.PHONY: all build-core run-core run-shell reload run-settings clean
