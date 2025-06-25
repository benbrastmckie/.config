#!/bin/bash
# Test centralized locking is working

echo "=== Testing Centralized Sync Locking ==="
echo "Time: $(date)"

# Clean slate
pkill -9 mbsync 2>/dev/null || true
rm -f /tmp/himalaya-sync.lock

echo ""
echo "1. Starting first sync (should succeed)"
timeout 30 nvim --headless -c "lua require('neotex.plugins.tools.himalaya.native_sync').enhanced_sync()" -c "sleep 2" 2>/dev/null &
FIRST_PID=$!
echo "Started nvim process: $FIRST_PID"

# Wait for sync to start
sleep 3

echo ""
echo "2. Current processes:"
ps aux | grep mbsync | grep -v grep || echo "No mbsync processes"
ls -la /tmp/himalaya-sync.lock 2>/dev/null || echo "No lock file"

echo ""
echo "3. Testing second sync (should be rejected)"
nvim --headless -c "lua print('Testing second sync...'); local result = require('neotex.plugins.tools.himalaya.native_sync').enhanced_sync(); print('Second sync result:', result)" -c "qa" 2>/dev/null

echo ""
echo "4. Testing utils.sync_mail (should also be rejected)"
nvim --headless -c "lua print('Testing utils.sync_mail...'); local result = require('neotex.plugins.tools.himalaya.utils').sync_mail(); print('utils.sync_mail result:', result)" -c "qa" 2>/dev/null

echo ""
echo "Cleaning up test..."
kill $FIRST_PID 2>/dev/null || true
pkill -9 mbsync 2>/dev/null || true
rm -f /tmp/himalaya-sync.lock

echo "Test complete!"