# Directory Naming Infrastructure Improvement Plan Research

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Infrastructure improvements for future spec directory naming
- **Report Type**: codebase analysis + standards enhancement
- **Complexity**: 3
- **Workflow Type**: research-and-plan

## Executive Summary

This research analyzes the directory naming infrastructure to implement clean-break improvements that prevent future naming violations without renaming existing directories. The analysis reveals that **sanitize_topic_name()** in topic-utils.sh requires four targeted enhancements to prevent the naming issues documented in spec 856's analysis (38% of directories affected). A clean-break approach focuses on improving the infrastructure—the sanitization function and command integration—rather than migrating legacy directories, aligning with the project's development philosophy of forward-looking improvements without legacy burden.

## Findings

### 1. Current Infrastructure Analysis

**Core Function**: `sanitize_topic_name()` in `.claude/lib/plan/topic-utils.sh` (lines 142-205)

**Current Algorithm** (8 steps):
1. Extract path components (last 2-3 meaningful segments)
2. Remove full paths from description
3. Convert to lowercase
4. Remove filler prefixes
5. Remove stopwords while preserving action verbs
6. Combine path components with cleaned description
7. Clean up formatting
8. Intelligent truncation (max 50 chars)

**Identified Weaknesses** (from spec 856 analysis):
- ❌ Preserves file basenames (`README.md` → `readmemd`, `.claude/plan-output.md` → `claude_planoutputmd`)
- ❌ No filtering for planning-specific meta-words (`create`, `plan`, `research`, `command`, `file`, `directory`)
- ❌ No detection of artifact references (`001_`, `reports_`, `summaries_`, `plans_`)
- ❌ No handling of topic number references in input (`816_`, `807_`)
- ❌ 50-char limit too generous for command-line usability (21 directories at 47-49 chars)

**Impact**: These weaknesses cause 78% of naming violations (21 of 27 problematic directories contain artifact references).

### 2. Commands Using Topic Naming Infrastructure

**Primary Commands** (direct topic allocation):
- `/plan` - Uses `sanitize_topic_name()` at line ~180-185 (block 2)
- `/research` - Uses `sanitize_topic_name()` at line ~180-185 (block 2)
- `/debug` - Uses topic allocation utilities

**Allocation Pattern** (from unified-location-detection.sh lines 12-33):
```bash
# Commands follow this standard pattern:
TOPIC_SLUG=$(sanitize_topic_name "$DESCRIPTION")
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
TOPIC_NUMBER="${RESULT%|*}"
TOPIC_PATH="${RESULT#*|}"
```

**Key Insight**: All commands funnel through `sanitize_topic_name()`, making it a **single point of improvement** for all future directory names.

### 3. Standards Documentation Review

**Current Standards** (directory-protocols.md lines 62-85):
- Format: `^[a-z0-9_]{1,50}$` (max 50 chars)
- Uses semantic slug generation
- Filters stopwords and preserves meaningful terms
- Examples show clean semantic names (`auth_patterns_implementation`, `jwt_token_expiration_bug`)

**Gap Analysis**:
- Standards document shows ideal examples but doesn't specify anti-patterns
- No explicit guidance on artifact reference prevention
- No documented naming best practices section
- Missing enforcement mechanism beyond the sanitization function

**Recommendation**: Add anti-patterns section to directory-protocols.md showing what to avoid (artifact refs, circular refs, excessive length).

### 4. Root Cause Analysis (from spec 856)

**Primary Root Causes**:

1. **User Input Patterns** (45% of violations)
   - Users reference specific files in descriptions: `/plan "Research .claude/commands/README.md..."`
   - Current sanitization preserves filename components
   - Example: `.claude/plan-output.md` → `claude_planoutputmd` (preserved in topic name)

2. **Stopword Filtering Limitations** (30% of violations)
   - Current 40-word stopword list lacks planning context terms
   - Missing: `create`, `update`, `research`, `plan`, `fix`, `implement`, `analyze`, `command`, `file`, `document`, `directory`
   - Impact: Verbose names with meta-words (avg 42 chars vs target 30-35)

3. **Insufficient Artifact Detection** (27% of violations)
   - No detection of artifact numbering (`001_`, `002_`)
   - No detection of artifact subdirectories (`reports_`, `plans_`, `summaries_`)
   - No stripping of file extensions (`.md`, `.txt`, `.sh`)

4. **Length Limit Too High** (21 directories affected)
   - Current 50-char limit allows 47-49 char names
   - Target: 30-35 chars for better command-line usability
   - Problem: Long names reduce terminal readability

### 5. Proposed Infrastructure Enhancements

#### Enhancement 1: Artifact Reference Stripping (Priority 1)

