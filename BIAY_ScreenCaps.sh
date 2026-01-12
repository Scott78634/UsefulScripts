#!/bin/bash

# 1. Determine the ImageMagick command
if command -v convert >/dev/null 2>&1; then
    IM_CMD="convert"
elif command -v magick >/dev/null 2>&1; then
    IM_CMD="magick"
else
    echo "Error: ImageMagick is not installed. Run: sudo apt install imagemagick"
    exit 1
fi

# 2. Ask for the Day Number
read -p "Which day are we recording? (e.g., 1 or 365): " DAY_INPUT

# 3. Pad the number to 3 digits (e.g., 1 becomes 001)
DAY_PADDED=$(printf "%03d" "$DAY_INPUT")

# 4. Construct the path
OUT_DIR="/home/scott/Documents/BIAY/working/Day${DAY_PADDED}/Images"

# Create the directory path if it doesn't exist
mkdir -p "$OUT_DIR"
echo "--- Output set to: $OUT_DIR ---"

# 5. Select the area
echo "Select the area of the screen to capture..."
REGION=$(slurp -f "%wx%h+%x+%y")

if [ -z "$REGION" ]; then
    echo "Selection cancelled."
    exit 1
fi

echo "Capturing every 5 seconds. Press [CTRL+C] to stop."

# 6. The Loop
while true; do
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    TEMP_FILE="/tmp/full_shot.png"
    FINAL_FILE="$OUT_DIR/shot_$TIMESTAMP.png"

    # Capture and Crop
    spectacle -b -n -f -o "$TEMP_FILE"
    $IM_CMD "$TEMP_FILE" -crop "$REGION" "$FINAL_FILE"

    echo "Saved: Day ${DAY_PADDED} - shot_$TIMESTAMP.png"

    sleep 5
done
