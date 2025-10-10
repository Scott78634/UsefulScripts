#!/bin/bash
# getbible.sh
# Scott Purcell, July 30, 2025 (Updated for Gedit External Tool compatibility)

# Check if the correct number of arguments is provided from the command line
# If run from Gedit, it will likely be 1 argument, which needs to be parsed.
if [ "$#" -ne 3 ] && [ "$#" -ne 1 ]; then
    echo "Usage (command line): $0 <translation> <book> <chapter:verse_start-verse_end>"
    echo "Example (command line): $0 NET 1PE 4:12-19"
    echo "Usage (Gedit External Tool): Select text like 'NET 1PE 4:12-19'"
    exit 1
fi

if [ "$#" -eq 3 ]; then
    # Command line usage: arguments are already separated
    translation="$1"
    book="$2"
    reference="$3"
elif [ "$#" -eq 1 ]; then
    # Gedit External Tool usage: parse the single argument
    full_reference="$1"

    # Extract translation: assuming it's the last word
    translation=$(echo "$full_reference" | awk '{print $NF}')

    # Extract book and reference: remove the last word (translation)
    # This sed command removes the last space and everything after it.
    book_and_reference=$(echo "$full_reference" | sed 's/ [^ ]*$//')

    # Now, try to separate book and reference from book_and_reference
    # This assumes the reference is typically in the format "Chapter:Verse" or "Chapter:Verse-Verse"
    # and the book name doesn't contain digits or colons in its main part (e.g., "1 John" is "1 John", not "1" then "John")
    # This is a more robust way to handle multi-word book names like "1 John"
    if [[ "$book_and_reference" =~ (.*)[[:space:]]+([0-9]+:.*) ]]; then
        book="${BASH_REMATCH[1]}"
        reference="${BASH_REMATCH[2]}"
    else
        # Fallback if the pattern doesn't match (e.g., only a book name selected)
        echo "Error: Could not parse book and reference from '$book_and_reference'" >&2
        exit 1
    fi

    # Basic validation for parsed values
    if [ -z "$translation" ] || [ -z "$book" ] || [ -z "$reference" ]; then
        echo "Error: Failed to parse translation, book, or reference from '$full_reference'." >&2
        echo "Please ensure the selected text is in the format 'Book Chapter:Verse Translation'." >&2
        exit 1
    fi
fi

# Construct the diatheke key directly
diatheke_key="$book $reference"

# Get the raw diatheke output
# Using `2>&1` to capture stderr, as diatheke might output errors there
diatheke_output=$(diatheke -b "$translation" -k "$diatheke_key" 2>&1)

# Check if diatheke_output contains an error message (e.g., "invalid module")
if echo "$diatheke_output" | grep -q "invalid module" || echo "$diatheke_output" | grep -q "not found"; then
    echo "Error: Diatheke could not find translation '$translation' or reference '$diatheke_key'." >&2
    echo "Diatheke output: $diatheke_output" >&2
    exit 1
fi

# Extract the book title and reference for the first line
# Using grep to find the line that starts with a book name followed by a number
# This assumes the first actual verse line has the format "Book Chapter:Verse ..."
# We'll try to get the actual book name from the diatheke output itself, which is more reliable.
# The `head -n 1` approach might be problematic if the first line is just a header or empty.

# Let's try to get the actual book name from the diatheke output more reliably.
# Diatheke typically outputs the full book name on the first line or just before the verse.
# A more robust way might be to look for the first line that looks like a verse number.
# However, for the header, we'll stick to the provided format and rely on `diatheke` to handle the key.
# The original script's `book_title` extraction is a bit fragile.
# Let's just use the parsed book and reference for the header, and let diatheke's output fill the rest.

# The original script's `book_title` extraction:
# book_title=$(echo "$diatheke_output" | head -n 1 | awk '{print $1, $2, $3, $4}'|sed 's/^\(.*\?\)\s\+[[:digit:]]\+:\(.*\)/\1/')
# This is problematic because it assumes a fixed structure for the first line of diatheke output.
# Let's simplify and use the parsed book and reference for the header.

first_line="$book $reference ($translation)" # Updated to include the translation in the header
echo "$first_line"
echo

# Process the remaining lines to extract verse numbers and text
# The existing sed commands are generally good for cleaning diatheke output.
echo "$diatheke_output" | sed 's/^[^:]*://' | sed 's/<[^>]*>//g' | sed 's/://'
