#!/bin/bash
# getbible.sh
# Scott Purcell, April 21, 2025

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <translation> <book> <chapter:verse_start-verse_end>"
    echo "Example: $0 NET 1PE 4:12-19"
    exit 1
fi

translation="$1"
book="$2"
reference="$3"

# Construct the diatheke key directly
diatheke_key="$book $reference"

# Get the raw diatheke output
diatheke_output=$(diatheke -b "$translation" -k "$diatheke_key")

# Extract the book title and reference for the first line
book_title=$(echo "$diatheke_output" | head -n 1 | awk '{print $1, $2, $3, $4}'|sed 's/^\(.*\?\)\s\+[[:digit:]]\+:\(.*\)/\1/')
#echo ">>> This is the Book Title <<<"
#echo $book_title
#echo ">>> <<<"
first_line="$book_title $reference"
echo "$first_line"
echo

# Process the remaining lines to extract verse numbers and text
echo "$diatheke_output" |sed 's/^[^:]*://' |sed 's/<[^>]*>//g' |sed 's/://'
