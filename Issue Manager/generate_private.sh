for file do
	path=$(dirname "$file")
	full=$(basename "$file")
	name=${full%%.*}
	extension=${full##*.}
	echo "full: $full, name: $name, extension: $extension"
	cp -n "$path/$name.public.$extension" "$path/$name.private.$extension"
done
