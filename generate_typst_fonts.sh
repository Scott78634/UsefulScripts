#!/bin/bash

# This script reads font names from standard input (e.g., from 'typst fonts')
# and generates Typst code to display each font name in two different sizes.

# Loop through each line (font name) provided via standard input
while IFS= read -r font_name; do
    # Skip empty lines, which might occur if there's trailing whitespace
    if [[ -z "$font_name" ]]; then
        continue
    fi

    # Remove any leading/trailing whitespace from the font name
    # This is important as 'typst fonts' might output names with extra spaces
    font_name=$(echo "$font_name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # Generate the Typst code for the 12pt sample
    # We use printf for precise formatting and to handle potential special characters in font names
    printf '#text(font: "%s", size: 12pt)[%s]\n' "$font_name" "$font_name"

    # Generate the Typst code for the 24pt sample
    printf '#text(font: "%s", size: 24pt)[%s]\n\n' "$font_name" "$font_name"

done

