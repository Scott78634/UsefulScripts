#!/bin/bash
# gedit_getbible.sh
# Scott Purcell, April 22, 2025

# Default translation if not specified
default_translation="NET"

# Check if an argument (the scripture reference) is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <book> <chapter:verse_start-verse_end> <translation>"
    echo "   or: $0 <translation> <book> <chapter:verse_start-verse_end>"
    echo "   or: $0 <book> <chapter:verse_start-verse_end> (using default translation: $default_translation)"
    echo "Examples: Select 'Ro 6:23 LEB', 'LEB Ro 6:23', or 'Ro 6:23' in Gedit."
    exit 1
fi

# Determine translation and reference
parts=($1)
translation=""
book_reference=""

# Check if the last part looks like a common Bible translation
if [[ "${parts[-1]}" =~ ^[A-Z]{2,}$ ]] || [[ "${parts[-1]}" =~ ^[A-Z]{3}\$ ]]; then
    translation="${parts[-1]}"
    # Rebuild the book and reference from the remaining parts
    unset parts[-1] # Remove the last element (the translation)
    book_reference=$(IFS=' '; echo "${parts[*]}")
elif [[ "${parts[0]}" =~ ^[A-Z]{2,}$ ]] || [[ "${parts[0]}" =~ ^[A-Z]{3}\$ ]]; then
    translation="${parts[0]}"
    # Rebuild the book and reference from the remaining parts
    unset parts[0]
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
