#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <file.drawio>"
  exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File '$INPUT_FILE' not found."
  exit 1
fi

BASE_NAME=$(basename "$INPUT_FILE" .drawio)

# Count the total number of pages/tabs in the file
NUM_PAGES=$(grep -o '<diagram' "$INPUT_FILE" | wc -l)

if [ "$NUM_PAGES" -eq 0 ]; then
  echo "Error: No pages found in '$INPUT_FILE'."
  exit 1
fi

echo "Found $NUM_PAGES page(s). Exporting..."

# Start indexing at 1 for Draw.io v27.0.2+
for ((i=1; i<= NUM_PAGES ; i++)); do
  output_file="${BASE_NAME}-c${i}.png"

  drawio --export --format png --page-index "$i" -o "$output_file" "$INPUT_FILE" 2>/dev/null
  
  if [ $? -ne 0 ]; then
    rm -f "$output_file"
       echo "Error exporting page $i"
       exit 1
    break
  else
	echo "$i successfully exported to png  --> $output_file"
  fi
done

