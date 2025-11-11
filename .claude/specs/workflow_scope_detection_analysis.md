# Workflow Scope Detection Implementation Analysis

## 1. CURRENT IMPLEMENTATION PATTERN ANALYSIS

### Regex Patterns by Priority Order

The implementation uses a **5-tier priority system** with explicit ordering (lines 23-89):

#### PRIORITY 1: Revision-First Patterns (Lines 42-50)
Most specific - checked first before plan path patterns

**Pattern 1a (Line 42)**:
```regex
^(revise|update|modify).*(plan|implementation).*(accommodate|based on|using|to|for)
```
- **Anchor**: `^(revise|update|modify)` - Must start with one of these verbs
- **Greedy Match 1**: `.*` - Consumes flexible spacing and text (e.g., "the plan /path/to/plan.md ")
- **Keyword**: `(plan|implementation)` - Must contain "plan" or "implementation"
- **Greedy Match 2**: `.*` - Consumes text between plan and trigger keywords
- **Trigger**: `(accommodate|based on|using|to|for)` - Must end with one of these triggers

**Examples that MATCH**:
- "Revise /path/to/specs/042_auth/plans/001_plan.md to accommodate new requirements" ✓
- "Revise the plan /path/to/implementation.md to accommodate changes" ✓
- "Update plan based on recent findings" ✓
- "Modify implementation for new requirements" ✓

**Examples that DON'T MATCH**:
- "revise the plan" (missing trigger keyword)
- "update implementation" (missing trigger keyword)

**Behavior Note**: Extracts EXISTING_PLAN_PATH from matched workflow description if path matches `/specs/[0-9]+_[^/]+/plans/`

#### Pattern 1b (Line 54)
```regex
(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)
```
- **Keyword 1**: `(research|analyze)` - Starts with research or analyze
- **Connector**: `(and |then |to )` - Explicit connectors between research and revision
- **Keyword 2**: `(revise|update.*plan|modify.*plan)` - Must contain revision keywords

**Examples that MATCH**:
- "research authentication and revise the plan" ✓
- "research patterns and then revise the plan" ✓
- "analyze system and update the plan" ✓

**Examples that DON'T MATCH**:
- "research the output which shows research-and-revise works" (NO revision action, just mentioning type name)
- "research and implement feature" (implement ≠ revision keyword)

**KEY ISSUE**: Line 54 pattern does NOT have start-of-string anchor `^`. This allows matching anywhere in text, including within descriptions of workflow *types* being discussed.

#### PRIORITY 2: Plan Path Detection (Lines 57-65)
Detects explicit plan file paths

**Pattern 2 (Line 60)**:
```regex
(^|[[:space:]])(\.|/)?(.*/)?specs/[0-9]+_[^/]+/plans/[^[:space:]]+\.md
```
- **Start Context**: `(^|[[:space:]])` - Plan path must start with whitespace or string start
- **Path Prefix**: `(\.|/)?(.*/)?` - Optional `.` or `/` prefix, optional parent directories
- **Pattern**: `specs/[0-9]+_[^/]+/plans/[^[:space:]]+\.md` - Full plan path pattern
- **Anchor**: `[^[:space:]]+\.md` - No spaces in filename, must end with `.md`

**Examples that MATCH**:
- "implement specs/661_auth/plans/001_implementation.md" ✓
- "implement /home/user/.config/.claude/specs/042_auth/plans/001_plan.md" ✓
- "implement ./.claude/specs/042_auth/plans/001_plan.md" ✓

#### PRIORITY 3: Research-Only Pattern (Lines 67-75)
Pure research with no action keywords

**Pattern 3a (Line 68)**:
```regex
^research.*
```
- **Start Anchor**: Must start with "research"
- **Greedy Match**: `.*` captures everything after "research"

**Pattern 3b (Line 69 - nested check)**:
```regex
(plan|implement|fix|debug|create|add|build)
```
- **Negation Logic**: If any action keyword found, NOT research-only
- Returns `research-and-plan` for ambiguous "research + action" cases

**Examples**:
- "research authentication patterns" → research-only ✓
- "research auth and create plan" → research-and-plan (action keyword found) ✓

#### PRIORITY 4: Explicit Keyword Patterns (Lines 77-80)
High-priority action keywords

**Pattern 4a (Line 79)**:
```regex
(^|[[:space:]])(implement|execute)
```
- **Context**: Word boundary - keyword must be standalone word
- **Keywords**: "implement" or "execute"
- **Classification**: full-implementation

