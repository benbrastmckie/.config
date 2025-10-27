# Command Architecture Standards: Function Placement Rules

## Research Topic
Analysis of command architecture standards for determining when functions should be inline vs. extracted to library files.

## Status
✅ Research complete

## Executive Summary

The command architecture standards establish a clear distinction between **structural templates** (must be inline) and **behavioral content** (must be referenced). However, there is **no explicit guidance** for simple utility functions like `display_brief_summary`. Analysis of current practice reveals:

- **Inline functions**: Command-specific utility functions (2 found: `display_brief_summary` in supervise.md, plan.md)
- **Library extraction**: Reusable deterministic operations (9+ libraries in `.claude/lib/`)
- **Decision criterion**: Single-use workflow-specific functions remain inline; multi-command reusable functions extract to libraries

## Key Finding: Gap in Standards

The Command Architecture Standards (`.claude/docs/reference/command_architecture_standards.md`) define what MUST be inline vs referenced, but do NOT address small utility functions:

**What standards cover:**
- ✅ Structural templates (Task blocks, bash execution, JSON schemas) → INLINE
- ✅ Behavioral content (agent STEP sequences, workflows) → REFERENCE agent files
- ✅ Execution-critical procedures → INLINE with `[EXECUTION-CRITICAL]` annotation
- ❌ **Simple utility functions (10-30 lines)** → NO EXPLICIT GUIDANCE

## Findings

### Standards Analysis

#### Standard 1: Executable Instructions Must Be Inline
**Source**: `command_architecture_standards.md:931-1125`

**Rule**: Execution-critical content MUST remain inline in command files:
- Step-by-step execution procedures (core workflow)
- Tool invocation patterns (Task, Bash, Read, Write examples)
- Decision flowcharts (if/then logic with specific conditions)
- Critical warnings (CRITICAL, IMPORTANT, NEVER, ALWAYS statements)
- Template structures (complete agent prompts, JSON schemas, bash scripts)
- Error recovery procedures (specific actions for each error type)

**Rationale**: Commands are AI execution scripts that Claude reads linearly during execution. External references break execution flow and lose state.

**Annotation**: Content marked with `[EXECUTION-CRITICAL]` or `[INLINE-REQUIRED]` CANNOT be extracted.

#### Standard 12: Structural vs Behavioral Content Separation
**Source**: `command_architecture_standards.md:1242-1332`

**Rule**: Commands MUST distinguish between:
1. **Structural Templates** (INLINE): Task invocation syntax, bash blocks, JSON schemas, verification checkpoints, critical warnings
2. **Behavioral Content** (REFERENCED): Agent STEP sequences, file creation workflows, agent verification steps, output format specifications

**Prohibition**: Commands MUST NOT duplicate agent behavioral content. Reference `.claude/agents/*.md` files instead.

**Benefit**: 90% code reduction per agent invocation (150 lines → 15 lines)

#### Refactoring Guidelines: When to Extract
**Source**: `command_architecture_standards.md:1334-1383`

**Safe to Extract** (move to reference files):
- Extended background (historical context, design rationale)
- Alternative approaches (other ways to solve similar problems)
- Additional examples (beyond 1-2 core examples needed inline)
- Troubleshooting guides (edge case handling, debugging tips)
- Deep dives (detailed explanations of algorithms)
- Related reading (links to external documentation)

**Never Extract** (must stay inline):
- Step-by-step execution procedures
- Tool invocation patterns
- Decision flowcharts
- Critical warnings
- Template structures
- Error recovery procedures
- Parameter specifications
- Parsing patterns (regex, jq queries, grep commands)

**Critical Mass Principle**: Command file must contain enough detail to execute independently. Reference files enhance understanding but aren't required for execution.

### Template vs Behavioral Distinction
**Source**: `.claude/docs/reference/template-vs-behavioral-distinction.md`

**Decision Tree**:
```
Is this content about command execution structure?
│
├─ YES → Is it Task syntax, bash blocks, schemas, or checkpoints?
│         │
│         ├─ YES → ✓ INLINE in command file (structural template)
│         │
│         └─ NO → Continue evaluation...
│
└─ NO → Is it STEP sequences, workflows, or agent procedures?
          │
          ├─ YES → ✓ REFERENCE agent file (behavioral content)
          │
          └─ NO → Ask: "If I change this, where do I update it?"
                    │
                    ├─ Multiple places → ✗ WRONG (should be referenced)
                    │
                    └─ Only here → Depends on context
```

**Quick Test**: "If I change this content, where do I update it?"
- "Only in this command file" → Likely structural template (inline OK)
- "In multiple command files" → WRONG! Should be in library (referenced)
- "In the agent file" → Behavioral content (must reference, not inline)

