# Phase 1: Standard 14 Compliance - Documentation Extraction

## Metadata
- **Phase Number**: 1
- **Dependencies**: []
- **Complexity**: High (8/10)
- **Estimated Duration**: 2-3 hours
- **Parent Plan**: 002_plan_command_polish_and_production_readiness.md

## Objective

Extract comprehensive documentation from plan.md (985 lines) to a dedicated guide file, reducing the command file to <250 lines while preserving all functionality. This aligns with Standard 14 (executable/documentation separation) and improves maintainability.

## Architecture Overview

```
BEFORE (Level 0 - Monolithic):
plan.md (985 lines)
├── Phase explanations (400+ lines)
├── Bash execution blocks (300+ lines)
├── Inline comments (200+ lines)
└── Examples and rationale (85+ lines)

AFTER (Level 0 - Separated):
plan.md (≤250 lines)                 plan-command-guide.md (2000+ lines)
├── Bash execution blocks            ├── Overview and purpose
├── Essential markers                ├── Usage examples
├── Standard N tags                  ├── Phase explanations
└── Guide references (§X.Y)          ├── Research delegation
                                     ├── Validation process
                                     ├── Troubleshooting
                                     └── API reference
```

## Design Decisions

### Content Classification Strategy

**Retention Criteria (Keep in plan.md)**:
1. All ````bash` code blocks (execution logic)
2. `EXECUTE NOW`, `YOU MUST`, `STANDARD N` markers (behavioral enforcement)
3. Error diagnostic templates (operational feedback)
4. Fail-fast validation checks (correctness verification)
5. Agent invocation markers (workflow orchestration)

**Extraction Criteria (Move to guide)**:
1. Multi-paragraph explanations of "why"
2. Conceptual overviews (e.g., "Research delegation enables...")
3. Architecture diagrams and workflows
4. Usage examples and pattern descriptions
5. Detailed Standard N rationale (keep only tags)
6. Troubleshooting scenarios and solutions

### Cross-Reference Pattern

**Command → Guide**:
```bash
# See plan-command-guide.md §3.2 for complexity scoring algorithm
```

**Guide → Command**:
```markdown
### 3.2 Complexity Scoring

The LLM classification process (plan.md lines 187-299) assigns a complexity score...
```

## Stage 1: Content Analysis and Classification

### Task 1.1: Inventory Current Content

**Objective**: Generate comprehensive line-by-line inventory of plan.md content

**Implementation**:
```bash
#!/bin/bash
# Content inventory script

PLAN_FILE="/home/benjamin/.config/.claude/commands/plan.md"
OUTPUT_FILE="/tmp/plan_content_inventory.md"

echo "# Plan.md Content Inventory" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Generated: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Analyze content by type
echo "## Content Analysis" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Count bash blocks
BASH_BLOCKS=$(grep -c '^```bash' "$PLAN_FILE")
echo "- Bash code blocks: $BASH_BLOCKS" >> "$OUTPUT_FILE"

