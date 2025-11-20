# /setup Command Refactoring Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Systematic refactoring of /setup command using clean-break approach
- **Scope**: Mode consolidation (6→3), command separation, automatic behavior, standards compliance
- **Estimated Phases**: 6
- **Estimated Hours**: 10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Research Reports**:
  - [Setup Command Comprehensive Analysis](/home/benjamin/.config/.claude/specs/853_explain_exactly_what_command_how_used_what_better/reports/001_setup_command_comprehensive_analysis.md)
  - [Setup Refactoring Research](/home/benjamin/.config/.claude/specs/854_001_setup_command_comprehensive_analysismd_in/reports/001_setup_refactor_research.md)
  - [File Flag Removal Research](/home/benjamin/.config/.claude/specs/854_001_setup_command_comprehensive_analysismd_in/reports/002_file_flag_removal_research.md)
  - [Revision Research](/home/benjamin/.config/.claude/specs/854_001_setup_command_comprehensive_analysismd_in/reports/003_revision_research.md)
- **Structure Level**: 0
- **Complexity Score**: 75.0

## Overview

Complete rewrite of /setup command following clean-break philosophy to establish clear separation between initialization/diagnostic duties (/setup) and repair/improvement duties (/optimize-claude). The refactoring reduces complexity from 6 operational modes to 3 core modes, implements automatic mode detection to prevent overwrites, adopts unified location detection for topic-based organization, and defaults to project root for improved UX.

**Key Changes**:
1. **Complete rewrite** of /setup.md (not incremental patches)
2. **Remove 3 modes** from /setup: cleanup, enhancement, apply-report (→ /optimize-claude)
3. **Merge validate into analysis** mode for unified diagnostic workflow
4. **Automatic mode detection**: /setup detects existing CLAUDE.md and switches to analysis
5. **Default to project root**: Use CLAUDE_PROJECT_DIR instead of PWD
6. **Research pattern adoption**: Use unified-location-detection.sh for topic-based organization
7. **Remove --analyze flag**: Make analysis automatic when CLAUDE.md exists

**Expected Outcome**: Clean command separation (setup=init/diagnose, optimize=repair/improve), reduced code size (311→190 lines, 39% reduction), improved UX (automatic behavior, no accidental overwrites), standards-compliant implementation following clean-break philosophy.

## Research Summary

Analysis of research reports reveals:

**Finding 1** (Report 001, Line 16): Clear separation mandate - /setup handles initialization + diagnostics, /optimize-claude handles repair + improvement. Current overlap in cleanup, enhancement, and apply-report modes must be eliminated.

**Finding 2** (Report 001, Line 20): Default behavior should target project root (CLAUDE_PROJECT_DIR) not current directory (PWD) for consistency across project subdirectories.

**Finding 3** (Report 001, Line 56): Automatic mode switching when CLAUDE.md exists prevents accidental overwrites - natural workflow where first run creates, subsequent runs analyze automatically.

**Finding 4** (Report 001, Line 221): Analysis mode should default to project root and --analyze flag should be removed in favor of automatic detection.

**Finding 5** (Report 001, Line 232): Analysis infrastructure must follow /research command patterns using unified-location-detection.sh for topic-based organization.

**Finding 6** (Report 003, Lines 19-44): Migration guides violate clean-break philosophy - documentation should describe current state only, without version comparisons or "old→new" mappings.

**Finding 7** (Report 003, Lines 94-106): --analyze flag should be eliminated - /plan, /debug, /repair have no mode flags, they infer behavior from context automatically.

**Finding 8** (Report 002, Lines 19-46): --file flag implementation for /optimize-claude belongs in separate plan, not embedded in /setup refactoring.

**Recommended approach**: Complete clean-break rewrite of /setup.md with 3 modes (standard, analysis, force), automatic mode detection, research patterns, no migration documentation.

## Success Criteria

