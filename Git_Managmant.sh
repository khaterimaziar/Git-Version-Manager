#!/bin/bash

# =================================================================
# Enhanced ML Model Version Manager
# Quick versioning for ML experiments with notebook copying
#
# Usage: ./version_model.sh [version_name] [description]
# Example: ./version_model.sh v1 "improved accuracy with new features"
# =================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }

# Get current directory name for project identification
PROJECT_NAME=$(basename "$(pwd)")

# Function to rollback changes
rollback_changes() {
    local STEP=$1
    echo
    warning "Rolling back changes..."
    
    case $STEP in
        "notebook_copy")
            if [ -d "notebooks" ]; then
                cd notebooks
                # Remove newly created notebooks
                for nb in Model\(${VERSION_NAME}\)*.ipynb Model_${VERSION_NAME}*.ipynb; do
                    if [ -f "$nb" ]; then
                        rm "$nb"
                        success "Removed $nb"
                    fi
                done
                cd ..
            fi
            ;;
        "commit")
            git reset --soft HEAD~1
            success "Last commit rolled back"
            ;;
        "branch")
            git checkout "$CURRENT_BRANCH"
            git branch -D "$VERSION_NAME" 2>/dev/null
            success "Branch $VERSION_NAME deleted"
            ;;
        "tag")
            git tag -d "$VERSION_NAME" 2>/dev/null
            git push origin --delete "$VERSION_NAME" 2>/dev/null
            success "Tag $VERSION_NAME removed"
            ;;
        "full")
            # Full rollback
            git checkout "$CURRENT_BRANCH" 2>/dev/null
            git branch -D "$VERSION_NAME" 2>/dev/null
            git tag -d "$VERSION_NAME" 2>/dev/null
            git push origin --delete "$VERSION_NAME" 2>/dev/null
            if [ -d "notebooks" ]; then
                cd notebooks
                for nb in Model\(${VERSION_NAME}\)*.ipynb Model_${VERSION_NAME}*.ipynb; do
                    if [ -f "$nb" ]; then
                        rm "$nb"
                    fi
                done
                cd ..
            fi
            success "Full rollback completed"
            ;;
    esac
}

# Function to handle errors with user choice
handle_error() {
    local ERROR_MSG=$1
    local STEP=$2
    
    error "$ERROR_MSG"
    echo
    echo "What would you like to do?"
    echo "  1) Try again"
    echo "  2) Skip this step"
    echo "  3) Rollback and exit"
    echo "  4) Continue anyway"
    
    read -p "Choose option [1-4]: " -n 1 -r
    echo
    
    case $REPLY in
        1) return 1 ;; # Try again
        2) return 0 ;; # Skip
        3) rollback_changes "$STEP"; exit 1 ;; # Rollback and exit
        4) return 0 ;; # Continue
        *) return 1 ;; # Default: try again
    esac
}

