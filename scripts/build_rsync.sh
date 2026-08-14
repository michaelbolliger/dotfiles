#!/bin/bash
set -e # Exit on error

# 1. Capture launch context and handle output path
START_DIR="$(pwd)"

if [ -n "$1" ]; then
    # Convert relative path to absolute path using starting directory
    case "$1" in
        /*) OUTPUT_PATH="$1" ;;
        *)  OUTPUT_PATH="$START_DIR/$1" ;;
    esac
else
    # Default: Place the compiled binary in the directory where the script was invoked
    OUTPUT_PATH="$START_DIR/rsync"
fi

# 2. Setup workspace
BUILD_DIR="$HOME/rsync-standalone-build"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
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
RSYNC_VER=${RSYNC_TAG#v} # Strip 'v' prefix

echo "ZSTD:    $ZSTD_TAG"
echo "LZ4:     $LZ4_TAG"
echo "XXHASH:  $XXHASH_TAG"
echo "OPENSSL: $OPENSSL_TAG"
echo "RSYNC:   $RSYNC_VER"
echo "------------------------------------"

# 3. Build zstd
echo "Building zstd..."
mkdir -p zstd-src && cd zstd-src
curl -LO "https://github.com/facebook/zstd/archive/refs/tags/${ZSTD_TAG}.tar.gz"
tar -xzf "${ZSTD_TAG}.tar.gz" --strip-components=1
make -j$CORES install PREFIX="$PREFIX"
rm -f "$PREFIX"/lib/*.dylib "$PREFIX"/lib/*.so* 2>/dev/null || true
cd "$BUILD_DIR"

# 4. Build lz4
echo "Building lz4..."
mkdir -p lz4-src && cd lz4-src
curl -LO "https://github.com/lz4/lz4/archive/refs/tags/${LZ4_TAG}.tar.gz"
tar -xzf "${LZ4_TAG}.tar.gz" --strip-components=1
make -j$CORES install PREFIX="$PREFIX"
rm -f "$PREFIX"/lib/*.dylib "$PREFIX"/lib/*.so* 2>/dev/null || true
cd "$BUILD_DIR"

# 5. Build xxHash
echo "Building xxHash..."
mkdir -p xxhash-src && cd xxhash-src
curl -LO "https://github.com/Cyan4973/xxHash/archive/refs/tags/${XXHASH_TAG}.tar.gz"
tar -xzf "${XXHASH_TAG}.tar.gz" --strip-components=1
make -j$CORES install PREFIX="$PREFIX"
rm -f "$PREFIX"/lib/*.dylib "$PREFIX"/lib/*.so* 2>/dev/null || true
cd "$BUILD_DIR"

# 6. Build OpenSSL
echo "Building OpenSSL..."
mkdir -p openssl-src && cd openssl-src
curl -LO "https://github.com/openssl/openssl/archive/refs/tags/${OPENSSL_TAG}.tar.gz"
tar -xzf "${OPENSSL_TAG}.tar.gz" --strip-components=1
./config no-shared --prefix="$PREFIX"
make -j$CORES && make install_sw
cd "$BUILD_DIR"

# 7. Download & Build Rsync
echo "Building Rsync..."
mkdir -p rsync-src && cd rsync-src
curl -LO "https://download.samba.org/pub/rsync/src/rsync-${RSYNC_VER}.tar.gz"
tar -xzf "rsync-${RSYNC_VER}.tar.gz" --strip-components=1

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
./rsync --version | grep -E "capabilities|file-flags"

# 8. Output handling & Cleanup
echo "--- Copying binary to destination ---"
mkdir -p "$(dirname "$OUTPUT_PATH")"
cp ./rsync "$OUTPUT_PATH"
echo "Successfully installed rsync to: $OUTPUT_PATH"

echo "--- Cleaning up build workspace ---"
cd "$START_DIR"
rm -rf "$BUILD_DIR"
echo "Cleanup finished. Done!"