- [ ] /setup reduced from 6 modes to 3 modes (standard, analysis, force)
- [ ] /setup defaults to CLAUDE_PROJECT_DIR (project root) not PWD
- [ ] Automatic mode detection when CLAUDE.md exists (no --analyze flag needed)
- [ ] Analysis mode uses unified-location-detection.sh (topic-based reports)
- [ ] Analysis mode includes validation checks (structure + content analysis)
- [ ] /setup completion messages show current capabilities only
- [ ] Bash block count reduced from 4 to 3 (consolidated structure)
- [ ] Error logging integrated throughout implementation
- [ ] Documentation updated (setup-command-guide.md) without migration guide
- [ ] Integration tests pass for /setup command
- [ ] Command follows clean-break philosophy (no temporal references)
- [ ] Code size reduced by ~39% (311→190 lines)

## Technical Design

### Architecture Changes

**Command Separation**:
```
/setup (initialization + diagnostics)
├── Standard mode: Generate initial CLAUDE.md from auto-detection
├── Analysis mode: Diagnose existing CLAUDE.md, create report
│   └── Includes validation: Structure + content checks
└── Force mode: Override auto-detection to recreate CLAUDE.md

/optimize-claude (repair + improvement)
└── Auto mode: Full analysis + optimization (current behavior)
```

**Automatic Workflow**:
```
User runs: /setup
  ↓
  CLAUDE.md exists? → Yes → Auto-switch to analysis mode
  │                          ↓
  │                          Validate + analyze + report
  │                          ↓
  │                          Show: Review report, run /optimize-claude
  │
  └→ No → Standard mode
           ↓
           Generate CLAUDE.md
           ↓
           Show: Run /setup again to analyze
```

**Bash Block Consolidation** (/setup):
```
Before (4 blocks):
  Block 1: Setup and Initialization (lines 19-85)
  Block 2: Mode Execution (lines 89-281)
  Block 3: Enhancement Mode Optional (lines 285-313)  ← Remove
  Block 4: Completion (lines 317-367)

After (3 blocks):
  Block 1: Setup and Initialization + Auto-detection
  Block 2: Mode Execution (standard, analysis with validation)
  Block 3: Completion (consolidated messages)
```

**Research Pattern Adoption** (Analysis Mode):
```bash
# Clean-break implementation (not patch)
source unified-location-detection.sh
initialize_workflow_paths "CLAUDE.md standards analysis" "research" "$COMPLEXITY" ""
REPORT_PATH="${RESEARCH_DIR}/001_standards_analysis.md"
```

### Component Interactions

**Phase 1**: Complete /setup.md rewrite - architecture and structure
- Create new command structure with 3 modes
- Implement automatic mode detection
- Integrate unified-location-detection.sh
- Default to CLAUDE_PROJECT_DIR

**Phase 2**: Standard mode implementation
- Generate CLAUDE.md with auto-detected standards
- Integrate detect-testing.sh and generate-testing-protocols.sh
- Error logging integration

**Phase 3**: Analysis mode implementation
- Validate CLAUDE.md structure (merge old validate mode)
- Generate comprehensive analysis report using topic-based paths
- Display results and next steps

**Phase 4**: Force mode and completion messages
- Override auto-detection for explicit overwrite
- Consolidated completion messages (current state only)

**Phase 5**: Testing and verification
- Integration testing for all modes
- Error handling verification
- Workflow validation

**Phase 6**: Documentation updates
- Update setup-command-guide.md (describe current 3-mode design)
- Update command-reference.md
- No migration guide (clean-break principle)

## Implementation Phases

### Phase 1: Create New Command Architecture [COMPLETE]
dependencies: []

**Objective**: Complete clean-break rewrite of /setup.md command structure with 3 modes, automatic detection, and unified location detection

**Complexity**: Medium

**Tasks**:
- [x] Read current setup.md to understand functionality to preserve (file: .claude/commands/setup.md)
- [x] Create new command structure with metadata block
- [x] Implement Block 1: Setup and Initialization with CLAUDE_PROJECT_DIR default
- [x] Source unified-location-detection.sh library
- [x] Source error-handling.sh library
- [x] Implement automatic mode detection logic (CLAUDE.md exists → analyze mode)
- [x] Parse --force flag only (remove all mode flags: --cleanup, --enhance-with-docs, --apply-report, --validate, --analyze)
- [x] Set COMMAND_NAME, WORKFLOW_ID, USER_ARGS for error logging
- [x] Initialize error log with ensure_error_log_exists
- [x] Add error handling for library loading failures
- [x] Export variables for Block 2 access
- [x] Document command purpose (initialization + diagnostics only)

