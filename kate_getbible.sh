#!/bin/bash
# kate_getbible.sh
# Scott Purcell, October 2025 (Adapted for Kate External Tool)

# Check if the correct number of arguments is provided.
# Expects either 3 args (Kate/CLI) or 1 arg (Gedit/Old setup).
if [ "$#" -ne 3 ] && [ "$#" -ne 1 ]; then
    echo "Usage (command line): $0 <translation> <book> <chapter:verse_start-verse_end>" >&2
    echo "Usage (Kate/CLI): Select text like 'Book Chapter:Verse Translation'" >&2
    exit 1
fi

# --- Argument Parsing ---
if [ "$#" -eq 3 ]; then
    # KATE/Command Line usage: arguments are split by the shell.
    # The arguments arrive in the order: Book Reference Translation
    book="$1"
    reference="$2"
    translation="$3"

elif [ "$#" -eq 1 ]; then
    # Gedit/Old setup usage: parse the single argument (robust logic)
    full_reference="$1"

    # 1. Extract translation (last word)
    translation=$(echo "$full_reference" | awk '{print $NF}')

    # 2. Extract book and reference (everything EXCEPT the last word)
    book_and_reference=$(echo "$full_reference" | awk '{$NF=""; print $0}' | xargs)

    # 3. Separate the book and reference using the LAST SPACE found.
    last_space_pos=$(echo "$book_and_reference" | grep -o -b ' ' | tail -1 | awk -F: '{print $1}')

    if [ -n "$last_space_pos" ]; then
        book=${book_and_reference:0:last_space_pos}
        reference=${book_and_reference:last_space_pos+1}
    else
        echo "Error: Could not parse book and reference from '$book_and_reference'" >&2
        exit 1
    fi

    # Trim leading/trailing whitespace
    book=$(echo "$book" | xargs)
    reference=$(echo "$reference" | xargs)

    # Basic validation for parsed values
    if [ -z "$translation" ] || [ -z "$book" ] || [ -z "$reference" ]; then
        echo "Error: Failed to parse translation, book, or reference from '$full_reference'." >&2
        exit 1
    fi
fi

# --- Diatheke Call and Error Check ---

# Construct the diatheke key (Book Reference)
diatheke_key="$book $reference"

# Get the raw diatheke output (capturing both stdout and stderr)
diatheke_output=$(diatheke -b "$translation" -k "$diatheke_key" 2>&1)

# Check if diatheke failed (looking for common error/help text)
if echo "$diatheke_output" | grep -qE "Usage|invalid module|not found"; then
    echo "Error: Diatheke failed. Check translation ('$translation') or reference ('$diatheke_key')." >&2
    echo "Diatheke output (showing error/help):" >&2
    echo "$diatheke_output" >&2
    exit 1
fi

# --- Canonical Book Name Extraction and Output Formatting ---

# 1. Extract the canonical Book Name from diatheke_output.
canonical_book_name=$(
    echo "$diatheke_output" |
    # Grab the first line that likely contains the full name and the reference
    grep -m 1 "$reference" |
    # Use sed to remove the chapter:verse portion
    sed -E "s/ +[0-9]+:.*//" |
    # Trim whitespace and take the first result
    head -n 1 | xargs
)

# Fallback: If parsing fails, use the original user-provided book name.
if [ -z "$canonical_book_name" ]; then
    canonical_book_name="$book"
fi

# 2. Construct the header using the canonical name.
first_line="$canonical_book_name $reference ($translation)"
echo "$first_line"
echo

# 3. Process the remaining lines to extract verse numbers and text
echo "$diatheke_output" | sed 's/^[^:]*://' | sed 's/<[^>]*>//g' | sed 's/://'
