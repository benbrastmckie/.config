#!/bin/bash
# Test to debug completion flag behavior

echo "=== Testing Completion Flag Behavior ==="
echo "Time: $(date)"

# Clean start
pkill -9 mbsync 2>/dev/null || true
rm -f /tmp/himalaya-sync.lock

echo ""
echo "1. Test sync with debug output"
echo "Run this in nvim:"
echo ":lua local native_sync = require('neotex.plugins.tools.himalaya.native_sync'); print('Before sync - completed:', native_sync.sync_completed); native_sync.enhanced_sync(); vim.defer_fn(function() print('After 5s - completed:', native_sync.sync_completed) end, 5000)"

echo ""
echo "This will show:"
echo "- Initial state of sync_completed flag"
echo "- State after 5 seconds"
echo "- Whether progress updates should stop"

echo ""
echo "Press ENTER when you've run the test..."
read -r

echo ""
echo "2. Check if any processes are still running:"
ps aux | grep mbsync | grep -v grep || echo "No mbsync processes"
ls -la /tmp/himalaya-sync.lock 2>/dev/null || echo "No lock file"

echo ""
echo "Analysis complete!"