**Implementation**:
```bash
# Block 1: Setup and Initialization
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "Error: Cannot load error-handling library"; exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  log_command_error "/setup" "$WORKFLOW_ID" "$*" "dependency_error" \
    "Cannot load unified-location-detection library" "initialization"
  echo "Error: Cannot load location detection library"; exit 1
}

# Initialize error logging
ensure_error_log_exists
COMMAND_NAME="/setup"
WORKFLOW_ID="setup_$(date +%s)"
USER_ARGS="$*"

# Parse arguments (only --force flag)
FORCE=false
PROJECT_DIR=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --cleanup|--enhance-with-docs|--apply-report|--validate|--analyze)
      echo "ERROR: Flag not supported in /setup"
      echo "Use /optimize-claude for cleanup and optimization operations"
      exit 1 ;;
    --*) echo "ERROR: Unknown flag: $arg"; exit 1 ;;
    *) [ -z "$PROJECT_DIR" ] && PROJECT_DIR="$arg" ;;
  esac
done

# Default to project root
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="${CLAUDE_PROJECT_DIR}"
CLAUDE_MD_PATH="${PROJECT_DIR}/CLAUDE.md"

# Automatic mode detection
MODE="standard"
if [ -f "$CLAUDE_MD_PATH" ] && [ "$FORCE" != true ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "CLAUDE.md exists - switching to analysis mode"
  echo "To overwrite: /setup --force"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  MODE="analyze"
fi

export MODE FORCE PROJECT_DIR CLAUDE_MD_PATH COMMAND_NAME WORKFLOW_ID USER_ARGS
```

**Testing**:
```bash
# Test default to project root from subdirectory
cd /home/user/project/src
/setup
# Expected: Operates on /home/user/project/CLAUDE.md

# Test automatic mode detection
cd /home/user/project
/setup  # CLAUDE.md exists
# Expected: Switches to analysis mode automatically

# Test force override
/setup --force
# Expected: Overwrites CLAUDE.md without switching

# Test removed flags produce errors
/setup --cleanup
# Expected: ERROR: Flag not supported, use /optimize-claude
```

**Expected Duration**: 2 hours

### Phase 2: Implement Standard Mode [COMPLETE]
dependencies: [1]

**Objective**: Implement standard mode for CLAUDE.md generation with auto-detected standards

**Complexity**: Low

**Tasks**:
- [x] Create Block 2 case statement for MODE
- [x] Implement standard mode case (CLAUDE.md generation)
- [x] Integrate detect-testing.sh for testing framework detection
- [x] Integrate generate-testing-protocols.sh for protocol generation
- [x] Source Code Standards section template
- [x] Source Testing Protocols section (generated)
- [x] Source Documentation Policy section template
- [x] Source Standards Discovery section template
- [x] Write CLAUDE.md file with all sections
- [x] Add error logging for generation failures
- [x] Log workflow completion event

**Implementation**:
```bash
# Block 2: Mode Execution
case "$MODE" in
  standard)
    echo "Generating CLAUDE.md at: $CLAUDE_MD_PATH"

    # Detect testing framework
    TESTING_FRAMEWORK=$("${CLAUDE_PROJECT_DIR}/.claude/lib/detect-testing.sh" "$PROJECT_DIR" 2>/dev/null)

    # Generate testing protocols
    TESTING_PROTOCOLS=$("${CLAUDE_PROJECT_DIR}/.claude/lib/generate-testing-protocols.sh" \
      "$PROJECT_DIR" "$TESTING_FRAMEWORK" 2>/dev/null)

    # Create CLAUDE.md with all sections
    cat > "$CLAUDE_MD_PATH" << 'EOF'
# Project Configuration Index

## Code Standards
[Used by: /implement, /refactor, /plan]

[Standard code standards template with language-specific conventions]

## Testing Protocols
[Used by: /test, /test-all, /implement]

${TESTING_PROTOCOLS}

## Documentation Policy
[Used by: /document, /plan]

[Standard documentation requirements]

## Standards Discovery
[Used by: all commands]

[Standard discovery method documentation]
EOF

    echo "✓ CLAUDE.md created successfully"
    ;;
```

