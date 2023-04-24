#!/bin/bash -e
export PATH=/usr/local/opt/gnu-sed/libexec/gnubin:$PATH
find . -name 'Makefile' -not -path './packages/golang/*' -exec sed  -i '/golang-package.mk/ c\include ../golang/golang-package.mk' {} \;

find . -name 'Makefile' -exec sed -i '/PKG_BUILD_FLAGS:=no-mips16/ c\PKG_USE_MIPS16:=0' {} \;
# if [[ $1 =~ '21.02'* ]]; then
#     find . -name 'Makefile' -exec sed -i '/PKG_BUILD_FLAGS:=no-mips16/ c\PKG_USE_MIPS16:=0' {} \;
# else
#     find . -name 'Makefile' -exec sed -i '/PKG_USE_MIPS16:=0/ c\PKG_BUILD_FLAGS:=no-mips16' {} \;
# fi