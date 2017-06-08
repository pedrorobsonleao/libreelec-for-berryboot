#!/bin/bash

LIBREELEC_URL='http://releases.libreelec.tv/';
PROCESS_PATH='/tmp/.librelec';
DEFAULT_IMG='LibreELEC-RPi2.arm-8.0.2.img.gz';
PROG=${0##*/};

function getImage() {
    local img=${1};
    
    mkdir -p ${PROCESS_PATH};
    wget    --quiet \
            --continue \
            --show-progress \
            --output-document=${PROCESS_PATH}/${img} \
            ${LIBREELEC_URL}/${img} && {
            rm -f "${PROCESS_PATH}/${img/.gz/}";
            gunzip "${PROCESS_PATH}/${img}";
    }
}


function mountPartition() {
    local img=${1};
    sudo true; # to get a user access
    local device=$( sudo losetup --find --partscan --show "${PROCESS_PATH}/${img/.gz/}" );
    
    #local device=$( losetup | egrep "${PROCESS_PATH}/${img/.gz/}" | cut -d ' ' -f1 | tail -1 );
    
    [ ! -z "${device}" ] && {
        sudo mount ${device}p1 /mnt && {
            unsquashfs /mnt/SYSTEM && {
                sudo losetup --detach ${device};
            }
        }
    }
}

function createImage() {
    local img=${1};
    mksquashfs  squashfs-root/ \
                "${PROCESS_PATH}/${img/.img.gz/}-berryboot.img" \
                -comp lzo \
                -e lib/modules \
                var/cache/apt/archives && {
        rm -rf squashfs-root;
        mv "${PROCESS_PATH}/${img/.img.gz/}-berryboot.img" /tmp;
        rm -rf ${PROCESS_PATH}/*;
    }
}

function help() {
    echo "Use: ${PROG} <parameters>";
    echo;
    echo "parameters:"
    echo "            -h - help";
    echo "            'LibreELEC-RPi2.arm-8.0.2.img.gz' - image name get in 'https://libreelec.tv/downloads/' "
}

function main() {
    set -- ${*//--help/-h};
    
    while getopts h opt; do
        case ${opt} in
            h) help; return 0;;
            *) help; return 0;;
        esac;
    done
    
    local file=;
    
    [ ${#@} == 0 ] && {
        file=${DEFAULT_IMG};
    }
    
    for file in ${@} ${file} ; do
        echo ${file} | egrep --quiet '.img.gz$' && {
            # valid name
            echo ":: ${file}" && \
            getImage ${file} && \
            mountPartition ${file} && \
            createImage ${file};
        } || {
            echo ":: invalide file ${file}";
        }
    done
    
    
    local img=$( ls -c1 '-berryboot.img' 2>/dev/null );
    [ ! -z "{img}" ] && {
        echo "Images:";
        ls -c1 *-berryboot.img;
    }
}

main ${@};