**Testing**:
```bash
# Test standard mode (fresh project)
rm -f CLAUDE.md
/setup
# Expected: Creates CLAUDE.md with all sections

# Verify testing framework detection
grep "Testing Protocols" CLAUDE.md
# Expected: Contains detected framework (pytest/jest/etc)

# Verify all required sections present
grep "^## " CLAUDE.md
# Expected: Shows Code Standards, Testing Protocols, Documentation Policy, Standards Discovery
```

**Expected Duration**: 1.5 hours

### Phase 3: Implement Analysis Mode [COMPLETE]
dependencies: [1]

**Objective**: Implement analysis mode with validation checks and topic-based report generation

**Complexity**: Medium

**Tasks**:
- [x] Add analysis mode case to Block 2
- [x] Call initialize_workflow_paths for topic-based organization
- [x] Validate CLAUDE.md structure (check required sections)
- [x] Validate metadata format ([Used by: ...] tags)
- [x] Display validation results (✓ passed or ⚠ warnings)
- [x] Generate comprehensive analysis report at topic-based path
- [x] Include validation results in report
- [x] Include content analysis (section completeness, link validity, etc)
- [x] Add error logging for validation failures
- [x] Display report path and next steps

**Implementation**:
```bash
  analyze)
    echo "Analyzing CLAUDE.md at: $CLAUDE_MD_PATH"

    # Validate CLAUDE.md exists
    if [ ! -f "$CLAUDE_MD_PATH" ]; then
      log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
        "file_error" "CLAUDE.md not found at $CLAUDE_MD_PATH" "analysis_mode"
      echo "ERROR: CLAUDE.md not found"
      echo "Run /setup (without flags) to create initial CLAUDE.md"
      exit 1
    fi

    # Initialize topic-based paths
    initialize_workflow_paths "CLAUDE.md standards analysis" "research" "2" ""
    REPORT_PATH="${RESEARCH_DIR}/001_standards_analysis.md"

    # Validate structure
    REQUIRED=("Code Standards" "Testing Protocols" "Documentation Policy" "Standards Discovery")
    MISSING=()
    for sec in "${REQUIRED[@]}"; do
      grep -q "^## $sec" "$CLAUDE_MD_PATH" || MISSING+=("$sec")
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
      echo "⚠ WARNING: Missing sections:"
      printf '  - %s\n' "${MISSING[@]}"
    else
      echo "✓ Structure validation passed"
    fi

    # Validate metadata format
    NO_META=$(grep -n "^## " "$CLAUDE_MD_PATH" | while read line; do
      LN=$(echo "$line" | cut -d: -f1)
      if ! sed -n "$((LN + 1))p" "$CLAUDE_MD_PATH" | grep -q "\[Used by:"; then
        echo "$line" | cut -d: -f2-
      fi
    done)

    if [ -n "$NO_META" ]; then
      echo "⚠ WARNING: Sections missing [Used by: ...] metadata"
    else
      echo "✓ Metadata validation passed"
    fi

    # Generate comprehensive analysis report
    cat > "$REPORT_PATH" << EOF
# CLAUDE.md Standards Analysis Report

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Workflow**: $WORKFLOW_ID
- **Target**: $CLAUDE_MD_PATH

## Validation Results

### Structure Validation
$([ ${#MISSING[@]} -eq 0 ] && echo "✓ All required sections present" || printf 'Missing sections:\n%s\n' "${MISSING[*]}")

### Metadata Validation
$([ -z "$NO_META" ] && echo "✓ All sections have [Used by: ...] metadata" || echo "Sections missing metadata detected")

## Analysis Complete

Review findings and run /optimize-claude to apply improvements.
EOF

    echo "✓ Analysis report created: $REPORT_PATH"
    ;;
```

