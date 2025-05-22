#!/bin/bash

# Input and output
INPUT_FILE="init.lua"
OUTPUT_FILE="spellbook.txt"

# Empty the output file
> "$OUTPUT_FILE"

# State machine flags
inside_function=0
function_name=""
description=""
usage_lines=()

while IFS= read -r line; do
  # Check for function definition like: spellbook.something = function(
  if [[ $line =~ ^spellbook\.([a-zA-Z0-9_]+)\ *=\ *function ]]; then
    inside_function=1
    function_name="${BASH_REMATCH[1]}"
    usage_lines=()
    description=""
    continue
  fi

  # If inside a function, look for comment lines
  if (( inside_function )); then
    # Capture the first comment line as description
    if [[ $line =~ ^[[:space:]]*--[[:space:]]*(.*) ]] && [[ -z $description ]]; then
      description="${BASH_REMATCH[1]}"
    elif [[ $line =~ ^[[:space:]]*--[[:space:]]*Usage:\ *(.*) ]]; then
      usage_lines+=("${BASH_REMATCH[1]}")
    # If we hit a non-comment line, we're done with this spell
    elif [[ ! $line =~ ^[[:space:]]*-- ]]; then
      # Write it to the output file
      echo "Spell: $function_name" >> "$OUTPUT_FILE"
      echo "Description: $description" >> "$OUTPUT_FILE"
      echo "Usage:" >> "$OUTPUT_FILE"
      for usage in "${usage_lines[@]}"; do
        echo "  $usage" >> "$OUTPUT_FILE"
      done
      echo "" >> "$OUTPUT_FILE"
      echo "--------------------" >> "$OUTPUT_FILE"
      inside_function=0
    fi
  fi
done < "$INPUT_FILE"

echo "✨ Spellbook compiled to $OUTPUT_FILE!"

