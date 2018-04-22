#!/bin/bash

#  Written by Felipe R. A.
#      22 April 2018
#       version 1.0
#
#  Special thanks to: Mike Mandel  
#                     Nanakos Chrysostomos 
#                     Tom Lloyd
         

ARGS=1 # required args

BADARGS=85
INVALIDIMAGE=76
INVALIDPATH=75
NOPERM=74
PRGNOTFOUND=73
UNKPATTERN=72

SRCPATH="/usr/src/linux/" # linux kernel source

LOCATION_KCONFIG="drivers/video/logo/Kconfig"
LOCATION_LOGO_C="drivers/video/logo/logo.c"
LOCATION_MAKEFILE="drivers/video/logo/Makefile"
LOCATION_LINUX_LOGO_H="include/linux/linux_logo.h"

# check usage
if [ $# -lt $ARGS ]; then
	echo "usage: `basename $0` image.png"
	echo "       `basename $0` image.png /path/to/kernel/src/"
	exit $BADARGS
fi

# check image 
if [ -z `echo "$1" | sed -n "/^.*\.png$/p"` ]; then
    echo "error: only accepts png file images"
    exit $INVALIDIMAGE
fi

IMAGENAME=$(basename $1 | sed -e "s/\.png//" | tr A-Z a-z) # lowercase
IMAGENAME_=$(echo ${IMAGENAME} | tr a-z A-Z) # uppercase

# check path
if [ -n "$2" ] && [ -d "$2" ]; then
    SRCPATH="$2/"
fi

# check permission
if [ ! -w $SRCPATH ]; then
    echo "error: action not permitted, try with sudo or su"
    exit $NOPERM
fi

addtext () {
    # Find pattern $2 on file $1 and
    # insert text $3 on next line
    nlines=0
    found=""
    while read line
    do
        nlines=$(expr $nlines + 1)
	if [ -n "`echo \"$line\" | sed -n \"/$2/p\"`" ]; then
	    found="true"
	    nlines=$(expr $nlines + 1)
	    break
        fi
    done < $1
    
    if [ -z "$found" ]; then
        echo "pattern not found: $2"
	exit $UNKPATTERN # not found pattern
    fi
    
    echo "`sed -e "$nlines i $3" $1`" > $1
    return 0
}

### Start

# Create image and move it 
if [ -n "`command -v pngtopnm`" ] \
&& [ -n "`command -v ppmquant`" ] \
&& [ -n "`command -v pnmtoplainpnm`" ]; then
    pngtopnm $1 | ppmquant -fs 223 | pnmtoplainpnm > "${SRCPATH}drivers/video/logo/logo_${IMAGENAME}_clut224.ppm"
else
    echo "error: netpbm tools not found"
    exit $PRGNOTFOUND
fi

# KCONFIG
echo "Editing Kconfig ..."
PATTERN="if LOGO"
TEXT="config LOGO_${IMAGENAME_}_CLUT224\n\
\tbool \"${IMAGENAME} 224-color Logo\"\n\
\tdepends on LOGO\n\
\tdefault y"
addtext "${SRCPATH}${LOCATION_KCONFIG}" "${PATTERN}" "${TEXT}"

#LOGO_C
echo "Editing logo.c ..."
PATTERN="}"
TEXT="extern const struct linux_logo logo_${IMAGENAME}_clut224;"
addtext "${SRCPATH}${LOCATION_LOGO_C}" "${PATTERN}" "${TEXT}"

PATTERN="if (depth >= 8) {"
TEXT="\#ifdef CONFIG_LOGO_${IMAGENAME_}_CLUT224\n\
\t\t/* ${IMAGENAME} logo */\n\
\t\tlogo = &logo_${IMAGENAME}_clut224;\n\
\#endif"
addtext "${SRCPATH}${LOCATION_LOGO_C}" "${PATTERN}" "${TEXT}"

#Makefile
echo "Editing Makefile ..."
PATTERN="\# How to generate logo's"
TEXT="obj-\$\(CONFIG_LOGO_${IMAGENAME_}_CLUT224\)\t\t+= logo_${IMAGENAME}_clut224.o"
addtext "${SRCPATH}${LOCATION_MAKEFILE}" "${PATTERN}" "${TEXT}"

#LINUX_LOGO_H
echo "Editing linux_logo.h ..."
PATTERN="};"
TEXT="extern const struct linux_logo logo_${IMAGENAME}_clut224;"
addtext "${SRCPATH}${LOCATION_LINUX_LOGO_H}" "${PATTERN}" "${TEXT}"

echo "Done!"

exit $?