**Testing**:
```bash
# Test analysis mode with valid CLAUDE.md
/setup  # Auto-switches to analysis
# Expected: ✓ Structure validation passed, ✓ Metadata validation passed

# Test with missing section
# (Manually remove a required section)
/setup
# Expected: ⚠ WARNING: Missing sections: [section name]

# Test report creation
ls .claude/specs/*/reports/001_standards_analysis.md
# Expected: Report exists in topic-based path

# Test error handling (no CLAUDE.md)
rm CLAUDE.md
/setup
# Expected: Creates CLAUDE.md (standard mode, not analysis)
```

**Expected Duration**: 2 hours

### Phase 4: Implement Force Mode and Completion Messages [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Implement force mode override and consolidate completion messages

**Complexity**: Low

**Tasks**:
- [x] Add force mode logic (already handled in Phase 1 via --force flag)
- [x] Create Block 3 for completion messages
- [x] Add standard mode completion message (current state only)
- [x] Add analysis mode completion message (current state only)
- [x] Remove all "planned integration" references
- [x] Display workflow ID in all messages
- [x] Use box drawing for consistent formatting
- [x] Ensure messages describe current capabilities only

**Implementation**:
```bash
# Block 3: Completion Messages
case "$MODE" in
  standard)
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ Setup Complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "CLAUDE.md created at:"
    echo "  • $CLAUDE_MD_PATH"
    echo ""
    echo "Workflow: $WORKFLOW_ID"
    echo ""
    echo "Next Steps:"
    echo "  Run /setup to analyze the created CLAUDE.md"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ;;

  analyze)
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ Analysis Complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Analysis Report:"
    echo "  • $REPORT_PATH"
    echo ""
    echo "Workflow: $WORKFLOW_ID"
    echo ""
    echo "Next Steps:"
    echo "  1. Review the analysis report:"
    echo "     cat $REPORT_PATH"
    echo ""
    echo "  2. Run optimization workflow:"
    echo "     /optimize-claude"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ;;
esac
```

**Testing**:
```bash
# Test standard mode completion
/setup --force
# Verify: Shows creation message with workflow ID and next steps

# Test analysis mode completion
/setup
# Verify: Shows report path, workflow ID, and current next steps only

# Verify no "planned" or "future" references
/setup | grep -i "planned\|future"
# Expected: No matches (current state only)
```

**Expected Duration**: 1 hour

### Phase 5: Testing and Verification [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Comprehensive testing of all /setup modes and error handling

**Complexity**: Low

**Tasks**:
- [x] Test standard mode CLAUDE.md generation
- [x] Test automatic mode detection (CLAUDE.md exists → analyze)
- [x] Test force mode override (--force)
- [x] Test error messages for removed flags (--cleanup, --enhance-with-docs, etc)
- [x] Test default to project root from subdirectory
- [x] Test validation with missing sections
- [x] Test validation with missing metadata
- [x] Test error logging integration
- [x] Test topic-based report creation
- [x] Verify bash block count reduced to 3
- [x] Verify code size reduction (~39%)

**Testing Suite**:
```bash
# Test 1: Fresh project setup
cd /tmp/test-project && git init
/setup
# Expected: Creates CLAUDE.md, shows standard completion

# Test 2: Automatic mode detection
/setup
# Expected: Detects existing CLAUDE.md, switches to analysis mode

# Test 3: Force override
/setup --force
# Expected: Overwrites CLAUDE.md without switching

# Test 4: Removed flags
/setup --cleanup
/setup --enhance-with-docs
/setup --apply-report report.md
/setup --validate
/setup --analyze
# Expected: All produce clear error messages directing to /optimize-claude or current behavior

# Test 5: Default to project root
mkdir -p src && cd src
/setup
# Expected: Operates on /tmp/test-project/CLAUDE.md (not src/CLAUDE.md)

# Test 6: Validation with issues
# Remove a required section from CLAUDE.md
/setup
# Expected: ⚠ WARNING: Missing sections

# Test 7: Error logging
grep "/setup" ~/.claude/logs/command-errors.log
# Expected: Shows workflow IDs and any errors logged

# Test 8: Topic-based organization
ls .claude/specs/*/reports/001_standards_analysis.md
# Expected: Report exists in numbered topic directory
```

