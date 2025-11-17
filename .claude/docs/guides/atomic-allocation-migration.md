# Atomic Topic Allocation Migration Guide

Guide for migrating commands from unsafe count+increment patterns to atomic topic allocation using `allocate_and_create_topic()`.

## Overview

The `allocate_and_create_topic()` function provides atomic (race-condition-free) topic directory allocation. All commands that create topic directories should use this function instead of the unsafe count+increment pattern.

### Problem: Race Conditions

The old pattern counts directories, increments, then creates:

```bash
# UNSAFE: Race condition between count and mkdir
TOPIC_NUMBER=$(find "$SPECS_DIR" -maxdepth 1 -type d -name '[0-9]*_*' | wc -l)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
mkdir -p "${SPECS_DIR}/${TOPIC_NUMBER}_${TOPIC_SLUG}"
```

**Timeline showing collision**:
```
T0: Process A counts directories -> 25
T1: Process B counts directories -> 25 (A hasn't created dir yet)
T2: Process A calculates next -> 26
T3: Process B calculates next -> 26
T4: Process A creates 026_workflow_a
T5: Process B creates 026_workflow_b (COLLISION!)
```

**Result**: 40-60% collision rate under concurrent load (5+ parallel processes).

### Solution: Atomic Allocation

The `allocate_and_create_topic()` function holds an exclusive lock through BOTH number calculation AND directory creation:

```bash
# SAFE: Atomic operation under exclusive lock
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
TOPIC_NUMBER="${RESULT%|*}"
TOPIC_PATH="${RESULT#*|}"
```

**Timeline showing safe operation**:
```
T0: Process A [LOCK] count -> 25, calc -> 26
T1: Process B [WAITING FOR LOCK]
T2: Process A mkdir 026_a [UNLOCK]
T3: Process B [LOCK] count -> 26, calc -> 27
T4: Process B mkdir 027_b [UNLOCK]
```

**Result**: 0% collision rate under concurrent load.

---

## Migration Steps

### Step 1: Add Library Source

Add the unified-location-detection.sh library source after other library sources:

```bash
# Source libraries in dependency order
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-version-check.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"

# ADD: Unified location detection for atomic topic allocation
if ! source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh" 2>&1; then
  echo "ERROR: Failed to source unified-location-detection.sh"
  echo "DIAGNOSTIC: Check library exists at: ${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"
  exit 1
fi
```

### Step 2: Replace Directory Allocation Logic

**Before (Unsafe)**:
```bash
# Pre-calculate directories
TOPIC_SLUG=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}"

mkdir -p "$SPECS_DIR"
```

**After (Safe)**:
```bash
# Generate topic slug from description
TOPIC_SLUG=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)

# Allocate topic directory atomically (eliminates race conditions)
SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  echo "DIAGNOSTIC: Check permissions on $SPECS_ROOT"
  exit 1
fi

# Extract topic number and full path from result
TOPIC_NUMBER="${RESULT%|*}"
SPECS_DIR="${RESULT#*|}"
```

### Step 3: Update Subdirectory Creation

The topic root is already created by `allocate_and_create_topic()`, so you only need to create subdirectories:

```bash
# Create subdirectories (topic root already created atomically)
RESEARCH_DIR="${SPECS_DIR}/reports"
PLANS_DIR="${SPECS_DIR}/plans"

mkdir -p "$RESEARCH_DIR"
mkdir -p "$PLANS_DIR"
```

### Step 4: Test Migration

Run concurrent execution test to verify no collisions:

```bash
# Launch multiple instances simultaneously
for i in {1..10}; do
  (./your-command "test $i" &)
done
wait

# Verify 10 unique directories
ls -1 .claude/specs/ | tail -10

# Check for duplicates (should be empty)
ls -1 .claude/specs/ | cut -d_ -f1 | sort | uniq -d
```

---

## Complete Before/After Example

### Before: /research-plan (Unsafe)

```bash
# Pre-calculate research directory path
TOPIC_SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}"
RESEARCH_DIR="${SPECS_DIR}/reports"
PLANS_DIR="${SPECS_DIR}/plans"

# Create directories
mkdir -p "$RESEARCH_DIR"
mkdir -p "$PLANS_DIR"
```

### After: /research-plan (Safe)

