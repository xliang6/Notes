#!/bin/sh

#DIR=$(pwd)
#DIR=$HOME/workspaces
DIR=$HOME/src

export TRHOME=$DIR
#export TRSRC=$TRHOME/proxy-openj9/runtime/tr.source
export TRSRC=$TRHOME/openj9/runtime/tr.source
#export TRSRC=$TRHOME/tr.open
export OMR=$TRHOME/omr
export B9=$TRHOME/Base9

#export J9SRC=/gsa/tlbgsa/projects/o/omr/latest/jre/lib/amd64/compressedrefs
#export J9SRC=/gsa/tlbgsa/projects/o/omr/latest/jre/lib/i386/default
#export J9ROOT=/team/xsliang/jvm
export J9ROOT=/team/xsliang/jvm64
#export J9SRC=$J9ROOT/lib/i386/default
#export J9SRC=$J9ROOT/jre/lib/amd64/compressedrefs
export J9SRC=$J9ROOT/lib/amd64/compressedrefs
#export J9_EXEC=$J9ROOT/jre/bin
export J9_EXEC=$J9ROOT/bin

export JITINTRHOME=1

export PLATFORM=amd64-linux64-gcc
#export PLATFORM=amd64-linux-gcc

export PATH=$J9_EXEC:$PATH

export J9_VERSION=29

alias java="java -XXjitdirectory=$TRSRC/objs/trj9_prod"

