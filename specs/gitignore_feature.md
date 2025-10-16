# Neo-tree Gitignore Integration

## Overview

This document describes the custom gitignore functionality added to the neo-tree file explorer, which allows users to easily add and remove files/directories from `.gitignore` directly from the file tree interface.

## Features

### Add to Gitignore
- **Keymap**: `gi` (while in neo-tree)
- **Function**: Adds the selected file or directory to `.gitignore`
- **Behavior**: 
  - For directories: Automatically adds trailing slash (e.g., `src/components/`)
  - For files: Adds the exact path (e.g., `config.env`)
  - Calculates relative path from git repository root
  - Prevents duplicate entries
  - Provides user feedback via notifications

### Remove from Gitignore
- **Keymap**: `gI` (while in neo-tree) 
- **Function**: Removes the selected file or directory from `.gitignore`
- **Behavior**:
  - Handles both directory formats (with and without trailing slash)
  - Removes all matching entries
  - Provides user feedback via notifications

## Implementation Details

### Architecture
- **Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua`
- **Integration**: Custom commands in `filesystem.commands` table
- **Buffer Safety**: Uses `vim.schedule()` to avoid "E21: Cannot make changes, 'modifiable' is off" errors

### Key Technical Features

1. **Modifiable Buffer Error Prevention**:
   - All file operations wrapped in `vim.schedule()` 
   - Prevents neo-tree buffer modification conflicts
   - Allows external file operations without buffer issues

2. **Git Repository Detection**:
   - Uses `git rev-parse --show-toplevel` to find repository root
   - Gracefully handles non-git directories
   - Calculates relative paths correctly

3. **Robust File Handling**:
   - Uses `pcall()` for safe file operations
   - Handles missing `.gitignore` files
   - Preserves existing file content and formatting

4. **Smart Duplicate Detection**:
   - Checks for existing entries before adding
   - Handles directory format variations (`dir/` vs `dir`)
   - Prevents unnecessary file modifications

5. **Visual Feedback**:
   - Neo-tree refresh after operations
   - User notifications for all actions
   - Clear error messages for edge cases

## Usage

1. **Adding to Gitignore**:
   - Open neo-tree (`<leader>e` or custom keymap)
   - Navigate to file/directory to ignore
   - Press `gi`
   - Confirm success notification

2. **Removing from Gitignore**:
   - Open neo-tree
   - Navigate to file/directory to unignore
   - Press `gI` (uppercase I)
   - Confirm success notification

## Error Handling

The implementation handles various edge cases:

- **Not in git repository**: Shows warning message
- **Missing .gitignore**: Creates new file when adding entries
- **File permission issues**: Shows error message
- **Duplicate entries**: Prevents duplicates and notifies user
- **Git root directory**: Prevents adding root directory to gitignore

## Testing

A test script is available at `/home/benjamin/.config/nvim/scripts/test_gitignore_commands.lua` that validates the core functionality without modifying actual git repositories.

## Benefits

- **Streamlined Workflow**: No need to manually edit `.gitignore`
- **Visual Integration**: Works directly in the file tree
- **Git-aware**: Automatically handles repository structure
- **Safe Operation**: Prevents buffer modification errors
- **User-friendly**: Clear notifications and error messages