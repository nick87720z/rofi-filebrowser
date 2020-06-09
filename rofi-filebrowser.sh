#!/bin/bash
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
##################################################################################

TMPDIR="/dev/shm/${UID}/rofi-filebrowser-$$"
WD="${ROFI_INFO}"

declare -A cols
eval $( dircolors )
eval 'cols=('$( echo -ne $LS_COLORS | sed -e 's/:$/\"/;  y/:/\ /;  s/^/[\\\"/g;  s/=/\\\"]=\"/g;  s/\ /\"\ [\\\"/g' )' )'

COLORS_FG=( [30]=black [31]=red [32]=green [33]=yellow [34]=blue [35]=magenta [36]=cyan [37]=white )
COLORS_BG=( [40]=black [41]=red [42]=green [43]=yellow [44]=blue [45]=magenta [46]=cyan [47]=white )

_exit()
{
        rm "${lskey}" "${lsstr}"
        rm -r "${TMPDIR}"
        exit
}

lsdir()
{
        lskey="${TMPDIR}/lskey"; mkfifo "${lskey}"
        lsstr="${TMPDIR}/lsstr"; mkfifo "${lsstr}"

        cd "${1}"

        ls --color=never -a -1   "${1}" >"${lskey}" &
        ls --color=never -a -lph "${1}" >"${lsstr}" &

        if [ "x${ROFI_FB_SHOW_ICONS}" == "x1" ]
        then
                lsmim="${TMPDIR}/lsmim"; mkfifo "${lsmim}"
                ls --color=never -a -1 "${1}" | file --mime-type -nNb --files-from - | tr '/' '-' >"${lsmim}" &
                exec 12< "${lsmim}"
        fi

        exec 10< "${lskey}"
        exec 11< "${lsstr}"

        read -u11 -t0.2 sum
        while read -u10 -t0.2 key
        do
                read -u11 -t0.2 str

                fg=
                bg=
                style=
                if [ "x${ROFI_FB_COLORS}" == "x1" ]
                then
                        case "${str:0:1}" in
                                b) style="bd" ;;
                                c) style="cd" ;;
                                C) style="ca" ;;
                                d) style='di' ;;
                                D) style='do' ;;
                                l) if readlink -e "${1}/${key}"
                                        then style="ln"
                                        else style="or"
                                   fi
                                ;;
                                p) style="pi" ;;
                                s) style="so" ;;
                                *) if [ "${str:3:1}" == 's' ] || [ "${str:3:1}" == 'S' ]
                                        then style="su"
                                   elif [ "${str:6:1}" == 's' ] || [ "${str:6:1}" == 'S' ]
                                        then style="sg"
                                   elif [ "${str:3:1}" == 'x' ] || [ "${str:6:1}" == 'x' ] || [ "${str:9:1}" == 'x' ]
                                        then style="ex"
                                   fi

                                   if [ "${str:8:1}" == 'wt' ] || [ "${str:8:1}" == 'wT' ]
                                        then style="tw"
                                   elif [ "${str:9:1}" == 't' ] || [ "${str:9:1}" == 'T' ]
                                        then style="st"
                                   elif [ "${str:8:1}" == 'w' ]
                                        then style="ow"
                                   fi
                                ;;
                        esac
                        if [ -z "${style}" ] ; then
                                style='*.'"${key##*.}"
                        fi
                        if [ -n "${style}" ]
                        then
                                props=( $( tr ';' ' ' <<< ${cols[\"${style}\"]} ) )
                                if [ -n "${props[*]}" ]
                                then
                                        for p in "${props[@]}"
                                        do
                                                if [ -z "${fg}" ]; then
                                                        fg="${COLORS_FG["${p}"]}"
                                                fi
                                                if [ -z "${bg}" ]; then
                                                        bg="${COLORS_BG["${p}"]}"
                                                fi
                                        done
                                fi
                        fi
                        if [ -n "${fg}${bg}" ]
                        then
                                echo -en "<span"
                                if [ -n "${fg}" ] ; then
                                        echo -en " foreground=\"${fg}\""
                                fi
                                if [ -n "${bg}" ] ; then
                                        echo -en " background=\"${bg}\""
                                fi
                                echo -en ">${str}</span>"
                        else
                                echo -en "${str}"
                        fi
                else
                        echo -en "${str}"
                fi

                echo -en "\x00info\x1f${1}/${key}"

                if [ "x${ROFI_FB_SHOW_ICONS}" == "x1" ]
                then
                        read -u12 icon
                        if [ -z "${icon}" ] ; then
                                icon=$( mimetype --output-format="%m" "${key}" | tr '/' '-' )
                        fi
                        echo -en "\x1ficon\x1f${icon}"
                fi
                echo
        done
        echo -en "\0active\x1f${pos}\n"
}

use_parent()
{
        local parent="$(dirname "${path}")"
        pos=2
        for f in "${parent}"/*
        do
                if [ "${f}" == "${path}" ]; then
                        break;
                fi
                (( pos++ ))
        done
        path="${parent}"
}

# Main #

shopt -s dotglob

mkdir -p "${TMPDIR}"

if ! [ -v ROFI_FB_SHOW_ICONS ]; then
        ROFI_FB_SHOW_ICONS=0
fi
if ! [ -v ROFI_FB_COLORS ]; then
        ROFI_FB_COLORS=0
fi

pos=0
msg=
path="${HOME}"

if [ $# != 0 ]; then
        path="$(realpath "${WD}")"
fi

if [ -d "${path}" ]
then
        if ! [ -r "${path}" ] || ! [ -x "${path}" ]
        then
                msg="Permission denied"
                use_parent
        fi
else
        xdg-open "${path}" > /dev/null 2>&1 &
        use_parent
fi

echo -en "\0markup-rows\x1ftrue\n"
echo -en "\0message\x1f${path}"
[ -n "${msg}" ] && \
        echo -en "\r<b>${msg}</b>"
echo
echo -en "\0no-custom\x1ftrue\n"

lsdir "${path}"
_exit
