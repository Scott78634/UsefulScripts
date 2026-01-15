#!/bin/bash

# 1. Setup the Day and Directory
read -p "Which day are we recording? (e.g., 1): " DAY_INPUT
DAY_PADDED=$(printf "%03d" "$DAY_INPUT")
OUT_DIR="/home/scott/Documents/BIAY/working/Day${DAY_PADDED}/Images"

mkdir -p "$OUT_DIR"
echo "--- Folder: Day $DAY_PADDED ---"

# 2. Select the area ONCE using slurp
echo "Select your capture area..."
REGION=$(slurp -f "%wx%h+%x+%y")

if [ -z "$REGION" ]; then
    echo "Selection cancelled. Exiting."
    exit 1
fi

echo "Area set to $REGION."
echo "Recording started. Press [CTRL+C] in this terminal to stop."

# 3. The Loop
while true; do
    TIMESTAMP=$(date +%H%M%S)
    FINAL_FILE="$OUT_DIR/shot_$TIMESTAMP.png"

    # Using ImageMagick's 'import' which handles the portal handshake
    # -window root tells it to look at the screen
    # -crop uses the coordinates we saved earlier
    import -window root -crop "$REGION" "$FINAL_FILE"

    if [ -f "$FINAL_FILE" ]; then
        echo "Saved: shot_$TIMESTAMP.png"
    else
        echo "Capture failed. The portal might be blocked."
        exit 1
    fi

    sleep 5
done
