#!/bin/bash
# kate_getbible.sh - Optimized version

# ----------------------------------------------------------------------
# --- 1. Argument Collection and Parsing ---
# ----------------------------------------------------------------------
FULL_INPUT="$*"
if [ -z "$FULL_INPUT" ]; then
    echo "Error: No text selected." >&2
    exit 1
fi

get_translation_interactive() {
    DEFAULT_TRANS="LEB"
    if command -v kdialog >/dev/null 2>&1; then
        kdialog --title "Bible Translation" --inputbox "Enter Translation:" "$DEFAULT_TRANS"
    elif command -v zenity >/dev/null 2>&1; then
        zenity --entry --title "Bible Translation" --text "Enter Translation:" --entry-text "$DEFAULT_TRANS"
    else
        read -p "Enter Translation (e.g., LEB): " input_trans
        echo "${input_trans:-$DEFAULT_TRANS}"
    fi
}

# Determine Translation vs Query
LAST_WORD=$(echo "$FULL_INPUT" | awk '{print $NF}')
if [[ "$LAST_WORD" =~ ^[A-Z]{3,5}$ ]]; then
    TRANSLATION="$LAST_WORD"
    QUERY=$(echo "$FULL_INPUT" | sed "s/[[:space:]]*$TRANSLATION$//")
else
    QUERY="$FULL_INPUT"
    TRANSLATION=$(get_translation_interactive)
fi

[ -z "$TRANSLATION" ] && exit 1

# ----------------------------------------------------------------------
# --- 2. Diatheke Call ---
# ----------------------------------------------------------------------
DIATHEKE_OUTPUT=$(diatheke -b "$TRANSLATION" -k "$QUERY" 2>&1)

if echo "$DIATHEKE_OUTPUT" | grep -qE "Usage|invalid module|not found"; then
    echo "Error: Diatheke failed. Check translation or reference." >&2
    exit 1
fi

# ----------------------------------------------------------------------
# --- 3. Output Formatting ---
# ----------------------------------------------------------------------

# Header: Use the user's original query to preserve ranges like "1:24-25"
echo "$QUERY ($TRANSLATION)"
echo

# Process the body
echo "$DIATHEKE_OUTPUT" | \
# 1. Strip XML tags
sed 's/<[^>]*>//g' | \
# 2. Clean LEB specific markers (⌞⌟)
sed 's/⌞//g; s/⌟//g' | \
# 3. Strip the Book and Chapter prefix, leave the verse number
# Transforms "Matthew 1:24: Text" into "24 Text"
sed -E 's/^([1-3][[:space:]])?[A-Za-z ]+[[:space:]]+[0-9]+:([0-9]+):/\2/' | \
# 4. Remove unwanted Psalm titles/trails
sed -E "s/Of David\. A psalm\.|A psalm\. Of David\.//g" | \
# 5. Remove the trailing translation tag that Diatheke sometimes appends
grep -v "^($TRANSLATION)$" | \
# 6. Convert newlines to spaces to create a paragraph
tr '\n' ' ' | \
# 7. Clean up double spaces and leading/trailing whitespace
sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]*//; s/[[:space:]]*$//'

echo # Final newline for cleanliness
