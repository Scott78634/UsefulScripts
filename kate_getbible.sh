#!/bin/bash
# kate_getbible.sh
# Updated for robustness with full book names, whole chapters, and interactive prompting.

# ----------------------------------------------------------------------
# --- 1. Argument Collection and Parsing ---
# ----------------------------------------------------------------------

# Combine all arguments into one string to handle various quoting styles
FULL_INPUT="$*"

# If no input provided, we can't do anything (unless we want to prompt for EVERYTHING,
# but usually in Kate you select text first).
if [ -z "$FULL_INPUT" ]; then
    echo "Error: No text selected or arguments provided." >&2
    exit 1
fi

# Function to prompt for translation
get_translation_interactive() {
    # Default translation preference
    DEFAULT_TRANS="LEB"

    if command -v kdialog >/dev/null 2>&1; then
        # KDE Native Dialog
        kdialog --title "Bible Translation" --inputbox "Enter Translation (e.g., KJV, ESV, LEB):" "$DEFAULT_TRANS"
    elif command -v zenity >/dev/null 2>&1; then
        # GTK/Gnome Fallback
        zenity --entry --title "Bible Translation" --text "Enter Translation:" --entry-text "$DEFAULT_TRANS"
    else
        # Terminal Fallback
        read -p "Enter Translation (e.g., LEB): " input_trans
        echo "$input_trans"
    fi
}

# --- Logic to determine Book/Reference vs Translation ---

# Get the last word of the input string
LAST_WORD=$(echo "$FULL_INPUT" | awk '{print $NF}')

# Regex to check if the last word looks like a translation code.
# Criteria: 3-5 uppercase letters, or specific common ones like "NKJV".
# If the last word is numeric (e.g. "Genesis 1"), it's NOT a translation.
if [[ "$LAST_WORD" =~ ^[A-Z]{3,5}$ ]]; then
    TRANSLATION="$LAST_WORD"
    # Remove the translation from the query string
    QUERY=$(echo "$FULL_INPUT" | sed "s/[[:space:]]*$TRANSLATION$//")
else
    # The input likely doesn't have a translation (e.g. "Genesis 1")
    QUERY="$FULL_INPUT"
    TRANSLATION=$(get_translation_interactive)
fi

if [ -z "$TRANSLATION" ]; then
    echo "Error: No translation provided." >&2
    exit 1
fi

# ----------------------------------------------------------------------
# --- 2. Diatheke Call ---
# ----------------------------------------------------------------------

# We pass the whole QUERY to diatheke. Diatheke is smart enough to parse
# "Genesis 1", "Gen 1:1", or "1 John 1" without us splitting it manually.
DIATHEKE_OUTPUT=$(diatheke -b "$TRANSLATION" -k "$QUERY" 2>&1)

# Error Checking
if echo "$DIATHEKE_OUTPUT" | grep -qE "Usage|invalid module|not found"; then
    echo "Error: Diatheke failed. Check translation ('$TRANSLATION') or reference ('$QUERY')." >&2
    exit 1
fi

# ----------------------------------------------------------------------
# --- 3. Header Extraction ---
# ----------------------------------------------------------------------

# Extract a display header. We try to grab the first verse reference returned.
# We relaxed the regex to allow numbered books (1 John) and full names.
CANONICAL_REF=$(echo "$DIATHEKE_OUTPUT" | \
    grep -oE '^[[:space:]]*([1-3]?[[:space:]]?[A-Za-z]+)[[:space:]]+[0-9]+:[0-9]+:' | \
    head -n 1 | \
    sed 's/:$//' | xargs)

if [ -z "$CANONICAL_REF" ]; then
    # Fallback if regex fails (e.g. sometimes diatheke output format varies)
    CANONICAL_REF="$QUERY"
fi

echo "$CANONICAL_REF ($TRANSLATION)"
echo

# ----------------------------------------------------------------------
# --- 4. Content Processing ---
# ----------------------------------------------------------------------

UNWANTED_TRAIL='Of David\. A psalm\.|A psalm\. Of David\.'

echo "$DIATHEKE_OUTPUT" |
# 1. Strip XML
sed 's/<[^>]*>//g' |
# 2. Normalize newlines for processing
tr '\n' ' ' |
# 3. Insert newline before Verse Markers.
# UPDATED REGEX: Handles "Gen", "Genesis", "1 John", "Song of Solomon"
# Logic: Optional number -> Space -> Word(s) -> Space -> Number:Number:
sed -E 's/(([1-3][[:space:]])?[A-Za-z ]+[[:space:]]+[0-9]+:[0-9]+:)/\n\1/g' |
# 4. Clean whitespace
sed -E 's/^[[:space:]]*//;s/[[:space:]]*$//' |
grep -v '^[[:space:]]*$' |
# 5. Filter for lines that actually look like verses
# UPDATED REGEX: Matches "Genesis 1:1:" or "1 John 1:1:"
grep -E '^([1-3][[:space:]])?[A-Za-z].*:[0-9]+:' |
# 6. Remove unwanted Psalm titles
sed -E "s/[[:space:]]*$UNWANTED_TRAIL[[:space:]]*$//" |
# 7. Extract Verse Number and Text.
# \1 = Verse Number, \2 = Text
sed -E 's/^.*:([0-9]+):[[:space:]]*(.*)/\1 \2/' |
# 8. Remove internal colons if any remain
sed 's/://g' |
# 9. Append Translation tag to end (deduplication handled via logic)
cat - <(echo "($TRANSLATION)") |
# 10. Clean up
sed -E 's/^[[:space:]]*//;s/[[:space:]]*$//' |
# 11. Final output formatting
awk -v tag="$TRANSLATION" '
    !seen[$0]++ {
        # Store lines to print them cleanly
        if ($0 != "(" tag ")" && $0 != tag) {
            print $0
        }
    }
    END {
        print "(" tag ")"
    }
'
