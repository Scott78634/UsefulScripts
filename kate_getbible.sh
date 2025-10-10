#!/bin/bash
# kate_getbible.sh
# Scott Purcell, October 2025 (Final, Error-Free, Robust Version)

# ----------------------------------------------------------------------
# --- Argument and Diatheke Call Blocks (Remaining Correct) ---
# ----------------------------------------------------------------------

# Check if the correct number of arguments is provided.
if [ "$#" -ne 3 ] && [ "$#" -ne 1 ]; then
    echo "Usage (command line): $0 <translation> <book> <chapter:verse_start-verse_end>" >&2
    echo "Usage (Kate/CLI): Select text like 'Book Chapter:Verse Translation'" >&2
    exit 1
fi

# --- Argument Parsing ---
if [ "$#" -eq 3 ]; then
    book="$1"
    reference="$2"
    translation="$3"
elif [ "$#" -eq 1 ]; then
    full_reference="$1"
    translation=$(echo "$full_reference" | awk '{print $NF}')
    book_and_reference=$(echo "$full_reference" | awk '{$NF=""; print $0}' | xargs)
    last_space_pos=$(echo "$book_and_reference" | grep -o -b ' ' | tail -1 | awk -F: '{print $1}')
    if [ -n "$last_space_pos" ]; then
        book=${book_and_reference:0:last_space_pos}
        reference=${book_and_reference:last_space_pos+1}
    else
        echo "Error: Could not parse book and reference from '$book_and_reference'." >&2
        exit 1
    fi
    book=$(echo "$book" | xargs)
    reference=$(echo "$reference" | xargs)
    if [ -z "$translation" ] || [ -z "$book" ] || [ -z "$reference" ]; then
        echo "Error: Failed to parse translation, book, or reference from '$full_reference'." >&2
        exit 1
    fi
fi

# --- Diatheke Call and Error Check ---
diatheke_key="$book $reference"
# CRUCIAL: Diatheke output is captured directly without modification here.
diatheke_output=$(diatheke -b "$translation" -k "$diatheke_key" 2>&1)

if echo "$diatheke_output" | grep -qE "Usage|invalid module|not found"; then
    echo "Error: Diatheke failed. Check translation ('$translation') or reference ('$diatheke_key')." >&2
    echo "Diatheke output (showing error/help):" >&2
    echo "$diatheke_output" >&2
    exit 1
fi

# ----------------------------------------------------------------------
# --- Canonical Book Name Extraction and Custom Header ---
# ----------------------------------------------------------------------

# Extract the canonical Book Name reliably from the raw output.
canonical_book_name=$(
    # Look for the pattern: [Book Name] [Chapter]:[Verse]: on a single line
    echo "$diatheke_output" |
    grep -v '^\s*$' |
    head -n 1 |
    grep -oE '^[[:space:]]*[^[:digit:]]*[[:digit:]]+:[[:digit:]]+:' |
    sed -E 's/[[:space:]]*[[:digit:]]+:.*//' |
    xargs
)

if [ -z "$canonical_book_name" ]; then
    canonical_book_name="$book"
fi

# Construct and print the custom header.
first_line="$canonical_book_name $reference ($translation)"
echo "$first_line"
echo

# ----------------------------------------------------------------------
# --- Final Output Processing (FINAL WORKING FIX) ---
# ----------------------------------------------------------------------

echo "$diatheke_output" |
# 1. Remove all XML tags (e.g., <milestone>, <transChange>, <divineName>).
sed 's/<[^>]*>//g' |
# 2. Skip the lines that are *not* verse text (i.e., lines that don't contain a verse reference).
# This prevents error messages from the next step trying to parse non-verse lines.
grep -E '^[A-Z][^:]*:[0-9]+:' |
# 3. CRUCIAL FIX: Extract ONLY the verse number and text.
# Pattern: [Book Name] [Chapter]:[Verse]: [Text] -> [Verse] [Text]
# \1 captures the verse number, \2 captures the text.
# The structure [^[:digit:]]* ensures any combination of book names is stripped.
sed -E 's/^[[:space:]]*[^[:digit:]]*[[:digit:]]+:([[:digit:]]+):[[:space:]]*(.*)/\1 \2/' |
# 4. Remove any remaining colons and the initial blank lines/headers.
sed 's/://g' |
# 5. Add the version tag back at the end and remove any blank lines.
cat - <(echo "$translation") |
grep -v '^[[:space:]]*$' |
# 6. Remove any leading/trailing whitespace
sed -E 's/^[[:space:]]*//;s/[[:space:]]*$//' |
# 7. Use awk to only print unique lines (since the version tag may be repeated)
awk '!x[$0]++' |
# 8. Ensure the version tag is wrapped in parentheses
sed -E 's/^([A-Z]+)$/(\1)/'