# Function to detect latest notebook version and suggest next
detect_latest_notebook_version() {
    local LATEST_VERSION=""
    local LATEST_NOTEBOOK=""
    local HIGHEST_NUM=0
    
    if [ ! -d "notebooks" ]; then
        # Write results to temp file
        echo "" > /tmp/detected_version.tmp
        echo "" > /tmp/detected_notebook.tmp
        echo "v1"
        return 0
    fi
    
    cd notebooks
    
    # Debug: Show what files are actually found
    echo "🔍 Scanning notebooks directory..." >&2
    
    # Look for different notebook naming patterns
    for nb in *.ipynb; do
        if [ -f "$nb" ]; then
            echo "  Found: $nb" >&2
            
            # Pattern 1: Model(v0).ipynb, Model(v1).ipynb
            if [[ "$nb" =~ Model\(v([0-9]+)\)\.ipynb ]]; then
                VERSION_NUM="${BASH_REMATCH[1]}"
                echo "    Detected version: v$VERSION_NUM (Pattern 1)" >&2
                if [ "$VERSION_NUM" -ge "$HIGHEST_NUM" ]; then
                    HIGHEST_NUM="$VERSION_NUM"
                    LATEST_VERSION="v$VERSION_NUM"
                    LATEST_NOTEBOOK="$nb"
                fi
            # Pattern 2: Model_v0.ipynb, Model_v1.ipynb  
            elif [[ "$nb" =~ Model_v([0-9]+)\.ipynb ]]; then
                VERSION_NUM="${BASH_REMATCH[1]}"
                echo "    Detected version: v$VERSION_NUM (Pattern 2)" >&2
                if [ "$VERSION_NUM" -ge "$HIGHEST_NUM" ]; then
                    HIGHEST_NUM="$VERSION_NUM"
                    LATEST_VERSION="v$VERSION_NUM"
                    LATEST_NOTEBOOK="$nb"
                fi
            # Pattern 3: ModelV0.ipynb, ModelV1.ipynb
            elif [[ "$nb" =~ Model[Vv]([0-9]+)\.ipynb ]]; then
                VERSION_NUM="${BASH_REMATCH[1]}"
                echo "    Detected version: v$VERSION_NUM (Pattern 3)" >&2
                if [ "$VERSION_NUM" -ge "$HIGHEST_NUM" ]; then
                    HIGHEST_NUM="$VERSION_NUM"
                    LATEST_VERSION="v$VERSION_NUM"
                    LATEST_NOTEBOOK="$nb"
                fi
            # Pattern 4: V0_baseline.ipynb, V1_improved.ipynb
            elif [[ "$nb" =~ ^V([0-9]+)_.*\.ipynb$ ]]; then
                VERSION_NUM="${BASH_REMATCH[1]}"
                echo "    Detected version: v$VERSION_NUM (Pattern 4 - V{num}_description)" >&2
                if [ "$VERSION_NUM" -ge "$HIGHEST_NUM" ]; then
                    HIGHEST_NUM="$VERSION_NUM"
                    LATEST_VERSION="v$VERSION_NUM"
                    LATEST_NOTEBOOK="$nb"
                fi
            # Pattern 5: v0_baseline.ipynb, v1_improved.ipynb
            elif [[ "$nb" =~ ^v([0-9]+)_.*\.ipynb$ ]]; then
                VERSION_NUM="${BASH_REMATCH[1]}"
                echo "    Detected version: v$VERSION_NUM (Pattern 5 - v{num}_description)" >&2
                if [ "$VERSION_NUM" -ge "$HIGHEST_NUM" ]; then
                    HIGHEST_NUM="$VERSION_NUM"
                    LATEST_VERSION="v$VERSION_NUM"
                    LATEST_NOTEBOOK="$nb"
                fi
            # Pattern 6: Model(v0).ipynb with special characters
            elif [[ "$nb" =~ ^.*Model.*v([0-9]+).*\.ipynb$ ]]; then
                VERSION_NUM="${BASH_REMATCH[1]}"
                echo "    Detected version: v$VERSION_NUM (Pattern 6 - flexible)" >&2
                if [ "$VERSION_NUM" -ge "$HIGHEST_NUM" ]; then
                    HIGHEST_NUM="$VERSION_NUM"
                    LATEST_VERSION="v$VERSION_NUM"
                    LATEST_NOTEBOOK="$nb"
                fi
            # Pattern 7: Model.ipynb (assume v0)
            elif [[ "$nb" =~ ^[Mm]odel.*\.ipynb$ ]]; then
                echo "    Found generic Model notebook (assuming v0)" >&2
                if [ "$HIGHEST_NUM" -eq 0 ] && [ -z "$LATEST_VERSION" ]; then
                    HIGHEST_NUM=0
                    LATEST_VERSION="v0"
                    LATEST_NOTEBOOK="$nb"
                fi
            else
                echo "    No version pattern matched for: $nb" >&2
            fi
        fi
    done
    
    cd ..
    
    # Debug output
    echo "🎯 Detection result: Latest=$LATEST_VERSION, Notebook=$LATEST_NOTEBOOK" >&2
    
    # Write results to temp files for main function to read
    echo "$LATEST_VERSION" > /tmp/detected_version.tmp
    echo "$LATEST_NOTEBOOK" > /tmp/detected_notebook.tmp
    echo "$HIGHEST_NUM" > /tmp/detected_num.tmp
    
    # Suggest next version
    if [ -z "$LATEST_VERSION" ]; then
        echo "v1" # No version found, start with v1
    else
        NEXT_NUM=$((HIGHEST_NUM + 1))
        echo "v$NEXT_NUM"
    fi
}

