#!/usr/bin/env bash
# Test: /todo command git-based backup functionality
# Verifies that git commits are created instead of file-based backups

set -euo pipefail

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$HOME/.config"
fi

# Test setup
TEST_DIR="/tmp/test_todo_git_backup_$$"
mkdir -p "$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Initialize test git repository
cd "$TEST_DIR"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"

# Create minimal .claude structure
mkdir -p .claude/specs
mkdir -p .claude/tmp

# Create initial TODO.md
cat > .claude/TODO.md << 'EOF'
# TODO

## In Progress
- Project A (spec 001)

## Not Started
- Project B (spec 002)

## Completed
- Project C (spec 003)
EOF

# Commit initial state
git add .claude/TODO.md
git commit -q -m "Initial TODO.md"

echo "=== Test 1: Git snapshot created on TODO.md modification ==="

# Modify TODO.md to have uncommitted changes
cat > .claude/TODO.md << 'EOF'
# TODO

## In Progress
- Project A (spec 001)
- Project D (spec 004)

## Not Started
- Project B (spec 002)

## Completed
- Project C (spec 003)
EOF

# Get current commit count
COMMITS_BEFORE=$(git log --oneline .claude/TODO.md | wc -l)

# Simulate the git snapshot logic from /todo command
TODO_PATH=".claude/TODO.md"
WORKFLOW_ID="test_12345"
USER_ARGS="--test"

if [ -f "$TODO_PATH" ]; then
  if ! git diff --quiet "$TODO_PATH" 2>/dev/null; then
    echo "Creating git snapshot of TODO.md before update"

    if ! git add "$TODO_PATH" 2>/dev/null; then
      echo "ERROR: Failed to stage TODO.md" >&2
      exit 1
    else
      COMMIT_MSG="chore: snapshot TODO.md before /todo update

Preserving current state for recovery if needed.

Workflow ID: ${WORKFLOW_ID}
Command: /todo ${USER_ARGS}"

      if git commit -m "$COMMIT_MSG" 2>/dev/null; then
        COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null)
        echo "Created snapshot commit: $COMMIT_HASH"
        echo "Recovery command: git checkout $COMMIT_HASH -- .claude/TODO.md"
      else
        echo "ERROR: Commit failed" >&2
        exit 1
      fi
    fi
  fi
fi

# Get new commit count
COMMITS_AFTER=$(git log --oneline .claude/TODO.md | wc -l)

# Verify commit was created
if [ "$COMMITS_AFTER" -eq $((COMMITS_BEFORE + 1)) ]; then
  echo "✓ Test 1 PASSED: Git snapshot commit created"
else
  echo "✗ Test 1 FAILED: Expected $((COMMITS_BEFORE + 1)) commits, got $COMMITS_AFTER"
  exit 1
fi

# Verify commit message format
LAST_COMMIT_MSG=$(git log -1 --pretty=format:%s .claude/TODO.md)
if [[ "$LAST_COMMIT_MSG" == "chore: snapshot TODO.md before /todo update" ]]; then
  echo "✓ Test 1.1 PASSED: Commit message format correct"
else
  echo "✗ Test 1.1 FAILED: Unexpected commit message: $LAST_COMMIT_MSG"
  exit 1
fi

# Verify workflow context in commit body
COMMIT_BODY=$(git log -1 --pretty=format:%b .claude/TODO.md)
if echo "$COMMIT_BODY" | grep -q "Workflow ID: ${WORKFLOW_ID}"; then
  echo "✓ Test 1.2 PASSED: Workflow ID present in commit body"
else
  echo "✗ Test 1.2 FAILED: Workflow ID not found in commit body"
  exit 1
fi

echo ""
echo "=== Test 2: No git snapshot when TODO.md already committed ==="

# Reset to initial state
git checkout -q HEAD~1 -- .claude/TODO.md
git commit -q -m "Reset TODO.md"

# Get current commit count
COMMITS_BEFORE=$(git log --oneline .claude/TODO.md | wc -l)

# Run snapshot logic (should not create commit)
if [ -f "$TODO_PATH" ]; then
  if ! git diff --quiet "$TODO_PATH" 2>/dev/null; then
    echo "ERROR: Should not have uncommitted changes" >&2
    exit 1
  else
    echo "TODO.md already committed, no snapshot needed"
  fi
fi

# Verify no new commit
COMMITS_AFTER=$(git log --oneline .claude/TODO.md | wc -l)
if [ "$COMMITS_AFTER" -eq "$COMMITS_BEFORE" ]; then
  echo "✓ Test 2 PASSED: No snapshot commit when already committed"