**Location**: Add to `sanitize_topic_name()` before stopword filtering

**Implementation**:
```bash
# New step 3.5: Strip artifact references
strip_artifact_references() {
  local text="$1"

  # Remove artifact numbering patterns (001_, 002_, etc.)
  text=$(echo "$text" | sed 's/[0-9]\{3\}_//g')

  # Remove artifact directory names
  text=$(echo "$text" | sed 's/\(reports\|plans\|summaries\|debug\|scripts\|outputs\|artifacts\|backups\)_//g')

  # Remove file extensions
  text=$(echo "$text" | sed 's/\.\(md\|txt\|sh\|json\|yaml\)//g')

  # Remove common file basenames (case-insensitive)
  text=$(echo "$text" | sed 's/\b\(readme\|claude\|output\|plan\|report\|summary\)\b//gi')

  # Remove topic number references (NNN_ pattern)
  text=$(echo "$text" | sed 's/\b[0-9]\{3\}_//g')

  echo "$text"
}
```

**Integration Point**: Call after path extraction (line 158) and before lowercase conversion (line 163)

**Impact**: Would fix 21 of 27 naming violations (78% of problematic directories)

**Testing**: Unit tests with 50+ examples covering all artifact patterns

#### Enhancement 2: Extended Stopword List (Priority 1)

**Location**: Modify stopword list at line 146

**Additional Stopwords** (32 terms):
```bash
# Planning/command context stopwords
local planning_stopwords="create update research plan fix implement analyze review investigate explore examine identify evaluate order accordingly appropriately exactly carefully detailed comprehensive command file document directory topic spec artifact report summary which want need make ensure check verify"

# Combine with existing stopwords
local stopwords="$stopwords $planning_stopwords"
```

**Impact**: 15-25% reduction in average name length (42 chars → 30-35 chars)

**Validation**: Test against existing directory descriptions to ensure semantic terms preserved

#### Enhancement 3: Reduced Length Limit (Priority 2)

**Location**: Line 198-202 (truncation logic)

**Change**:
```bash
# Reduce from 50 to 35 characters
if [ ${#combined} -gt 35 ]; then
  combined=$(echo "$combined" | cut -c1-35 | sed 's/_[^_]*$//')
fi
```

**Rationale**: 35 chars provides adequate description while improving usability
- `35 chars: fix_jwt_token_expiration_bug` ✓ clear, concise
- `48 chars: fix_state_machine_transition_error_build_command` ✗ excessive

**Impact**: Forces more concise names for 21 directories currently at 45+ chars

#### Enhancement 4: Pre-Sanitization Warning Display (Priority 3)

**Location**: Commands using topic allocation (/plan, /research, /debug)

**Implementation**: Add display step before topic creation
```bash
# After generating topic slug, before allocation
TOPIC_SLUG=$(sanitize_topic_name "$DESCRIPTION")

# Display proposed name
echo "Proposed directory name: ${NEXT_NUMBER}_${TOPIC_SLUG}"
echo "Based on description: $DESCRIPTION"

# Validate name quality
if [ ${#TOPIC_SLUG} -lt 10 ]; then
  echo "WARNING: Topic name may be too short for clarity"
fi

# Continue with allocation
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
```

**Impact**: Provides visibility into naming before directory creation, allows manual intervention if needed

### 6. Standards Documentation Enhancements

**File**: `.claude/docs/concepts/directory-protocols.md`

**Additions Needed**:

1. **Anti-Patterns Section** (new section after line 85):
```markdown
### Topic Naming Anti-Patterns

**Avoid These Patterns**:

| Anti-Pattern | Example | Problem | Better Alternative |
|--------------|---------|---------|-------------------|
| Artifact references | `794_001_comprehensive_output_formatting_refactormd_to` | Includes file artifacts | `794_output_formatting_standards` |
| File extensions | `795_claude_commands_readmemd_accordingly_all_flags` | Contains `.md` reference | `795_commands_readme_update` |
| Topic number refs | `816_807_docs_guides_directory_has_become_bloated` | Circular reference | `816_docs_guides_cleanup` |
| Excessive length | `831_plan_command_except_that_what_it_does_is_initiate` | 49 chars, hard to read | `831_plan_command_enhancement` |
| Meta-words | `824_claude_planoutputmd_in_order_to_create_a_plan_to` | Verbose meta-language | `824_plan_output_analysis` |

**Why These Matter**:
- Artifact references mislead about directory purpose
- Long names reduce command-line usability
- Meta-words add noise without semantic value
- Topic references create circular dependencies
```