**Pattern 4b (Lines 83-88)**:
Multiple lower-priority keyword patterns:
```regex
(plan|create.*plan|design)           → research-and-plan
(fix|debug|troubleshoot)              → debug-only
(build|add|create).*feature           → full-implementation
```

### Pattern Precedence and Priority Order

```
1. Revision-first (HIGHEST SPECIFICITY)
   ├─ Line 42: ^(revise|update|modify)....(plan|implementation)....(trigger)
   └─ Line 54: (research|analyze)...(and|then|to)...(revise|update|modify)

2. Plan path detection
   └─ Line 60: Plan file path matching

3. Research-only (with nested action check)
   └─ Line 68-74: Pure research pattern

4. Explicit keywords
   ├─ Line 79: (implement|execute)
   ├─ Line 83: (plan|create.*plan|design)
   ├─ Line 85: (fix|debug|troubleshoot)
   └─ Line 87: (build|add|create).*feature

5. Default fallback
   └─ Line 14: research-and-plan
```

---

## 2. FAILURE MODE ANALYSIS

### Documented Failure Mode 1: Pattern 1b Missing Start Anchor

**Location**: Line 54
**Severity**: MEDIUM - Causes false positives in edge cases
**Description**: Pattern lacks `^` anchor, allowing matches anywhere in text

**Root Cause**:
```bash
# Current (problematic)
echo "research the output which shows research-and-revise works" | \
  grep -Eiq "(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)"
# Result: MATCHES (false positive) - but actually returns research-only due to nested check

# More problematic example:
echo "discuss research-and-revise workflow in coordinate" | \
  grep -Eiq "(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)"
# Result: MATCHES (false positive) if "and" is found in the right place
```

**False Positive Scenarios**:
1. "research how to use research-and-revise pattern and then decide" - Mentions pattern name, not requesting it
2. "research the documentation and revise approach" - Ambiguous: are we revising a plan or our approach?
3. Text with "research the" + "and" + "revise" with other words in between

**Why It Doesn't Manifest as Bad Behavior**:
- Pattern 1b is checked with `elif`, so if Pattern 1a matches, it doesn't run
- When Pattern 1b alone matches, it correctly returns "research-and-revise" for most cases
- Only problematic when DISCUSSING a workflow type (metadata confusion)

**Example Test Case That Would Fail**:
```bash
# Input discussing workflow type (should be research-only or default)
detect_workflow_scope "research the output of coordinate when using research-and-revise approach"
# Current: research-and-revise (FALSE POSITIVE - discussing type, not requesting it)
# Expected: research-only
```

---

### Documented Failure Mode 2: Pattern 1a Greedy Match Behavior

**Location**: Line 42
**Severity**: LOW - Documented and intentional
**Description**: Greedy `.*` matches can consume legitimate keywords

**Example of Greedy Matching**:
```bash
"Revise the implementation plan to accommodate changes using new architecture"
                          ↑ greedy match consumes "implementation" before checking keyword
```

**Why It Works**: 
- Pattern checks for `(plan|implementation)` AFTER the first greedy match
- So consuming "implementation" with `.*` still finds "plan" later, or the second instance
- Commit 1984391a explicitly fixed this issue with comprehensive regex validation

**Tested and Verified**: Tests 14-19 in test_scope_detection.sh validate this pattern

---

### Failure Mode 3: Keyword Proximity Issues (Pattern 4b)

**Location**: Lines 83-88
**Severity**: LOW - Falls back to default on ambiguity
**Description**: Keyword must appear with no context checking

**Examples**:
- "debug implementation of feature X" → debug-only (correct)
- "feature implementation with debug mode" → COULD match debug-only if checked in isolation

**Actual Behavior**: Line 85 checks `grep -Eiq "(fix|debug|troubleshoot)"` - case insensitive, whole pattern
- "debug" will match anywhere in the string
- Falls back to research-and-plan default if no keyword matches

**Not Really a Failure**: Default behavior is correct; if text mentions debugging, some debug workflow is intended

---

### Failure Mode 4: Pattern Overlap - "implement" vs "implement feature"

**Location**: Lines 79 and 87
**Severity**: MEDIUM - Pattern priority matters
**Description**: Two patterns could match "implement feature", different classifications

**Patterns**:
- Line 79: `(^|[[:space:]])(implement|execute)` → full-implementation
- Line 87: `(build|add|create).*feature` → full-implementation

