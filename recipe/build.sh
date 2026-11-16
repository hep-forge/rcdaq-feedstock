#!/usr/bin/env bash
set -euo pipefail

# rpcgen runs the C preprocessor, and conda's is target-prefixed
# (x86_64-conda-linux-gnu-cpp): conda-forge's rpcgen follows RPCGEN_CPP.
export RPCGEN_CPP="${CPP:-cpp}"

# libtirpc keeps rpc/rpc.h under include/tirpc. With it on CPPFLAGS,
# configure's rpc/rpc.h check passes (instead of hard-coding
# -I/usr/include/tirpc), so -ltirpc goes in by LIBS.
export CPPFLAGS="${CPPFLAGS:-} -I${PREFIX}/include/tirpc"
export LIBS="${LIBS:-} -ltirpc"

# autogen.sh, without the configure call it ends with
aclocal
libtoolize --force
automake -a --add-missing
autoconf

./configure --prefix="${PREFIX}" --disable-static
make -j"${CPU_COUNT}"
make install

# configure enables MQTT only when it finds mosquitto.h: make sure it did
${READELF:-readelf} -d "${PREFIX}/bin/rcdaq_server" | grep -q 'NEEDED.*libmosquitto' \
    || { echo "rcdaq_server built without MQTT (mosquitto.h not found)"; exit 1; }