# Count lines in bash blocks
BASH_LINES=0
IN_BASH=false
while IFS= read -r line; do
  if [[ "$line" =~ ^\`\`\`bash ]]; then
    IN_BASH=true
  elif [[ "$line" =~ ^\`\`\` ]] && [ "$IN_BASH" = true ]; then
    IN_BASH=false
  elif [ "$IN_BASH" = true ]; then
    ((BASH_LINES++))
  fi
done < "$PLAN_FILE"
echo "- Lines in bash blocks: $BASH_LINES" >> "$OUTPUT_FILE"

# Count comment lines (lines starting with #)
COMMENT_LINES=$(grep -c '^#' "$PLAN_FILE" || echo "0")
echo "- Comment/heading lines: $COMMENT_LINES" >> "$OUTPUT_FILE"

# Count Standard N references
STANDARD_REFS=$(grep -c 'STANDARD [0-9]' "$PLAN_FILE" || echo "0")
echo "- Standard N references: $STANDARD_REFS" >> "$OUTPUT_FILE"

# Count EXECUTE NOW markers
EXECUTE_MARKERS=$(grep -c 'EXECUTE NOW' "$PLAN_FILE" || echo "0")
echo "- EXECUTE NOW markers: $EXECUTE_MARKERS" >> "$OUTPUT_FILE"

# Count YOU MUST markers
MUST_MARKERS=$(grep -c 'YOU MUST' "$PLAN_FILE" || echo "0")
echo "- YOU MUST markers: $MUST_MARKERS" >> "$OUTPUT_FILE"

# Total lines
TOTAL_LINES=$(wc -l < "$PLAN_FILE")
echo "- Total lines: $TOTAL_LINES" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Estimate extractable content
NON_CODE_LINES=$((TOTAL_LINES - BASH_LINES))
EXTRACTABLE_ESTIMATE=$((NON_CODE_LINES * 70 / 100))  # Assume 70% extractable

echo "## Extraction Estimate" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "- Estimated extractable lines: $EXTRACTABLE_ESTIMATE" >> "$OUTPUT_FILE"
echo "- Estimated retained lines: $((TOTAL_LINES - EXTRACTABLE_ESTIMATE))" >> "$OUTPUT_FILE"
echo "- Target: ≤250 lines" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Phase-by-phase breakdown
echo "## Phase-by-Phase Breakdown" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

awk '
  /^## Phase [0-9]/ {
    if (phase != "") {
      print "- " phase ": " count " lines"
    }
    phase = $0
    count = 0
    next
  }
  /^## / {
    if (phase != "") {
      print "- " phase ": " count " lines"
      phase = ""
      count = 0
    }
  }
  { if (phase != "") count++ }
  END {
    if (phase != "") {
      print "- " phase ": " count " lines"
    }
  }
' "$PLAN_FILE" >> "$OUTPUT_FILE"

echo ""
echo "Inventory saved to: $OUTPUT_FILE"
cat "$OUTPUT_FILE"
```

**Expected Output**:
```
Content Analysis:
- Bash code blocks: 7
- Lines in bash blocks: 650
- Comment/heading lines: 45
- Standard N references: 15
- EXECUTE NOW markers: 8
- YOU MUST markers: 0
- Total lines: 985

Extraction Estimate:
- Estimated extractable lines: 234
- Estimated retained lines: 751
- Target: ≤250 lines

Phase-by-Phase Breakdown:
- Phase 0: 165 lines
- Phase 1: 112 lines
- Phase 1.5: 240 lines
- Phase 2: 50 lines
- Phase 3: 165 lines
- Phase 4: 118 lines
- Phase 5: 35 lines
- Phase 6: 50 lines
```

### Task 1.2: Create Content Classification Map

**Objective**: Tag every section with KEEP/EXTRACT decision

**Implementation**:
```bash
#!/bin/bash
# Create classification map

PLAN_FILE="/home/benjamin/.config/.claude/commands/plan.md"
MAP_FILE="/tmp/plan_classification_map.json"

# Generate classification map as JSON
cat > "$MAP_FILE" << 'EOF'
{
  "sections": [
    {
      "name": "Frontmatter (lines 1-16)",
      "decision": "KEEP",
      "reason": "Metadata required for command discovery"
    },
    {
      "name": "Phase 0 heading (lines 17-19)",
      "decision": "KEEP",
      "reason": "Phase structure preserved"
    },
    {
      "name": "Phase 0 explanation (lines 20-21)",
      "decision": "EXTRACT",
      "reason": "Detailed explanation → guide §4.1"
    },
    {
      "name": "Phase 0 bash block (lines 22-184)",
      "decision": "KEEP",
      "reason": "Execution logic (core functionality)"
    },
    {
      "name": "Phase 1 heading (lines 186-188)",
      "decision": "KEEP",
      "reason": "Phase structure preserved"
    },
    {
      "name": "Phase 1 explanation (lines 189-190)",
      "decision": "EXTRACT",
      "reason": "Detailed explanation → guide §4.2"
    },
    {
      "name": "Phase 1 bash block (lines 191-299)",
      "decision": "KEEP",
      "reason": "Execution logic (LLM classification)"
    },
    {
      "name": "Phase 1.5 heading (lines 301-303)",
      "decision": "KEEP",
      "reason": "Phase structure preserved"
    },
    {
      "name": "Phase 1.5 explanation (lines 304-305)",
      "decision": "EXTRACT",
      "reason": "Detailed explanation → guide §5.1"
    },
    {
      "name": "Phase 1.5 bash block (lines 306-548)",
      "decision": "KEEP",
      "reason": "Execution logic (research delegation)"
    },
    {
      "name": "Phase 2 heading (lines 550-552)",
      "decision": "KEEP",
      "reason": "Phase structure preserved"
    },
    {
      "name": "Phase 2 bash block (lines 553-602)",
      "decision": "KEEP",
      "reason": "Execution logic (standards discovery)"
    },
    {
      "name": "Phase 3 heading (lines 604-606)",
      "decision": "KEEP",
      "reason": "Phase structure preserved"
    },
    {
      "name": "Phase 3 bash block (lines 607-768)",
      "decision": "KEEP",
      "reason": "Execution logic (plan creation)"
    },
    {
      "name": "Phase 4 heading (lines 770-772)",
      "decision": "KEEP",
      "reason": "Phase structure preserved"
    },
    {
      "name": "Phase 4 bash block (lines 773-890)",
      "decision": "KEEP",
      "reason": "Execution logic (validation)"
    },
    {
      "name": "Phase 5 heading (lines 892-894)",
      "decision": "KEEP",
      "reason": "Phase structure preserved"
    },
    {
      "name": "Phase 5 bash block (lines 895-931)",
      "decision": "KEEP",
      "reason": "Execution logic (expansion eval)"
    },
    {
      "name": "Phase 6 heading (lines 933-935)",
      "decision": "KEEP",
      "reason": "Phase structure preserved"
    },
    {
      "name": "Phase 6 bash block (lines 936-981)",
      "decision": "KEEP",
      "reason": "Execution logic (presentation)"
    },
    {
      "name": "Footer (lines 983-985)",
      "decision": "KEEP",
      "reason": "Troubleshooting reference"
    }
  ],
  "inline_comments": {
    "detailed_explanations": "EXTRACT",
    "standard_rationale": "EXTRACT (keep tags only)",
    "execution_markers": "KEEP (EXECUTE NOW, YOU MUST)",
    "error_templates": "KEEP (DIAGNOSTIC, FIX)",
    "verification_checks": "KEEP (STANDARD N: Verify...)"
  },
  "extraction_targets": {
    "guide_section_4_1": "Phase 0 orchestrator initialization explanation",
    "guide_section_4_2": "Phase 1 feature analysis and LLM classification",
    "guide_section_5_1": "Phase 1.5 research delegation workflow",
    "guide_section_5_2": "Topic generation logic and keyword analysis",
    "guide_section_6_1": "Phase 2 standards discovery process",
    "guide_section_7_1": "Phase 3 plan creation behavioral injection",
    "guide_section_8_1": "Phase 4 validation library integration",
    "guide_section_9_1": "Phase 5 expansion evaluation criteria",
    "guide_section_10_1": "Phase 6 presentation and next steps"
  }
}
EOF

echo "Classification map created: $MAP_FILE"
jq '.' "$MAP_FILE"
```

**Expected Output**: JSON map with KEEP/EXTRACT decisions for all sections

## Stage 2: Guide File Creation

### Task 2.1: Initialize Guide Structure

**Objective**: Create plan-command-guide.md skeleton with all sections

**Implementation**:
```bash
#!/bin/bash
# Initialize guide file

GUIDE_FILE="/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md"
GUIDE_DIR=$(dirname "$GUIDE_FILE")

# Ensure directory exists
mkdir -p "$GUIDE_DIR"

cat > "$GUIDE_FILE" << 'EOF'
# Plan Command User Guide

**Version**: 1.0
**Last Updated**: 2025-11-16
**Command File**: `.claude/commands/plan.md`

## Table of Contents

1. [Overview and Purpose](#1-overview-and-purpose)
2. [Quick Start](#2-quick-start)
3. [Usage Examples](#3-usage-examples)
4. [Phase-by-Phase Execution](#4-phase-by-phase-execution)
5. [Research Delegation](#5-research-delegation)
6. [Plan Validation](#6-plan-validation)
7. [Standards Compliance](#7-standards-compliance)
8. [Expansion Evaluation](#8-expansion-evaluation)
9. [Troubleshooting](#9-troubleshooting)
10. [Advanced Topics](#10-advanced-topics)
11. [Agent Integration](#11-agent-integration)
12. [API Reference](#12-api-reference)

---

## 1. Overview and Purpose

### 1.1 What is /plan?

The `/plan` command is an intelligent implementation plan generator that creates detailed, standards-compliant project plans from natural language feature descriptions.

**Key Capabilities**:
- **LLM-driven complexity analysis** (1-10 scale)
- **Automatic research delegation** for complex features (complexity ≥7)
- **Standards-aware plan generation** (CLAUDE.md integration)
- **8-function validation library** (metadata, dependencies, testing, docs)
- **Expansion evaluation** (recommends /expand when beneficial)
- **Workflow state persistence** (resume-safe, crash-resistant)

**Architecture**:
```
User Input → Feature Analysis → Research (conditional) → Plan Creation → Validation → Presentation
     ↓              ↓                    ↓                     ↓              ↓            ↓
  Feature      Complexity           1-4 Reports           Plan File      8 Checks     Next Steps
Description    Score 1-10          (parallel agents)      (Level 0)    (pass/warn)   (implement/expand)
```

### 1.2 When to Use /plan

**Use /plan when**:
- Starting a new feature implementation
- Need structured approach for complex changes
- Want research-backed architecture decisions
- Require standards-compliant planning

**Use /implement instead when**:
- Plan already exists (implements existing plan)

**Use /expand instead when**:
- Plan exists but needs phase/stage breakdown

**Use /research instead when**:
- Only need investigation, not implementation plan

---

## 2. Quick Start

### 2.1 Basic Usage

```bash
/plan "Add user authentication with OAuth2"
```

**Output**:
```
✓ Phase 0: Orchestrator initialized
  Project: /home/user/project
  Topic: /home/user/project/.claude/specs/728_add_user_authentication_with_oauth2
  Plan: /home/user/project/.claude/specs/728_add_user_authentication_with_oauth2/plans/728_implementation_plan.md

PROGRESS: Analyzing feature complexity...
  Complexity: 7/10
  Suggested phases: 5
  Requires research: true

PROGRESS: Complex feature detected - delegating research
  Generated 3 research topics
  ...

PLAN CREATED SUCCESSFULLY
========================================

Feature: Add user authentication with OAuth2
Plan location: /home/user/project/.claude/specs/728_add_user_authentication_with_oauth2/plans/728_implementation_plan.md
Complexity: 7/10
Phases: 5
Tasks: 23

Next steps:
  1. Review plan: cat [plan-path]
  2. Implement: /implement [plan-path]
```

### 2.2 With Research Reports

```bash
/plan "Refactor plugin system" /path/to/architecture_analysis.md /path/to/best_practices.md
```

Pre-existing research reports are integrated into plan creation.

---

## 3. Usage Examples

### 3.1 Simple Feature (No Research)

**Command**:
```bash
/plan "Add button to navigation bar"
```

**Behavior**:
- Complexity: 2/10
- Research: Not triggered (complexity <7)
- Phases: 3
- Duration: 5-10 minutes

**Generated Plan Preview**:
```markdown
### Phase 1: Component Creation
- [ ] Create button component
- [ ] Add to navigation bar
- [ ] Style according to design system

### Phase 2: Testing
- [ ] Write unit tests
- [ ] Verify accessibility

### Phase 3: Integration
- [ ] Update documentation
- [ ] Create pull request
```

### 3.2 Complex Feature (With Research)

**Command**:
```bash
/plan "Migrate authentication system to OAuth2 with multi-provider support"
```

**Behavior**:
- Complexity: 9/10
- Research: Triggered (4 topics)
- Phases: 7
- Duration: 30-45 minutes (including research)

**Research Topics Generated**:
1. Current architecture patterns and design principles
2. Migration strategies and refactoring best practices
3. Integration patterns and API design
4. Implementation approaches for OAuth2 multi-provider

**Generated Plan Preview**:
```markdown
### Phase 0: Architecture Analysis
- [ ] Review current authentication system
- [ ] Identify OAuth2 provider requirements
- [ ] Design provider abstraction layer

### Phase 1: OAuth2 Core Implementation
- [ ] Implement OAuth2 client library
- [ ] Create provider interface
- [ ] Add token management

...
```

### 3.3 Multi-word Feature with Special Characters

**Quoting Requirements**:
```bash
# Correct (quoted)
/plan "Implement real-time sync (WebSockets) with retry logic"

# Incorrect (will fail)
/plan Implement real-time sync (WebSockets) with retry logic
```

**Special Character Handling**:
- Parentheses: Supported in quotes
- Hyphens: Supported
- Ampersands (&): Must be quoted
- Pipes (|): Must be quoted

---

## 4. Phase-by-Phase Execution

### 4.1 Phase 0: Orchestrator Initialization

**Purpose**: Set up execution environment and pre-calculate all artifact paths

**Implementation**: `plan.md` lines 17-184

**Key Operations**:
1. Detect project directory (CLAUDE_PROJECT_DIR)
2. Source 7 libraries in dependency order:
   - workflow-state-machine.sh
   - state-persistence.sh
   - error-handling.sh
   - verification-helpers.sh
   - unified-location-detection.sh
   - complexity-utils.sh
   - metadata-extraction.sh
3. Initialize workflow state file (plan_$$)
4. Parse and validate arguments
5. Allocate topic directory atomically
6. Pre-calculate PLAN_PATH before agent invocation
7. Persist paths to state file

**Why Pre-calculation Matters**:
- Ensures absolute paths (Standard 13 compliance)
- Enables behavioral injection (agents know output path)
- Prevents race conditions in parallel operations
- Supports fail-fast verification

**Error Handling**:
```bash
# Library sourcing failure
ERROR: Failed to source workflow-state-machine.sh
DIAGNOSTIC: Required for state management

# Absolute path validation
ERROR: PLAN_PATH is not absolute: relative/path/plan.md
DIAGNOSTIC: This is a programming error in path calculation
```

### 4.2 Phase 1: Feature Analysis (LLM Classification)

**Purpose**: Analyze feature complexity using LLM with heuristic fallback

**Implementation**: `plan.md` lines 186-299

**LLM Classification Process**:
1. Design analysis prompt with complexity scoring guide
2. Invoke haiku-4 model (fast, cost-effective)
3. Request JSON output:
   ```json
   {
     "estimated_complexity": 7,
     "suggested_phases": 5,
     "template_type": "architecture",
     "keywords": ["migrate", "oauth2", "integration"],
     "requires_research": true
   }
   ```
4. Parse JSON response
5. Cache results to workflow state

**Complexity Scoring Scale**:
- **1-3**: Simple features (add button, fix typo, update config)
- **4-6**: Moderate features (new endpoint, UI component, data model)
- **7-8**: Complex features (authentication system, API integration)
- **9-10**: Major features (microservices migration, architecture redesign)

**Heuristic Fallback Algorithm**:

When LLM unavailable, use keyword + length scoring:

```bash
# Keyword scoring
if [[ "$FEATURE" =~ architecture|migrate|redesign ]]; then
  KEYWORD_SCORE=8
elif [[ "$FEATURE" =~ refactor|integrate|system ]]; then
  KEYWORD_SCORE=6
elif [[ "$FEATURE" =~ implement|create|build ]]; then
  KEYWORD_SCORE=4
else
  KEYWORD_SCORE=2
fi

# Length scoring
WORD_COUNT=$(echo "$FEATURE" | wc -w)
if [ "$WORD_COUNT" -gt 40 ]; then
  LENGTH_SCORE=3
elif [ "$WORD_COUNT" -gt 20 ]; then
  LENGTH_SCORE=2
elif [ "$WORD_COUNT" -gt 10 ]; then
  LENGTH_SCORE=1
else
  LENGTH_SCORE=0
fi

# Combined score
COMPLEXITY=$((KEYWORD_SCORE + LENGTH_SCORE))
```

**Research Delegation Triggers**:
- Complexity ≥7
- Architecture keywords present
- Migration/refactoring keywords present

**Output**:
```
✓ Phase 1: Feature analysis complete
  Complexity: 7/10
  Suggested phases: 5
  Requires research: true
```

[Continue with remaining sections...]

---

## 12. API Reference

### 12.1 Command-Line Interface

```
/plan <feature-description> [report-path1] [report-path2] ...
```

**Arguments**:
- `<feature-description>` (required): Natural language feature description
  - Type: String
  - Quoting: Required if contains spaces or special characters
  - Max length: 500 characters recommended

- `[report-pathN]` (optional): Absolute paths to research reports
  - Type: Absolute file path
  - Format: Must end with .md
  - Validation: Must exist and be readable
  - Limit: No hard limit (practical: 2-4 reports)

**Exit Codes**:
- `0`: Success (plan created and validated)
- `1`: Error (validation failed, file creation failed, invalid arguments)

**Examples**:
```bash
# Success case
/plan "Add OAuth2 authentication"
echo $?  # Output: 0

# Error case (relative path)
/plan "Feature" relative/path/report.md
echo $?  # Output: 1
```

### 12.2 Environment Variables

**CLAUDE_PROJECT_DIR** (optional):
- Override project directory detection
- Default: Git root detection
- Example: `export CLAUDE_PROJECT_DIR=/home/user/project`

**CLAUDE_SPECS_ROOT** (optional, testing only):
- Override specs directory location
- Default: `$CLAUDE_PROJECT_DIR/.claude/specs`
- Example: `export CLAUDE_SPECS_ROOT=/tmp/test_specs_$$`

### 12.3 State File Format

**Location**: `/tmp/plan_$$/workflow_state.json`

**Structure**:
```json
{
  "FEATURE_DESCRIPTION": "Add OAuth2 authentication",
  "TOPIC_DIR": "/home/user/project/.claude/specs/728_add_oauth2_authentication",
  "TOPIC_NUMBER": "728",
  "PLAN_PATH": "/home/user/project/.claude/specs/728_add_oauth2_authentication/plans/728_implementation_plan.md",
  "SPECS_DIR": "/home/user/project/.claude/specs",
  "PROJECT_ROOT": "/home/user/project",
  "ESTIMATED_COMPLEXITY": "7",
  "SUGGESTED_PHASES": "5",
  "REQUIRES_RESEARCH": "true",
  "ANALYSIS_JSON": "{...}",
  "REPORT_PATHS_JSON": "[...]",
  "RESEARCH_METADATA_JSON": "[...]",
  "CLAUDE_MD": "/home/user/project/CLAUDE.md",
  "VALIDATION_REPORT": "{...}"
}
```

### 12.4 Validation Report Schema

**Generated by**: `validate-plan.sh` (Phase 4)

**Structure**:
```json
{
  "summary": {
    "valid": true,
    "errors": 0,
    "warnings": 2
  },
  "metadata": {
    "valid": true,
    "missing": [],
    "present": ["Date", "Feature", "Scope", "Estimated Phases", "Estimated Hours", "Structure Level", "Complexity Score", "Standards File"]
  },
  "standards": {
    "valid": false,
    "issues": ["No reference to CLAUDE.md found in plan"]
  },
  "tests": {
    "valid": true,
    "issues": []
  },
  "documentation": {
    "valid": false,
    "issues": ["No documentation update tasks found"]
  },
  "dependencies": {
    "valid": true,
    "issues": []
  }
}
```

---

**End of Guide**

For implementation details, see: `.claude/commands/plan.md`
For validation library source, see: `.claude/lib/validate-plan.sh`
For testing protocols, see: CLAUDE.md → Testing Protocols
EOF

echo "Guide skeleton created: $GUIDE_FILE"
echo "File size: $(wc -c < "$GUIDE_FILE") bytes"
```

**Expected Output**: Guide file with ~2000+ lines after full content population

### Task 2.2: Extract Documentation Content

**Objective**: Move documentation from plan.md to guide.md with context preservation

See classification map (Task 1.2) for extraction targets.

**Implementation**: Manual extraction with cross-reference insertion (see Task 3.1)

## Stage 3: Command File Reduction

### Task 3.1: Remove Extracted Content from plan.md

**Objective**: Delete documentation sections and replace with guide references

**Implementation**:
```bash
#!/bin/bash
# Reduce plan.md by removing documentation

PLAN_FILE="/home/benjamin/.config/.claude/commands/plan.md"
BACKUP_FILE="${PLAN_FILE}.backup_$(date +%Y%m%d_%H%M%S)"

# Create backup
cp "$PLAN_FILE" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Example reduction (Phase 0 explanation)
# BEFORE:
# ## Phase 0: Orchestrator Initialization and Path Pre-Calculation
#
# **EXECUTE NOW**: Initialize orchestrator state, detect project directory, source libraries in correct order, pre-calculate all artifact paths before any agent invocations.

# AFTER:
# ## Phase 0: Orchestrator Initialization and Path Pre-Calculation
#
# **EXECUTE NOW**: Initialize orchestrator. See plan-command-guide.md §4.1 for details.

# Use Edit tool for each reduction
# This is a template for the Edit operation
```

**Reduction Strategy**:
1. Keep phase headings (structure)
2. Keep first sentence of explanations
3. Replace detailed explanations with "See guide §X.Y"
4. Keep all bash blocks unchanged
5. Keep all EXECUTE NOW, YOU MUST, STANDARD N markers
6. Keep error diagnostic templates

### Task 3.2: Minimize Inline Comments

**Objective**: Reduce inline comment verbosity while preserving essential markers

**Before**:
```bash
# STANDARD 13: Detect project directory using CLAUDE_PROJECT_DIR (git-based detection)
# This uses the detect-project-dir.sh library which implements git root detection
# with fallback to current directory. The CLAUDE_PROJECT_DIR variable is set
# globally and available to all subsequent library functions.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

**After**:
```bash
# STANDARD 13: Detect project directory (see guide §4.1.2)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

**Retention Rules**:
- Keep: `STANDARD N: <one-line summary>`
- Keep: `EXECUTE NOW`, `YOU MUST`, `CRITICAL`
- Keep: `DIAGNOSTIC:`, `FIX:`, `ERROR:`
- Remove: Multi-line explanations
- Replace: Long comments with guide references

### Task 3.3: Add Cross-References

**Objective**: Insert bidirectional links between command and guide

**Command → Guide References**:
```bash
# See plan-command-guide.md §3.2 for complexity scoring algorithm
# See plan-command-guide.md §5.1 for research delegation workflow
# See plan-command-guide.md §6.1 for validation process
```

**Guide → Command References**:
```markdown
### 4.1 Phase 0: Orchestrator Initialization

**Implementation**: `plan.md` lines 17-184

The orchestrator initialization phase...
```

**Verification**:
```bash
#!/bin/bash
# Verify cross-references

PLAN_FILE="/home/benjamin/.config/.claude/commands/plan.md"
GUIDE_FILE="/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md"

# Count command → guide references
CMD_TO_GUIDE=$(grep -c 'plan-command-guide.md' "$PLAN_FILE" || echo "0")
echo "Command → Guide references: $CMD_TO_GUIDE"

# Count guide → command references
GUIDE_TO_CMD=$(grep -c 'plan.md' "$GUIDE_FILE" || echo "0")
echo "Guide → Command references: $GUIDE_TO_CMD"

# Target: ≥5 each direction
if [ "$CMD_TO_GUIDE" -ge 5 ] && [ "$GUIDE_TO_CMD" -ge 5 ]; then
  echo "✓ Cross-reference target met"
else
  echo "✗ Need more cross-references"
  echo "  Target: ≥5 each direction"
fi
```

## Stage 4: Verification and Testing

### Task 4.1: Line Count Verification

**Objective**: Confirm command file ≤250 lines

**Implementation**:
```bash
#!/bin/bash
# Verify line count

PLAN_FILE="/home/benjamin/.config/.claude/commands/plan.md"

# Count total lines
TOTAL_LINES=$(wc -l < "$PLAN_FILE")

# Count non-blank lines
NON_BLANK=$(grep -cvE '^\s*$' "$PLAN_FILE" || echo "0")

# Count code lines (in bash blocks)
CODE_LINES=0
IN_BASH=false
while IFS= read -r line; do
  if [[ "$line" =~ ^\`\`\`bash ]]; then
    IN_BASH=true
  elif [[ "$line" =~ ^\`\`\` ]] && [ "$IN_BASH" = true ]; then
    IN_BASH=false
  elif [ "$IN_BASH" = true ]; then
    ((CODE_LINES++))
  fi
done < "$PLAN_FILE"

echo "Line Count Analysis:"
echo "  Total lines: $TOTAL_LINES"
echo "  Non-blank lines: $NON_BLANK"
echo "  Code lines (bash blocks): $CODE_LINES"
echo "  Documentation lines: $((NON_BLANK - CODE_LINES))"
echo ""
echo "Target: ≤250 lines"

if [ "$TOTAL_LINES" -le 250 ]; then
  echo "✓ PASS: Standard 14 compliance achieved"
  exit 0
else
  echo "✗ FAIL: Exceeds target by $((TOTAL_LINES - 250)) lines"
  echo "  Further reduction needed"
  exit 1
fi
```

### Task 4.2: Functionality Verification

**Objective**: Ensure no functionality lost during extraction

**Test Cases**:

1. **Basic invocation**:
```bash
/plan "Test feature for verification"
# Expected: Plan created successfully
```

2. **Complex feature (research trigger)**:
```bash
/plan "Migrate authentication to OAuth2 system"
# Expected: Research delegation triggered
```

3. **With report paths**:
```bash
/plan "Test feature" /path/to/report.md
# Expected: Report integrated
```

4. **Error handling**:
```bash
/plan ""  # Empty description
# Expected: ERROR: Feature description is required

/plan "Test" relative/path.md  # Relative path
# Expected: ERROR: REPORT_PATH must be absolute
```

**Verification Script**:
```bash
#!/bin/bash
# Functionality verification tests

PLAN_CMD="/home/benjamin/.config/.claude/commands/plan.md"
TEST_SPECS_ROOT="/tmp/test_plan_verification_$$"
export CLAUDE_SPECS_ROOT="$TEST_SPECS_ROOT"

cleanup() {
  rm -rf "$TEST_SPECS_ROOT"
}
trap cleanup EXIT

mkdir -p "$TEST_SPECS_ROOT"

echo "Functionality Verification Tests"
echo "================================"
echo ""

# Test 1: Basic invocation
echo "Test 1: Basic invocation"
if bash "$PLAN_CMD" "Test feature" 2>&1 | grep -q "PLAN CREATED SUCCESSFULLY"; then
  echo "  ✓ PASS"
else
  echo "  ✗ FAIL"
fi

# Test 2: Empty description error
echo "Test 2: Empty description error handling"
if bash "$PLAN_CMD" "" 2>&1 | grep -q "ERROR: Feature description is required"; then
  echo "  ✓ PASS"
else
  echo "  ✗ FAIL"
fi

# Test 3: Relative path rejection
echo "Test 3: Relative path rejection"
if bash "$PLAN_CMD" "Test" "relative/path.md" 2>&1 | grep -q "ERROR: REPORT_PATH must be absolute"; then
  echo "  ✓ PASS"
else
  echo "  ✗ FAIL"
fi

echo ""
echo "Verification complete"
```

### Task 4.3: Guide Completeness Check

**Objective**: Verify guide contains all extracted content

**Checklist**:
- [ ] Section 1: Overview and Purpose (complete)
- [ ] Section 2: Quick Start (complete)
- [ ] Section 3: Usage Examples (≥3 examples)
- [ ] Section 4: Phase-by-phase (all 7 phases documented)
- [ ] Section 5: Research Delegation (topic generation, parallel execution)
- [ ] Section 6: Plan Validation (8 validation functions)
- [ ] Section 7: Standards Compliance (Standard 0, 11, 12, 13, 15, 16)
- [ ] Section 8: Expansion Evaluation (criteria)
- [ ] Section 9: Troubleshooting (≥5 common issues)
- [ ] Section 10: Advanced Topics (≥3 topics)
- [ ] Section 11: Agent Integration (behavioral injection)
- [ ] Section 12: API Reference (CLI, env vars, schemas)

**Verification**:
```bash
#!/bin/bash
# Guide completeness check

GUIDE_FILE="/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md"

echo "Guide Completeness Check"
echo "========================"
echo ""

# Check section headings
SECTIONS=(
  "1. Overview and Purpose"
  "2. Quick Start"
  "3. Usage Examples"
  "4. Phase-by-Phase Execution"
  "5. Research Delegation"
  "6. Plan Validation"
  "7. Standards Compliance"
  "8. Expansion Evaluation"
  "9. Troubleshooting"
  "10. Advanced Topics"
  "11. Agent Integration"
  "12. API Reference"
)

MISSING=0
for section in "${SECTIONS[@]}"; do
  if grep -q "## $section" "$GUIDE_FILE"; then
    echo "✓ $section"
  else
    echo "✗ $section (MISSING)"
    ((MISSING++))
  fi
done

echo ""
if [ "$MISSING" -eq 0 ]; then
  echo "✓ All sections present"
else
  echo "✗ $MISSING sections missing"
fi

# Check file size (should be ≥2000 lines for comprehensive guide)
LINE_COUNT=$(wc -l < "$GUIDE_FILE")
echo ""
echo "Guide size: $LINE_COUNT lines"
if [ "$LINE_COUNT" -ge 2000 ]; then
  echo "✓ Comprehensive documentation (≥2000 lines)"
else
  echo "⚠ May need more detail ($((2000 - LINE_COUNT)) lines below target)"
fi
```

## Error Handling

### Expected Errors

**E1: Line count still exceeds 250**:
```
ERROR: Command file exceeds target
Current: 275 lines
Target: ≤250 lines
Overage: 25 lines

DIAGNOSTIC: Further reduction needed
FIX: Review inline comments for additional extraction opportunities
```

**Recovery**:
1. Identify longest inline comments
2. Extract to guide with references
3. Re-verify line count

**E2: Functionality broken after extraction**:
```
ERROR: Plan command execution failed
Test case: Basic invocation
Expected: PLAN CREATED SUCCESSFULLY
Actual: ERROR: Failed to source workflow-state-machine.sh

DIAGNOSTIC: Library sourcing may have been affected
FIX: Verify bash block integrity
```

**Recovery**:
1. Restore from backup: `cp plan.md.backup_* plan.md`
2. Re-extract more carefully
3. Test after each extraction

**E3: Cross-references insufficient**:
```
WARNING: Cross-reference target not met
Command → Guide: 3 references
Guide → Command: 2 references
Target: ≥5 each direction

DIAGNOSTIC: Need more bidirectional links
FIX: Add guide references to complex sections
```

**Recovery**:
1. Identify sections without references
2. Add "See guide §X.Y" to plan.md
3. Add "Implementation: plan.md lines X-Y" to guide
4. Re-verify

## Performance Considerations

**Extraction Time**: 1-2 hours for careful content migration
**Testing Time**: 30 minutes for verification
**Total Time**: 2-3 hours (within estimate)

**Optimization Strategies**:
1. Use classification map (Task 1.2) to batch extractions
2. Extract phase-by-phase (reduces context switching)
3. Verify after each phase extraction (early error detection)
4. Use backup files for rollback safety

## Spec Updater Checklist

After Phase 1 completion:

- [ ] Update parent plan with phase completion status
- [ ] Mark all Phase 1 tasks as [x] in this file
- [ ] Verify bidirectional cross-references functional
- [ ] Update plan metadata with completion timestamp
- [ ] Create git commit: `refactor(726): extract documentation per Standard 14`

## Phase Completion Checklist

**MANDATORY STEPS AFTER ALL PHASE TASKS COMPLETE**:

- [ ] **Mark all phase tasks as [x]** in this file
- [ ] **Update parent plan** with phase completion status
  - Use spec-updater: `mark_phase_complete` function
  - Verify hierarchy synchronization
- [ ] **Run full test suite**: Per Testing Protocols in CLAUDE.md
  - Verify all tests passing
  - Debug failures before proceeding
- [ ] **Create git commit** with standardized message
  - Format: `refactor(726): complete Phase 1 - Standard 14 Compliance`
  - Include files modified in this phase
  - Verify commit created successfully
- [ ] **Create checkpoint**: Save progress to `.claude/data/checkpoints/`
  - Include: Plan path, phase number, completion status
  - Timestamp: ISO 8601 format
- [ ] **Invoke spec-updater**: Update cross-references and summaries
  - Verify bidirectional links intact
  - Update plan metadata with completion timestamp