### Current Practice: Inline Function Examples

#### Example 1: `display_brief_summary` in supervise.md
**Source**: `.claude/commands/supervise.md:326-350`

```bash
# Define display_brief_summary function inline
# (Must be defined before function verification checks below)
display_brief_summary() {
  echo ""
  echo "✓ Workflow complete: $WORKFLOW_SCOPE"

  case "$WORKFLOW_SCOPE" in
    research-only)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count research reports in: $TOPIC_PATH/reports/"
      echo "→ Review artifacts: ls -la $TOPIC_PATH/reports/"
      ;;
    research-and-plan)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count reports + 1 plan in: $TOPIC_PATH/"
      echo "→ Run: /implement $PLAN_PATH"
      ;;
    # ... additional workflow scopes
  esac
}
```

**Characteristics**:
- **Size**: ~25 lines
- **Purpose**: Workflow-specific completion summary
- **Usage**: Single command (supervise.md)
- **Dependencies**: Uses workflow-specific variables ($WORKFLOW_SCOPE, $REPORT_PATHS)
- **Reusability**: Low (tightly coupled to /supervise workflow phases)

**Classification**: Command-specific utility function → INLINE

#### Example 2: Inline function in plan.md
**Search Result**: `.claude/commands/plan.md` contains inline function definitions

**Pattern**: Commands define small utility functions inline when:
1. Function is command-specific (not reusable across commands)
2. Function size is small (<50 lines)
3. Function uses command-specific variables/state
4. Function is workflow-phase specific

### Library Extraction: When Functions Move to `.claude/lib/`

#### Criteria for Library Extraction
**Source**: `.claude/docs/guides/using-utility-libraries.md:18-62`

**Use Utility Libraries When:**

1. **Deterministic Operations** (no AI reasoning needed):
   - Location detection from user input
   - Topic name sanitization
   - Directory structure creation
   - Plan file parsing
   - Metadata extraction from structured files

2. **Performance Critical Paths**:
   - Workflow initialization (create topic directories)
   - Checkpoint save/load operations
   - Log file writes
   - JSON/YAML parsing

3. **Reusable Patterns Across Commands**:
   - All commands need location detection → `unified-location-detection.sh`
   - All commands need logging → `unified-logger.sh`
   - Multiple commands parse plans → `plan-core-bundle.sh`

4. **Context Window Optimization**:
   - Libraries use 0 tokens (pure bash)
   - Agents use 15k-75k tokens per invocation
   - Example: `unified-location-detection.sh` saves 65k tokens vs `location-specialist` agent

**Benefit Example**: Location detection
- **Before**: 50+ lines per command (duplicated across 4 commands)
- **After**: 10 lines per command (reference library)
- **Reduction**: 80% code reduction
- **Maintenance**: Fix bug once, all commands benefit

#### Existing Library Examples

**Source**: `.claude/commands/supervise.md:243-323` (library sourcing)

Commands source 9 utility libraries:
1. `workflow-detection.sh` - Detect workflow scope (research-only, full-implementation)
2. `error-handling.sh` - Standardized error classification and recovery
3. `checkpoint-utils.sh` - Save/load workflow state
4. `unified-logger.sh` - Log rotation and formatting
5. `unified-location-detection.sh` - Topic directory detection/creation
6. `metadata-extraction.sh` - Extract metadata from reports/plans (95% context reduction)
7. `context-pruning.sh` - Context window optimization (<30% usage target)
8. `topic-utils.sh` - Topic name sanitization
9. `detect-project-dir.sh` - Project root detection

**Pattern**: All 9 libraries provide deterministic operations used by multiple commands.

### Key Patterns

#### Pattern 1: Annotation-Based Guidance
**Source**: `command_architecture_standards.md:1120-1125`

```markdown
## Process
[EXECUTION-CRITICAL: This section contains step-by-step procedures that Claude must see during command execution]

### Step 1: Initialize Workflow
[INLINE-REQUIRED: Bash commands and tool calls must remain inline]
```

**Annotation Types**:
- `[EXECUTION-CRITICAL]`: Cannot be moved to external files
- `[INLINE-REQUIRED]`: Must stay inline for tool invocation
- `[REFERENCE-OK]`: Can be supplemented with external references
- `[EXAMPLE-ONLY]`: Can be moved to external files if core example remains

**Implication**: Small utility functions lack explicit annotation guidance. Apply by analogy:
- Workflow-specific utility → Consider `[INLINE-REQUIRED]` if command-specific
- Multi-command utility → Extract to library, mark with `[REFERENCE-OK]`

