#!/bin/bash

PYTHON_VERSION=3.6.4
# Please update these links carefully, some versions won't work under Wine
PYTHON_URL=https://www.python.org/ftp/python/$PYTHON_VERSION/python-$PYTHON_VERSION.exe
PYTHON_SHA256=f1c783363504c353d4b2478d3af21f72cee0bdd6d4f363a9e0e4fffda3dc9fdf
NSIS_URL=http://prdownloads.sourceforge.net/nsis/nsis-3.02.1-setup.exe?download
NSIS_SHA256=736c9062a02e297e335f82252e648a883171c98e0d5120439f538c81d429552e
LYRA2RE_HASH_PYTHON_URL=https://github.com/wakiyamap/lyra2re-hash-python/releases/download/1.1.2/lyra2re2_hash-1.1.2-cp36-cp36m-win32.whl
LIB_GCC_URL=http://prdownloads.sourceforge.net/mingw/libgcc-6.3.0-1-mingw32-dll-1.tar.xz
LIB_GCC_SHA256=8cbfa963f645cc0f81c08df2a3ecbcefc776606f0fb9db7a280d79f05209a1c3
LIBUSB_URL=https://prdownloads.sourceforge.net/project/libusb/libusb-1.0/libusb-1.0.21/libusb-1.0.21.7z?download
LIBUSB_SHA256=acdde63a40b1477898aee6153f9d91d1a2e8a5d93f832ca8ab876498f3a6d2b8


## These settings probably don't need change
export WINEPREFIX=/opt/wine64
#export WINEARCH='win32'

PYHOME=c:/python$PYTHON_VERSION
PYTHON="wine $PYHOME/python.exe -OO -B"


verify_hash() {
    local file=$1 expected_hash=$2 out=
    actual_hash=$(sha256sum $file | awk '{print $1}')
    if [ "$actual_hash" == "$expected_hash" ]; then
        return 0
    else
        echo "$file $actual_hash (unexpected hash)" >&2
        exit 0
    fi
}

# Let's begin!
cd `dirname $0`
set -e

# Clean up Wine environment
echo "Cleaning $WINEPREFIX"
rm -rf $WINEPREFIX
echo "done"

wine 'wineboot'

echo "Cleaning tmp"
rm -rf tmp
mkdir -p tmp
echo "done"

cd tmp

# Install Python
wget -O python$PYTHON_VERSION.exe "$PYTHON_URL"
verify_hash python$PYTHON_VERSION.exe $PYTHON_SHA256
wine python$PYTHON_VERSION.exe /quiet TargetDir=C:\python$PYTHON_VERSION

# upgrade pip
$PYTHON -m pip install pip --upgrade

# Install pywin32-ctypes (needed by pyinstaller)
$PYTHON -m pip install pywin32-ctypes==0.1.2

# install PySocks
$PYTHON -m pip install win_inet_pton==1.0.1

$PYTHON -m pip install -r ../../deterministic-build/requirements-binaries.txt

## Install pyinstaller
$PYTHON -m pip install pyinstaller==3.3.1

# Install ZBar
#wget -q -O zbar.exe "https://sourceforge.net/projects/zbar/files/zbar/0.10/zbar-0.10-setup.exe/download"
#wine zbar.exe


# Upgrade setuptools (so Electrum can be installed later)
$PYTHON -m pip install setuptools --upgrade

# Install NSIS installer
wget -q -O nsis.exe "$NSIS_URL"
verify_hash nsis.exe $NSIS_SHA256
wine nsis.exe /S

wget -q -O libusb.7z "$LIBUSB_URL"
verify_hash libusb.7z "$LIBUSB_SHA256"
7z x -olibusb libusb.7z
cp libusb/MS32/dll/libusb-1.0.dll $WINEPREFIX/drive_c/python$PYTHON_VERSION/

# Install UPX
#wget -O upx.zip "https://downloads.sourceforge.net/project/upx/upx/3.08/upx308w.zip"
#unzip -o upx.zip
#cp upx*/upx.exe .

# add dlls needed for pyinstaller:
cp $WINEPREFIX/drive_c/python$PYTHON_VERSION/Lib/site-packages/PyQt5/Qt/bin/* $WINEPREFIX/drive_c/python$PYTHON_VERSION/

# install lyra2re2_hash
$PYTHON -m pip install $LYRA2RE_HASH_PYTHON_URL

# copy from mingw for lyra2re2_hash
wget $LIB_GCC_URL
verify_hash libgcc-6.3.0-1-mingw32-dll-1.tar.xz $LIB_GCC_SHA256
tar Jxfv libgcc-6.3.0-1-mingw32-dll-1.tar.xz
cp bin/libgcc_s_dw2-1.dll $WINEPREFIX/drive_c/python$PYTHON_VERSION/Lib/site-packages/

#echo "Wine is configured. Please run prepare-pyinstaller.sh"
