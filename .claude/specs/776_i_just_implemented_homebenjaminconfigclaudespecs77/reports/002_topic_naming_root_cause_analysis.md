# Topic Naming Root Cause Analysis

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Root cause analysis of malformed topic directory names
- **Report Type**: bug investigation

## Executive Summary

The `sanitize_topic_name` function in `.claude/lib/topic-utils.sh` produces malformed directory names when workflow descriptions contain paths to `.claude/specs/` directories. The root cause is inadequate path component filtering that fails to handle self-referential descriptions and the `.claude` prefix.

## Problem Statement

Directory 776 was created with the name:
```
776_i_just_implemented_homebenjaminconfigclaudespecs77
```

Expected behavior would be a semantic name like:
```
776_topic_naming_investigation
```

## Root Cause Analysis

### Issue Location

**File**: `.claude/lib/topic-utils.sh`
**Function**: `sanitize_topic_name()` (lines 142-205)
**Specific Problem**: Step 1 - Path extraction (lines 151-158)

### Technical Details

The function uses this regex to extract path components:

```bash
path_components=$(echo "$raw_name" | grep -oE '/[^/]+/[^/]+/?[^/]*/?$' | ...)
```

When processing a description like:
```
"I just implemented /home/benjamin/.config/.claude/specs/774_for_the_research..."
```

**Step 1** extracts the last 2-3 path segments:
```
.claude_specs_774_for_the_research_debug_plan
```

**Step 1 filter** (line 157) attempts to remove common prefixes:
```bash
sed 's/home_[^_]*_//; s/usr_[^_]*_//; s/opt_[^_]*_//; s/config_//'
```

This filter **fails to remove**:
- `.claude_` prefix (dot not handled)
- `specs_` directory
- `774_for_the_research_debug_plan` (the existing topic name)

**Result**: The entire path tail gets concatenated with description words, producing:
```
claude_specs_774_for_the_research_debug_plan_just_implemented
```

After truncation to 50 characters:
```
claude_specs_774_for_the_research_debug_plan_just
```

### Pattern of Affected Directories

| Directory | Name | Issue |
|-----------|------|-------|
| 770 | `i_see_that_in_the_project_directories_in_claude_sp` | Descriptive words, no path extraction benefit |
| 771 | `research_option_1_in_home_benjamin_config_claude_s` | Path components leaked into name |
| 775 | `use_homebenjaminconfigclaudespecs774_for_the_resea` | Self-referential path to spec 774 |
| 776 | `i_just_implemented_homebenjaminconfigclaudespecs77` | Self-referential path to spec 774/775 |

## Identified Issues

### Issue 1: No Self-Reference Detection
The function doesn't detect when descriptions reference existing `.claude/specs/NNN_*` directories. These self-referential paths should be stripped entirely.

### Issue 2: Incomplete Prefix Filtering
The sed filter on line 157 doesn't handle:
- Dot-prefixed directories (`.claude`)
- The `specs` directory
- Numbered topic directories (`NNN_*`)

### Issue 3: Greedy Path Extraction
The regex captures too much of the path tail. For deep paths like `/home/benjamin/.config/.claude/specs/774_topic_name`, it captures meaningless infrastructure segments.

## Recommended Fixes

### Option A: Add Self-Reference Stripping (Minimal Change)

Add detection for `.claude/specs/NNN_*` patterns and strip them entirely:

```bash
# Before path extraction, remove self-referential spec paths
raw_name=$(echo "$raw_name" | sed 's|/[^ ]*/.claude/specs/[0-9][0-9][0-9]_[^ ]*||g')
```

### Option B: Improve Prefix Filtering (Targeted Fix)

Extend the filter to handle `.claude` and `specs`:

```bash
path_components=$(echo "$path_components" | sed '
  s/home_[^_]*_//
  s/usr_[^_]*_//
  s/opt_[^_]*_//
  s/config_//
  s/^\.//
  s/^claude_//
  s/^specs_//
  s/^[0-9][0-9][0-9]_//
')
```

### Option C: Redesign Path Extraction (Comprehensive Fix)

Only extract the final meaningful segment, not the full path tail:

```bash
# Extract only the last path segment (filename/dirname)
if echo "$raw_name" | grep -qE '/[a-zA-Z0-9_-]+/?$'; then
  path_components=$(echo "$raw_name" | grep -oE '[^/]+/?$' | sed 's|/$||')
fi
```

## Testing Recommendations

After implementing fixes, test with these inputs:

```bash
# Self-referential descriptions
sanitize_topic_name "Research /home/benjamin/.config/.claude/specs/774_topic/reports"
# Expected: something like "research_reports" or "topic_reports"

# Deep paths
sanitize_topic_name "Investigate the /home/user/.config/.claude/lib/utils.sh file"
# Expected: "investigate_utils" or "utils_investigation"

# Normal descriptions (regression test)
sanitize_topic_name "Add authentication to the API"
# Expected: "add_authentication_api"
```

## Impact Assessment

- **Severity**: Low (cosmetic issue, doesn't affect functionality)
- **Frequency**: Occurs when users reference existing specs in workflow descriptions
- **User Impact**: Confusing directory names make navigation harder

## Conclusion

The `sanitize_topic_name` function needs enhancement to handle self-referential workflow descriptions that mention existing `.claude/specs/` directories. Option A (self-reference stripping) provides the quickest fix with minimal risk of regression. Option C provides the most robust long-term solution.

## References

- Source file: `.claude/lib/topic-utils.sh:142-205`
- Affected directories: 770, 771, 775, 776
- Related documentation: `.claude/docs/guides/enhanced-topic-generation-guide.md`
