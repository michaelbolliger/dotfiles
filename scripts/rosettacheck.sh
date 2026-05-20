#!/bin/bash
if [[ `uname -m` != "arm64" ]] ; then
    echo "not arm64"
else
    if ! (arch -arch x86_64 uname -m > /dev/null) ; then
        echo "arm64: no Rosetta installed"
        # softwareupdate --install-rosetta --agree-to-license
    else
        echo "arm64: Rosetta already installed"
    fi
fi