# Function to copy notebooks with new version name
copy_notebooks() {
    local NEW_VERSION=$1
    local SOURCE_NOTEBOOK="$DETECTED_LATEST_NOTEBOOK"
    
    # Check if notebooks directory exists
    if [ ! -d "notebooks" ]; then
        if ! handle_error "notebooks directory not found" "notebook_copy"; then
            return 0
        fi
        mkdir -p notebooks
        success "Created notebooks directory"
    fi
    
    cd notebooks
    
    # Use detected source notebook if available
    if [ -n "$SOURCE_NOTEBOOK" ] && [ -f "$SOURCE_NOTEBOOK" ]; then
        # Determine naming pattern based on source
        if [[ "$SOURCE_NOTEBOOK" =~ Model\(v[0-9]+\)\.ipynb ]]; then
            NEW_NOTEBOOK="Model(${NEW_VERSION}).ipynb"
        elif [[ "$SOURCE_NOTEBOOK" =~ Model_v[0-9]+\.ipynb ]]; then
            NEW_NOTEBOOK="Model_${NEW_VERSION}.ipynb"
        elif [[ "$SOURCE_NOTEBOOK" =~ Model[Vv][0-9]+\.ipynb ]]; then
            NEW_NOTEBOOK="ModelV${NEW_VERSION#v}.ipynb"
        elif [[ "$SOURCE_NOTEBOOK" =~ ^V[0-9]+_.*\.ipynb$ ]]; then
            # V0_baseline.ipynb -> V1_description.ipynb pattern
            read -p "Enter description for ${NEW_VERSION} (e.g., 'improved'): " DESCRIPTION_SHORT
            DESCRIPTION_SHORT=${DESCRIPTION_SHORT:-"updated"}
            NEW_NOTEBOOK="V${NEW_VERSION#v}_${DESCRIPTION_SHORT}.ipynb"
        elif [[ "$SOURCE_NOTEBOOK" =~ ^v[0-9]+_.*\.ipynb$ ]]; then
            # v0_baseline.ipynb -> v1_description.ipynb pattern  
            read -p "Enter description for ${NEW_VERSION} (e.g., 'improved'): " DESCRIPTION_SHORT
            DESCRIPTION_SHORT=${DESCRIPTION_SHORT:-"updated"}
            NEW_NOTEBOOK="v${NEW_VERSION#v}_${DESCRIPTION_SHORT}.ipynb"
        else
            # Default pattern
            NEW_NOTEBOOK="V${NEW_VERSION#v}_updated.ipynb"
        fi
        
        if [ "$SOURCE_NOTEBOOK" != "$NEW_NOTEBOOK" ]; then
            cp "$SOURCE_NOTEBOOK" "$NEW_NOTEBOOK"
            success "Created: notebooks/$NEW_NOTEBOOK (copied from $SOURCE_NOTEBOOK)"
            add_version_to_notebook "$NEW_NOTEBOOK" "$NEW_VERSION" "$2"
        else
            warning "Source and target notebook names are the same"
        fi
    else
        # Fallback: Look for existing Model notebooks with old method
        for notebook in Model\(v*.ipynb Model*.ipynb; do
            if [ -f "$notebook" ]; then
                # Extract current version from filename
                if [[ "$notebook" =~ Model\(v([0-9]+)\)\.ipynb ]]; then
                    OLD_VERSION="v${BASH_REMATCH[1]}"
                    NEW_NOTEBOOK="Model(${NEW_VERSION}).ipynb"
                elif [[ "$notebook" =~ Model_v([0-9]+)\.ipynb ]]; then
                    OLD_VERSION="v${BASH_REMATCH[1]}"
                    NEW_NOTEBOOK="Model_${NEW_VERSION}.ipynb"
                else
                    # Default pattern
                    NEW_NOTEBOOK="Model(${NEW_VERSION}).ipynb"
                fi
                
                if [ "$notebook" != "$NEW_NOTEBOOK" ]; then
                    cp "$notebook" "$NEW_NOTEBOOK"
                    success "Created: notebooks/$NEW_NOTEBOOK (copied from $notebook)"
                    add_version_to_notebook "$NEW_NOTEBOOK" "$NEW_VERSION" "$2"
                fi
                break  # Only copy the first found notebook
            fi
        done
        
        # If still no notebook created, look for any Model notebook
        if [ ! -f "Model(${NEW_VERSION}).ipynb" ] && [ ! -f "Model_${NEW_VERSION}.ipynb" ]; then
            for notebook in Model.ipynb model.ipynb; do
                if [ -f "$notebook" ]; then
                    NEW_NOTEBOOK="Model(${NEW_VERSION}).ipynb"
                    cp "$notebook" "$NEW_NOTEBOOK"
                    success "Created: notebooks/$NEW_NOTEBOOK (copied from $notebook)"
                    add_version_to_notebook "$NEW_NOTEBOOK" "$NEW_VERSION" "$2"
                    break
                fi
            done
        fi
    fi
    
    cd ..
}

# Function to add version info to notebook
add_version_to_notebook() {
    local NOTEBOOK_FILE=$1
    local VERSION=$2
    local DESCRIPTION=$3
    
    # Create a temporary Python script to add version cell
    cat > temp_add_version.py << EOF
import json
import sys
from datetime import datetime

try:
    with open('$NOTEBOOK_FILE', 'r', encoding='utf-8') as f:
        notebook = json.load(f)
    
    # Create version info cell
    version_cell = {
        "cell_type": "markdown",
        "metadata": {},
        "source": [
            "# $VERSION - $DESCRIPTION\\n",
            "**Created:** $(date)\\n",
            "**Previous Version:** Copied and updated\\n",
            "\\n",
            "## Changes in this version:\\n",
            "- $DESCRIPTION\\n"
        ]
    }
    
    # Insert at the beginning
    notebook['cells'].insert(0, version_cell)
    
    # Save updated notebook
    with open('$NOTEBOOK_FILE', 'w', encoding='utf-8') as f:
        json.dump(notebook, f, indent=2, ensure_ascii=False)
    
    print("Version info added to notebook")
except Exception as e:
    print(f"Could not add version info: {e}")
EOF

    python3 temp_add_version.py 2>/dev/null
    rm -f temp_add_version.py
}

# Main function
main() {
    clear
    echo -e "${GREEN}🤖 Enhanced ML Model Version Manager${NC}"
    echo "============================================"
    echo
    
    # Get current status
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ $? -ne 0 ]; then
        error "Not a git repository! Run: git init"
        exit 1
    fi
    
    info "Project: $PROJECT_NAME"
    info "Current branch: $CURRENT_BRANCH"
    
    # Detect latest notebook version automatically
    SUGGESTED_NEXT_VERSION=$(detect_latest_notebook_version)
    
    # Read detected values from temp files
    DETECTED_LATEST_VERSION=""
    DETECTED_LATEST_NOTEBOOK=""
    DETECTED_HIGHEST_NUM="0"
    
    if [ -f "/tmp/detected_version.tmp" ]; then
        DETECTED_LATEST_VERSION=$(cat /tmp/detected_version.tmp)
    fi
    if [ -f "/tmp/detected_notebook.tmp" ]; then
        DETECTED_LATEST_NOTEBOOK=$(cat /tmp/detected_notebook.tmp)
    fi
    if [ -f "/tmp/detected_num.tmp" ]; then
        DETECTED_HIGHEST_NUM=$(cat /tmp/detected_num.tmp)
    fi
    
    # Show current notebooks with version detection
    if [ -d "notebooks" ]; then
        echo
        info "Current notebooks:"
        cd notebooks
        for nb in *.ipynb; do
            if [ -f "$nb" ]; then
                if [ "$nb" == "$DETECTED_LATEST_NOTEBOOK" ]; then
                    echo "  📓 $nb ← Latest ($DETECTED_LATEST_VERSION)"
                else
                    echo "  📓 $nb"
                fi
            fi
        done
        cd ..
        
        if [ -n "$DETECTED_LATEST_VERSION" ]; then
            info "Detected latest version: $DETECTED_LATEST_VERSION in '$DETECTED_LATEST_NOTEBOOK'"
            info "Suggested next version: $SUGGESTED_NEXT_VERSION"
        else
            warning "No versioned notebooks found in current naming patterns"
            info "Available notebooks will be copied as: $SUGGESTED_NEXT_VERSION"
        fi
    else
        warning "No notebooks directory found"
        info "Will create notebooks directory and suggested first version: $SUGGESTED_NEXT_VERSION"
    fi
    
    # Check for changes
    if git diff-index --quiet HEAD --; then
        warning "No changes detected. Make sure you've saved your model improvements!"
        read -p "Continue anyway? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi
    
    # Get version information
    if [ -z "$1" ]; then
        read -p "Version name [$SUGGESTED_NEXT_VERSION]: " VERSION_NAME
        VERSION_NAME=${VERSION_NAME:-$SUGGESTED_NEXT_VERSION}
    else
        VERSION_NAME="$1"
    fi
    
    # Add 'v' prefix if not present
    if [[ ! "$VERSION_NAME" =~ ^v ]]; then
        VERSION_NAME="v$VERSION_NAME"
    fi
    
    # Get description
    if [ -z "$2" ]; then
        read -p "What did you improve in this version?: " DESCRIPTION
        if [ -z "$DESCRIPTION" ]; then
            DESCRIPTION="Model improvements and updates"
        fi
    else
        DESCRIPTION="$2"
    fi
    
    echo
    info "Creating version: $VERSION_NAME"
    info "Description: $DESCRIPTION"
    echo
    
    # Confirm
    read -p "Proceed? [Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    # Store current branch for rollback purposes
    ORIGINAL_BRANCH="$CURRENT_BRANCH"
    
    # Step 1: Copy notebooks with new version name
    echo "Step 1: Creating versioned notebook copies..."
    while ! copy_notebooks "$VERSION_NAME" "$DESCRIPTION"; do
        if ! handle_error "Failed to copy notebooks" "notebook_copy"; then
            break
        fi
    done
    
    # Step 2: Commit current changes (including new notebooks)
    echo
    echo "Step 2: Committing current model and notebooks..."
    git add .
    
    COMMIT_MSG="feat: $VERSION_NAME - $DESCRIPTION"
    while true; do
        if git commit -m "$COMMIT_MSG"; then
            success "Changes committed"
            break
        else
            if ! handle_error "Failed to commit changes" "commit"; then
                exit 1
            fi
        fi
    done
    
    # Step 3: Push current branch
    echo
    echo "Step 3: Pushing current branch..."
    if git push origin "$CURRENT_BRANCH" 2>/dev/null; then
        success "Current branch pushed"
    else
        # Maybe first push
        if git push -u origin "$CURRENT_BRANCH" 2>/dev/null; then
            success "Current branch pushed (first time)"
        else
            warning "Failed to push current branch, continuing..."
        fi
    fi
    
    # Step 4: Create new branch
    echo
    echo "Step 4: Creating new branch '$VERSION_NAME'..."
    
    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$VERSION_NAME"; then
        warning "Branch '$VERSION_NAME' already exists!"
        read -p "Switch to existing branch? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git checkout "$VERSION_NAME"
            success "Switched to existing branch"
        else
            echo "Cancelled."
            exit 0
        fi
    else
        if git checkout -b "$VERSION_NAME"; then
            success "New branch '$VERSION_NAME' created"
        else
            error "Failed to create branch"
            exit 1
        fi
    fi
    
    # Step 5: Update version in other files (if they exist)
    echo
    echo "Step 5: Updating version in project files..."
    
    # Look for Python files and add version comment
    for py_file in *.py; do
        if [ -f "$py_file" ]; then
            # Add version comment at the top if not already there
            if ! grep -q "Version: $VERSION_NAME" "$py_file"; then
                # Create temp file with version comment
                echo "# Version: $VERSION_NAME - $DESCRIPTION" > temp_file
                echo "# Created: $(date)" >> temp_file
                echo "" >> temp_file
                cat "$py_file" >> temp_file
                mv temp_file "$py_file"
                success "Updated $py_file with version info"
            fi
        fi
    done
    
    # Step 6: Commit version updates
    echo
    echo "Step 6: Committing version updates..."
    git add .
    
    VERSION_COMMIT_MSG="docs: initialize $VERSION_NAME codebase"
    if git commit -m "$VERSION_COMMIT_MSG"; then
        success "Version updates committed"
    else
        info "No additional changes to commit"
    fi
    
    # Step 7: Push new branch
    echo
    echo "Step 7: Pushing new branch to remote..."
    if git push -u origin "$VERSION_NAME"; then
        success "New branch pushed to remote"
    else
        error "Failed to push new branch"
        warning "You can push later with: git push -u origin $VERSION_NAME"
    fi
    
    # Step 8: Create tag
    echo
    echo "Step 8: Creating version tag..."
    TAG_MSG="$VERSION_NAME: $DESCRIPTION"
    if git tag -a "$VERSION_NAME" -m "$TAG_MSG"; then
        success "Tag '$VERSION_NAME' created"
        
        # Push tag
        if git push origin "$VERSION_NAME"; then
            success "Tag pushed to remote"
        else
            warning "Tag not pushed to remote"
        fi
    else
        warning "Tag might already exist"
    fi
    
    # Final summary
    echo
    echo "============================================"
    success "Model versioning completed!"
    echo
    info "✨ New version: $VERSION_NAME"
    info "📝 Description: $DESCRIPTION"
    info "🌿 Branch: $VERSION_NAME"
    info "🏷️ Tag: $VERSION_NAME"
    info "📓 Notebook: notebooks/Model(${VERSION_NAME}).ipynb"
    info "📁 Current directory: $(pwd)"
    echo
    echo "Your notebooks:"
    if [ -d "notebooks" ]; then
        for nb in notebooks/Model*.ipynb; do
            if [ -f "$nb" ]; then
                echo "  📓 $(basename "$nb")"
            fi
        done
    fi
    echo
    echo "Your next steps:"
    echo "  🔬 Continue improving your model in: notebooks/Model(${VERSION_NAME}).ipynb"
    echo "  💾 Save changes regularly"
    echo "  🚀 Run this script again when ready for next version"
    echo
    echo "Useful commands:"
    echo "  git branch -a          # See all branches"
    echo "  git log --oneline      # See commit history"
    echo "  git checkout main      # Go back to main branch"
    echo "  git checkout $VERSION_NAME  # Return to this version"
    echo
    echo "🔧 If something went wrong:"
    echo "  ./$(basename "$0") --rollback $VERSION_NAME    # Rollback this version"
    echo "  ./$(basename "$0") --fix                       # Interactive fix mode"
    echo
}

