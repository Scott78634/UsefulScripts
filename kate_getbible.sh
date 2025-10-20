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
# --- Final Output Processing (FIXING REPETITIVE TITLE) ---
# ----------------------------------------------------------------------

# Define the common unwanted text found at the end of Psalms verses
# This is usually the stripped psalm title/heading.
# We make it generic to try and catch all multi-word trailing artifacts.
UNWANTED_TRAIL='Of David\. A psalm\.|A psalm\. Of David\.'
TRANSLATION_TAG_REGEX='^\(([A-Z]+)\)$'

echo "$diatheke_output" |
# 1. Remove all XML tags first. This exposes the clean verse references.
sed 's/<[^>]*>//g' |
# 2. Join lines back together, then insert a newline before every Book/Chapter/Verse marker.
# This ensures each verse starts a new line.
tr '\n' ' ' |
sed -E 's/([A-Z]{1,3}[a-z]*[[:space:]]+[[:digit:]]+:[[:digit:]]+:)/\n\1/g' |
# 3. Clean up leading/trailing whitespace and remove empty lines.
sed -E 's/^[[:space:]]*//;s/[[:space:]]*$//' |
grep -v '^[[:space:]]*$' |
# 4. Filter for only the lines that start with a verse reference.
grep -E '^[A-Z][^:]*:[0-9]+:' |
# 5. Remove the unwanted trailing title text (e.g., "Of David. A psalm.").
# This uses the UNWANTED_TRAIL regex defined above.
sed -E "s/[[:space:]]*$UNWANTED_TRAIL[[:space:]]*$//" |
# 6. CRUCIAL FIX: Extract ONLY the verse number and text.
# Pattern: [Book Name] [Chapter]:[Verse]: [Text] -> [Verse] [Text]
# \1 captures the verse number, \2 captures the text.
sed -E 's/^[[:space:]]*[^[:digit:]]*[[:digit:]]+:([[:digit:]]+):[[:space:]]*(.*)/\1 \2/' |
# 7. Remove any remaining colons.
sed 's/://g' |
# 8. Add the version tag back at the end and remove any blank lines.
# We do this one time and rely on the later steps to ensure uniqueness.
cat - <(echo "$translation") |
grep -v '^[[:space:]]*$' |
# 9. Remove any leading/trailing whitespace
sed -E 's/^[[:space:]]*//;s/[[:space:]]*$//' |
# 10. Use awk to only print unique lines (This prevents duplicate verse lines)
awk '!x[$0]++' |
# 11. Ensure the translation tag is wrapped in parentheses and is printed only once.
# This specifically targets the translation tag and removes duplicates if present.
awk -v tag="$translation" '
    { lines[i++] = $0 }
    END {
        for (j = 0; j < i; j++) {
            if (lines[j] != tag && lines[j] != "(" tag ")") {
                print lines[j]
            }
        }
        print "(" tag ")"
    }
'