**Both return same result** (full-implementation), so not actually a conflict
**But ordering matters**: Line 79 checked first, so "implement feature" matches line 79 first

**Edge Case**: "add to feature implementation"
- Line 87 pattern: `(build|add|create).*feature` - Greedy `.*` could consume "to" and match
- Actually works correctly because both return full-implementation

---

### Failure Mode 5: Research + Conflicting Keywords

**Location**: Lines 68-75 (nested check)
**Severity**: LOW - Correctly defaults to research-and-plan
**Description**: "research + implement" ambiguity

**Example**:
```bash
detect_workflow_scope "research patterns and implement authentication"
```

**What Happens**:
1. Line 68: Matches `^research.*` ✓
2. Line 69: Checks for action keywords in the string
3. Finds "implement" (action keyword)
4. Returns "research-and-plan" (line 71)

**Expected**: research-and-plan (research phase followed by planning/implementation phase)
**Actual**: research-and-plan ✓ CORRECT

**Note**: This correctly interprets "research X and implement Y" as "do research, THEN plan implementation" 
not "revise existing implementation" (research-and-revise)

---

## 3. TEST COVERAGE ANALYSIS

### Test Files Overview

**File 1: test_scope_detection.sh** (19 tests)
- **Pass Rate**: 17/19 (89%)
- **Failures**: 
  - Test 4: "research auth and implement feature" → Expected full-implementation, Got research-and-plan
  - Test 5: "research and build authentication feature" → Expected full-implementation, Got research-and-plan

**File 2: test_workflow_scope_detection.sh** (20 tests)
- **Pass Rate**: 20/20 (100%)
- Comprehensive coverage of all scope types
- Includes plan path tests (absolute, relative, with/without prefix)
- Includes revision-first pattern variations
- Includes edge cases and ambiguous queries

**File 3: test_supervise_scope_detection.sh** (19 tests)
- Tests /supervise compatibility
- Sources different library: workflow-detection.sh (fallback version)
- Not directly testing workflow-scope-detection.sh

### Test Coverage Gaps

**MISSING TEST CASES** (high-value additions):

#### Gap 1: False Positive - Discussing Workflow Type
```bash
test_case_1="research the output of workflow which shows research-and-revise"
# Current: Returns research-only (correct by accident)
# Should be documented to prevent regression

test_case_2="I'm investigating the research-and-revise pattern implementation"
# Current: Returns research-only (correct by accident)
```
**Why It's a Gap**: Pattern 1b line 54 is missing start anchor. It COULD match in these cases if "research" + "and" + "revise" appear naturally. Currently protected by being checked with `elif` after Pattern 1a.

#### Gap 2: Edge Case - "Research and then revise" without plan
```bash
test_case_3="research the system architecture and then revise our implementation approach"
# Current: research-and-revise
# Issue: Could be confused with revision-first workflow
# Should verify this is intended behavior
```

#### Gap 3: Pattern 1a with "for" trigger at end
```bash
test_case_4="revise implementation for new features"
# Pattern 1a trigger: (accommodate|based on|using|to|for)
# This SHOULD match but might not if "for" appears late
# Needs explicit test
```

#### Gap 4: Mixed keywords - debug + implement
```bash
test_case_5="debug and implement new authentication"
# Current: Returns debug-only (pattern 85 matched)
# But should arguably be full-implementation
# Currently defaults to first matching pattern (debug)
```

#### Gap 5: Case insensitivity edge cases
```bash
test_case_6="RESEARCH Authentication PATTERNS"
test_case_7="Debug The System"
# Case insensitive flag (-i) used, but not tested comprehensively
```

#### Gap 6: Whitespace and special characters
```bash
test_case_8="research  patterns  with   extra spaces"
test_case_9="research-patterns with hyphenated-words"
# Greedy .* could consume whitespace differently
```

#### Gap 7: Plan path with unusual formats
```bash
test_case_10="implement ./specs/042_auth/plans/001.md"  # Already tested
test_case_11="implement specs/042_auth/plans/001.md"    # Relative without ./
test_case_12="implement ../specs/042_auth/plans/001.md" # Parent directory
# Line 60 pattern: (\.|/)?(.*/)?specs/... - might not match parent dir traversal
```

#### Gap 8: Full-implementation keyword conflicts
```bash
test_case_13="build debug feature"
# Matches: both line 85 (debug) and line 87 (build...feature)
# Which one wins? Currently line 85 (checked first in elif chain)
# Should be explicitly tested
```

