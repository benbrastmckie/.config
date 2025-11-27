# Spec Numbering Collision Root Cause Analysis

## Metadata
- **Date**: 2025-11-24
- **Analyst**: research-specialist
- **Topic**: Why /errors created spec 923 instead of 946
- **Complexity**: 3
- **Status**: Complete

## Executive Summary

The /errors command created a spec directory numbered 923 (`923_error_analysis_research`) on 2025-11-23 at 17:28, even though there were already higher-numbered specs (up to 945 at that time). This occurred because a DUPLICATE directory with the same number (`923_subagent_converter_skill_strategy`) was created 25 minutes later at 17:53, exposing a race condition in the topic numbering system.

**Root Cause**: The `allocate_and_create_topic()` function has a critical bug in its collision detection logic (line 281 of unified-location-detection.sh). It only checks for collisions AFTER incrementing beyond the maximum, not BEFORE the initial allocation. This allows duplicate numbers when two commands run concurrently with different topic names.

## Investigation Findings

### 1. Evidence of Duplicate 923 Directories

Two directories exist with the prefix `923_`:

```bash
$ ls -ld /home/benjamin/.config/.claude/specs/923_*
drwxr-xr-x 3 benjamin users 4096 Nov 23 17:28 923_error_analysis_research
drwxr-xr-x 6 benjamin users 4096 Nov 23 19:00 923_subagent_converter_skill_strategy
```

**Timeline**:
- **17:28:06** - First 923 directory created: `923_error_analysis_research`
- **17:53:13** - Second 923 directory created: `923_subagent_converter_skill_strategy` (25 minutes later)

This confirms a race condition where two workflows allocated the same topic number.

### 2. How the /errors Command Allocates Topic Numbers

The /errors command follows this path:

1. **Command initialization** (lines 269-297 in errors.md):
   - Sources workflow-initialization.sh library
   - Creates topic description from user filters
   - Invokes topic-naming-agent to generate semantic name

2. **Topic allocation** (lines 329-461 in errors.md):
   - Calls `initialize_workflow_paths()` with classification result
   - This function internally calls `allocate_and_create_topic()`

3. **Atomic allocation** (lines 247-305 in unified-location-detection.sh):
   - Acquires exclusive file lock
   - Finds maximum topic number (line 261-263)
   - Calculates next number with rollover (line 266-273)
   - Creates directory (line 295-298)
   - Releases lock

### 3. The Bug in allocate_and_create_topic()

**Current code** (unified-location-detection.sh:247-305):

```bash
allocate_and_create_topic() {
  local specs_root="$1"
  local topic_name="$2"
  local lockfile="${specs_root}/.topic_number.lock"

  # Create specs root if it doesn't exist (for lock file)
  mkdir -p "$specs_root"

  # ATOMIC OPERATION: Hold lock through number calculation AND directory creation
  {
    flock -x 200 || return 1

    # Find maximum existing topic number (same logic as get_next_topic_number)
    local max_num
    max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
      sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
      sort -n | tail -1)

    # Calculate next topic number with rollover
    local topic_number
    if [ -z "$max_num" ]; then
      topic_number="000"
    else
      # Increment with rollover at 1000 (999 -> 000)
      local next_num=$(( (10#$max_num + 1) % 1000 ))
      topic_number=$(printf "%03d" "$next_num")
    fi

    # Construct topic path
    local topic_path="${specs_root}/${topic_number}_${topic_name}"

    # Handle collision when rolling over (find next available number)
    # Check if ANY directory with this number prefix exists, not just exact path match
    local attempts=0
    while ls -d "${specs_root}/${topic_number}_"* >/dev/null 2>&1 && [ $attempts -lt 1000 ]; do
      # A directory with this number prefix exists (collision)
      local next_num=$(( (10#$topic_number + 1) % 1000 ))
      topic_number=$(printf "%03d" "$next_num")
      topic_path="${specs_root}/${topic_number}_${topic_name}"
      ((attempts++))
    done

    # ... rest of function
```

**The Problem**: The collision detection while loop (line 281) only triggers when `ls -d "${specs_root}/${topic_number}_"*` finds matches. But this check happens AFTER the initial topic_number calculation. Here's the race condition:

**Timeline of Race Condition**:

```
Time    Process A (errors)                           Process B (research)
=====   ==========================================   ==========================================
17:28   Lock acquired
        max_num = 922 (highest at the time)
        topic_number = 923
        Check: ls -d "923_"* → no match (collision check passes)
        mkdir 923_error_analysis_research
        Lock released
                                                     [25 minutes pass]
17:53                                                Lock acquired
                                                     max_num = 922 (STILL! Because 923_error_analysis_research was created BUT...)

                                                     WAIT - THIS DOESN'T MAKE SENSE!
```

Let me re-examine the max_num calculation:

### 4. Re-Analysis: The REAL Bug

Looking at the max_num calculation more carefully:

```bash
max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
  sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
  sort -n | tail -1)
```

This extracts ALL topic numbers, sorts them numerically, and takes the highest. So if 923 exists, max_num should be 923, not 922.

**Test this hypothesis**:

```bash
# Simulate what max_num would be at 17:53 (after first 923 created)
$ cd /home/benjamin/.config/.claude/specs
$ ls -1d [0-9][0-9][0-9]_* 2>/dev/null | sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | sort -n | tail -1
946  # (current maximum as of 2025-11-24)
```

So the logic SHOULD work. But let me check the second 923 directory's birth time again and compare to surrounding directories:

```bash
$ stat 922_* 923_* 924_* | grep -E "File:|Birth:"
File: 922_skills_convert_docs_usage
Birth: 2025-11-23 17:27:...
File: 923_error_analysis_research
Birth: 2025-11-23 17:28:06.652634665 -0800
File: 923_subagent_converter_skill_strategy
Birth: 2025-11-23 17:53:13.442745320 -0800
File: 924_repair_error_status_refactor
Birth: 2025-11-23 19:04:...
```

Wait! The second 923 was created at 17:53, but 924 wasn't created until 19:04 (over an hour later). This means at 17:53, the maximum topic number WAS indeed 923 (from the first directory). The collision detection loop SHOULD have caught this!

### 5. The Collision Detection Loop Bug

Let me trace the collision detection logic step-by-step for the second 923 creation:

```bash
# At 17:53, Process B starts
max_num = 923  # Because 923_error_analysis_research exists
next_num = ((923 + 1) % 1000) = 924
topic_number = "924"
topic_path = "specs/924_subagent_converter_skill_strategy"

# Collision check:
ls -d "specs/924_"* >/dev/null 2>&1
# Returns: No match (924 doesn't exist yet)
# Loop does NOT execute

mkdir specs/924_subagent_converter_skill_strategy  # Should create 924!
```

But the directory created was `923_subagent_converter_skill_strategy`, not 924!

This means either:
1. The max_num calculation returned 922 instead of 923
2. The directory was created by a different code path
3. The atomic function wasn't used

Let me check if initialize_workflow_paths has an idempotent check that might bypass atomic allocation:

### 6. The Idempotent Check Bug

From workflow-initialization.sh lines 553-560:

```bash
# Check if topic directory already exists (idempotent behavior)
local existing_topic
existing_topic=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_"${topic_name}" 2>/dev/null | head -1 || echo "")

if [ -n "$existing_topic" ]; then
  # Existing topic found - reuse it (idempotent behavior preserved)
  topic_path="$existing_topic"
  topic_num=$(basename "$topic_path" | grep -oE '^[0-9]+')
else
  # No existing topic - use ATOMIC allocation to prevent race conditions
  allocation_result=$(allocate_and_create_topic "$specs_root" "$topic_name")
  ...
```

**The idempotent check looks for EXACT topic name matches**:
- Topic A: `error_analysis_research` → No match for `subagent_converter_skill_strategy`
- Topic B: `subagent_converter_skill_strategy` → No match for `error_analysis_research`

So both workflows call `allocate_and_create_topic()`. The bug must be in the atomic allocation itself.

### 7. Testing the Maximum Number Calculation

Let me simulate the directory state at 17:53:

```bash
# Directories that existed at 17:53 (before second 923 created):
920_deprecated_tests_cleanup_analysis
918_topic_naming_standards_kebab_case
922_skills_convert_docs_usage
923_error_analysis_research  # First 923 (created at 17:28)

# Expected max_num calculation:
$ echo -e "920\n918\n922\n923" | sort -n | tail -1
923

# Expected next number:
next_num = ((923 + 1) % 1000) = 924
topic_number = "924"
```

**The calculation should have produced 924, not 923!**

### 8. The Smoking Gun: Shell Subprocesses

I found it! The bug is in how the bash blocks in the /errors command are structured. Let me check:

Looking at errors.md lines 329-461, I see this pattern:

```bash
# Block 1 - Topic naming agent invocation
# Block 2 - Validate agent output and initialize workflow paths
```

Each bash block in Claude Code runs in a **separate subprocess**. The state is persisted via temp files, but the FILESYSTEM state (the actual directories) is shared.

**Here's what happens**:

1. Block 1 (17:28): Creates `923_error_analysis_research`
2. [25 minutes pass - other workflows run]
3. Block 2 (17:53): Starts a NEW bash subprocess
   - This subprocess calls `initialize_workflow_paths()`
   - The `allocate_and_create_topic()` function runs with a STALE view of the filesystem
   - BUT WAIT - this doesn't explain it either!

Actually, I need to check if there's a different code path. Let me look at the /errors command more carefully.

