#!/bin/bash

# Sync skills directory to ~/.agents/skills
# Only overwrites subdirectories that exist in source, doesn't delete other content in destination

set -e

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/skills" && pwd)"
DEST_DIR="$HOME/.agents/skills"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

echo "Syncing skills from $SOURCE_DIR to $DEST_DIR"
echo "----------------------------------------"

# Iterate through each subdirectory in the source skills directory
for skill_dir in "$SOURCE_DIR"/*/ ; do
    if [ -d "$skill_dir" ]; then
        # Remove trailing slash from skill_dir to copy the directory itself
        skill_dir="${skill_dir%/}"
        skill_name=$(basename "$skill_dir")
        echo "Syncing: $skill_name"
        
        # Use rsync to sync each skill directory
        # -a: archive mode (preserves permissions, timestamps, etc.)
        # -v: verbose
        # --delete: delete files in destination that don't exist in source (only within this skill dir)
        # Without trailing slash on source, rsync copies the directory itself
        rsync -av --delete "$skill_dir" "$DEST_DIR/"
    fi
done



# Sync global rules template to ~/.gemini/GEMINI.md
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEMINI_TEMPLATE="$PROJECT_ROOT/config/global-agent.rules.md"
GEMINI_TARGET="$HOME/.gemini/GEMINI.md"

if [ -f "$GEMINI_TEMPLATE" ]; then
    # 1. Sync to global Antigravity config
    mkdir -p "$HOME/.gemini"
    
    if [ ! -f "$GEMINI_TARGET" ] || [ ! -s "$GEMINI_TARGET" ]; then
        # File doesn't exist or is empty - copy template
        echo "Installing global rules from template"
        cp "$GEMINI_TEMPLATE" "$GEMINI_TARGET"
        echo "✓ Global rules installed to ~/.gemini/GEMINI.md"
    else
        # File exists with content - check if ask-logger rule already exists
        if ! grep -q "Auto-Log User Questions" "$GEMINI_TARGET"; then
            echo "Appending ask-logger rule to existing GEMINI.md"
            echo "" >> "$GEMINI_TARGET"
            echo "---" >> "$GEMINI_TARGET"
            echo "" >> "$GEMINI_TARGET"
            cat "$GEMINI_TEMPLATE" >> "$GEMINI_TARGET"
            echo "✓ Ask-logger rule added to ~/.gemini/GEMINI.md"
        else
            echo "✓ Ask-logger rule already exists in ~/.gemini/GEMINI.md"
        fi
    fi
fi



echo "----------------------------------------"
echo "Sync completed successfully!"