2. **Best Practices Section** (expand existing section at lines 1132-1180):
```markdown
### Topic Naming Best Practices

**Good Names** (semantic, concise, clear):
- `042_authentication` - Feature area (12 chars)
- `787_state_machine_persistence_bug` - Specific bug (31 chars)
- `788_commands_readme_update` - Clear scope (23 chars)

**Poor Names** (artifact refs, verbose, unclear):
- `794_001_comprehensive_output_formatting_refactormd_to` - Artifact reference (48 chars)
- `824_claude_planoutputmd_in_order_to_create_a_plan_to` - Meta-words + artifact (48 chars)
- `846_001_error_analysis_repair_plan_20251119_232415md` - Timestamp + artifact (48 chars)

**Target Characteristics**:
- Length: 15-35 characters (sweet spot: 20-30)
- Content: Feature/bug description, not file references
- Format: Snake_case technical terms
- Clarity: Understandable without reading description
```

3. **Sanitization Function Reference** (new section):
```markdown
### Automatic Topic Name Generation

Topic names are automatically generated using `sanitize_topic_name()` from user descriptions.

**How It Works**:
1. Extracts meaningful path components from descriptions containing paths
2. Removes common stopwords (70+ terms) while preserving technical terms
3. Strips artifact references (file extensions, numbering, subdirectory names)
4. Converts to snake_case and truncates intelligently at word boundaries
5. Enforces 35-character maximum for readability

**Example Transformations**:
| Input Description | Generated Name |
|-------------------|----------------|
| "Research .claude/commands/README.md and update flags" | `commands_readme_flags_update` |
| "Fix the JWT token expiration bug in auth module" | `jwt_token_expiration_bug` |
| "Create plan to implement user authentication" | `user_authentication` |
| "Research reports/001_analysis.md findings" | `analysis_findings` |
```

### 7. Implementation Strategy (Clean-Break Approach)

**Philosophy Alignment** (from writing-standards.md):
- Clean-break refactors without legacy burden
- Forward-looking improvements
- No historical documentation of "old way vs new way"
- Document current state only

**Approach**: Improve infrastructure, let legacy directories age out naturally

**What We DO**:
1. ✅ Enhance `sanitize_topic_name()` with all four improvements
2. ✅ Update directory-protocols.md with anti-patterns and best practices
3. ✅ Add unit tests for new sanitization behavior
4. ✅ Deploy to all commands using topic allocation
5. ✅ Monitor new directory names for compliance

**What We DON'T DO**:
1. ❌ Rename existing 27 problematic directories
2. ❌ Create migration scripts or utilities
3. ❌ Document "before and after" comparisons
4. ❌ Add deprecation warnings for old names
5. ❌ Track legacy directory cleanup

**Rationale**:
- Existing directories work fine (naming is cosmetic)
- Renaming risks breaking workflows and git history
- Clean-break means "improve going forward, ignore past"
- Natural attrition: old specs become irrelevant over time
- Development velocity: focus on preventing future issues, not fixing past ones

### 8. Testing Requirements

**Unit Tests** (new file: `.claude/tests/test_topic_name_sanitization.sh`):

Test coverage for all enhancement areas:

1. **Artifact Reference Stripping** (20 test cases):
   - File extensions: `.md`, `.txt`, `.sh`, `.json`
   - Artifact numbering: `001_`, `042_`, `123_`
   - Subdirectories: `reports_`, `plans_`, `summaries_`, `debug_`
   - Common basenames: `README`, `claude`, `output`, `plan`
   - Topic references: `816_807_`, `822_`

2. **Extended Stopwords** (15 test cases):
   - Planning terms: `create`, `research`, `plan`, `implement`
   - Meta-words: `command`, `file`, `document`, `directory`
   - Modifiers: `carefully`, `detailed`, `comprehensive`
   - Preservation: Technical terms NOT filtered

3. **Length Limit** (10 test cases):
   - Exactly 35 chars (preserved)
   - 36-40 chars (truncated at word boundary)
   - 50+ chars (truncated to <35)
   - Word boundary preservation

4. **Edge Cases** (15 test cases):
   - Empty input
   - Only stopwords
   - Only artifacts
   - All caps
   - Special characters
   - Unicode
   - Very short descriptions
   - Path-only input
   - Mixed case

**Integration Tests**:
- Run `/plan` with various descriptions
- Verify topic names match expected output
- Check no artifacts in generated names

**Performance Tests**:
- Benchmark sanitization function (target: <10ms)
- Ensure no regression from added processing

### 9. Performance Impact Analysis

**Current Performance** (from unified-location-detection.sh):
- Topic allocation: ~12ms (includes lock contention)
- Sanitization: ~5ms (simple string operations)
- Total: ~17ms per topic creation

