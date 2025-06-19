#!/bin/bash

# Script to restructure mail from mbsync format to Maildir++ format for Himalaya
# This converts separate Maildir directories to a single Maildir with subfolders

MAIL_DIR="/home/benjamin/Mail/Gmail"
BACKUP_DIR="/home/benjamin/Mail/Gmail_backup_$(date +%Y%m%d_%H%M%S)"
TEMP_DIR="/tmp/maildir_restructure"

echo "=== Maildir Restructure Script ==="
echo "Converting mbsync format to Maildir++ format for Himalaya compatibility"
echo

# Check if mail directory exists
if [ ! -d "$MAIL_DIR" ]; then
    echo "Error: Mail directory $MAIL_DIR does not exist"
    exit 1
fi

# Create backup
echo "1. Creating backup at $BACKUP_DIR..."
cp -r "$MAIL_DIR" "$BACKUP_DIR"
if [ $? -eq 0 ]; then
    echo "   ✓ Backup created successfully"
else
    echo "   ✗ Backup failed"
    exit 1
fi

# Create temporary directory
echo "2. Creating temporary working directory..."
mkdir -p "$TEMP_DIR"

# Show current structure
echo "3. Current structure:"
ls -la "$MAIL_DIR"

echo
echo "4. Analyzing folders..."
folders=()

# Function to process a directory and find Maildirs
process_directory() {
    local base_dir="$1"
    local relative_path="$2"
    
    for dir in "$base_dir"/*; do
        if [ -d "$dir" ]; then
            folder_name=$(basename "$dir")
            current_path="$relative_path$folder_name"
            
            # Check if it's a valid Maildir (has cur, new, tmp)
            if [ -d "$dir/cur" ] && [ -d "$dir/new" ] && [ -d "$dir/tmp" ]; then
                folders+=("$current_path")
                echo "   Found Maildir: $current_path"
            else
                # Recursively check subdirectories
                process_directory "$dir" "$current_path/"
            fi
        fi
    done
}

process_directory "$MAIL_DIR" ""

if [ ${#folders[@]} -eq 0 ]; then
    echo "   ✗ No valid Maildir directories found"
    exit 1
fi

# Create new Maildir++ structure
echo "5. Creating new Maildir++ structure..."

# Create main Maildir directories at root
mkdir -p "$TEMP_DIR/cur" "$TEMP_DIR/new" "$TEMP_DIR/tmp"
echo "   ✓ Created main Maildir directories"

# Process each folder
for folder in "${folders[@]}"; do
    echo "   Processing folder: $folder"
    
    # Get the full path to the source folder
    source_path="$MAIL_DIR/$folder"
    
    # Determine subfolder name (use dot prefix for Maildir++)
    if [ "$folder" = "INBOX" ]; then
        # INBOX contents go to the main Maildir
        echo "     Moving INBOX to main Maildir..."
        target_dir="$TEMP_DIR"
    else
        # Other folders become dot-prefixed subfolders
        # Replace slashes with dots for nested folders
        subfolder_name=$(echo ".$folder" | sed 's|/|.|g')
        echo "     Creating subfolder: $subfolder_name"
        target_dir="$TEMP_DIR/$subfolder_name"
        mkdir -p "$target_dir/cur" "$target_dir/new" "$target_dir/tmp"
    fi
    
    # Copy emails efficiently using rsync for speed
    for subdir in cur new tmp; do
        if [ -d "$source_path/$subdir" ] && [ "$(ls -A "$source_path/$subdir" 2>/dev/null)" ]; then
            file_count=$(ls "$source_path/$subdir" | wc -l)
            echo "       Copying $subdir/ ($file_count files)..."
            if [ "$file_count" -gt 1000 ]; then
                # Use rsync for large directories (much faster)
                rsync -a "$source_path/$subdir/" "$target_dir/$subdir/" 2>/dev/null || true
            else
                # Use cp for small directories
                cp "$source_path/$subdir"/* "$target_dir/$subdir/" 2>/dev/null || true
            fi
        fi
    done
done

echo "6. Verifying new structure..."
echo "   New structure at $TEMP_DIR:"
ls -la "$TEMP_DIR"

# Count emails in old vs new structure
echo "7. Counting emails..."
old_count=$(find "$MAIL_DIR" -name "*:2,*" | wc -l)
new_count=$(find "$TEMP_DIR" -name "*:2,*" | wc -l)
echo "   Old structure: $old_count emails"
echo "   New structure: $new_count emails"

if [ "$old_count" -ne "$new_count" ]; then
    echo "   ⚠ Warning: Email count mismatch! Check the conversion."
    echo "   Backup is available at: $BACKUP_DIR"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting. Backup preserved at: $BACKUP_DIR"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# Replace old structure with new one
echo "8. Replacing old structure with new Maildir++ format..."
read -p "This will replace your current mail structure. Continue? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$MAIL_DIR"
    mv "$TEMP_DIR" "$MAIL_DIR"
    echo "   ✓ Mail structure updated successfully"
    
    echo
    echo "=== Conversion Complete ==="
    echo "✓ Backup created at: $BACKUP_DIR"
    echo "✓ Mail converted to Maildir++ format"
    echo "✓ Try running Himalaya again with <leader>ml"
    echo
    echo "New structure:"
    ls -la "$MAIL_DIR"
else
    echo "Conversion cancelled. Backup preserved at: $BACKUP_DIR"
    rm -rf "$TEMP_DIR"
fi