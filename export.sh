#!/bin/sh
# Export Project Files to Single Text File
# POSIX-compliant script for any *nix system

set -e

# Default values
PROJECT_PATH="${1:-.}"
OUTPUT_FILE="${2:-docs/llm/dump.txt}"

# File extensions to include (space-separated)
INCLUDE_EXTENSIONS="cs json xml csproj sln slnx props config cshtml razor js css scss html yml yaml sql"

# Directories to exclude (space-separated)
EXCLUDE_DIRS="bin obj .vs .git node_modules packages .vscode .idea docs"

# File patterns to exclude (space-separated)
EXCLUDE_FILES="*.exe *.dll *.pdb *.cache *.log *.md *.txt LICENSE* LICENCE*"

# Colors (will be disabled if not a terminal)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' CYAN='' WHITE='' NC=''
fi

log_green() { printf "${GREEN}%s${NC}\n" "$1"; }
log_yellow() { printf "${YELLOW}%s${NC}\n" "$1"; }
log_cyan() { printf "${CYAN}%s${NC}\n" "$1"; }
log_white() { printf "${WHITE}%s${NC}\n" "$1"; }

# Resolve to absolute path
PROJECT_PATH=$(cd "$PROJECT_PATH" && pwd)

log_green "Starting project export..."
log_yellow "Project Path: $PROJECT_PATH"
log_yellow "Output File: $OUTPUT_FILE"

# Create output directory if needed
OUTPUT_PATH="$PROJECT_PATH/$OUTPUT_FILE"
OUTPUT_DIR=$(dirname "$OUTPUT_PATH")
mkdir -p "$OUTPUT_DIR"

# Build find exclude pattern for directories
build_exclude_pattern() {
    first=1
    for dir in $EXCLUDE_DIRS; do
        if [ $first -eq 1 ]; then
            printf "%s" "-name $dir"
            first=0
        else
            printf "%s" " -o -name $dir"
        fi
    done
}

# Check if file matches exclude patterns
is_excluded_file() {
    filename=$(basename "$1")
    for pattern in $EXCLUDE_FILES; do
        case "$filename" in
            $pattern) return 0 ;;
        esac
    done
    return 1
}

# Check if file has included extension
has_included_extension() {
    filename=$(basename "$1")
    ext="${filename##*.}"
    [ "$ext" != "$filename" ] || return 1
    for inc_ext in $INCLUDE_EXTENSIONS; do
        [ "$ext" = "$inc_ext" ] && return 0
    done
    return 1
}

# Write header
cat > "$OUTPUT_PATH" << EOF
===============================================================================
PROJECT EXPORT
Generated: $(date)
Project Path: $PROJECT_PATH
===============================================================================

EOF

# Generate directory structure
log_cyan "Generating directory structure..."

cat >> "$OUTPUT_PATH" << EOF
DIRECTORY STRUCTURE:
===================

EOF

# Try tree command first, fall back to find-based tree
if command -v tree >/dev/null 2>&1; then
    # Build tree ignore pattern
    TREE_IGNORE=$(echo "$EXCLUDE_DIRS" | tr ' ' '|')
    tree "$PROJECT_PATH" -a -I "$TREE_IGNORE" --noreport >> "$OUTPUT_PATH" 2>/dev/null || {
        # macOS tree might have different options
        tree "$PROJECT_PATH" -a -I "$TREE_IGNORE" >> "$OUTPUT_PATH" 2>/dev/null || true
    }
else
    log_yellow "tree command not available, using find alternative..."
    
    # Simple find-based directory listing
    (
        cd "$PROJECT_PATH"
        echo "$(basename "$PROJECT_PATH")/"
        
        # Build prune expression
        PRUNE_EXPR=""
        for dir in $EXCLUDE_DIRS; do
            PRUNE_EXPR="$PRUNE_EXPR -name $dir -prune -o"
        done
        
        eval "find . $PRUNE_EXPR -print" 2>/dev/null | \
            grep -v '^\.$' | \
            sort | \
            while read -r path; do
                # Calculate depth for indentation
                depth=$(echo "$path" | tr -cd '/' | wc -c)
                indent=""
                i=0
                while [ $i -lt "$depth" ]; do
                    indent="$indent    "
                    i=$((i + 1))
                done
                name=$(basename "$path")
                if [ -d "$path" ]; then
                    echo "${indent}+-- ${name}/"
                else
                    echo "${indent}+-- ${name}"
                fi
            done
    ) >> "$OUTPUT_PATH"