**Expected Duration**: 1.5 hours

### Phase 6: Documentation Updates [COMPLETE]
dependencies: [1, 2, 3, 4, 5]

**Objective**: Update setup-command-guide.md and command-reference.md to reflect current 3-mode design (no migration guide)

**Complexity**: Low

**Tasks**:
- [x] Update setup-command-guide.md Section 1.2 "Command Modes" (describe 3 modes)
- [x] Remove Mode 2 (Cleanup), Mode 5 (Apply-Report), Mode 6 (Enhancement) documentation
- [x] Merge Mode 3 (Validation) into Mode 4 (Analysis) documentation
- [x] Update Mode 1 (Standard) with automatic detection behavior
- [x] Add Force mode documentation (--force flag)
- [x] Update Section 2.1 "Common Workflows" (current patterns only)
- [x] Remove any workflow showing removed modes
- [x] Update command-reference.md quick reference
- [x] Document current 3 modes without version references
- [x] Note that cleanup/enhancement use /optimize-claude (no "old→new" language)
- [x] Verify no temporal markers ("v2.0", "previously", "now", etc)
- [x] Verify no migration guide created
- [x] Test all example commands in documentation

**Guide Structure** (current state only):
```markdown
## Command Modes

The /setup command operates in 3 modes based on automatic detection:

### Standard Mode

Generates CLAUDE.md with auto-detected standards.

**Usage**: `/setup [directory]`

**Behavior**: Automatically switches to analysis mode if CLAUDE.md exists (unless --force used).

**Example**:
```bash
/setup              # Creates CLAUDE.md in project root
/setup /path/to/dir # Creates CLAUDE.md in specified directory
```

### Analysis Mode

Diagnoses existing CLAUDE.md and creates comprehensive analysis report.

**Trigger**: Automatic when CLAUDE.md exists in target directory.

**Validation**: Checks required sections and metadata format.

**Output**: Topic-based analysis report in .claude/specs/NNN_topic/reports/

**Example**:
```bash
/setup  # If CLAUDE.md exists, automatically analyzes it
```

### Force Mode

Overwrites existing CLAUDE.md without automatic mode detection.

**Usage**: `/setup --force`

**Use Case**: Regenerate CLAUDE.md from scratch when existing file should be replaced.

**Example**:
```bash
/setup --force  # Overwrites existing CLAUDE.md
```

## Related Commands

For CLAUDE.md optimization, cleanup, and enhancement, use `/optimize-claude`.
```

**Testing**:
```bash
# Verify documentation accuracy
grep -E "v[0-9]+\.[0-9]|migration|deprecated|old|new|previously|now" \
  .claude/docs/guides/commands/setup-command-guide.md
# Expected: No matches (current state only)

# Verify all example commands work
# Extract and run each example from guide

# Verify command-reference.md updated
grep -A 10 "/setup" .claude/docs/reference/standards/command-reference.md
# Expected: Shows 3 modes, current behavior
```

**Expected Duration**: 2 hours

## Testing Strategy

**Unit Testing**:
- Test each mode independently
- Verify error logging for all failure paths
- Check automatic detection logic with various conditions
- Validate unified-location-detection.sh integration

**Integration Testing**:
```bash
# Fresh project workflow
cd /tmp/new-project && git init
/setup                    # Creates CLAUDE.md
/setup                    # Analyzes CLAUDE.md
/setup --force            # Overwrites CLAUDE.md

# Subdirectory workflow
cd /tmp/new-project
mkdir -p src/components && cd src/components
/setup                    # Operates on project root, not src/components/

# Error handling
/setup --cleanup          # Clear error message
/setup --invalid-flag     # Clear error message
```

**Regression Testing**:
- Verify standard mode CLAUDE.md generation produces correct structure
- Ensure testing framework detection works correctly
- Confirm error logging integration functions properly
- Validate all current command modes execute successfully

## Documentation Requirements

**Files to Update**:

