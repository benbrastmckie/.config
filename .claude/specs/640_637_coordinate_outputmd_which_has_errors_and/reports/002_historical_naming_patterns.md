# Historical Plan Naming Patterns Research Report

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Historical plan naming patterns in .claude/specs
- **Report Type**: codebase analysis

## Executive Summary

The spec directory naming convention underwent a significant change on November 5, 2025 (commit ed69cacc). Before this change, spec directories used a literal character-by-character conversion of the entire workflow description including paths, resulting in extremely long, non-descriptive names with embedded paths. After the change, spec directories use an intelligent algorithm that extracts meaningful path components, removes stopwords, and produces concise, human-readable names. The old pattern produced names like `586_research_the_homebenjaminconfignvimdocs_directory_` while the new pattern produces names like `nvim_docs_directory`.

## Findings

### Old Naming Pattern (Before November 5, 2025)

**Algorithm**: `sanitize_topic_name()` in `.claude/lib/topic-utils.sh` (pre-ed69cacc)

**Characteristics**:
1. **Literal Conversion**: Converted entire workflow description character-by-character
2. **No Path Extraction**: Embedded full paths directly into topic name
3. **No Stopword Filtering**: Included common words like "the", "to", "for", "in"
4. **No Semantic Understanding**: Treated workflow description as plain text
5. **Simple Rules**:
   - Convert to lowercase
   - Replace spaces with underscores
   - Remove special characters (keep alphanumeric and underscores)
   - Remove leading/trailing underscores
   - Truncate to 50 characters (hard cutoff)

**Example Old Pattern** (from `.claude/lib/topic-utils.sh:33-46` at ed69cacc^):
```bash
sanitize_topic_name() {
  local raw_name="$1"

  echo "$raw_name" | \
    tr '[:upper:]' '[:lower:]' | \
    tr ' ' '_' | \
    sed 's/[^a-z0-9_]//g' | \
    sed 's/^_*//;s/_*$//' | \
    cut -c1-50
}
```

**Real Examples from Codebase**:
- `586_research_the_homebenjaminconfignvimdocs_directory_` (spec 586)
- `587_research_the_homebenjaminconfignvimdocs_directory_` (spec 587)
- `591_research_the_homebenjaminconfignvimdocs_directory_` (spec 591)
- `594_research_the_bash_command_failures_in_homebenjamin` (spec 594)
- `509_use_homebenjaminconfigclaudespecs508_research_best` (spec 509)
- `583_research_the_plan_homebenjaminconfigclaudespecs580` (spec 583)
- `584_in_the_documentation_for_nvim_in_homebenjaminconfi` (spec 584)

**Problems Identified**:
1. **Embedded Full Paths**: Names like `homebenjaminconfignvimdocs` are not descriptive
2. **Stopword Pollution**: Words like "the", "to", "for", "research" add no value
3. **Truncation Issues**: 50-char hard cutoff often cut mid-word
4. **Poor Readability**: Very difficult to understand what the spec is about
5. **Redundancy**: Multiple specs with nearly identical names (586, 587, 591)

### New Naming Pattern (After November 5, 2025)

**Algorithm**: Enhanced `sanitize_topic_name()` implemented in Spec 594, Phase 4

**Commit**: ed69cacc0d60bafd31744b6929047bc0c4eb29f3
**Date**: Wed Nov 5 00:17:24 2025 -0800
**Message**: "feat(594): complete Phase 4 - Implement Improved Topic Naming Algorithm"

**Characteristics**:
1. **Path Component Extraction**: Extracts last 2-3 meaningful path segments
2. **Stopword Filtering**: Removes 40+ common English words
3. **Filler Removal**: Removes research context words ("carefully", "research", "analyze")
4. **Keyword Prioritization**: Preserves action verbs and technical terms
5. **Intelligent Truncation**: Preserves whole words up to 50 characters
6. **Path Cleaning**: Filters out common meaningless segments (home, user, config)

**Example New Pattern** (from `.claude/lib/topic-utils.sh:78-141` at ed69cacc):
```bash
sanitize_topic_name() {
  local raw_name="$1"

  # 40+ common English stopwords to filter
  local stopwords="the a an and or but to for of in on at by with from as is are was were be been being have has had do does did will would should could may might must can about through during before after above below between among into onto upon"

  # Research context words to remove
  local filler_prefixes="carefully research|research the|research|analyze the|investigate the|explore the|examine the"

  # Extract last 2-3 meaningful path segments
  # Remove full paths and trailing generic words
  # Remove filler prefixes and stopwords
  # Combine path components with cleaned description
  # Intelligent truncation preserving whole words
}
```

**Algorithm Steps** (from `.claude/lib/topic-utils.sh:64-73`):
1. Extract path components (last 2-3 meaningful segments)
2. Remove full paths from description
3. Convert to lowercase
4. Remove filler prefixes ("carefully research", "analyze", etc.)
5. Remove stopwords (preserving action verbs and technical terms)
6. Combine path components with cleaned description
7. Clean up formatting (multiple underscores, leading/trailing)
8. Intelligent truncation (preserve whole words, max 50 chars)

**Test Results from Implementation** (commit message):
- "Research the /home/user/nvim/docs directory/" → "nvim_docs_directory"
- "research authentication patterns to create implementation plan" → "authentication_patterns_create_implementation_plan"
- "fix the token refresh bug" → "fix_token_refresh_bug"