fi

printf "\n\n" >> "$OUTPUT_PATH"

# Collect and process files
log_cyan "Collecting files..."

# Create temp file for file list
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

# Find all matching files
(
    cd "$PROJECT_PATH"
    
    # Build prune expression for excluded directories
    PRUNE_EXPR=""
    for dir in $EXCLUDE_DIRS; do
        PRUNE_EXPR="$PRUNE_EXPR -name $dir -prune -o"
    done
    
    # Find files, excluding directories
    eval "find . $PRUNE_EXPR -type f -print" 2>/dev/null
) | while read -r file; do
    # Check extension
    if has_included_extension "$file"; then
        # Check exclusion patterns
        if ! is_excluded_file "$file"; then
            echo "$file"
        fi
    fi
done | sort -u > "$TEMP_FILE"

FILE_COUNT=$(wc -l < "$TEMP_FILE" | tr -d ' ')
log_green "Found $FILE_COUNT files to export"

# Export each file
cat >> "$OUTPUT_PATH" << EOF
FILE CONTENTS:
==============

EOF

CURRENT=0
while IFS= read -r file; do
    CURRENT=$((CURRENT + 1))
    
    # Remove leading ./
    REL_PATH="${file#./}"
    FULL_PATH="$PROJECT_PATH/$REL_PATH"
    
    log_white "Processing ($CURRENT/$FILE_COUNT): $REL_PATH"
    
    # Get file info (portable way)
    if [ -f "$FULL_PATH" ]; then
        FILE_SIZE=$(wc -c < "$FULL_PATH" | tr -d ' ')
        FILE_SIZE_KB=$(awk "BEGIN {printf \"%.2f\", $FILE_SIZE / 1024}")
        
        # Get modification time (different on Linux vs BSD/macOS)
        if stat --version >/dev/null 2>&1; then
            # GNU stat (Linux)
            MOD_TIME=$(stat -c '%y' "$FULL_PATH" 2>/dev/null | cut -d'.' -f1)
        else
            # BSD stat (macOS)
            MOD_TIME=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$FULL_PATH" 2>/dev/null)
        fi
        
        cat >> "$OUTPUT_PATH" << EOF
================================================================================
FILE: $REL_PATH
SIZE: ${FILE_SIZE_KB} KB
MODIFIED: $MOD_TIME
================================================================================

EOF
        
        # Read and append file content
        if [ -s "$FULL_PATH" ]; then
            cat "$FULL_PATH" >> "$OUTPUT_PATH" 2>/dev/null || \
                echo "[ERROR READING FILE]" >> "$OUTPUT_PATH"
        else
            echo "[EMPTY FILE]" >> "$OUTPUT_PATH"
        fi
        
        printf "\n\n" >> "$OUTPUT_PATH"
    fi
done < "$TEMP_FILE"

# Add footer
cat >> "$OUTPUT_PATH" << EOF
===============================================================================
EXPORT COMPLETED: $(date)
Total Files Exported: $FILE_COUNT
Output File: $OUTPUT_PATH
===============================================================================
EOF

log_green ""
log_green "Export completed successfully!"
log_yellow "Output file: $OUTPUT_PATH"
log_green "Total files exported: $FILE_COUNT"

# Display file size
if [ -f "$OUTPUT_PATH" ]; then
    OUTPUT_SIZE=$(wc -c < "$OUTPUT_PATH" | tr -d ' ')
    OUTPUT_SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $OUTPUT_SIZE / 1048576}")
    log_cyan "Output file size: ${OUTPUT_SIZE_MB} MB"
fi