# Function to rollback a specific version
rollback_version() {
    local VERSION_TO_ROLLBACK=$1
    
    if [ -z "$VERSION_TO_ROLLBACK" ]; then
        error "Please specify version to rollback"
        echo "Usage: ./$(basename "$0") --rollback v1"
        exit 1
    fi
    
    echo "🔄 Rolling back version: $VERSION_TO_ROLLBACK"
    echo
    
    # Confirm
    read -p "This will delete branch, tag, and notebook. Continue? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    # Switch to main/master branch first
    MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@' 2>/dev/null || echo "main")
    git checkout "$MAIN_BRANCH" 2>/dev/null || git checkout main 2>/dev/null || git checkout master 2>/dev/null
    
    # Delete local branch
    if git branch -D "$VERSION_TO_ROLLBACK" 2>/dev/null; then
        success "Local branch $VERSION_TO_ROLLBACK deleted"
    fi
    
    # Delete remote branch
    if git push origin --delete "$VERSION_TO_ROLLBACK" 2>/dev/null; then
        success "Remote branch $VERSION_TO_ROLLBACK deleted"
    fi
    
    # Delete tag
    if git tag -d "$VERSION_TO_ROLLBACK" 2>/dev/null; then
        success "Local tag $VERSION_TO_ROLLBACK deleted"
    fi
    
    if git push origin --delete "$VERSION_TO_ROLLBACK" 2>/dev/null; then
        success "Remote tag $VERSION_TO_ROLLBACK deleted"
    fi
    
    # Delete notebooks
    if [ -d "notebooks" ]; then
        cd notebooks
        for nb in Model\(${VERSION_TO_ROLLBACK}\)*.ipynb Model_${VERSION_TO_ROLLBACK}*.ipynb; do
            if [ -f "$nb" ]; then
                rm "$nb"
                success "Deleted notebook: $nb"
            fi
        done
        cd ..
    fi
    
    echo
    success "Rollback completed!"
}

