#!/bin/bash
set -e # Exit on error

# 1. Capture launch context and resolve output directory
START_DIR="$(pwd)"
OUTPUT_DIR="${1:-$START_DIR}"

case "$OUTPUT_DIR" in
    /*) ;;
    *) OUTPUT_DIR="$START_DIR/$OUTPUT_DIR" ;;
esac
OUTPUT_PATH="$OUTPUT_DIR/rsync"

# 2. Setup workspace
BUILD_DIR="$(mktemp -d "$HOME/rsync-standalone-build.XXXXXX")"
cleanup() {
    status=$?
    trap - EXIT
    cd "$START_DIR"
    if [ -d "$BUILD_DIR" ]; then
        echo "--- Cleaning up build workspace: $BUILD_DIR ---"
        rm -rf "$BUILD_DIR"
    fi
    if [ "$status" -eq 0 ]; then
        echo "Cleanup finished. Done!"
    else
        echo "Build failed (exit $status); temporary workspace removed." >&2
    fi
    exit "$status"
}
trap cleanup EXIT

cd "$BUILD_DIR"
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
# libidn2 depends on libunistring.  GNU publishes stable latest-release
# tarball aliases for both projects.

echo "ZSTD:    $ZSTD_TAG"
echo "LZ4:     $LZ4_TAG"
echo "XXHASH:  $XXHASH_TAG"
echo "OPENSSL: $OPENSSL_TAG"
echo "RSYNC:   $RSYNC_VER"
echo "LIBUNISTRING: latest GNU release"
echo "LIBIDN2:       latest GNU release"
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

# 7. Build libunistring (required by libidn2)
echo "Building libunistring..."
mkdir -p libunistring-src && cd libunistring-src
curl -LO "https://ftp.gnu.org/gnu/libunistring/libunistring-latest.tar.gz"
tar -xzf "libunistring-latest.tar.gz" --strip-components=1
./configure --prefix="$PREFIX" --disable-shared --enable-static
make -j$CORES && make install
rm -f "$PREFIX"/lib/*.dylib "$PREFIX"/lib/*.so* 2>/dev/null || true
cd "$BUILD_DIR"

# 8. Build libidn2
echo "Building libidn2..."
mkdir -p libidn2-src && cd libidn2-src
curl -LO "https://ftp.gnu.org/gnu/libidn/libidn2-latest.tar.gz"
tar -xzf "libidn2-latest.tar.gz" --strip-components=1
./configure --prefix="$PREFIX" --with-libunistring-prefix="$PREFIX" --disable-shared --enable-static
make -j$CORES && make install
rm -f "$PREFIX"/lib/*.dylib "$PREFIX"/lib/*.so* 2>/dev/null || true
cd "$BUILD_DIR"

# 9. Download & Build Rsync
echo "Building Rsync..."
mkdir -p rsync-src && cd rsync-src
curl -LO "https://download.samba.org/pub/rsync/src/rsync-${RSYNC_VER}.tar.gz"
tar -xzf "rsync-${RSYNC_VER}.tar.gz" --strip-components=1

export CFLAGS="-I$PREFIX/include -O2"
export LDFLAGS="-L$PREFIX/lib"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
# libidn2 is static, so its libunistring dependency must be available to the
# configure link probe and the final rsync link.
export LIBS="-lunistring"

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
mkdir -p "$OUTPUT_DIR"
cp ./rsync "$OUTPUT_PATH"
echo "Successfully installed rsync to: $OUTPUT_PATH"