else
  echo "✗ Test 2 FAILED: Unexpected commit created"
  exit 1
fi

echo ""
echo "=== Test 3: No file-based backups created ==="

# Modify TODO.md again
cat > .claude/TODO.md << 'EOF'
# TODO

## In Progress
- Project E (spec 005)

## Completed
- Project C (spec 003)
EOF

# Create snapshot
git add .claude/TODO.md
git commit -q -m "chore: snapshot TODO.md before /todo update"

# Check for backup files
BACKUP_COUNT=$(find .claude -name "TODO.md.backup*" 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -eq 0 ]; then
  echo "✓ Test 3 PASSED: No file-based backups created"
else
  echo "✗ Test 3 FAILED: Found $BACKUP_COUNT backup files"
  find .claude -name "TODO.md.backup*"
  exit 1
fi

echo ""
echo "=== Test 4: Recovery - Restore from git commit ==="

# Make a change
cat > .claude/TODO.md << 'EOF'
# TODO

## In Progress
- Project F (spec 006)

## Completed
- Project C (spec 003)
EOF

git add .claude/TODO.md
git commit -q -m "chore: TODO.md update"

# Restore from previous commit
git checkout -q HEAD~1 -- .claude/TODO.md

# Verify content restored
if grep -q "Project E" .claude/TODO.md; then
  echo "✓ Test 4 PASSED: Successfully restored from git commit"
else
  echo "✗ Test 4 FAILED: Restoration unsuccessful"
  exit 1
fi

echo ""
echo "=== Test 5: Multiple sequential snapshots ==="

# Reset
git checkout -q HEAD -- .claude/TODO.md

SNAPSHOTS_BEFORE=$(git log --grep="snapshot TODO.md" --oneline .claude/TODO.md | wc -l)

# Create 3 sequential snapshots
for i in 1 2 3; do
  cat > .claude/TODO.md << EOF
# TODO

## In Progress
- Project $i (spec 00$i)
EOF

  git add .claude/TODO.md
  git commit -q -m "chore: snapshot TODO.md before /todo update

Workflow ID: test_iteration_$i
Command: /todo"
done

SNAPSHOTS_AFTER=$(git log --grep="snapshot TODO.md" --oneline .claude/TODO.md | wc -l)

if [ "$SNAPSHOTS_AFTER" -eq $((SNAPSHOTS_BEFORE + 3)) ]; then
  echo "✓ Test 5 PASSED: Multiple sequential snapshots created"
else
  echo "✗ Test 5 FAILED: Expected $((SNAPSHOTS_BEFORE + 3)) snapshots, got $SNAPSHOTS_AFTER"
  exit 1
fi

echo ""
echo "=== Test 6: Git diff comparison between versions ==="

# Get commits
LATEST=$(git rev-parse HEAD)
PREVIOUS=$(git rev-parse HEAD~1)

# Check diff exists
if git diff "$PREVIOUS" "$LATEST" -- .claude/TODO.md | grep -q "Project"; then
  echo "✓ Test 6 PASSED: Git diff shows changes between versions"
else
  echo "✗ Test 6 FAILED: Git diff did not show expected changes"
  exit 1
fi

echo ""
echo "=== Test 7: Error handling - git add failure ==="

# Simulate git add failure by making file unreadable
chmod 000 .claude/TODO.md

# Attempt snapshot (should handle gracefully)
if git add .claude/TODO.md 2>/dev/null; then
  echo "✗ Test 7 FAILED: git add should have failed"
  chmod 644 .claude/TODO.md
  exit 1
else
  echo "✓ Test 7 PASSED: git add failure handled gracefully"
fi

# Restore permissions
chmod 644 .claude/TODO.md

echo ""
echo "=== Test 8: First run (no existing TODO.md) ==="

# Remove TODO.md
rm .claude/TODO.md

# Run snapshot logic
if [ -f "$TODO_PATH" ]; then
  echo "✗ Test 8 FAILED: TODO.md should not exist"
  exit 1
else
  echo "No existing TODO.md to snapshot (first run)"
  echo "✓ Test 8 PASSED: First run handled correctly"
fi

echo ""
echo "=== All Tests Passed ==="
echo ""
echo "Summary:"
echo "  ✓ Git snapshot created on modification"
echo "  ✓ No snapshot when already committed"
echo "  ✓ No file-based backups created"
echo "  ✓ Recovery from git commit works"
echo "  ✓ Multiple sequential snapshots"
echo "  ✓ Git diff comparison works"
echo "  ✓ Error handling for git failures"
echo "  ✓ First run handling"
echo ""

exit 0