**Real Examples from Codebase** (post-change):
- `595_nvim_docs_directory_in_order_to_plan_and` (spec 595 - partial improvement)
- `596_refactor_coordinate_command_to_reduce_bash` (spec 596 - descriptive)
- `597_fix_coordinate_variable_persistence` (spec 597 - concise)
- `598_fix_coordinate_three_critical_issues` (spec 598 - clear)
- `599_coordinate_refactor_research` (spec 599 - concise)
- `600_598_fix_coordinate_three_critical_issues_plans` (spec 600 - reference-based)

### Format Structure

Both old and new patterns follow the same directory structure:

**Format**: `{NNN}_{topic_name}/`
- **NNN**: Three-digit sequential number (001, 002, 003...)
- **topic_name**: Sanitized workflow description (varies by algorithm)

**Directory Location**: `.claude/specs/`

**Numbering**: Sequential, assigned by `get_next_topic_number()` function

**Example**: `594_research_the_bash_command_failures_in_homebenjamin/` (old) vs `594_bash_command_failures/` (hypothetical new)

### Transition Period

**Key Observation**: The naming change occurred mid-sequence (spec 594), so older specs retain old naming while newer specs use new naming.

**Evidence**:
- Specs 580-594: Old pattern with embedded paths
- Spec 594: Implementation of new algorithm (but directory created before change)
- Specs 595+: Mix of patterns during transition
- Specs 596-599: Cleaner new pattern evident

**No Retroactive Renaming**: Existing spec directories were not renamed, creating a historical record of the naming evolution.

### Documentation

**Primary Documentation**: `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md`

**Topic Naming Best Practices** (from directory-protocols.md:985-996):
```markdown
### Topic Naming

**Good**:
- `042_authentication` - clear, specific
- `001_cleanup` - describes area
- `015_user_profile` - focused feature

**Avoid**:
- `042_misc` - too vague
- `001_stuff` - unclear
- `099_temp` - temporary names
```

**Current Standard** (from directory-protocols.md:54-58):
- **Format**: `NNN_topic_name/` (e.g., `042_authentication/`, `001_cleanup/`)
- **Numbering**: Three-digit sequential numbers (001, 002, 003...)
- **Naming**: Snake_case describing the feature or area
- **Scope**: Contains all artifacts for a single feature or related area

## Recommendations

### For Understanding Historical Specs

1. **Old Pattern Recognition**: Specs 001-594 use literal conversion with embedded paths
2. **Path Extraction**: To understand old spec names, extract path segments manually (e.g., `homebenjaminconfignvimdocs` = `~/.config/nvim/docs`)
3. **Stopword Removal**: Mentally filter words like "the", "to", "for", "research" to find core meaning
4. **Numbering Reference**: Use spec number as primary identifier when old names are unclear

### For Creating New Specs

1. **Use New Algorithm**: Current `sanitize_topic_name()` produces concise, descriptive names
2. **Verify Output**: Check that generated name is human-readable and suggestive
3. **Manual Override**: If automatic naming fails, manually specify concise name
4. **Consistency**: Follow current best practices (clear, specific, focused)

### For Documentation

1. **Document Both Patterns**: Acknowledge historical pattern in directory protocols
2. **Migration Guide**: Create guide for understanding old spec names
3. **No Retroactive Changes**: Do not rename existing specs (breaks git history)
4. **Example Library**: Maintain examples of both old and new patterns for reference

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/lib/topic-utils.sh` (lines 1-141) - Current implementation
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 54-58, 985-996) - Documentation
- `/home/benjamin/.config/.claude/specs/594_research_the_bash_command_failures_in_homebenjamin/plans/001_implementation.md` (lines 1-100) - Implementation plan
- Git commit ed69cacc0d60bafd31744b6929047bc0c4eb29f3 - Algorithm change

### Spec Directory Examples Examined

**Old Pattern (Pre-Nov 5)**:
- `509_use_homebenjaminconfigclaudespecs508_research_best`
- `583_research_the_plan_homebenjaminconfigclaudespecs580`
- `584_in_the_documentation_for_nvim_in_homebenjaminconfi`
- `586_research_the_homebenjaminconfignvimdocs_directory_`
- `587_research_the_homebenjaminconfignvimdocs_directory_`
- `591_research_the_homebbenjaminconfignvimdocs_directory_`
- `594_research_the_bash_command_failures_in_homebenjamin`

**New Pattern (Post-Nov 5)**:
- `595_nvim_docs_directory_in_order_to_plan_and`
- `596_refactor_coordinate_command_to_reduce_bash`
- `597_fix_coordinate_variable_persistence`
- `598_fix_coordinate_three_critical_issues`
- `599_coordinate_refactor_research`
- `600_598_fix_coordinate_three_critical_issues_plans`

### Git History References

- Commit ed69cacc: Topic naming algorithm implementation (Nov 5, 2025)
- Commit c8b16fc0: Phase 5 - Comprehensive test suite for new algorithm
- Spec 594: "Fix Bash Command Failures and Topic Naming Implementation Plan"

### Related Documentation

- `.claude/docs/concepts/directory-protocols.md` - Complete directory structure documentation
- `.claude/lib/topic-utils.sh` - Topic management utilities implementation
- `.claude/specs/594_research_the_bash_command_failures_in_homebenjamin/reports/002_topic_directory_naming.md` - Original naming analysis