**Estimated Impact of Enhancements**:
- Artifact stripping: +2ms (4-5 additional sed operations)
- Extended stopwords: +1ms (larger word list iteration)
- Reduced length limit: 0ms (same logic, different threshold)
- Pre-display warning: +1ms (string operations)
- **Total**: +4ms (17ms → 21ms)

**Assessment**: 24% increase in processing time is acceptable
- Human-driven workflow commands (not hot path)
- 21ms is still imperceptible to users
- Improved naming quality worth minor performance cost

### 10. Rollout Plan

**Phase 1: Implementation** (Week 1)
- Implement four enhancements in topic-utils.sh
- Add unit tests for all enhancement areas
- Test against sample descriptions

**Phase 2: Documentation** (Week 1)
- Update directory-protocols.md with anti-patterns
- Add best practices section
- Document sanitization function behavior

**Phase 3: Deployment** (Week 2)
- Deploy enhanced sanitization to production
- Monitor first 10 new topic directories
- Validate naming quality improvements

**Phase 4: Validation** (Week 2-3)
- Collect naming samples from new directories
- Measure compliance rate (target: 95%+)
- Gather user feedback on name clarity

**Success Metrics**:
- ✅ Zero new directories with artifact references
- ✅ Average name length: 30-35 chars (down from 42)
- ✅ 95%+ semantic clarity (human evaluator rating)
- ✅ Zero naming-related user complaints
- ✅ All new names comply with standards

## Recommendations

### Immediate Actions (Priority 1)

1. **Implement Artifact Reference Stripping**
   - Add `strip_artifact_references()` function to topic-utils.sh
   - Integration: Call before lowercase conversion (line 163)
   - Testing: 20 unit test cases covering all patterns
   - Timeline: 1 day implementation + 1 day testing

2. **Extend Stopword List**
   - Add 32 planning/command context terms to line 146
   - Validation: Test against 50 existing descriptions
   - Ensure technical terms preserved
   - Timeline: 4 hours implementation + 4 hours validation

3. **Update directory-protocols.md**
   - Add anti-patterns section with examples
   - Expand best practices with good/bad comparisons
   - Document sanitization function behavior
   - Timeline: 1 day documentation

### Secondary Actions (Priority 2)

4. **Reduce Length Limit to 35 Characters**
   - Modify truncation logic at line 198
   - Test against existing descriptions for semantic preservation
   - Timeline: 2 hours implementation + 2 hours testing

5. **Add Pre-Sanitization Warning Display**
   - Integrate into /plan, /research, /debug commands
   - Show proposed name before directory creation
   - Timeline: 3 hours per command (9 hours total)

6. **Create Comprehensive Test Suite**
   - New file: `.claude/tests/test_topic_name_sanitization.sh`
   - 60 unit tests covering all enhancement areas
   - Integration tests with real commands
   - Timeline: 2 days development + 1 day validation

### Monitoring Actions (Priority 3)

7. **Track New Directory Naming Quality**
   - Monitor first 20 new directories after deployment
   - Calculate compliance rate with standards
   - Identify any remaining edge cases
   - Timeline: Ongoing, 3 weeks post-deployment

8. **Gather User Feedback**
   - Survey users on name clarity and usability
   - Identify any confusion or issues
   - Iterate on sanitization logic if needed
   - Timeline: 2 weeks post-deployment

## References

### Primary Source Files

- **Spec 856 Analysis**: `/home/benjamin/.config/.claude/specs/856_to_create_a_plan_to_improve_directory_names_while/reports/001_spec_directory_naming_analysis.md` - Complete analysis of existing naming violations and root causes
- **Topic Utils**: `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` (lines 142-205) - Current sanitization implementation
- **Directory Protocols**: `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 62-85) - Topic naming standards
- **Unified Location Detection**: `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh` (lines 12-33) - Atomic topic allocation
- **Code Standards**: `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` - General naming conventions
- **Writing Standards**: `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` - Clean-break development philosophy

### Commands Using Topic Allocation

- **Plan Command**: `/home/benjamin/.config/.claude/commands/plan.md` (lines 180-185) - Research-and-plan workflow
- **Research Command**: `/home/benjamin/.config/.claude/commands/research.md` (lines 180-185) - Research-only workflow
- **Debug Command**: `/home/benjamin/.config/.claude/commands/debug.md` - Debug workflow (uses topic allocation)

### Related Documentation

- **Bash Block Execution**: `.claude/docs/concepts/bash-block-execution-model.md` - Output suppression patterns
- **Test Isolation**: `.claude/docs/reference/standards/test-isolation.md` - Environment override patterns
- **Development Workflow**: `.claude/docs/concepts/development-workflow.md` - Clean-break approach

---

**End of Report**
