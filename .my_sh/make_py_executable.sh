#!/bin/bash

# Colors and styling
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print banner
echo -e "${BLUE}${BOLD}"
echo "╔═══════════════════════════════════════╗"
echo "║     Python Files Permission Tool       ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# If no directory name is provided, show usage
if [ "$#" -eq 0 ]; then
    echo -e "${YELLOW}Usage: $0 <directory_name> [directory_name2] [directory_name3] ...${NC}"
    echo -e "${YELLOW}Example: $0 src tests scripts${NC}"
    exit 1
fi

# Function to find directories with given names
find_directories() {
    local search_names=("$@")
    local found_dirs=()
    
    for name in "${search_names[@]}"; do
        while IFS= read -r dir; do
            found_dirs+=("$dir")
        done < <(find . -type d -name "$name" 2>/dev/null)
    done
    
    printf "%s\n" "${found_dirs[@]}"
}

# Find all matching directories
mapfile -t found_directories < <(find_directories "$@")

# Check if any directories were found
if [ ${#found_directories[@]} -eq 0 ]; then
    echo -e "${RED}❌ No directories found matching: $*${NC}"
    exit 1
fi

# Show found directories
echo -e "${BLUE}Found these matching directories:${NC}"
for dir in "${found_directories[@]}"; do
    echo -e "${YELLOW}→ $dir${NC}"
done
echo ""

# Count Python files in found directories
INITIAL_COUNT=0
for dir in "${found_directories[@]}"; do
    count=$(find "$dir" -name "*.py" 2>/dev/null | wc -l)
    INITIAL_COUNT=$((INITIAL_COUNT + count))
done

if [ "$INITIAL_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ No Python files found in the specified directories.${NC}"
    exit 1
fi

# Check if we're running with sudo if needed
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Note: If you get permission errors, run with sudo${NC}\n"
fi

# Inform user and ask for confirmation
echo -e "${BLUE}🔍 Found${NC} ${BOLD}$INITIAL_COUNT${NC} ${BLUE}Python files${NC}"
echo -e "${YELLOW}Do you want to make all these Python files executable? (y/N)${NC}"
read -r response

# Check response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Operation cancelled by user${NC}"
    exit 0
fi

echo -e "${BLUE}📂 Starting permission changes...${NC}\n"

# Make files executable
for dir in "${found_directories[@]}"; do
    find "$dir" -name "*.py" -type f -print0 2>/dev/null | while IFS= read -r -d '' file; do
        if chmod +x "$file"; then
            echo -e "${GREEN}✓${NC} Made executable: $file"
        else
            echo -e "${RED}✗${NC} Failed to change: $file"
        fi
    done
done

# Final status
echo -e "\n${GREEN}${BOLD}✅ Operation completed!${NC}"
echo -e "${BLUE}ℹ️  All Python files should now be executable${NC}"
exit 0
