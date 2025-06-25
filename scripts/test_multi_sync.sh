#!/bin/bash
# Test script to verify multiple process prevention

echo "=== Multi-Instance Sync Test ==="
echo "Current time: $(date)"

echo "Current mbsync processes:"
ps aux | grep mbsync | grep -v grep || echo "No processes running"

echo ""
echo "Testing process detection command:"
pgrep mbsync | wc -l

echo ""
echo "Current INBOX count: $(ls ~/Mail/Gmail/INBOX/cur 2>/dev/null | wc -l)"

echo ""
echo "Instructions:"
echo "1. Run 'pkill -9 mbsync' to clean up"
echo "2. Test <leader>ms in one nvim instance"
echo "3. Quickly test <leader>ms in another nvim instance"
echo "4. Should see 'Found X mbsync process(es)' warning in second instance"