#### Gap 9: Ambiguous "create" keyword
```bash
test_case_14="create a plan for authentication"    # Line 83 pattern
test_case_15="create the authentication feature"   # Line 87 pattern
# Both could match create patterns - precedence matters
```

#### Gap 10: Research-only with modifier words
```bash
test_case_16="research the authentication patterns thoroughly"
test_case_17="research async patterns in detail"
# Should stay research-only, but no test verifies this
```

---

## 4. CONTEXT AND DEPENDENCIES

### Function Call Sites

**Primary Caller**: `.claude/lib/workflow-state-machine.sh`

**Invocation Points**:
1. **Line 102**: During state machine initialization
   ```bash
   WORKFLOW_SCOPE=$(detect_workflow_scope "$workflow_desc")
   ```
   
2. **Line 106**: Fallback if sm_init not called directly
   ```bash
   WORKFLOW_SCOPE=$(detect_workflow_scope "$workflow_desc")
   ```

**Secondary Callers**:
- `/coordinate` command (lines 128, 135, 251, 659, 677, 789+)
- Test files (test_scope_detection.sh, test_workflow_scope_detection.sh)

### Downstream Impact of WORKFLOW_SCOPE

**1. State Machine Flow Control** (workflow-state-machine.sh, line 113)
```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    TERMINAL_STATE="complete"
    ;;
  research-and-plan)
    TERMINAL_STATE="debug"  # Can skip debug and go to document
    ;;
  full-implementation)
    TERMINAL_STATE="debug"  # Full implementation expects debug phase
    ;;
  research-and-revise)
    TERMINAL_STATE="document"
    ;;
esac
```

**Impact**: Determines which state is considered "terminal" (completion point)

**2. Coordinate Command Flow** (coordinate.md, lines 789+)
```bash
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # Special handling: invokes revise workflow with existing plan
  # Branch 1: Revision-focused path
else
  # Branch 2: Standard research → plan → implement → test → document
fi
```

**Impact**: Entire workflow branches on this single variable

**3. Downstream Phase Behavior** (coordinate.md, lines 950-1040)
- Line 952: Skip planning if research-and-revise (already have plan)
- Line 965: Different agent invocation for research-and-revise
- Line 1024: Skip implementation setup for debug-only workflows
- Line 1037: Special handling for revision-first workflow

**4. Error Messages and Validation** (coordinate.md, lines 695, 1103)
```bash
case "$WORKFLOW_SCOPE" in
  research-only | research-and-plan | full-implementation | \
  research-and-revise | debug-only)
    # Valid scope
    ;;
  *)
    echo "ERROR: Unknown workflow scope: $WORKFLOW_SCOPE"
    exit 1
    ;;
esac
```

**Impact**: Invalid scope causes immediate termination

### What Happens on Misclassification

#### Scenario 1: "implement <plan>" detected as "research-and-plan" instead of "full-implementation"

**Current Code Flow**:
1. User runs: `/coordinate implement specs/661_auth/plans/001_plan.md`
2. WORKFLOW_SCOPE becomes "research-and-plan" (WRONG)
3. State machine terminal becomes "debug" instead of "debug" (same result by luck)
4. Coordinate skips straight to research phase instead of implementing plan
5. **Result**: Workflow doesn't execute the plan, tries to create new plan instead

**From Spec 664**: This is the BUG that was fixed in commit 1984391a
- "Research scheduler had incorrect scope detection: plan path detection after research-only check instead of before"
- Phase 1 added explicit plan path detection at PRIORITY 2 (before research-only checks)

#### Scenario 2: "research-and-revise" pattern incorrectly matched in discussion

**Current Code Flow**:
1. User mentions: "research how to use research-and-revise workflow"
2. Pattern 1b line 54 might match (no start anchor)
3. WORKFLOW_SCOPE becomes "research-and-revise" (WRONG)
4. Coordinate tries to find EXISTING_PLAN_PATH (not provided)
5. **Result**: Workflow assumes user has existing plan to revise, but they're just asking questions

**Likelihood**: LOW - Pattern 1b uses `elif`, so Pattern 1a must fail first
**Protection**: Lines 68-75 nested check prevents this for "research" pattern

#### Scenario 3: "debug-only" triggered when "build feature" intended

