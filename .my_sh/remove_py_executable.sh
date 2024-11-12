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
echo "║  Remove Python Files Execute Rights    ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Function to count Python files
count_py_files() {
    find . -name "*.py" | wc -l
}

# Check if we're running with sudo if needed
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Note: If you get permission errors, run with sudo${NC}\n"
fi

# Count files before starting
INITIAL_COUNT=$(count_py_files)

if [ "$INITIAL_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ No Python files found in the current directory and subdirectories.${NC}"
    exit 1
fi

# Inform user and ask for confirmation
echo -e "${BLUE}🔍 Found${NC} ${BOLD}$INITIAL_COUNT${NC} ${BLUE}Python files${NC}"
echo -e "${YELLOW}Do you want to remove executable permissions from all these Python files? (y/N)${NC}"
read -r response

# Check response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Operation cancelled by user${NC}"
    exit 0
fi

echo -e "${BLUE}📂 Starting permission changes...${NC}\n"

# Remove executable permissions
find . -name "*.py" -type f -print0 | while IFS= read -r -d '' file; do
    if chmod -x "$file"; then
        echo -e "${GREEN}✓${NC} Removed executable permission: $file"
    else
        echo -e "${RED}✗${NC} Failed to change: $file"
    fi
done

# Final status
echo -e "\n${GREEN}${BOLD}✅ Operation completed!${NC}"
echo -e "${BLUE}ℹ️  Execute permissions have been removed from all Python files${NC}"
exit 0
