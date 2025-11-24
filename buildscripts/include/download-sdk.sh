#!/bin/bash -e

. ./include/depinfo.sh

. ./include/path.sh # load $os var

[ -z "$TRAVIS" ] && TRAVIS=0 # skip steps not required for CI?
[ -z "$WGET" ] && WGET=wget # possibility of calling wget differently

if [ $TRAVIS -eq 0 ]; then
	hash yum &>/dev/null && {
		yum install autoconf pkgconfig libtool ninja-build unzip \
		python3-pip python3-setuptools unzip wget;
		pip3 install meson; }
	apt-get -v &>/dev/null && {
		apt-get update;
		apt-get install -y autoconf pkg-config libtool ninja-build nasm unzip po4a libgtest-dev autopoint gperf gettext \
		python3-pip python3-setuptools unzip;
		pip3 install meson; }
fi
# pip3 install jinja2


os_ndk="linux"

# gas-preprocessor
mkdir -p bin
$WGET "https://github.com/FFmpeg/gas-preprocessor/raw/master/gas-preprocessor.pl" \
	-O bin/gas-preprocessor.pl
chmod +x bin/gas-preprocessor.pl

cd ..
