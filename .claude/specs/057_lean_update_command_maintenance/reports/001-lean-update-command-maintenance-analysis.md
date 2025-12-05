# /lean-update Command: Lean Project Maintenance Documentation Workflow Research

## Metadata
- **Date**: 2025-12-05
- **Agent**: research-specialist
- **Topic**: Lean project maintenance documentation update workflow
- **Report Type**: codebase analysis and workflow design
- **Research Complexity**: 3

## Executive Summary

This research analyzes the TODO cleanup workflow implemented in the ProofChecker Lean project (spec 040) and the /todo command from the .config project to design a comprehensive /lean-update command. The ProofChecker project maintains six interconnected maintenance documents (TODO.md, MAINTENANCE.md, SORRY_REGISTRY.md, IMPLEMENTATION_STATUS.md, KNOWN_LIMITATIONS.md, and CLAUDE.md) using a git-based history model. The /lean-update command should scan the Lean project for changes, update all maintenance documents systematically, and maintain bidirectional cross-references—extending beyond the single-file focus of /todo to provide holistic project documentation maintenance.

## Findings

### 1. ProofChecker Maintenance Document Ecosystem

**Analysis of Documentation/ProjectInfo/**:

The ProofChecker Lean project maintains a sophisticated four-document integration model documented in the spec 040 plan (lines 66-149):

1. **TODO.md** (Active Work, ~350 lines)
   - Overview with status summary
   - Quick links to related docs
   - High/Medium/Low priority tasks (active only)
   - Completion History section (git query examples)
   - Project References section
   - **Purpose**: Task tracking only, no completion history
   - **File**: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/TODO.md`

2. **SORRY_REGISTRY.md** (Technical Debt Bridge, ~100 lines)
   - Active placeholders with resolution context
   - Bidirectional links to IMPLEMENTATION_STATUS.md
   - Bidirectional links to KNOWN_LIMITATIONS.md
   - Bidirectional links to TODO.md
   - Module-by-module organization
   - **Purpose**: Track sorry placeholders in Lean code
   - **File**: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/Documentation/ProjectInfo/SORRY_REGISTRY.md`

3. **MAINTENANCE.md** (Workflow Documentation, ~200 lines)
   - Related Documentation section (links to all docs)
   - Task lifecycle (creation, active work, completion)
   - Git-based history queries
   - Documentation synchronization requirements
   - Sorry placeholder workflow
   - Priority classification guidelines
   - **Purpose**: Document maintenance workflow itself
   - **File**: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/Documentation/ProjectInfo/MAINTENANCE.md`

4. **IMPLEMENTATION_STATUS.md** (Macro Vision, 692 lines)
   - Module completion percentages (Syntax 100%, Metalogic 60%, etc.)
   - Sorry verification commands (canonical source)
   - "What Works" vs "What's Partial" categorization
   - Cross-references to TODO.md and SORRY_REGISTRY.md
   - **Purpose**: High-level module progress tracking
   - **File**: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/Documentation/ProjectInfo/IMPLEMENTATION_STATUS.md`

5. **KNOWN_LIMITATIONS.md** (Obstacles & Blockers, 109 lines)
   - Gaps requiring user awareness
   - Workarounds for current limitations
   - Architectural blockers
   - Cross-references to TODO.md and SORRY_REGISTRY.md
   - **Purpose**: User-facing limitation documentation
   - **File**: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/Documentation/ProjectInfo/KNOWN_LIMITATIONS.md`

6. **CLAUDE.md** (Project Configuration, 359 lines)
   - Project overview and essential commands
   - Project structure and documentation index
   - Development principles and quality standards
   - Quick reference to all maintenance documents
   - **Purpose**: Central project configuration for AI assistants
   - **File**: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/CLAUDE.md`

7. **README.md** (User Entry Point, ~35K lines)
   - Project vision and architecture overview
   - Installation and getting started
   - Theoretical foundations
   - Application domains
   - **Purpose**: Primary user-facing documentation
   - **File**: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/README.md`

**Cross-Reference Architecture** (from spec 040, lines 136-149):

```
Integration Philosophy: Each document maintains single responsibility with strategic cross-linking.

Information Flow:
                    ┌─────────────────┐
                    │   TODO.md       │
                    │  (Active Work)  │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
    ┌──────────────┐  ┌─────────────┐  ┌──────────────┐
    │ IMPL STATUS  │  │   SORRY      │  │   KNOWN      │
    │ (Module %)   │◄─┤  REGISTRY    │─►│ LIMITATIONS  │
    │              │  │ (Tech Debt)  │  │ (Gaps)       │
    └──────────────┘  └─────────────┘  └──────────────┘
            │                │                │
            └────────────────┼────────────────┘
                             │
                    ┌────────▼────────┐
                    │  MAINTENANCE.md │
                    │   (Workflow)    │
                    └─────────────────┘
```

### 2. /todo Command Analysis

**Command Structure** (from `/home/benjamin/.config/.claude/commands/todo.md`):

The /todo command provides a focused workflow for maintaining the .claude/TODO.md file:

**Key Features**:
1. **Default Mode**: Scan specs/ directories, classify plan status, update TODO.md
2. **Clean Mode** (--clean flag): Remove completed/abandoned projects after git commit
3. **7-Section Structure** (lines 36-93):
   - In Progress (active implementation, `[x]`)
   - Not Started (planned but not begun, `[ ]`)
   - Research (research-only projects, `[ ]`)
   - Saved (intentionally demoted, `[ ]`) - **PRESERVED manually**
   - Backlog (manual prioritization, `[ ]`) - **PRESERVED manually**
   - Abandoned (intentionally discontinued, `[x]` or `[~]`)
   - Completed (successfully finished, `[x]`) - **REGENERATED with today's date**

**Preservation Policy** (lines 63-85):
- Backlog and Saved sections are **manually curated** and never regenerated
- Content is extracted and preserved verbatim during updates
- All other sections are regenerated from filesystem scan

**Status Classification Algorithm** (lines 48-61):
1. **Primary**: Check plan metadata `Status:` field
2. **Fallback**: Analyze phase completion markers if Status missing

**Related Artifacts** (lines 87-93):
- Each plan entry includes related artifacts as indented bullets
- Reports: Analysis and research documents
- Summaries: Implementation summaries
- Format: `  - [Report|Summary]: {relative-path}`

**Block Structure** (lines 119-757):
- Block 1: Setup and Discovery (argument parsing, project scanning)
- Block 2a: Pre-Calculate Output Paths (hard barrier pattern)
- Block 2b: TODO.md Generation Execution (task delegation to todo-analyzer)
- Block 2c: TODO.md Semantic Verification (file existence, structure, preservation)
- Block 3: Atomic File Replace (backup and atomic replace with git snapshot)
- Block 4a-c: Clean Mode blocks (dry-run preview, cleanup execution, regeneration)
- Block 5: Standardized Completion Output

**Agent Delegation** (lines 419-463):
- Uses todo-analyzer agent via Task tool
- Pre-calculated output path pattern (hard barrier)
- Contract-based delegation (MUST receive paths, MUST create file)
- Verification after agent returns

### 3. Git-Based History Model

**Philosophy** (from MAINTENANCE.md, lines 16-36):

The ProofChecker project implements a git-based history model where:
- TODO.md contains only active work (300-400 lines vs 800+)
- Git commits preserve completion history permanently
- Spec summaries provide rich implementation details

**Benefits**:
1. Reduced Maintenance: No completion log to update after each task
2. Better Searchability: Git queries more powerful than table scanning
3. Permanent History: Commits never deleted, always available
4. Rich Context: Spec summaries provide 10-100x more detail
5. Single Responsibility: TODO.md focuses on planning, not history

**Completion History Queries** (from MAINTENANCE.md, lines 259+):
```bash
# Find completed tasks via git log
git log --all --grep="Complete Task" --oneline

# Find spec summaries for completed work
find .claude/specs -name "*summary*.md" -type f

# Search git history for specific feature
git log --all --grep="authentication" --oneline
```

### 4. Documentation Synchronization Workflow

**Decision Tree** (from MAINTENANCE.md, lines 136-160):

When a task completes, update files in this order:

| Order | File | Updates |
|-------|------|---------|
| 1 | Spec summaries | Create completion summary |
| 2 | IMPLEMENTATION_STATUS.md | Module %, sorry counts |
| 3 | KNOWN_LIMITATIONS.md | Remove fixed gaps |
| 4 | SORRY_REGISTRY.md | Remove resolved items |
| 5 | TODO.md | Remove task, update counts |
| 6 | Git commit | Comprehensive message |

**Decision Tree Logic**:
```
Is this about module completion %?
  -> IMPLEMENTATION_STATUS.md

Is this about a gap/limitation being fixed?
  -> KNOWN_LIMITATIONS.md (remove entry)

Is this about a sorry placeholder?
  -> SORRY_REGISTRY.md (remove/move to resolved)

Is this about task status?
  -> TODO.md (remove if complete, update if partial)

Is this about workflow or process?
  -> MAINTENANCE.md (update procedures)
```

### 5. Lean-Specific Maintenance Requirements

**Sorry Placeholder Tracking**:

From IMPLEMENTATION_STATUS.md verification commands (lines 23-39 per spec 040):
```bash
# Count sorry placeholders per module
grep -rn "sorry" Logos/Core/Syntax/
grep -rn "sorry" Logos/Core/ProofSystem/
grep -rn "sorry" Logos/Core/Semantics/
grep -rn "sorry" Logos/Core/Metalogic/
grep -rn "sorry" Logos/Core/Theorems/
grep -rn "sorry" Logos/Core/Automation/
```

**Module Completion Percentages**:

IMPLEMENTATION_STATUS.md tracks completion % for each module:
- Syntax: 100% (complete)
- ProofSystem: 100% (complete)
- Semantics: 100% (complete)
- Metalogic: 60% (partial - completeness proofs missing)
- Theorems: 50% (partial - perpetuity principles incomplete)
- Automation: 33% (4/12 tactics implemented)

**Build and Test Verification**:
```bash
# Verify project builds
lake build

# Run test suite
lake test

# Check for lint warnings
lake lint
```

### 6. Lean Project File Structure Differences

**ProofChecker Structure** (from CLAUDE.md lines 52-112):
```
Logos/Core/               # Main source (Lean 4 implementation)
├── Syntax/                 # Formula types, parsing, DSL
├── ProofSystem/            # Axioms and inference rules
├── Semantics/              # Task frame semantics
├── Metalogic/              # Soundness and completeness
├── Theorems/               # Key theorems
└── Automation/             # Proof automation

LogosTest/           # Test suite
├── Syntax/
├── ProofSystem/
├── Semantics/
├── Integration/
└── Metalogic/

Documentation/              # User documentation
├── UserGuide/              # User-facing documentation
├── ProjectInfo/            # Project status and contribution
├── Development/            # Developer standards
└── Reference/              # Reference materials

Archive/                    # Pedagogical examples
lakefile.toml               # LEAN 4 build configuration
lean-toolchain              # LEAN version pinning
```

**Maintenance Scan Requirements**:
1. Scan `Logos/Core/**/*.lean` for sorry placeholders
2. Scan `LogosTest/**/*.lean` for test coverage
3. Check `lakefile.toml` for dependency changes
4. Review `Documentation/ProjectInfo/*.md` for staleness
5. Verify `CLAUDE.md` cross-references are current

### 7. Workflow Adaptation from /todo to /lean-update

**Key Differences**:

| Aspect | /todo Command | /lean-update Command |
|--------|--------------|---------------------|
| **Scope** | Single file (.claude/TODO.md) | Multiple maintenance docs |
| **File Count** | 1 file updated | 6+ files reviewed/updated |
| **Scan Target** | .claude/specs/ directories | Lean source tree + docs |
| **Classification** | Plan status (not started, in progress, complete) | Module completion %, sorry counts, test coverage |
| **Preservation** | Backlog + Saved sections | Manual curation sections in multiple files |
| **Agent** | todo-analyzer (single-purpose) | lean-maintenance-analyzer (multi-file) |
| **Verification** | 7-section structure, preservation check | Cross-reference integrity, sorry count accuracy |
| **Output** | Single TODO.md file | Multiple updated docs + verification report |

**Reusable Patterns from /todo**:
1. **Pre-calculated paths**: Hard barrier pattern (Block 2a)
2. **Agent delegation**: Task tool with contract-based requirements
3. **Semantic verification**: Post-agent validation (Block 2c)
4. **Atomic replacement**: Git snapshot before update (Block 3)
5. **Manual preservation**: Extract and preserve curated sections
6. **State persistence**: Workflow state across bash blocks
7. **4-section console summary**: Standardized completion output

**New Requirements for /lean-update**:
1. **Multi-file coordination**: Update 6+ files in synchronization
2. **Sorry counting**: Automated grep-based sorry placeholder detection
3. **Module status calculation**: Derive completion % from sorry counts
4. **Build verification**: Optionally run `lake build` and `lake test`
5. **Cross-reference validation**: Verify bidirectional links across docs
6. **Stale detection**: Identify outdated sections via git log analysis
7. **Dry-run mode**: Preview all changes before applying

### 8. Proposed /lean-update Command Design

**Command Modes**:

1. **Scan Mode** (default): Scan Lean project and update maintenance docs
2. **Verify Mode** (--verify): Check cross-reference integrity without updates
3. **Build Mode** (--with-build): Include build/test verification
4. **Dry-Run Mode** (--dry-run): Preview changes without modifying files

**Update Workflow**:

```bash
# Phase 1: Project Analysis
- Scan Lean source for sorry placeholders (by module)
- Count test files and coverage
- Check git log for completion history
- Analyze documentation staleness

# Phase 2: Document Updates (in order)
1. SORRY_REGISTRY.md: Update active placeholders
2. IMPLEMENTATION_STATUS.md: Update module completion %
3. KNOWN_LIMITATIONS.md: Check for resolved gaps
4. TODO.md: Verify task status matches reality
5. MAINTENANCE.md: Update workflow if changed
6. CLAUDE.md: Update documentation index

# Phase 3: Cross-Reference Validation
- Verify bidirectional links
- Check for broken file references
- Validate section structure

# Phase 4: Optional Build Verification
- Run lake build (if --with-build)
- Run lake test (if --with-build)
- Report build/test status

# Phase 5: Git Commit
- Create comprehensive commit message
- Reference all updated files
- Include verification report
```

**Agent Delegation Strategy**:

Use `lean-maintenance-analyzer` agent (new) with responsibilities:
1. **Input**: Lean project root, current maintenance docs
2. **Analysis**: Scan source tree, count sorries, detect staleness
3. **Output**: JSON report with recommended updates per file
4. **Format**: `{file: path, updates: [{section, old_content, new_content}]}`

**Preservation Strategy** (extending /todo pattern):

For each document, preserve manually-curated sections:
- TODO.md: Backlog, Saved sections
- SORRY_REGISTRY.md: Resolved placeholders section
- IMPLEMENTATION_STATUS.md: Manual annotations
- KNOWN_LIMITATIONS.md: Workaround details
- MAINTENANCE.md: Workflow customizations
- CLAUDE.md: Project-specific standards

**Verification Requirements**:

1. **Sorry Count Accuracy**: Verify SORRY_REGISTRY.md count matches grep
2. **Module Status Consistency**: Verify IMPLEMENTATION_STATUS.md % aligns with sorries
3. **Cross-Reference Integrity**: All links bidirectional and valid
4. **Section Structure**: All documents maintain required sections
5. **Git Snapshot Created**: Backup commit before updates

## Recommendations

### 1. Implement /lean-update Command with Phased Rollout

**Approach**: Start with minimal viable implementation focusing on sorry tracking, then expand to full documentation synchronization.

**Phase 1: Sorry Tracking Only** (10-15 hours):
- Scan Lean source for sorry placeholders
- Update SORRY_REGISTRY.md automatically
- Update IMPLEMENTATION_STATUS.md sorry counts
- Basic cross-reference validation

**Phase 2: Full Documentation Sync** (15-20 hours):
- Add KNOWN_LIMITATIONS.md staleness detection
- Integrate TODO.md task verification
- Add MAINTENANCE.md workflow update detection
- Update CLAUDE.md documentation index

**Phase 3: Build Verification** (8-12 hours):
- Add --with-build flag for lake build/test
- Report build/test failures in summary
- Optionally block updates on build failure

**Pros**:
- Reduces maintenance burden significantly
- Ensures documentation accuracy
- Provides automated sorry tracking
- Extends proven /todo patterns

**Cons**:
- Complex implementation (30-50 hours total)
- Requires new agent (lean-maintenance-analyzer)
- Must preserve manual curation carefully

**Suitability**: High - addresses real maintenance pain in Lean projects

### 2. Create lean-maintenance-analyzer Agent

**Approach**: Build specialized agent for Lean project analysis extending research-specialist patterns.

**Agent Responsibilities**:
1. Scan Lean source tree for sorry placeholders
2. Count test files and estimate coverage
3. Analyze git log for completion signals
4. Generate JSON report with file-specific updates
5. Respect preservation policies per document

**Agent Tools**:
- Read: Access Lean source and documentation
- Glob: Find Lean files by pattern
- Grep: Search for sorry placeholders
- Bash: Run lake build/test (optional)
- Write: Create analysis report (JSON)

**Contract Requirements**:
- **Input**: Lean project root, current doc paths
- **Output**: JSON report at pre-calculated path
- **Format**: `{files: [{path, updates: [{section, old, new}]}]}`
- **Return Signal**: `ANALYSIS_COMPLETE: [report-path]`

**Verification Pattern** (following /todo Block 2c):
- File existence check
- File size validation (not empty)
- JSON structure validation
- Required fields present (files, updates)

**Suitability**: High - enables automated multi-file updates safely

### 3. Use Hard Barrier Pattern for Path Pre-Calculation

**Approach**: Follow /todo command Block 2a pattern - pre-calculate all output paths before agent invocation.

**Implementation**:
```bash
# Block 1: Pre-calculate paths for all documents
SORRY_REGISTRY_PATH="$PROJECT_ROOT/Documentation/ProjectInfo/SORRY_REGISTRY.md"
IMPL_STATUS_PATH="$PROJECT_ROOT/Documentation/ProjectInfo/IMPLEMENTATION_STATUS.md"
KNOWN_LIMITS_PATH="$PROJECT_ROOT/Documentation/ProjectInfo/KNOWN_LIMITATIONS.md"
TODO_PATH="$PROJECT_ROOT/TODO.md"
MAINTENANCE_PATH="$PROJECT_ROOT/Documentation/ProjectInfo/MAINTENANCE.md"
CLAUDE_PATH="$PROJECT_ROOT/CLAUDE.md"
ANALYSIS_REPORT_PATH="$PROJECT_ROOT/.lean-update-analysis-$WORKFLOW_ID.json"

# Persist all paths to state
persist_state SORRY_REGISTRY_PATH IMPL_STATUS_PATH KNOWN_LIMITS_PATH \
  TODO_PATH MAINTENANCE_PATH CLAUDE_PATH ANALYSIS_REPORT_PATH

# Block 2: Delegate to agent with contract
Task {
  prompt: |
    You MUST create analysis report at: $ANALYSIS_REPORT_PATH
    You MUST analyze these files: $SORRY_REGISTRY_PATH, $IMPL_STATUS_PATH, ...
    Return signal: ANALYSIS_COMPLETE: $ANALYSIS_REPORT_PATH
}

# Block 3: Verify analysis report exists
if [ ! -f "$ANALYSIS_REPORT_PATH" ]; then
  echo "ERROR: Analysis report missing"
  exit 1
fi
```

**Benefits**:
- Prevents agent path derivation errors
- Enables strict contract enforcement
- Supports automated verification
- Matches proven /todo pattern

**Suitability**: Critical - ensures reliability

### 4. Implement Preservation Strategy for Manual Sections

**Approach**: Extract and preserve manually-curated sections from each document before regeneration.

**Preservation Map**:

| Document | Preserved Sections | Extraction Method |
|----------|-------------------|-------------------|
| TODO.md | Backlog, Saved | `sed -n '/^## Backlog/,/^## /p'` |
| SORRY_REGISTRY.md | Resolved Placeholders | `sed -n '/^## Resolved/,/^## /p'` |
| IMPLEMENTATION_STATUS.md | Manual annotations | Inline comments with `<!-- MANUAL -->` |
| KNOWN_LIMITATIONS.md | Workaround details | Preserve full section if not auto-generated |
| MAINTENANCE.md | Workflow customizations | Preserve custom procedures |
| CLAUDE.md | Project standards | Preserve custom sections |

**Implementation Pattern** (following /todo Block 2c lines 565-598):
```bash
# Extract section for preservation
ORIGINAL_SECTION=$(sed -n '/^## Section/,/^## /p' "$DOC_PATH" | sed '$d' || echo "")

# After agent generates new content, verify preservation
NEW_SECTION=$(sed -n '/^## Section/,/^## /p' "$NEW_DOC_PATH" | sed '$d' || echo "")

if [ "$ORIGINAL_SECTION" != "$NEW_SECTION" ]; then
  echo "ERROR: Preserved section modified"
  exit 1
fi
```

**Benefits**:
- Prevents accidental overwrite of manual curation
- Maintains project-specific customizations
- Follows proven /todo preservation pattern

**Suitability**: Critical - protects user content

### 5. Add Cross-Reference Validation

**Approach**: After document updates, verify bidirectional links and section references.

**Validation Checks**:

1. **Bidirectional Links** (following spec 040 lines 202-208):
```bash
# TODO.md → SORRY_REGISTRY.md implies SORRY_REGISTRY.md → TODO.md
grep -q "SORRY_REGISTRY.md" TODO.md && \
  grep -q "TODO.md" Documentation/ProjectInfo/SORRY_REGISTRY.md

# Verify all cross-reference pairs
for doc in SORRY_REGISTRY IMPL_STATUS KNOWN_LIMITS; do
  # Check A → B and B → A
done
```

2. **Broken File References**:
```bash
# Extract all markdown links
grep -oP '\[.*?\]\(\K[^)]+' $DOC_PATH | while read link; do
  # Resolve relative path
  # Check file exists
done
```

3. **Section Structure**:
```bash
# Verify required sections present
for section in "Overview" "Quick Links" "High Priority"; do
  grep -q "^## $section" TODO.md || echo "Missing: $section"
done
```

**Benefits**:
- Prevents broken documentation
- Ensures architectural integrity
- Catches stale references

**Suitability**: High - critical for multi-file maintenance

## References

### ProofChecker Project Files
- Plan: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/.claude/specs/040_todo_cleanup_git_history/plans/001-todo-cleanup-git-history-plan.md` (lines 1-698)
- TODO.md: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/TODO.md` (lines 1-100)
- CLAUDE.md: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/CLAUDE.md` (lines 1-359)
- MAINTENANCE.md: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/Documentation/ProjectInfo/MAINTENANCE.md` (lines 1-150)
- README.md: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/README.md` (lines 1-100)

### .config Project Files
- /todo Command: `/home/benjamin/.config/.claude/commands/todo.md` (lines 1-1331)
- research-specialist Agent: `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-697)

### Related Patterns
- Hard Barrier Pattern: Pre-calculated paths before agent delegation
- Preservation Pattern: Extract and verify manually-curated sections
- State Persistence: Workflow state across bash blocks
- Agent Delegation: Task tool with contract requirements
- Semantic Verification: Post-agent validation of structure and content
- Cross-Reference Validation: Bidirectional link integrity checks
- Git-Based History Model: Completion history via commits, not logs

---

**Research Complete**: 2025-12-05