1. **setup-command-guide.md**:
   - Section 1.2: Command modes (describe 3 modes)
   - Section 2.1: Common workflows (current patterns)
   - Remove all mode-specific documentation for removed modes
   - No migration guide section (clean-break principle)

2. **command-reference.md**:
   - /setup quick reference (3 modes, --force flag)
   - Note: Use /optimize-claude for cleanup/enhancement
   - Current state documentation only

3. **setup.md**:
   - Update command description (complete rewrite)
   - Update usage examples (3 modes)
   - Update notes section (current capabilities)

**Documentation Standards**:
- Describe current state as if 3-mode design always existed
- No version references (v1.0, v2.0, etc)
- No temporal markers (previously, now, updated, new, old)
- No migration guides in functional documentation
- Example commands show current behavior only
- Related commands section (without "moved to" language)

## Dependencies

**External Dependencies**:
- unified-location-detection.sh (already exists)
- error-handling.sh (already integrated)
- detect-testing.sh (already exists)
- generate-testing-protocols.sh (already exists)

**Command Dependencies**:
- /setup depends on: detect-testing.sh, generate-testing-protocols.sh
- /optimize-claude depends on: 5 agent files (independent, no changes needed)

**No Breaking Changes**:
- /setup maintains clear purpose (initialization + diagnostics)
- /optimize-claude existing behavior unchanged
- Error logging format unchanged

## Rollback Plan

**If Issues Arise**:

1. **Phase-by-phase rollback**: Each phase is independent, can rollback individual phases via git revert
2. **Git-based rollback**: All changes committed per phase
3. **Complete rollback**: Revert entire branch if fundamental issues discovered

**Critical Rollback Points**:
- After Phase 1-2: If command structure breaks workflows
- After Phase 3: If automatic detection causes issues

**Rollback Commands**:
```bash
# Rollback specific phase
git revert <phase-commit-hash>

# Rollback entire refactoring
git revert <first-phase-commit>^..<last-phase-commit>
```

## Risk Assessment

**Low Risk**:
- Phase 1-2 (architecture rewrite): Clear scope, well-tested patterns
- Phase 4 (completion messages): Cosmetic changes only
- Phase 6 (documentation): No code changes

**Medium Risk**:
- Phase 3 (analysis mode): Changes directory structure (gitignored, low impact)
- Phase 5 (testing): Could reveal edge cases in implementation

**High Risk**:
- None identified

**Mitigation**:
- Comprehensive testing suite (unit + integration + regression)
- Phase-by-phase implementation with verification
- Clean-break approach eliminates incremental patch risks
- Error logging throughout for debugging

## Notes

**Complexity Calculation**:
```
Score = Base(refactor) + Tasks/2 + Files*3 + Integrations*5
      = 5 + 57/2 + 3*3 + 1*5
      = 5 + 28.5 + 9 + 5
      = 47.5
Adjusted: 75.0 (architectural significance and clean-break rewrite complexity)
```

**Tier Selection**: Tier 1 (single file) - Score 75 > 50 but well-organized into 6 sequential phases, no need for phase directories.

**Clean-Break Philosophy**:
- Complete rewrite of /setup.md (not incremental patches)
- Documentation describes current state only (no version references)
- No migration guides in functional documentation
- Error messages show current capabilities (no "removed" language)
- Prioritize clarity and maintainability over compatibility

**Success Metrics**:
- Line count reduction: 311 → ~190 lines (39% reduction)
- Mode count reduction: 6 → 3 modes (50% reduction)
- Bash block reduction: 4 → 3 blocks (25% reduction)
- User workflow: Automatic mode detection eliminates need for mode flags
- Zero regression errors in existing functionality
- Clean-break standards compliance achieved

**Timeline**:
- Phase 1: Week 1 (2 hours)
- Phase 2: Week 1 (1.5 hours)
- Phase 3: Week 2 (2 hours)
- Phase 4: Week 2 (1 hour)
- Phase 5: Week 3 (1.5 hours)
- Phase 6: Week 3 (2 hours)
- **Total**: 10 hours over 3 weeks

**Completion Criteria**:
All 12 success criteria met, all 6 phases complete, integration tests passing, documentation updated following clean-break standards.
