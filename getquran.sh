#!/bin/bash

# getquran.sh

# This script fetches a Quranic passage and its English translation
# using the api.quran.com API and formats it with Typst markup.

# Dependencies:
# - curl: For making HTTP requests to the API.
# - jq: For parsing the JSON response from the API.
# - zenity: For displaying graphical input dialogs (common on Linux desktops).

# --- 1. Prompt for Surah and Ayah numbers using Zenity ---
# Zenity provides a user-friendly graphical input box.
# If the user cancels the dialog, the script will exit.
SURAH=$(zenity --entry \
               --title="Quran Passage" \
               --text="Enter Surah number (e.g., 1):")

# Check if Surah input was cancelled or empty
if [ -z "$SURAH" ]; then
    zenity --warning --title="Input Cancelled" --text="Surah input cancelled. Exiting."
    exit 1
fi

AYAH=$(zenity --entry \
              --title="Quran Passage" \
              --text="Enter Ayah number for Surah $SURAH (e.g., 1):")

# Check if Ayah input was cancelled or empty
if [ -z "$AYAH" ]; then
    zenity --warning --title="Input Cancelled" --text="Ayah input cancelled. Exiting."
    exit 1
fi

# --- 2. Construct the API URL ---
# We use the api.quran.com v4 API.
# 'language=en' for English translation.
# 'words=false' to get the full verse text, not individual words.
# 'fields=text_uthmani,translations' to specifically request Arabic Uthmani text and translations.
API_URL="https://api.quran.com/api/v4/verses/by_key/${SURAH}:${AYAH}?language=en&words=false&fields=text_uthmani,translations"

# --- 3. Fetch data using curl and parse with jq ---
# '-s' makes curl silent (no progress meter or error messages).
# The entire JSON response is stored in JSON_RESPONSE.
JSON_RESPONSE=$(curl -s "$API_URL")

# Extract the Arabic text (text_uthmani) and the first English translation.
# 'jq -r' outputs raw strings, removing quotes.
ARABIC_TEXT=$(echo "$JSON_RESPONSE" | jq -r '.verse.text_uthmani')
ENGLISH_TRANSLATION=$(echo "$JSON_RESPONSE" | jq -r '.verse.translations[0].text')

# --- 4. Error Handling: Check if data was retrieved successfully ---
if [ -z "$ARABIC_TEXT" ] || [ -z "$ENGLISH_TRANSLATION" ] || [ "$ARABIC_TEXT" == "null" ] || [ "$ENGLISH_TRANSLATION" == "null" ]; then
    zenity --error \
           --title="Error Retrieving Passage" \
           --text="Could not retrieve passage for Surah $SURAH, Ayah $AYAH.
Please check the Surah and Ayah numbers, or your network connection.
(API response might be empty or invalid)"
    exit 1
fi

# --- 5. Generate Typst markup ---
# Set the text font for Arabic to "Noto Naskh Arabic" for proper rendering.
# "Latin Modern Roman" is a good default for English.
# Use #align(right, ...) for Arabic (right-to-left) and #align(left, ...) for English.
# Adjust font sizes as desired.

# Set the font for Arabic text and align it to the right.
echo "#set text(font: (\"Noto Naskh Arabic\", \"Latin Modern Roman\"))"
echo "#align(right, #text(size: 1.2em, \"$ARABIC_TEXT\"))"

# Reset font for English text and align it to the left.
echo "#set text(font: \"Latin Modern Roman\")"
echo "#align(left, #text(size: 1em, \"$ENGLISH_TRANSLATION\"))"
echo "" # Add an empty line for visual separation after the passage

