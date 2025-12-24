#!/bin/bash
# kate_getbible.sh - Final Robust Version

# --- 1. Configuration ---
DEFAULT_TRANS="LEB"

# --- 2. Argument Collection ---
FULL_INPUT="$*"
if [ -z "$FULL_INPUT" ]; then
    echo "Error: No text selected." >&2
    exit 1
fi

# --- 3. Translation & Query Parsing ---
# Extract the last word to check if it's a translation code (e.g., KJV, LEB)
LAST_WORD=$(echo "$FULL_INPUT" | awk '{print $NF}')

if [[ "$LAST_WORD" =~ ^[A-Z]{3,5}$ ]]; then
    TRANSLATION="$LAST_WORD"
    QUERY=$(echo "$FULL_INPUT" | sed "s/[[:space:]]*$TRANSLATION$//")
else
    QUERY="$FULL_INPUT"
    # Prompt user for translation if not provided in text
    if [ -n "$DISPLAY" ]; then
        if command -v kdialog >/dev/null 2>&1; then
            TRANSLATION=$(kdialog --title "Bible Translation" --inputbox "Enter Translation:" "$DEFAULT_TRANS")
        elif command -v zenity >/dev/null 2>&1; then
            TRANSLATION=$(zenity --entry --title "Bible Translation" --text "Enter Translation:" --entry-text "$DEFAULT_TRANS")
        fi
    fi
fi

# Sanitize Translation: strip newlines/spaces and default if empty
TRANSLATION=$(echo "${TRANSLATION:-$DEFAULT_TRANS}" | tr -d '[:space:]')

# --- 4. Diatheke Execution ---
DIATHEKE_OUTPUT=$(diatheke -b "$TRANSLATION" -k "$QUERY" 2>&1)

# Better Error Checking:
# Don't look for "not found" in the body text.
# Only trigger if output is tiny or contains usage/module errors.
if [[ -z "$DIATHEKE_OUTPUT" || "$DIATHEKE_OUTPUT" == *"Usage:"* || "$DIATHEKE_OUTPUT" == *"invalid module"* ]]; then
    echo "Error: Diatheke failed for '$QUERY' using '$TRANSLATION'." >&2
    exit 1
fi

# --- 5. Formatting the Result ---

# Header: Reference (Translation)
echo "$QUERY ($TRANSLATION)"
echo

echo "$DIATHEKE_OUTPUT" | \
# 1. Strip XML tags
sed 's/<[^>]*>//g' | \
# 2. Clean LEB specific markers (⌞⌟) and non-breaking spaces
sed 's/⌞//g; s/⌟//g; s/&nbsp;//g' | \
# 3. Strip Book/Chapter prefix but keep Verse Number
# Matches "Genesis 2:18:" or "1 John 1:1:" and leaves just "18 "
sed -E 's/^([1-3]?[[:space:]]?[A-Za-z ]+[[:space:]]+[0-9]+):([0-9]+):/\2/' | \
# 4. Remove Psalm titles or trails
sed -E "s/Of David\. A psalm\.|A psalm\. Of David\.//g" | \
# 5. Remove the trailing translation info line (e.g., "(LEB)")
grep -v "^($TRANSLATION)$" | \
# 6. Join into a paragraph
tr '\n' ' ' | \
# 7. Final Polish: remove redundant spaces and trim
sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]*//; s/[[:space:]]*$//'

echo # Final newline
