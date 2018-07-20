#!/bin/sh
for file do
	path=$(dirname "$file")
	full=$(basename "$file")
	name=${full%%.*}
	extension=${full##*.}
	echo "handling $path/$name.{private,public}.$extension"
	cp -n "$path/$name.public.$extension" "$path/$name.private.$extension"
done
