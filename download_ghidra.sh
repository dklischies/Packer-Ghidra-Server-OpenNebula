#!/bin/bash -e

cd /home/ghidra
wget https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/${GHIDRA_FILENAME}
unzip $GHIDRA_FILENAME
rm $GHIDRA_FILENAME
mv ghidra_${GHIDRA_VERSION}_PUBLIC ghidra
mkdir repositories
