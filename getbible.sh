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
book_title=$(echo "$diatheke_output" | head -n 1 | awk '{print $1, $2}')
first_line="$book_title $reference"
echo "$first_line"

# Process the remaining lines to extract verse numbers and text
echo "$diatheke_output" | awk '
NR > 1 && !/\(NET\)/ {
    match($0, /^[^ ]+ [^ ]+ ([0-9]+): (.*)/, parts);
    if (parts[1] != "") {
        print parts[1] " " parts[2];
    }
}
END {
    if ($0 ~ /\(NET\)/) {
        print $0
    }
}
' | sed 's/<[^>]*>//g'
