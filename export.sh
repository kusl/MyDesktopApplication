#!/bin/bash
# Export project files for LLM analysis
# Includes: .cs, .csproj, .axaml, .json, .props, .slnx

OUTPUT_DIR="docs/llm"
OUTPUT_FILE="$OUTPUT_DIR/dump.txt"
PROJECT_PATH="$(pwd)"

echo "Starting project export..."
echo "Project Path: $PROJECT_PATH"
echo "Output File: $OUTPUT_FILE"

mkdir -p "$OUTPUT_DIR"

{
    echo "==============================================================================="
    echo "PROJECT EXPORT"
    echo "Generated: $(date)"
    echo "Project Path: $PROJECT_PATH"
    echo "==============================================================================="
    echo ""
    echo "DIRECTORY STRUCTURE:"
    echo "==================="
    echo ""
    tree -I 'bin|obj|.git|.vs|.idea|TestResults' --noreport 2>/dev/null || find . -type f \( -name "*.cs" -o -name "*.csproj" -o -name "*.axaml" -o -name "*.json" -o -name "*.props" -o -name "*.slnx" \) | grep -v -E "(bin|obj|\.git)" | sort
    echo ""
    echo ""
    echo "FILE CONTENTS:"
    echo "=============="
    echo ""
} > "$OUTPUT_FILE"

# Find all relevant files (including .axaml!)
FILES=$(find . -type f \( \
    -name "*.cs" -o \
    -name "*.csproj" -o \
    -name "*.axaml" -o \
    -name "*.json" -o \
    -name "*.props" -o \
    -name "*.slnx" -o \
    -name "*.md" \
    \) ! -path "*/bin/*" ! -path "*/obj/*" ! -path "*/.git/*" ! -path "*/.vs/*" | sort)

FILE_COUNT=$(echo "$FILES" | wc -l)
echo "Generating directory structure..."
echo "Collecting files..."
echo "Found $FILE_COUNT files to export"

COUNTER=0
for file in $FILES; do
    COUNTER=$((COUNTER + 1))
    FILENAME="${file#./}"
    FILESIZE=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
    MODIFIED=$(stat -c%y "$file" 2>/dev/null | cut -d'.' -f1 || stat -f"%Sm" "$file" 2>/dev/null)
    
    echo "Processing ($COUNTER/$FILE_COUNT): $FILENAME"
    
    {
        echo "================================================================================"
        echo "FILE: $FILENAME"
        echo "SIZE: $(echo "scale=2; $FILESIZE/1024" | bc) KB"
        echo "MODIFIED: $MODIFIED"
        echo "================================================================================"
        echo ""
        cat "$file"
        echo ""
        echo ""
    } >> "$OUTPUT_FILE"
done

{
    echo "==============================================================================="
    echo "EXPORT COMPLETED: $(date)"
    echo "Total Files Exported: $FILE_COUNT"
    echo "Output File: $PROJECT_PATH/$OUTPUT_FILE"
    echo "==============================================================================="
} >> "$OUTPUT_FILE"

echo ""
echo "Export completed successfully!"
echo "Output file: $PROJECT_PATH/$OUTPUT_FILE"
echo "Total files exported: $FILE_COUNT"
FILESIZE=$(stat -c%s "$OUTPUT_FILE" 2>/dev/null || stat -f%z "$OUTPUT_FILE" 2>/dev/null)
echo "Output file size: $(echo "scale=2; $FILESIZE/1048576" | bc) MB"
