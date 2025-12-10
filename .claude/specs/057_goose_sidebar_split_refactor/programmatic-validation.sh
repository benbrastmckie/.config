#!/bin/bash
# Programmatic Validation Script for goose.nvim Split Configuration
# This script validates configuration and keybinding setup without requiring GUI interaction

set -euo pipefail

CONFIG_FILE="/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua"
KEYMAPS_FILE="/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua"

echo "=== goose.nvim Split Configuration Validation ==="
echo ""

# Test 1: Verify window_type = "split" in configuration
echo "[Test 1] Verifying split mode configuration..."
if grep -q 'window_type = "split"' "$CONFIG_FILE"; then
    echo "✓ PASS: window_type = \"split\" found in config"
else
    echo "✗ FAIL: window_type = \"split\" not found in config"
    exit 1
fi

# Test 2: Verify layout = "right" configuration
echo "[Test 2] Verifying right sidebar layout..."
if grep -q 'layout = "right"' "$CONFIG_FILE"; then
    echo "✓ PASS: layout = \"right\" found in config"
else
    echo "✗ FAIL: layout = \"right\" not found in config"
    exit 1
fi

# Test 3: Verify window_width = 0.35 configuration
echo "[Test 3] Verifying window width configuration..."
if grep -q 'window_width = 0.35' "$CONFIG_FILE"; then
    echo "✓ PASS: window_width = 0.35 found in config"
else
    echo "✗ FAIL: window_width = 0.35 not found in config"
    exit 1
fi

# Test 4: Verify input_height = 0.15 configuration
echo "[Test 4] Verifying input height configuration..."
if grep -q 'input_height = 0.15' "$CONFIG_FILE"; then
    echo "✓ PASS: input_height = 0.15 found in config"
else
    echo "✗ FAIL: input_height = 0.15 not found in config"
    exit 1
fi

# Test 5: Verify normal mode navigation keybindings
echo "[Test 5] Verifying normal mode navigation keybindings..."
for key in h j k l; do
    if grep -q "\"<C-$key>\", \"<C-w>$key\"" "$KEYMAPS_FILE"; then
        echo "✓ PASS: <C-$key> → <C-w>$key keybinding found"
    else
        echo "✗ FAIL: <C-$key> → <C-w>$key keybinding not found"
        exit 1
    fi
done

# Test 6: Verify terminal mode navigation keybindings
echo "[Test 6] Verifying terminal mode navigation keybindings..."
for key in h j k l; do
    if grep -q "\"<C-$key>\", \"<Cmd>wincmd $key<CR>\"" "$KEYMAPS_FILE"; then
        echo "✓ PASS: Terminal <C-$key> → wincmd $key keybinding found"
    else
        echo "✗ FAIL: Terminal <C-$key> → wincmd $key keybinding not found"
        exit 1
    fi
done

# Test 7: Verify backup file exists from Phase 1
echo "[Test 7] Verifying configuration backup..."
BACKUP_FILE=$(ls /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua.backup.* 2>/dev/null | head -n1)
if [ -n "$BACKUP_FILE" ]; then
    echo "✓ PASS: Configuration backup found: $BACKUP_FILE"
else
    echo "✗ WARN: No configuration backup found (expected from Phase 1)"
fi

# Test 8: Verify sidebar plugin configurations exist
echo "[Test 8] Verifying sidebar plugin installations..."
NEOTREE_FILE="/home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua"
TOGGLETERM_FILE="/home/benjamin/.config/nvim/lua/neotex/plugins/editor/toggleterm.lua"
LEAN_FILE="/home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua"

if [ -f "$NEOTREE_FILE" ]; then
    echo "✓ PASS: neo-tree configuration found"
else
    echo "✗ WARN: neo-tree configuration not found"
fi

if [ -f "$TOGGLETERM_FILE" ]; then
    echo "✓ PASS: toggleterm configuration found"
else
    echo "✗ WARN: toggleterm configuration not found"
fi

if [ -f "$LEAN_FILE" ]; then
    echo "✓ PASS: lean.nvim configuration found"
else
    echo "✗ WARN: lean.nvim configuration not found"
fi

# Test 9: Verify GitHub issue reference in documentation
echo "[Test 9] Verifying GitHub issue reference..."
if grep -q "https://github.com/azorng/goose.nvim/issues/82" "$CONFIG_FILE"; then
    echo "✓ PASS: GitHub issue #82 referenced in config comments"
else
    echo "✗ WARN: GitHub issue #82 not referenced in config comments"
fi

# Test 10: Verify split mode documentation comments
echo "[Test 10] Verifying split mode documentation..."
if grep -q "Integrates with <C-h/l> split navigation keybindings" "$CONFIG_FILE"; then
    echo "✓ PASS: Split navigation integration documented"
else
    echo "✗ WARN: Split navigation integration not documented"
fi

echo ""
echo "=== Validation Summary ==="
echo "Configuration file: $CONFIG_FILE"
echo "Keybindings file: $KEYMAPS_FILE"
echo ""
echo "All programmatic checks passed!"
echo ""
echo "MANUAL TESTING REQUIRED:"
echo "  - Phase 2: Split navigation with <C-h/j/k/l> keybindings"
echo "  - Phase 3: Terminal mode navigation testing"
echo "  - Phase 4: Multi-sidebar layout testing"
echo "  - Phase 5: Edge cases and configuration tuning"
echo ""
echo "See test-phase2-navigation.md for manual test procedures."
