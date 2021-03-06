#!/usr/bin/make -f

.PHONY: all

all: fetch_sources build_srpms build_rpms deploy_repo prune_repo gen_repo_metadata

sign: sign_rpms gen_repo_metadata

clean: clean_build clean_download

download:
	test -d build/repo || mkdir -p build/repo
	# sync down the repository into build/repo
	( cd build/repo && s3cmd sync s3://$(S3_BUCKET)/ ./ )

upload:
	# sync up the repository to s3
	( cd build/repo && s3cmd sync --server-side-encryption --delete-removed ./ s3://$(S3_BUCKET) )

fetch_sources:
	spectool -g -S -C sources/ specs/aacplusenc.spec
	spectool -g -S -C sources/ specs/ffmpeg.spec
	spectool -g -S -C sources/ specs/gstreamer1-plugins-libav.spec
	spectool -g -S -C sources/ specs/gstreamer1-plugins-ugly.spec
	spectool -g -S -C sources/ specs/gstreamer-plugins-ugly.spec
	spectool -g -S -C sources/ specs/handbrake.spec
	spectool -g -S -C sources/ specs/handbrake-legacy.spec
	spectool -g -S -C sources/ specs/lame.spec
	spectool -g -S -C sources/ specs/liba52.spec
	spectool -g -S -C sources/ specs/libdvdcss.spec
	spectool -g -S -C sources/ specs/libdvdread.spec
	spectool -g -S -C sources/ specs/libdvdnav.spec
	spectool -g -S -C sources/ specs/libfdk-aac.spec
	spectool -g -S -C sources/ specs/libmad.spec
	spectool -g -S -C sources/ specs/libmfx.spec
	spectool -g -S -C sources/ specs/libmpeg2.spec
	spectool -g -S -C sources/ specs/libvo-aacenc.spec
	spectool -g -S -C sources/ specs/libvo-amrwbenc.spec
	spectool -g -S -C sources/ specs/libxvidcore.spec
	spectool -g -S -C sources/ specs/makemkv.spec
	spectool -g -S -C sources/ specs/opencore-amr.spec
	spectool -g -S -C sources/ specs/stepmania.spec
	spectool -g -S -C sources/ specs/x264.spec
	spectool -g -S -C sources/ specs/x265.spec

build_srpms: fetch_sources
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/aacplusenc.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/ffmpeg.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/lame.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/gstreamer1-plugins-libav.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/gstreamer1-plugins-ugly.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/gstreamer-plugins-ugly.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/handbrake.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/handbrake-legacy.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/liba52.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/libdvdcss.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/libdvdread.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/libdvdnav.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/libfdk-aac.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/libmad.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/libmfx.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/libmpeg2.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/libvo-aacenc.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/libvo-amrwbenc.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/libxvidcore.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/makemkv.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/opencore-amr.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/stepmania.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/x264.spec
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/x265.spec

build-stepmania-srpm:
	mock -q --buildsrpm --sources sources/ --resultdir build/source --spec specs/stepmania.spec

build_rpms:
	# build i686 RPMS
	mockchain -r fedora-24-i386 -l build --recurse build/source/*.src.rpm
	# build x86_64 RPMS
	mockchain -r fedora-24-x86_64 -l build --recurse build/source/*.src.rpm

build-stepmania-rpm: build-stepmania-rpm-i386 build-stepmania-rpm-x86_64

build-stepmania-rpm-i386:
	mock -r build/configs/fedora-24-i386/fedora-24-i386.cfg --rebuild build/source/stepmania-5.0.10-?.fc24.src.rpm

build-stepmania-rpm-x86_64:
	mock -r build/configs/fedora-24-x86_64/fedora-24-x86_64.cfg --rebuild build/source/stepmania-5.0.10-?.fc24.src.rpm

deploy_repo:
	# copy all rpms into the repo folder
	test -d build/repo/fedora-24 || mkdir -p build/repo/fedora-24
	find build/results/fedora-24-i386 build/results/fedora-24-x86_64 -type f -iname '*.rpm' \
		-exec cp {} build/repo/fedora-24 \;

gen_repo_metadata:
	( cd build/repo/fedora-24 && createrepo . )

prune_repo:
	prune-rpm-repo -v --config prune-repo.yml build/repo/ build/source/ build/results

sign_rpms:
	find build/repo -type f -iname '*.rpm' | xargs rpmsign -D "_gpg_name $(GPG_KEY_ID)" --addsign

clean_build:
	find build -mindepth 1 -maxdepth 1 -not -iname '.gitignore' -exec rm -fr {} \;

clean_download:
	find sources -mindepth 1 -maxdepth 1 -not \( -iname '*.patch' -or -iname '.gitignore' \) -exec rm -fr {} \;
