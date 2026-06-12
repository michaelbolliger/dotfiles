#!/bin/bash
set -e # Exit on error

# 1. Setup workspace
mkdir -p ~/rsync-standalone-build && cd ~/rsync-standalone-build
export BUILD_DIR=$(pwd)
export PREFIX="$BUILD_DIR/local"
export CORES=$(sysctl -n hw.ncpu)
mkdir -p "$PREFIX"

echo "--- Starting build for rsync 3.4.3 with file-flags ---"

# 2. Build zstd 1.5.7
curl -LO https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz
tar -xzf zstd-1.5.7.tar.gz && cd zstd-1.5.7
make -j$CORES install PREFIX="$PREFIX"
rm -f "$PREFIX"/lib/*.dylib 
cd ..

# 3. Build lz4 1.10.0
curl -LO https://github.com/lz4/lz4/archive/refs/tags/v1.10.0.tar.gz
tar -xzf v1.10.0.tar.gz && cd lz4-1.10.0
make -j$CORES install PREFIX="$PREFIX"
rm -f "$PREFIX"/lib/*.dylib
cd ..

# 4. Build xxHash 0.8.3
curl -LO https://github.com/Cyan4973/xxHash/archive/refs/tags/v0.8.3.tar.gz
tar -xzf v0.8.3.tar.gz && cd xxHash-0.8.3
make -j$CORES install PREFIX="$PREFIX"
rm -f "$PREFIX"/lib/*.dylib
cd ..

# 5. Build OpenSSL 4.0.1
curl -LO https://github.com/openssl/openssl/releases/download/openssl-4.0.1/openssl-4.0.1.tar.gz
tar -xzf openssl-4.0.1.tar.gz && cd openssl-4.0.1
./config no-shared --prefix="$PREFIX"
make -j$CORES && make install_sw
cd ..

# 6. Download Rsync 3.4.3
curl -LO https://download.samba.org/pub/rsync/src/rsync-3.4.3.tar.gz
tar -xzf rsync-3.4.3.tar.gz
cd rsync-3.4.3

# 7. Configure and Compile
export CFLAGS="-I$PREFIX/include -O2"
export LDFLAGS="-L$PREFIX/lib"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"

./configure \
    --with-included-popt \
    --with-included-zlib \
    --enable-xattr-support \
    --disable-debug

make -j$CORES

echo "--- Build Complete! ---"
echo "Binary location: $(pwd)/rsync"
./rsync --version | grep -E "capabilities|file-flags"