#### Pattern 2: Single Source of Truth Principle
**Source**: `template-vs-behavioral-distinction.md:183-194`

**Metrics when properly applied**:
| Metric | Before (Duplication) | After (Proper Distinction) | Improvement |
|--------|---------------------|---------------------------|-------------|
| Code per agent invocation | 150 lines | 15 lines | 90% reduction |
| Context window usage | 85% | 25% | 71% reduction |
| File creation success rate | 70% | 100% | 43% improvement |
| Maintenance burden | Baseline | 50-67% of baseline | 50-67% reduction |

**Application to Functions**: If function exists in multiple commands, extract to library for single source of truth.

#### Pattern 3: Workflow-Specific Context Injection
**Source**: Multiple files (behavioral-injection.md, command-development-guide.md)

**Pattern**: Commands inject workflow-specific context, not behavioral duplication:

```yaml
Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH}
    - Project Standards: ${STANDARDS_FILE}
  "
}
```

**Analogy for Functions**:
- Workflow-specific logic → Inline function in command
- Reusable utility logic → Library function with parameters

## Recommendations

### Recommendation 1: Add Explicit Guidance for Utility Functions

**Problem**: Standards define structural templates vs behavioral content, but do not address small utility functions (10-50 lines).

**Proposed Addition** to Command Architecture Standards:

```markdown
### Standard 13: Utility Function Placement

**Command-Specific Utility Functions** (INLINE):
- Single-use functions specific to one command's workflow
- Functions using command-specific variables/state
- Functions <50 lines that aid command readability
- Functions called only within one command file

**Examples**:
- display_brief_summary() in /supervise (workflow completion messages)
- validate_plan_structure() in /plan (plan-specific validation)

**Reusable Utility Functions** (EXTRACT TO LIBRARY):
- Deterministic operations used by 2+ commands
- Functions providing standardized operations (location detection, parsing)
- Functions enhancing performance (caching, optimization)
- Functions managing shared state (checkpoints, logs)

**Examples**:
- perform_location_detection() in unified-location-detection.sh
- extract_report_metadata() in metadata-extraction.sh
- save_checkpoint() in checkpoint-utils.sh

**Decision Criterion**: Apply "If I change this, where do I update it?" test
- "Only in this command" → INLINE
- "In multiple commands" → EXTRACT to library
```

### Recommendation 2: Document Inline Function Best Practices

**Add section** to Command Development Guide:

```markdown
### Inline Function Guidelines

**When to Define Functions Inline**:
1. Function is command-specific workflow logic
2. Function size is <50 lines
3. Function uses command-scoped variables
4. Function is called only within this command

**Inline Function Structure**:
```bash
# Define <function_name> inline
# (Purpose: brief explanation)
function_name() {
  # Implementation
}
```

**Comment Requirement**: Inline functions MUST include comment explaining:
1. Why function is inline (not extracted)
2. Purpose of function
3. Dependencies on command-specific state (if any)

**Example**:
```bash
# Define display_brief_summary inline
# (Command-specific: Uses $WORKFLOW_SCOPE from /supervise workflow detection)
display_brief_summary() {
  case "$WORKFLOW_SCOPE" in
    research-only) echo "Research complete" ;;
    # ...
  esac
}
```
```

### Recommendation 3: Add Refactoring Decision Tree

**Create quick reference** in `.claude/docs/quick-reference/function-placement-decision-tree.md`:

```
Should this function be inline or in a library?

START: I have a function to add
│
├─ Is this function used in multiple commands?
│  │
│  ├─ YES → EXTRACT to .claude/lib/[category]-utils.sh
│  │         (Example: location detection, metadata extraction)
│  │
│  └─ NO → Continue...
│
├─ Is this function >50 lines?
│  │
│  ├─ YES → Consider extracting to library for maintainability
│  │         (Even if single-use, large functions improve readability)
│  │
│  └─ NO → Continue...
│
├─ Does this function use command-specific variables?
│  │
│  ├─ YES → INLINE in command file
│  │         (Example: display_brief_summary uses $WORKFLOW_SCOPE)
│  │
│  └─ NO → Continue...
│
├─ Is this function deterministic and testable?
│  │
│  ├─ YES → Consider library extraction for testing
│  │         (Unit tests easier for library functions)
│  │
│  └─ NO → INLINE in command file
│             (Workflow-specific logic)

RESULT:
- INLINE → Add comment explaining why inline
- LIBRARY → Add to appropriate .claude/lib/*.sh file
```

### Recommendation 4: Validation Script Enhancement

