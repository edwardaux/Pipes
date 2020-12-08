prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

build:
	swift build -c release --disable-sandbox

install: build
	install ".build/release/CLI" "$(bindir)/pipe"

uninstall:
	rm -rf "$(bindir)/pipe"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
