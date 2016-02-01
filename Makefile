#!/usr/bin/make -f

SPECTOOL=$(shell which spectool)

.PHONY: all

all: fetch_sources build_srpms build_rpms

fetch_sources:
	$(SPECTOOL) -g -S -C sources/ specs/lame.spec

build_srpms:
	mock --buildsrpm --spec specs/lame.spec --sources sources/ --resultdir build/source

build_rpms:
	# build i686 RPMS
	mockchain -r fedora-23-i386 -l build --recurse build/source/*.src.rpm
	# build x86_64 RPMS
	mockchain -r fedora-23-x86_64 -l build --recurse build/source/*.src.rpm

clean:
	find build -mindepth 1 -maxdepth 1 -not -iname '.gitignore' -exec rm -fr {} \;
