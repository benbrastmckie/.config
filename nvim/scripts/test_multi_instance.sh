#!/bin/bash
# Test multi-instance sync prevention

echo "=== Multi-Instance Prevention Test ==="
echo "Time: $(date)"

# Clean slate first
pkill -9 mbsync 2>/dev/null || true
rm -f /tmp/himalaya-sync.lock

echo ""
echo "Step 1: Starting sync in background (simulates first nvim instance)"
timeout 60 mbsync gmail-inbox &
FIRST_PID=$!
sleep 2

echo "First process PID: $FIRST_PID"
echo "Current mbsync processes:"
ps aux | grep mbsync | grep -v grep

echo ""
echo "Step 2: Testing if second instance detects running process"
echo "Running: pgrep mbsync"
pgrep mbsync | wc -l

echo ""
echo "Expected behavior: Enhanced sync should detect running process and refuse to start"
echo "Test this with: <leader>ms in a second nvim instance"

echo ""
echo "Cleanup: kill $FIRST_PID in 60 seconds or use Ctrl+C"