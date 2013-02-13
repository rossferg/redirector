#!/bin/bash

#
#  check all domains mentioned in sites.csv file exist in a set of mappings files
#

usage() {
    echo "usage: $(basename $0) [opts] [mappings.csv ...]" >&2
    echo "    [-n|--name name]            name of mappings" >&2
    echo "    [-s|--sites sites.csv]      sites file" >&2
    echo "    [-?|--help]                 print usage" >&2
    exit 1
}

name="mappings"
sites="data/sites.csv"

while test $# -gt 0 ; do
    case "$1" in
    -n|--name) shift; name="$1 " ; shift ; continue;;
    -s|--sites) shift; sites="$1" ; shift ; continue;;
    -\?|-h|--help) usage ;;
    --) break ;;
    -*) usage ;;
    esac
    break
done


#
#  hosts from sites.csv
#
#  1     2   3                4             5     6             7  8
#  Site,Host,Redirection Date,TNA Timestamp,Title,New Site,Aliases,Validate Options
#

hosts=/tmp/test_coverage.csv
cat "$sites" | 
    tail -n +2 |
    cut -d , -f 2,7 |
    sed -e 's/,/ /g' -e 's/[	 ][	 ]*/\
/g' |
    sed -e '/^ *$/d' |
    sort -u > $hosts

#
#  hosts from mappings
#
missing=$(
cat "$@" |
    cut -d , -f 1 |
    sed -e 's/^http:\/\///' -e 's/\/.*$//' |
    sort -u |
    grep -v "Old Url" |
    comm -3 $hosts - |
    sed -e 's/[ 	]//g'
)

if [ -n "$missing" ] ; then
    echo "missing $name" >&2
    echo "$missing"
    exit 2
fi

exit 0