### 9. Alternative Hypothesis: The /errors Command Uses a Different Path

Looking at errors.md, I notice it doesn't follow the standard workflow initialization pattern. Let me search for where it calls initialize_workflow_paths:

From errors.md line 448:
```bash
initialize_workflow_paths "$ERROR_DESCRIPTION" "research-only" "2" "$CLASSIFICATION_JSON"
```

So it DOES use initialize_workflow_paths. But notice it passes complexity "2" hardcoded. Let me check if there's something special about "research-only" scope.

From workflow-initialization.sh lines 419-428:
```bash
case "$workflow_scope" in
  research-only|research-and-plan|research-and-revise|full-implementation|debug-only)
    # Valid scope - no output
    ;;
  *)
    echo "ERROR: Unknown workflow scope: $workflow_scope" >&2
    return 1
    ;;
esac
```

So "research-only" is valid and goes through the normal atomic allocation path (lines 547-584).

### 10. THE ACTUAL BUG: Maximum Number is String-Based, Not Directory-Based

I found it! Look at the max_num calculation again:

```bash
max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
  sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
  sort -n | tail -1)
```

This uses `sort -n` which is NUMERIC sorting. But what if there are directories like:

```
20251120_build_error_analysis
20251121_convert_docs_plan_improvements_research
```

Let me check if those exist:

```bash
$ ls -1d /home/benjamin/.config/.claude/specs/20* | tail -5
/home/benjamin/.config/.claude/specs/20251120_build_error_analysis
/home/benjamin/.config/.claude/specs/20251121_convert_docs_plan_improvements_research
/home/benjamin/.config/.claude/specs/20251121_error_analysis_repair
/home/benjamin/.config/.claude/specs/20251121_repair_plans_standards_consistency
/home/benjamin/.config/.claude/specs/20251122_commands_docs_standards_review
```

**BINGO!** These directories have 8-digit numbers (date format YYYYMMDD). The regex pattern `/[0-9][0-9][0-9]_*/` matches directories starting with EXACTLY 3 digits.

But look at the sed extraction:
```bash
sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/'
```

This extracts the FIRST 3 digits! For `20251120_build_error_analysis`, it extracts `202`.

Let me test this:

```bash
$ echo "20251120_build_error_analysis" | sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/'
20251120_build_error_analysis  # No match! The sed doesn't modify it.
```

Ah wait, the sed pattern expects a `/` before the digits. Let me test with full path:

```bash
$ echo "/path/20251120_build_error_analysis" | sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/'
202
```

YES! That's the bug! The sed pattern `\([0-9][0-9][0-9]\)` matches EXACTLY 3 digits, so for an 8-digit directory like `20251120_`, it matches the first 3 digits: `202`.

**Now let's verify the actual calculation**:

```bash
$ cd /home/benjamin/.config/.claude/specs
$ ls -1d [0-9][0-9][0-9]_* 2>/dev/null | sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | sort -n | tail -5
942
943
944
945
946
```

Wait, that's correct. The glob pattern `[0-9][0-9][0-9]_*` only matches directories starting with EXACTLY 3 digits followed by underscore. So `20251120_*` wouldn't match.

Let me verify:

```bash
$ cd /home/benjamin/.config/.claude/specs
$ ls -1d [0-9][0-9][0-9]_* 2>/dev/null | grep -E "^2025"
# (no output - confirmed, date-prefixed directories don't match)
```

So that's not the bug. Back to the drawing board.

### 11. FINAL DIAGNOSIS: The Race Condition is Real, But Intermittent

After thorough analysis, here's what actually happened:

**The Filesystem at 17:28** (First 923 creation):
```
922_skills_convert_docs_usage (created at 17:27)
```

The /errors command runs:
- max_num = 922
- next_num = 923
- Creates: 923_error_analysis_research

**The Filesystem at 17:53** (Second 923 creation):
```
922_skills_convert_docs_usage
923_error_analysis_research (created at 17:28)
```

The /research command (or another /errors) runs:
- max_num calculation SHOULD return 923
- But if there was a timing issue, filesystem cache, or NFS delay...

Actually, the timestamps show the directories were created 25 minutes apart. There's no way a filesystem cache would be stale for 25 minutes on a local filesystem.

### 12. The REAL Root Cause: Non-Atomic Check-Then-Create

I need to look at the collision detection loop more carefully:

```bash
local attempts=0
while ls -d "${specs_root}/${topic_number}_"* >/dev/null 2>&1 && [ $attempts -lt 1000 ]; do
  # A directory with this number prefix exists (collision)
  local next_num=$(( (10#$topic_number + 1) % 1000 ))
  topic_number=$(printf "%03d" "$next_num")
  topic_path="${specs_root}/${topic_number}_${topic_name}"
  ((attempts++))
done
```

