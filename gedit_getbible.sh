#!/bin/bash
# getbible.sh
# Scott Purcell, April 21, 2025

# Default translation if not specified
default_translation="NET"

# Check if an argument (the scripture reference) is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <translation> <book> <chapter:verse_start-verse_end>"
    echo "   or: $0 <book> <chapter:verse_start-verse_end> (using default translation: $default_translation)"
    echo "Example: Select 'NET 1PE 1:6-7' or '1PE 1:6-7' in Gedit and run this tool."
    exit 1
fi

# Determine translation and reference
parts=($1)
translation=""
book_reference=""

# Check if the first part looks like a common Bible translation (all caps or short abbreviations)
if [[ "${parts[0]}" =~ ^[A-Z]{2,}$ ]] || [[ "${parts[0]}" =~ ^[A-Z]{3}\$ ]]; then
    translation="${parts[0]}"
    # Rebuild the book and reference from the remaining parts
    shift parts
    book_reference=$(IFS=' '; echo "${parts[*]}")
else
    translation="$default_translation"
    book_reference="$1"
fi

# Split the book and reference
IFS=' ' read -r book reference <<< "$book_reference"

# Construct the diatheke key directly
diatheke_key="$book $reference"

# Get the raw diatheke output
diatheke_output=$(diatheke -b "$translation" -k "$diatheke_key")

# Extract the book title and reference for the first line
book_title=$(echo "$diatheke_output" | head -n 1 | awk '{print $1, $2, $3, $4}'|sed 's/^\(.*\?\)\s\+[[:digit:]]\+:\(.*\)/\1/')
first_line="$book_title $reference ($translation)"
echo "$first_line"
echo

# Process the remaining lines to extract verse numbers and text
echo "$diatheke_output" |sed 's/^[^:]*://' |sed 's/<[^>]*>//g' |sed 's/://'