**Extend** `.claude/tests/validate_command_structure.sh` to check inline functions:

```bash
# Check 1: Inline functions have explanatory comments
INLINE_FUNCS=$(grep -n "^[a-z_]*() {" "$COMMAND_FILE" | wc -l)
FUNC_COMMENTS=$(grep -B1 "^[a-z_]*() {" "$COMMAND_FILE" | grep "^#" | wc -l)

if [ "$INLINE_FUNCS" -gt 0 ] && [ "$FUNC_COMMENTS" -lt "$INLINE_FUNCS" ]; then
  echo "WARNING: $COMMAND_FILE has $INLINE_FUNCS inline functions but only $FUNC_COMMENTS have comments"
  echo "Recommendation: Add comments explaining why functions are inline (not in library)"
fi

# Check 2: Inline functions are <50 lines
grep -n "^[a-z_]*() {" "$COMMAND_FILE" | while read FUNC_LINE; do
  # Extract function and count lines
  # If >50 lines, suggest library extraction
done

# Check 3: No duplicate function definitions across commands
# (Suggests need for library extraction)
```

## Implementation Guidance

### For `display_brief_summary` specifically:

**Current Status**: Inline function in `/supervise` command

**Decision**: **KEEP INLINE**

**Rationale**:
1. **Single-use**: Only used in `/supervise` command
2. **Workflow-specific**: Tightly coupled to `/supervise` workflow phases (research-only, research-and-plan, full-implementation, debug-only)
3. **Command-scoped variables**: Uses `$WORKFLOW_SCOPE`, `$REPORT_PATHS`, `$TOPIC_PATH` from supervise-specific detection
4. **Size**: ~25 lines (well under 50-line threshold)
5. **No reusability**: Other commands have different completion workflows

**Action Required**: Add explanatory comment per Recommendation 2:

```bash
# Define display_brief_summary inline
# (Command-specific: Uses $WORKFLOW_SCOPE from /supervise workflow detection.
#  Other commands have different completion messages. Not extracted to library.)
display_brief_summary() {
  # ... existing implementation
}
```

### For future function decisions:

Apply the decision tree from Recommendation 3:
1. Used in 2+ commands? → Extract to library
2. >50 lines? → Consider library extraction
3. Uses command-specific variables? → Inline with comment
4. Deterministic and testable? → Consider library for testing
5. Default: Inline with explanatory comment

## References

### Primary Sources

1. **Command Architecture Standards** (`.claude/docs/reference/command_architecture_standards.md`)
   - Lines 931-1125: Standard 1 (Executable Instructions Must Be Inline)
   - Lines 1242-1332: Standard 12 (Structural vs Behavioral Content Separation)
   - Lines 1334-1383: Refactoring Guidelines (When to Extract Content)
   - Lines 1120-1125: Annotation types (EXECUTION-CRITICAL, INLINE-REQUIRED)

2. **Template vs Behavioral Distinction** (`.claude/docs/reference/template-vs-behavioral-distinction.md`)
   - Lines 26-87: Structural Templates (MUST Be Inline)
   - Lines 88-139: Behavioral Content (MUST Be Referenced)
   - Lines 154-173: Decision Tree
   - Lines 183-194: Quantified Benefits

3. **Using Utility Libraries** (`.claude/docs/guides/using-utility-libraries.md`)
   - Lines 18-62: When to Use Libraries vs Agents
   - Lines 117-150: Pattern 1: Location Detection for Workflow Commands

4. **Command Development Guide** (`.claude/docs/guides/command-development-guide.md`)
   - Lines 1-200: Command architecture and tool selection

### Current Implementation Examples

5. **supervise.md Inline Function** (`.claude/commands/supervise.md`)
   - Line 326: `display_brief_summary()` definition
   - Lines 243-323: Library sourcing (9 utility libraries)

6. **plan.md Inline Function** (`.claude/commands/plan.md`)
   - Contains inline function definitions (pattern confirmation)

### Related Patterns

7. **Behavioral Injection Pattern** (`.claude/docs/concepts/patterns/behavioral-injection.md`)
   - Workflow-specific context injection examples

8. **Refactoring Methodology** (`.claude/docs/guides/refactoring-methodology.md`)
   - Command-specific logic vs library extraction criteria

## Metadata
- **Research Date**: 2025-10-26
- **Files Analyzed**: 15 documentation files, 2 command files
- **External Sources**: None (codebase-only research)
- **Standards Gap Identified**: Utility function placement (10-50 lines)
- **Recommendation Status**: 4 actionable recommendations provided

---
*Report generated: 2025-10-26*
*Research Specialist Agent*