# Interactive fix mode
interactive_fix() {
    echo "🔧 Interactive Fix Mode"
    echo "======================"
    echo
    
    echo "What went wrong?"
    echo "  1) Notebook copying failed"
    echo "  2) Git commit failed" 
    echo "  3) Branch creation failed"
    echo "  4) Push to remote failed"
    echo "  5) Tag creation failed"
    echo "  6) Want to rollback everything"
    
    read -p "Choose issue [1-6]: " -n 1 -r
    echo
    
    case $REPLY in
        1)
            echo "Fixing notebook copying..."
            if [ ! -d "notebooks" ]; then
                mkdir -p notebooks
                success "Created notebooks directory"
            fi
            cd notebooks
            echo "Available notebooks:"
            ls -la *.ipynb 2>/dev/null || echo "No notebooks found"
            ;;
        2)
            echo "Fixing git commit..."
            git status
            echo "Run: git add . && git commit -m 'your message'"
            ;;
        3)
            echo "Fixing branch creation..."
            echo "Current branches:"
            git branch -a
            ;;
        4)
            echo "Fixing remote push..."
            echo "Try: git push -u origin \$(git branch --show-current)"
            ;;
        5)
            echo "Fixing tag creation..."
            echo "Current tags:"
            git tag
            ;;
        6)
            echo "Available versions to rollback:"
            git branch | grep -E "v[0-9]+" || echo "No version branches found"
            read -p "Enter version to rollback (e.g., v1): " ROLLBACK_VERSION
            if [ -n "$ROLLBACK_VERSION" ]; then
                rollback_version "$ROLLBACK_VERSION"
            fi
            ;;
    esac
}

# Show help
show_help() {
    echo "Enhanced ML Model Version Manager"
    echo
    echo "USAGE:"
    echo "  ./version_model.sh                           # Interactive mode"
    echo "  ./version_model.sh v1                       # Quick version"
    echo "  ./version_model.sh v2 'improved accuracy'   # With description"
    echo
    echo "WHAT IT DOES:"
    echo "  1. Creates versioned copy of your notebook (Model(v0).ipynb -> Model(v1).ipynb)"
    echo "  2. Commits your current model improvements"
    echo "  3. Creates a new branch for the next version"
    echo "  4. Updates version info in Python files"
    echo "  5. Pushes everything to remote (GitHub, etc.)"
    echo "  6. Creates a git tag for easy reference"
    echo
    echo "Perfect for ML experimentation workflow!"
    echo "Keeps all your notebook versions organized and accessible."
    echo
}

# Check arguments
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
elif [[ "$1" == "--rollback" ]]; then
    rollback_version "$2"
    exit 0
elif [[ "$1" == "--fix" ]]; then
    interactive_fix
    exit 0
fi

# Run main function
main "$@"
