#!/bin/sh

set -e

. tools/messages.sh

status "DEPLOY_TO=$DEPLOY_TO"

csv="dist/full_urls.csv"

status "Combining all known mappings into $csv ..."

# find all mappings and tests
mkdir -p dist
cat data/mappings/*.csv \
	data/tests/full/*.csv \
	data/tests/popular/*.csv \
	data/tests/subsets/*.csv \
	| sed 's/"//g' | sort | uniq | egrep -v '^Old Url' | (

	echo "Old Url,New Url,Status,Suggested Link,Archive Link"
	cat

) > $csv

status "Testing $csv ..."

prove -l tools/test_csv.pl :: $csv