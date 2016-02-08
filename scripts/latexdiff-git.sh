#!/bin/bash

# Copyright 2016 Ankur Sinha 
# Author: Ankur Sinha <sanjay DOT ankur AT gmail DOT com> 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# File : latexdiff-git.sh
# It appears that the --flatten option in latexdiff doesn't work with revision control for some reason. I'm not entirely sure why this is. 
# http://tex.stackexchange.com/questions/61405/latexdiff-svn-not-working-with-multiple-files-flatten
# Therefore, the workaround seems to be to scriptify it.

GITREPO=""
MAINFILE="main.tex"
SUBDIR="."
REV1FILE="rev1-main.tex"
REV2FILE="rev2-main.tex"
LATEXPANDFOUND="no"
LATEXDIFFFOUND="no"
GITFOUND="no"
PDFLATEXFOUND="no"
LATEXPANDPATH="/usr/bin/latexpand"
LATEXDIFFPATH="/usr/bin/latexdiff"
PDFLATEXPATH="/usr/bin/pdflatex"
GITPATH="/usr/bin/git"
REV1="master^"
REV2="master"

function main ()
{
    TEMPDIR=$(mktemp -d)
    CLONEDIR="$TEMPDIR/tempclone"
    GITREPO=$(pwd)
    DIFFNAME="diff-$REV1-$REV2"

    pushd "$TEMPDIR"
        git clone "$GITREPO" "$CLONEDIR"

        pushd "$CLONEDIR"
            git reset HEAD --hard
            git checkout -b temp-head-2 "$REV1"
            pushd "$CLONEDIR/$SUBDIR"
                latexpand "$MAINFILE" -o "$REV1FILE"
                mv "$REV1FILE" "$TEMPDIR"
            popd
            git checkout -b temp-head-1 "$REV2"
            pushd "$CLONEDIR/$SUBDIR"
                latexpand "$MAINFILE" -o "$REV2FILE"
                mv "$REV2FILE" "$TEMPDIR"
            popd
        popd
        latexdiff --type=UNDERLINE "$REV1FILE" "$REV2FILE" > "$DIFFNAME"".tex"
        pdflatex "$DIFFNAME"".tex"
        mv "$DIFFNAME"".pdf" "$GITREPO" -v
    popd
    rm -rf "$TEMPDIR/*"
    rm -frv "$TEMPDIR"
    echo "Cleaned up. Exiting."
}

function check_requirements ()
{
    if [ -x "$LATEXPANDPATH" ]; then
        LATEXPANDFOUND="yes"
    fi
    if [ -x "$LATEXDIFFPATH" ]; then
        LATEXDIFFFOUND="yes"
    fi
    if [ -x "$GITPATH" ]; then
        GITFOUND="yes"
    fi
    if [ -x "$PDFLATEXPATH" ]; then
        PDFLATEXFOUND="yes"
    fi

    if [ "yes" == "$LATEXPANDFOUND" ] &&  [ "yes" == "$LATEXDIFFFOUND" ] && [ "yes" == "$GITFOUND" ] && [ "yes" == "$PDFLATEXFOUND" ]; then
        echo "Found required binaries. Continuing."
    else
        echo "Did not find required binaries. Please check that latexpand, latexdiff, pdflatex and git are installed and the paths they're installed at are set correctly in the script."
        return -1
    fi
}

usage ()
{
    cat << EOF
    usage: $0 options

    This script generates a pdf diff from two git commits in the working directory.
    To be run in the root of the git repo.

    It's a very simple script. If it doesn't work, you're doing something wrong ;)

    latexdiff itself provides various output options. Please read the latexdiff manpage for more information.

    OPTIONS:
    -h  Show this message

    -m  Main file to be converted (in case of includes and so on). 
        Default: main.tex

    -s  Subdirectory which contains tex files. 
        Default: .

    -r  Revision 1 
        Default: HEAD~1

    -t  Revision 2 
        Default: HEAD

    NOTES:
    Please use shortcommit references as far as possible since pdflatex and so
    on have difficulties with special characters in filenames - ~, ^ etc. may
    not always work. If they don't, look at the script output to understand
    why.

    In general, anything that can be checked out should work - branch names, tags, commits.

EOF
}

# Run it
check_requirements

while getopts "hm:s:r:t:" OPTION
do
    case $OPTION in
        h)
            usage
            exit 0
            ;;
        m) 
            MAINFILE=$OPTARG
            ;;
        s)
            SUBDIR=$OPTARG
            ;;
        r)
            REV1=$OPTARG
            ;;
        t)
            REV2=$OPTARG
            ;;
        ?)
            usage
            exit 0
            ;;
    esac
done
main
