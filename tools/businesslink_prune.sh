#!/bin/bash

#
#  prune URLs which have an error status,  or are redirected to an error page
#

site=businesslink

echo $(date +"%H:%M:%S") "businesslink status codes are probably accurate..." >&2
awk '$3 !~ /^[4-5]/ { print }' < ${site}.txt | sort > ${site}-testable-urls.txt

echo $(date +"%H:%M:%S") "formatting to csv for testing that day's output..." >&2
sort -k2 -nr "${site}-testable-urls.txt" | awk 'BEGIN { print "Old Url,Count,Status" }
  { print "\"" $1 "\"," $2 "," $3 }' > ${site}-testable.csv

echo $(date +"%H:%M:%S") "adding URLs only to site-all.txt..." >&2
( awk '{ print $1 }' "${site}-testable-urls.txt"; cat ../${site}-all.txt ) | sort | uniq > new_${site}_all.txt
mv new_${site}_all.txt ../${site}-all.txt