```bash
# Generate topic slug from feature description
TOPIC_SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)

# Allocate topic directory atomically (eliminates race conditions)
SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  echo "DIAGNOSTIC: Check permissions on $SPECS_ROOT"
  echo "DETAILS: $RESULT"
  exit 1
fi

# Extract topic number and full path from result
TOPIC_NUMBER="${RESULT%|*}"
SPECS_DIR="${RESULT#*|}"

# Define subdirectories
RESEARCH_DIR="${SPECS_DIR}/reports"
PLANS_DIR="${SPECS_DIR}/plans"

# Create subdirectories (topic root already created atomically)
mkdir -p "$RESEARCH_DIR"
mkdir -p "$PLANS_DIR"
```

---

## Testing Checklist

After migration, verify:

- [ ] Command executes without errors
- [ ] Topic directory created with correct number format (NNN_name)
- [ ] Subdirectories created correctly (reports/, plans/, etc.)
- [ ] Concurrent execution produces unique directories (no collisions)
- [ ] No duplicate topic numbers
- [ ] Artifacts land in correct locations
- [ ] Lock file created in specs directory (.topic_number.lock)

### Concurrent Test Script

```bash
#!/bin/bash
# Test concurrent allocation for your command

COMMAND="your-command"
TEST_COUNT=10

echo "Testing concurrent $COMMAND execution..."

# Get current max topic number
MAX_BEFORE=$(ls -1 .claude/specs/ 2>/dev/null | cut -d_ -f1 | sort -n | tail -1)
echo "Max topic before: ${MAX_BEFORE:-000}"

# Launch concurrent instances
for i in $(seq 1 $TEST_COUNT); do
  (./$COMMAND "concurrent test $i" &)
done
wait

# Check results
MAX_AFTER=$(ls -1 .claude/specs/ | cut -d_ -f1 | sort -n | tail -1)
DUPLICATES=$(ls -1 .claude/specs/ | cut -d_ -f1 | sort | uniq -d)

echo "Max topic after: $MAX_AFTER"

if [ -n "$DUPLICATES" ]; then
  echo "FAIL: Duplicate numbers found: $DUPLICATES"
  exit 1
else
  echo "PASS: No collisions detected"
fi
```

---

## Common Pitfalls

### 1. Forgetting Error Handling

**Bad**:
```bash
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
TOPIC_NUMBER="${RESULT%|*}"
```

**Good**:
```bash
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  exit 1
fi
TOPIC_NUMBER="${RESULT%|*}"
```

### 2. Using Wrong Variable for Specs Root

**Bad**:
```bash
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")  # SPECS_DIR is the final path!
```

**Good**:
```bash
SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"  # Use the root directory
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
```

### 3. Not Extracting Both Number and Path

**Bad**:
```bash
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
TOPIC_DIR="$RESULT"  # Result is "number|path", not just path
```

**Good**:
```bash
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
TOPIC_NUMBER="${RESULT%|*}"
TOPIC_DIR="${RESULT#*|}"
```

### 4. Creating Topic Root After Allocation

**Bad**:
```bash
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
TOPIC_DIR="${RESULT#*|}"
mkdir -p "$TOPIC_DIR"  # Already exists! allocate_and_create_topic creates it
```

**Good**:
```bash
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
TOPIC_DIR="${RESULT#*|}"
# Topic directory already exists, only create subdirectories
mkdir -p "$TOPIC_DIR/reports"
```

---

## API Reference

### allocate_and_create_topic()

```bash
allocate_and_create_topic <specs_root> <topic_name>
```

**Arguments**:
- `specs_root`: Absolute path to specs directory (e.g., `/path/to/.claude/specs`)
- `topic_name`: Sanitized topic name (snake_case, max 50 chars)

**Returns**: Pipe-delimited string `"topic_number|topic_path"`
- `topic_number`: Three-digit number (e.g., "042")
- `topic_path`: Absolute path to created directory

**Exit Codes**:
- 0: Success (directory created)
- 1: Failure (lock acquisition or mkdir failed)

**Usage**:
```bash
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_NAME")
TOPIC_NUM="${RESULT%|*}"    # "042"
TOPIC_PATH="${RESULT#*|}"   # "/path/to/.claude/specs/042_topic_name"
```

**See**: [unified-location-detection.sh](../../lib/unified-location-detection.sh) for implementation details.

---

## Related Documentation

- [Directory Protocols](../concepts/directory-protocols.md#atomic-topic-allocation) - Atomic allocation standard
- [Library API Reference](../reference/library-api.md#allocate_and_create_topic) - Function documentation
- [Test Suite](../../tests/test_atomic_topic_allocation.sh) - Concurrent allocation tests

---

## Revision History

- **2025-11-17**: Initial creation during spec 753 implementation