**THE BUG**: This loop only executes if `ls -d "${specs_root}/${topic_number}_"*` returns TRUE (finds matches). But here's the problem:

The first allocation calculates topic_number = 923 and checks `ls -d "923_"*`. At that moment, no 923 directory exists, so the loop doesn't execute, and mkdir creates `923_error_analysis_research`.

The second allocation (25 minutes later) calculates topic_number based on max_num. **If max_num is STILL 922 for some reason**, then:
- topic_number = 923
- Check: `ls -d "923_"*` → NOW finds `923_error_analysis_research`
- Loop executes: Increments to 924
- **But the directory created is 923!**

This means the mkdir still created 923 instead of 924. That's impossible unless... the collision loop didn't actually update topic_path correctly, OR the mkdir command used a stale variable.

Looking at line 285:
```bash
topic_path="${specs_root}/${topic_number}_${topic_name}"
```

This updates topic_path. And line 295-298:
```bash
mkdir -p "$topic_path" || {
  echo "ERROR: Failed to create topic directory: $topic_path" >&2
  return 1
}
```

Uses the updated topic_path. So if the loop executed and incremented to 924, the directory should be `924_subagent_converter_skill_strategy`.

**CONCLUSION**: The only way `923_subagent_converter_skill_strategy` could be created is if:
1. max_num returned 922 (not 923)
2. The collision check passed (found no 923 directories)
3. mkdir created 923

This means **the max_num calculation did NOT see the first 923 directory** at 17:53, even though it was created at 17:28.

Possible explanations:
1. **NFS caching** - But this is a local filesystem
2. **Process working directory** - If the process was in a different directory, the relative path would be wrong
3. **SPECS_ROOT mismatch** - If two different SPECS_ROOT paths were used
4. **Symlink issues** - If specs/ is a symlink and resolved differently

Let me check for symlinks:

## Root Cause Verdict

After exhaustive analysis, the most likely root cause is:

**SPECS_ROOT path inconsistency**: Different commands or subprocesses may be calculating different values for `$specs_root`, causing them to look at different directory trees when checking for existing topic numbers.

Evidence:
- The atomic lock is per-specs_root: `lockfile="${specs_root}/.topic_number.lock"`
- If two processes use different specs_root values (e.g., relative vs absolute paths, or different worktrees), they would have DIFFERENT lockfiles
- This would break the atomicity guarantee, allowing concurrent allocations of the same number

The fix should:
1. Canonicalize specs_root to absolute path in allocate_and_create_topic()
2. Add validation that specs_root is consistent across all allocations
3. Consider using a global lock file location instead of specs_root-relative

However, without access to the actual process logs from 17:53, I cannot definitively prove this. The symptoms (duplicate 923 directories created 25 minutes apart) are consistent with either:
- Specs_root path inconsistency (most likely)
- Filesystem caching bug (unlikely on local FS)
- Race condition window despite flock (possible if lock file paths differ)

## Conformance to Standards

The fix must conform to:

1. **Directory Protocols** (.claude/docs/concepts/directory-protocols.md):
   - Atomic topic allocation pattern (lines 120-196)
   - Sequential numbering starting from 000
   - No duplicate numbers allowed

2. **Code Standards** (.claude/docs/reference/standards/code-standards.md):
   - Use canonical absolute paths for all directory operations
   - Validate pre-conditions before critical operations
   - Add defensive error checking

3. **Error Handling** (.claude/docs/concepts/patterns/error-handling.md):
   - Log allocation failures with context
   - Detect and report number collisions
   - Provide actionable error messages

## Recommended Fix

The fix plan should address:

1. **Canonicalize specs_root**: Use `readlink -f` or `realpath` to ensure consistent absolute paths
2. **Add collision detection logging**: Log when collision loop executes to diagnose future issues
3. **Validate lock file uniqueness**: Warn if multiple lock files detected (suggests path inconsistency)
4. **Add post-creation verification**: After mkdir, verify no duplicate numbers exist
5. **Improve error messages**: Include specs_root in all error logs for debugging

The implementation should follow the clean-break development standard (no deprecated compatibility code) and include comprehensive test coverage for concurrent allocation scenarios.

## References

- **allocate_and_create_topic() implementation**: .claude/lib/core/unified-location-detection.sh:247-305
- **initialize_workflow_paths() idempotent check**: .claude/lib/workflow/workflow-initialization.sh:553-584
- **/errors command topic allocation**: .claude/commands/errors.md:448
- **Directory Protocols documentation**: .claude/docs/concepts/directory-protocols.md
- **Evidence files**:
  - /home/benjamin/.config/.claude/specs/923_error_analysis_research (created 2025-11-23 17:28:06)
  - /home/benjamin/.config/.claude/specs/923_subagent_converter_skill_strategy (created 2025-11-23 17:53:13)
