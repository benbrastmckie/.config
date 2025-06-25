#!/bin/bash
# Comprehensive test for sync locking mechanisms

echo "=== Comprehensive Sync Locking Test ==="
echo "Time: $(date)"

# Function to check processes
check_processes() {
    local count=$(pgrep mbsync 2>/dev/null | wc -l)
    echo "Current mbsync processes: $count"
    if [ $count -gt 0 ]; then
        echo "PIDs: $(pgrep mbsync | tr '\n' ',' | sed 's/,$//')"
    fi
}

# Function to check lock file
check_lock() {
    if [ -f /tmp/himalaya-sync.lock ]; then
        echo "Lock file exists: $(cat /tmp/himalaya-sync.lock)"
    else
        echo "No lock file exists"
    fi
}

# Clean start
echo "=== SETUP ==="
pkill -9 mbsync 2>/dev/null || true
rm -f /tmp/himalaya-sync.lock
check_processes
check_lock

echo ""
echo "=== TEST 1: Start primary sync ==="
echo "Run this in nvim: <leader>ms"
echo "Press ENTER when sync is started..."
read -r

check_processes
check_lock

echo ""
echo "=== TEST 2: Try second sync (should be blocked) ==="
echo "Open another nvim instance and run: <leader>ms"
echo "You should see: 'Found X mbsync process(es): ... - cancel sync to clean up'"
echo "Press ENTER when you've tested this..."
read -r

echo ""
echo "=== TEST 3: Try utils.sync_mail (should be blocked) ==="
echo "In another nvim instance, run: :lua require('neotex.plugins.tools.himalaya.utils').sync_mail()"
echo "Should also be blocked. Press ENTER when tested..."
read -r

echo ""
echo "=== TEST 4: Cancel sync ==="
echo "Run this in any nvim: <leader>mk"
echo "Should kill all processes and clean locks. Press ENTER when done..."
read -r

check_processes
check_lock

echo ""
echo "=== TEST 5: Verify clean state ==="
echo "Try <leader>ms again - should now work since locks are cleared"
echo "Press ENTER when verified..."
read -r

echo ""
echo "=== Final cleanup ==="
pkill -9 mbsync 2>/dev/null || true
rm -f /tmp/himalaya-sync.lock
check_processes
check_lock

echo ""
echo "=== Test Summary ==="
echo "✅ If sync was blocked in TEST 2 & 3: Locking works"
echo "✅ If <leader>mk cleaned everything in TEST 4: Cancel works"  
echo "✅ If sync worked again in TEST 5: Recovery works"
echo ""
echo "If all tests passed, the multi-process issue is SOLVED!"