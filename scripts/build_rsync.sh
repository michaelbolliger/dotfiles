#!/bin/bash
set -e # Exit on error

# Capture optional output path from the first argument
OUTPUT_PATH="$1"

# 1. Setup workspace
mkdir -p ~/rsync-standalone-build && cd ~/rsync-standalone-build
export BUILD_DIR=$(pwd)
export PREFIX="$BUILD_DIR/local"
# Get core count for macOS or Linux, fallback to 4
export CORES=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
mkdir -p "$PREFIX"

# Helper function to dynamically grab the latest tag from GitHub releases
get_latest_github_tag() {
    curl -sI "https://github.com/$1/releases/latest" | grep -i '^location:' | sed -n 's/.*\/tag\/\([^[:space:]]*\).*/\1/p' | tr -d '\r'
}

echo "--- Fetching latest version tags ---"
ZSTD_TAG=$(get_latest_github_tag "facebook/zstd")
LZ4_TAG=$(get_latest_github_tag "lz4/lz4")
XXHASH_TAG=$(get_latest_github_tag "Cyan4973/xxHash")
OPENSSL_TAG=$(get_latest_github_tag "openssl/openssl")
RSYNC_TAG=$(get_latest_github_tag "RsyncProject/rsync")
RSYNC_VER=${RSYNC_TAG#v} # Strip 'v' prefix for the Samba download URL (e.g., v3.4.4 -> 3.4.4)

echo "ZSTD:    $ZSTD_TAG"
echo "LZ4:     $LZ4_TAG"
echo "XXHASH:  $XXHASH_TAG"
echo "OPENSSL: $OPENSSL_TAG"
echo "RSYNC:   $RSYNC_VER"
echo "------------------------------------"

# 2. Build zstd
echo "Building zstd..."
mkdir -p zstd-src && cd zstd-src
curl -LO "https://github.com/facebook/zstd/archive/refs/tags/${ZSTD_TAG}.tar.gz"
tar -xzf "${ZSTD_TAG}.tar.gz" --strip-components=1
make -j$CORES install PREFIX="$PREFIX"
rm -f "$PREFIX"/lib/*.dylib "$PREFIX"/lib/*.so* 2>/dev/null || true
cd ..

# 3. Build lz4
echo "Building lz4..."
mkdir -p lz4-src && cd lz4-src
curl -LO "https://github.com/lz4/lz4/archive/refs/tags/${LZ4_TAG}.tar.gz"
tar -xzf "${LZ4_TAG}.tar.gz" --strip-components=1
make -j$CORES install PREFIX="$PREFIX"
rm -f "$PREFIX"/lib/*.dylib "$PREFIX"/lib/*.so* 2>/dev/null || true
cd ..

# 4. Build xxHash
echo "Building xxHash..."
mkdir -p xxhash-src && cd xxhash-src
curl -LO "https://github.com/Cyan4973/xxHash/archive/refs/tags/${XXHASH_TAG}.tar.gz"
tar -xzf "${XXHASH_TAG}.tar.gz" --strip-components=1
make -j$CORES install PREFIX="$PREFIX"
rm -f "$PREFIX"/lib/*.dylib "$PREFIX"/lib/*.so* 2>/dev/null || true
cd ..

# 5. Build OpenSSL
echo "Building OpenSSL..."
mkdir -p openssl-src && cd openssl-src
curl -LO "https://github.com/openssl/openssl/archive/refs/tags/${OPENSSL_TAG}.tar.gz"
tar -xzf "${OPENSSL_TAG}.tar.gz" --strip-components=1
./config no-shared --prefix="$PREFIX"
make -j$CORES && make install_sw
cd ..

# 6. Download Rsync
echo "Building Rsync..."
mkdir -p rsync-src && cd rsync-src
# We fetch from samba.org rather than Github because it includes pre-generated configure scripts
curl -LO "https://download.samba.org/pub/rsync/src/rsync-${RSYNC_VER}.tar.gz"
tar -xzf "rsync-${RSYNC_VER}.tar.gz" --strip-components=1

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
echo "Compiled binary location: $(pwd)/rsync"
./rsync --version | grep -E "capabilities|file-flags"

# 8. Handle Output Path
if [ -n "$OUTPUT_PATH" ]; then
    echo "--- Copying binary to destination ---"
    # Ensure the parent directory of the target path exists
    mkdir -p "$(dirname "$OUTPUT_PATH")"
    cp ./rsync "$OUTPUT_PATH"
    echo "Successfully copied rsync to: $OUTPUT_PATH"
fi
