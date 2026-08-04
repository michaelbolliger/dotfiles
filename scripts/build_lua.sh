#!/usr/bin/env bash

set -euo pipefail

# Usage:
#   ./build-lua.sh [output-path]
#
# Example:
#   ./build-lua.sh ~/bin/lua
#
# Defaults to:
#   ./lua

OUTPUT="${1:-./lua}"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "==> Fetching latest Lua version..."

LATEST=$(curl -fsSL https://www.lua.org/ftp/ \
    | grep -oE 'lua-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz' \
    | sort -V \
    | tail -n1)

if [[ -z "$LATEST" ]]; then
    echo "Failed to determine latest Lua version."
    exit 1
fi

VERSION="${LATEST%.tar.gz}"
URL="https://www.lua.org/ftp/$LATEST"

echo "Latest release: $VERSION"

cd "$WORKDIR"

echo "==> Downloading..."
curl -LO "$URL"

echo "==> Extracting..."
tar xf "$LATEST"

cd "$VERSION/src"

echo "==> Building..."

# Compile all Lua sources
COMMON_FLAGS="-O3 -DNDEBUG -DLUA_USE_MACOSX -arch arm64"

clang $COMMON_FLAGS -c *.c

# Remove the standalone compiler object
rm -f luac.o

# Build a static library
ar rcs liblua.a \
    lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o \
    llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o \
    ltable.o ltm.o lundump.o lvm.o lzio.o lauxlib.o lbaselib.o \
    lcorolib.o ldblib.o liolib.o lmathlib.o loadlib.o loslib.o \
    lstrlib.o ltablib.o lutf8lib.o linit.o

# Build the interpreter
clang $COMMON_FLAGS \
    lua.o \
    liblua.a \
    -ledit \
    -o lua

mkdir -p "$(dirname "$OUTPUT")"
cp lua "$OUTPUT"
chmod +x "$OUTPUT"

echo
echo "Success!"
echo "Lua installed at:"
echo "  $OUTPUT"

echo
"$OUTPUT" -v

echo
echo "Binary information:"
file "$OUTPUT"