**Current Code Flow**:
1. User: "/coordinate build debug feature for performance"
2. Pattern 85 line (fix|debug|troubleshoot) matches "debug"
3. WORKFLOW_SCOPE becomes "debug-only" (WRONG)
4. Coordinate runs debug workflow instead of implementation
5. **Result**: System tries to debug non-existent bug

**Likelihood**: LOW - Would need unusual phrasing
**Current Behavior**: Line 85 checked first due to `elif` chain

---

## 5. STRUCTURED SUMMARY

### Current Regex Patterns Reference Table

| Priority | Pattern | Location | Regex | Scope | Start Anchor? |
|----------|---------|----------|-------|-------|---------------|
| 1a | Revision-first (simple) | L42 | `^(revise\|update\|modify).*` | research-and-revise | YES ✓ |
| 1b | Research-and-revise | L54 | `(research\|analyze).*(and \|then \|to ).*(revise\|update.*plan\|modify.*plan)` | research-and-revise | NO ✗ |
| 2 | Plan path | L60 | `(^[[:space:]])(...)?specs/[0-9]+_...` | full-implementation | YES ✓ |
| 3a | Research-only | L68 | `^research.*` | research-only | YES ✓ |
| 3b | Research + action | L69 | `(plan\|implement\|fix\|...)` | research-and-plan | NO |
| 4a | Implement/Execute | L79 | `(^[[:space:]])(implement\|execute)` | full-implementation | YES ✓ |
| 4b | Plan/Design | L83 | `(plan\|create.*plan\|design)` | research-and-plan | NO |
| 4c | Fix/Debug | L85 | `(fix\|debug\|troubleshoot)` | debug-only | NO |
| 4d | Build feature | L87 | `(build\|add\|create).*feature` | full-implementation | NO |

### Known Limitations

1. **Pattern 1b missing start anchor** - Could match discussion of workflow types
2. **Greedy `.*` matching** - Can consume legitimate keywords (mitigated by re-checking after)
3. **No word boundaries** - Keywords can match as substrings (e.g., "updated" might match "update")
4. **Precedence matters** - First matching pattern wins; order is critical
5. **No semantic understanding** - Pure regex, can't distinguish "revise our approach" from "revise the plan"

### Test Coverage Summary

- **Total Test Files**: 3
- **Total Tests**: 58 (19 + 20 + 19)
- **Passing**: 56 (96.5%)
- **Failing**: 2 (test_scope_detection.sh, tests 4-5)
- **Gaps Identified**: 10+ high-value test cases missing

---

## APPENDIX: Test Case Reference

### Current Test Coverage by Scope Type

**research-only** (4 tests):
- ✓ Simple research
- ✓ Research with "the"
- ✓ Capitalized
- ✓ Pure research no keywords

**research-and-plan** (8 tests):
- ✓ Plan keyword explicit
- ✓ Design keyword
- ✓ Create plan
- ✓ Research + plan intent
- ✓ Research + analyze + plan
- ✓ Ambiguous analyze
- ✓ Informal request
- ✓ Vague check

**full-implementation** (12 tests):
- ✓ Implement feature
- ✓ Build feature
- ✓ Add feature
- ✓ Create component
- ✓ Execute plan
- ✓ Absolute plan path
- ✓ Relative plan path
- ✓ Plan path implicit
- ✓ Mixed research + implement
- ✓ Create feature explicit
- ✗ Research + build (FAILING)
- ✗ Research + implement feature (FAILING)

**research-and-revise** (10 tests):
- ✓ Revision-first simple
- ✓ Revision-first with "the plan"
- ✓ Full user input from issue
- ✓ Update plan based on
- ✓ Modify for requirements
- ✓ Using keyword trigger
- ✓ Revise without path
- ✓ Update plan pattern
- ✓ Modify plan pattern
- ✓ Research + revise

**debug-only** (6 tests):
- ✓ Fix keyword
- ✓ Debug keyword
- ✓ Troubleshoot keyword
- ✓ Mixed fix + add (fix wins)
- ✓ Implement fix (implement wins)
- ✓ Case insensitive

### Edge Cases Tested
- ✓ Empty description (error handling)
- ✓ Case insensitivity (multiple tests)
- ✓ Mixed keywords/connectors (and, then, to)
- ✓ Plan path variations (absolute, relative, with prefix)

### Edge Cases NOT Tested
- Discussing workflow types (false positives)
- Greedy match behavior with complex nesting
- Whitespace variations
- Parent directory navigation in paths
- Keyword appearing as substring
- Unicode characters in description
