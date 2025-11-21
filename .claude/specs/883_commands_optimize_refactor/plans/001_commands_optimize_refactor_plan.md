# Command Optimization and Standardization Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Systematic optimization and standardization of .claude/commands/
- **Scope**: Refactor 12 commands to reduce duplication, consolidate bash blocks, standardize documentation, and enhance maintainability
- **Estimated Phases**: 6
- **Estimated Hours**: 24
- **Structure Level**: 0
- **Complexity Score**: 142.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Research Reports**:
  - [Command Optimization Analysis](../reports/001_command_optimization_analysis.md)

## Overview

The .claude/commands/ system currently contains 12 well-functioning commands (10,649 LOC) with strong standardization in state management, error logging, and agent integration. However, the research analysis identified significant optimization opportunities:

1. **Initialization duplication**: 30-40 line initialization pattern repeated across all workflow commands (1,200+ lines of duplication)
2. **Bash block fragmentation**: /expand (32 blocks) and /collapse (29 blocks) have 4x-10x more fragmentation than other commands
3. **Documentation inconsistency**: Mix of "Block N" vs "Part N" vs "Phase N" naming conventions
4. **Missing guidelines**: No established bash block budget guidelines or command templates

This plan systematically refactors the commands to eliminate duplication, reduce complexity, and enhance maintainability while preserving the robust functionality that currently exists.

## Research Summary

Key findings from the command optimization analysis:

**Strengths Identified**:
- 100% metadata compliance across all commands
- Excellent error handling standardization (171 occurrences)
- Robust state management patterns (379 occurrences)
- Consistent library sourcing and history expansion protection
- Strong agent integration with standardized Task invocations

**Primary Bottlenecks**:
- Initialization overhead: 30-40 lines repeated in every bash block of workflow commands
- Extreme bash block fragmentation in /expand and /collapse (60+ blocks combined vs 4 in /plan)
- Documentation variance: Inconsistent section naming across commands
- State restoration pattern: 20-30 line pattern repeated in every block
- Missing command templates and bash block budget guidelines

**Recommended Optimizations**:
1. Extract common initialization into command-initialization.sh library (reduces 1,200+ lines)
2. Consolidate /expand from 32→8 blocks and /collapse from 29→8 blocks (75% reduction)
3. Standardize documentation to "Block N" pattern across all commands
4. Create workflow-command-template.md for new command development
5. Document bash block budget guidelines (3-8 for workflows, 2-4 for utilities)

## Success Criteria

- [ ] Command initialization library created and integrated into all 6 workflow commands
- [ ] /expand bash blocks reduced from 32 to ≤8 blocks
- [ ] /collapse bash blocks reduced from 29 to ≤8 blocks
- [ ] All commands use consistent "Block N" documentation pattern
- [ ] Command template created with best practices and standards
- [ ] Bash block budget guidelines documented in command-standards.md
- [ ] README.md enhanced with table of contents navigation
- [ ] All commands maintain 100% functionality after refactoring
- [ ] Test suite passes after all optimizations
- [ ] Standards documentation updated to reflect optimized patterns

## Technical Design

### Architecture Overview

The optimization follows a systematic refactoring approach:

```
Phase 1: Foundation
├─ Create command-initialization.sh library
├─ Document bash block budget guidelines
└─ Create command template for future development

Phase 2: Library Integration
├─ Integrate command-initialization.sh into /plan, /debug, /research
├─ Integrate command-initialization.sh into /build, /revise, /repair
└─ Verify state management and error logging preserved

Phase 3: Block Consolidation
├─ Analyze /expand block boundaries and consolidation opportunities
├─ Refactor /expand to 8 blocks with validation
├─ Analyze /collapse block boundaries and consolidation opportunities
└─ Refactor /collapse to 8 blocks with validation

Phase 4: Documentation Standardization
├─ Standardize all commands to "Block N" pattern
├─ Add table of contents to README.md
└─ Update command-standards.md with optimization patterns

Phase 5: Testing and Validation
├─ Run integration tests on all refactored commands
├─ Validate state persistence across block boundaries
├─ Test error logging and recovery workflows
└─ Verify agent integration still functional

Phase 6: Documentation and Standards Update
├─ Update .claude/docs/ to reflect optimized patterns
├─ Document new command-initialization.sh library
└─ Update CLAUDE.md references to optimization standards
```

### Key Components

**1. command-initialization.sh Library**
- Encapsulates 30-40 line initialization pattern
- Provides `init_command_block()` function
- Handles project detection, library sourcing, state loading, error setup
- Reduces duplication by 1,200+ lines across 6 workflow commands

**2. Bash Block Consolidation Strategy**
- Target: /expand (32→8 blocks), /collapse (29→8 blocks)
- Method: Combine adjacent blocks with no agent invocations between them
- Preserve: Agent invocations as natural block separators
- Benefit: Reduced state serialization overhead, improved performance

**3. Documentation Standardization**
- Adopt "Block N" pattern across all commands
- Migrate /debug from "Part N" to "Block N"
- Add table of contents to 905-line README.md
- Create hierarchical navigation structure

**4. Command Template and Guidelines**
- Create workflow-command-template.md with best practices
- Document bash block budget guidelines (3-8 for workflows, 2-4 for utilities)
- Establish consolidation triggers (>10 blocks = review for consolidation)
- Provide examples from optimized commands

### Design Decisions

**Why extract initialization library?**
- Eliminates 1,200+ lines of duplication
- Ensures consistent initialization across all commands
- Simplifies maintenance and bug fixes
- Reduces context size for AI assistance

**Why target /expand and /collapse?**
- Highest fragmentation (32 and 29 blocks vs 3-4 in comparable commands)
- Opportunity for 75% reduction in block count
- Improved execution performance through reduced state serialization
- Better maintainability with consolidated logic

**Why standardize on "Block N" pattern?**
- Already adopted by majority of commands (/plan, /build, /research)
- Clear, consistent terminology
- Aligns with "Block" terminology in CLAUDE.md output formatting standards
- Simplifies documentation navigation

## Implementation Phases

### Phase 1: Foundation and Library Creation [NOT STARTED]
dependencies: []

**Objective**: Create command-initialization.sh library, document bash block budget guidelines, and establish command template for future development.

**Complexity**: Low

**Tasks**:
- [ ] Create /home/benjamin/.config/.claude/lib/workflow/command-initialization.sh with init_command_block() function
- [ ] Implement project directory detection logic in init_command_block()
- [ ] Implement workflow ID loading logic in init_command_block()
- [ ] Implement core library sourcing in init_command_block()
- [ ] Implement state restoration logic in init_command_block()
- [ ] Implement error logging context restoration in init_command_block()
- [ ] Add version metadata and documentation to command-initialization.sh
- [ ] Create /home/benjamin/.config/.claude/commands/templates/workflow-command-template.md
- [ ] Document bash block budget guidelines in /home/benjamin/.config/.claude/docs/reference/standards/command-standards.md
- [ ] Add consolidation triggers documentation (>10 blocks = review)
- [ ] Document target block counts by command type (primary: 3-8, utility: 2-4, progressive: 6-10)

**Testing**:
```bash
# Test command-initialization.sh library loading
source /home/benjamin/.config/.claude/lib/workflow/command-initialization.sh
type init_command_block  # Should output function definition

# Test init_command_block function with mock state file
echo "test_workflow_id" > /tmp/test_state_id.txt
init_command_block /tmp/test_state_id.txt "/test"
echo $?  # Should return 0 for success
```

**Expected Duration**: 3 hours

### Phase 2: Command Initialization Library Integration [NOT STARTED]
dependencies: [1]

**Objective**: Integrate command-initialization.sh into all 6 workflow commands, replacing 30-40 line initialization blocks with 2-line library calls.

**Complexity**: Medium

**Tasks**:
- [ ] Integrate command-initialization.sh into /home/benjamin/.config/.claude/commands/plan.md (Block 2, 3, 4)
- [ ] Integrate command-initialization.sh into /home/benjamin/.config/.claude/commands/debug.md (all bash blocks)
- [ ] Integrate command-initialization.sh into /home/benjamin/.config/.claude/commands/research.md (Block 2, 3)
- [ ] Integrate command-initialization.sh into /home/benjamin/.config/.claude/commands/build.md (Block 2, 3, 4)
- [ ] Integrate command-initialization.sh into /home/benjamin/.config/.claude/commands/revise.md (all bash blocks)
- [ ] Integrate command-initialization.sh into /home/benjamin/.config/.claude/commands/repair.md (Block 2, 3)
- [ ] Verify state management preserved in all commands after integration
- [ ] Verify error logging preserved in all commands after integration
- [ ] Test each command end-to-end after library integration
- [ ] Document migration patterns in command-initialization.sh header

**Testing**:
```bash
# Test /plan command with new initialization
cd /home/benjamin/.config
/plan "test feature" --dry-run

# Test /debug command with new initialization
/debug "test issue" --dry-run

# Test /research command with new initialization
/research "test topic" --dry-run

# Test /build command with new initialization
# (requires existing plan, skip if not available)

# Verify error logging still functional
/errors --since 1h --command /plan
```

**Expected Duration**: 5 hours

### Phase 3: Bash Block Consolidation - /expand and /collapse [NOT STARTED]
dependencies: [2]

**Objective**: Consolidate /expand from 32 blocks to ≤8 blocks and /collapse from 29 blocks to ≤8 blocks through strategic block merging.

**Complexity**: High

**Tasks**:
- [ ] Analyze /home/benjamin/.config/.claude/commands/expand.md block structure and dependencies
- [ ] Identify adjacent blocks in /expand with no agent invocations between them
- [ ] Map validation operations in /expand for consolidation into single validation block
- [ ] Design consolidated block structure for /expand (target: 8 blocks)
- [ ] Refactor /expand to consolidated structure (Block 1: Setup, Block 2-6: Operations, Block 7: Validation, Block 8: Completion)
- [ ] Test /expand with automatic phase expansion scenario
- [ ] Test /expand with manual phase N expansion scenario
- [ ] Analyze /home/benjamin/.config/.claude/commands/collapse.md block structure and dependencies
- [ ] Identify adjacent blocks in /collapse with no agent invocations between them
- [ ] Map validation operations in /collapse for consolidation into single validation block
- [ ] Design consolidated block structure for /collapse (target: 8 blocks)
- [ ] Refactor /collapse to consolidated structure (Block 1: Setup, Block 2-6: Operations, Block 7: Validation, Block 8: Completion)
- [ ] Test /collapse with automatic phase collapse scenario
- [ ] Test /collapse with manual phase N collapse scenario
- [ ] Verify state persistence across new block boundaries in both commands

**Testing**:
```bash
# Test /expand automatic phase expansion
cd /home/benjamin/.config/.claude/tests/progressive
./test_progressive_expansion.sh

# Test /expand manual phase expansion
cd /home/benjamin/.config
/expand phase /path/to/plan.md 1

# Test /collapse automatic phase collapse
cd /home/benjamin/.config/.claude/tests/progressive
./test_progressive_collapse.sh

# Test /collapse manual phase collapse
cd /home/benjamin/.config
/collapse phase /path/to/expanded_plan.md 1

# Run progressive roundtrip test
cd /home/benjamin/.config/.claude/tests/progressive
./test_progressive_roundtrip.sh
```

**Expected Duration**: 8 hours

### Phase 4: Documentation Standardization [NOT STARTED]
dependencies: [3]

**Objective**: Standardize all commands to "Block N" documentation pattern and enhance README navigation structure.

**Complexity**: Low

**Tasks**:
- [ ] Migrate /home/benjamin/.config/.claude/commands/debug.md from "Part N" to "Block N" pattern
- [ ] Review /home/benjamin/.config/.claude/commands/expand.md for consistent "Block N" pattern after consolidation
- [ ] Review /home/benjamin/.config/.claude/commands/collapse.md for consistent "Block N" pattern after consolidation
- [ ] Add table of contents to /home/benjamin/.config/.claude/commands/README.md (Core Workflow, Primary Commands, Workflow Commands, Utility Commands, etc.)
- [ ] Create hierarchical navigation structure in README with anchor links
- [ ] Update section organization documentation in README to reflect "Block N" standard
- [ ] Document "Block" vs "Phase" vs "Part" terminology conventions in README
- [ ] Verify all cross-references in documentation are accurate after refactoring

**Testing**:
```bash
# Validate markdown syntax in all command files
cd /home/benjamin/.config/.claude/commands
for file in *.md; do
  markdown-lint "$file" 2>/dev/null || echo "Lint check for $file"
done

# Verify table of contents links in README.md
# (Manual verification - click through all TOC links)

# Grep for inconsistent section naming
grep -n "^## Part" /home/benjamin/.config/.claude/commands/*.md
# Should return no results after standardization
```

**Expected Duration**: 3 hours

### Phase 5: Testing and Validation [NOT STARTED]
dependencies: [4]

**Objective**: Run comprehensive integration tests on all refactored commands to ensure functionality, state persistence, and error recovery are preserved.

**Complexity**: Medium

**Tasks**:
- [ ] Run integration tests for /plan command at /home/benjamin/.config/.claude/tests/integration/test_workflow_initialization.sh
- [ ] Run integration tests for /debug command at /home/benjamin/.config/.claude/tests/integration/test_command_integration.sh
- [ ] Run integration tests for /build command at /home/benjamin/.config/.claude/tests/integration/test_command_integration.sh
- [ ] Run integration tests for /expand and /collapse at /home/benjamin/.config/.claude/tests/progressive/
- [ ] Test state persistence across block boundaries in all refactored commands
- [ ] Test error logging and recovery workflows at /home/benjamin/.config/.claude/tests/unit/test_error_logging.sh
- [ ] Verify agent integration still functional with Task invocations
- [ ] Test /repair workflow with logged errors from refactored commands
- [ ] Run system-wide location detection tests at /home/benjamin/.config/.claude/tests/integration/test_system_wide_location.sh
- [ ] Document any test failures and create fix tasks

**Testing**:
```bash
# Run all integration tests
cd /home/benjamin/.config/.claude/tests/integration
for test in test_*.sh; do
  echo "Running $test..."
  ./"$test" || echo "FAILED: $test"
done

# Run all progressive tests
cd /home/benjamin/.config/.claude/tests/progressive
for test in test_*.sh; do
  echo "Running $test..."
  ./"$test" || echo "FAILED: $test"
done

# Run unit tests for error logging
cd /home/benjamin/.config/.claude/tests/unit
./test_error_logging.sh

# Run state management tests
cd /home/benjamin/.config/.claude/tests/state
for test in test_*.sh; do
  echo "Running $test..."
  ./"$test" || echo "FAILED: $test"
done
```

**Expected Duration**: 4 hours

### Phase 6: Documentation and Standards Update [NOT STARTED]
dependencies: [5]

**Objective**: Update .claude/docs/ to reflect optimized patterns, document new command-initialization.sh library, and update CLAUDE.md references.

**Complexity**: Low

**Tasks**:
- [ ] Create library documentation at /home/benjamin/.config/.claude/lib/workflow/README.md documenting command-initialization.sh
- [ ] Add command-initialization.sh usage examples to workflow library documentation
- [ ] Update /home/benjamin/.config/.claude/docs/reference/standards/command-reference.md with optimization notes
- [ ] Document bash block consolidation patterns in command-standards.md
- [ ] Update /home/benjamin/.config/CLAUDE.md "output_formatting" section with bash block budget reference
- [ ] Create optimization case study documenting /expand and /collapse consolidation
- [ ] Update /home/benjamin/.config/.claude/docs/guides/commands/ with refactoring best practices
- [ ] Document command template usage in development workflow documentation
- [ ] Add "Command Optimization" section to .claude/docs/concepts/patterns/
- [ ] Update cross-references throughout .claude/docs/ to reflect optimized command patterns

**Testing**:
```bash
# Validate markdown syntax in updated documentation
cd /home/benjamin/.config/.claude/docs
find . -name "*.md" -exec markdown-lint {} \; 2>/dev/null

# Verify all cross-references are valid
cd /home/benjamin/.config/.claude/docs
grep -r "\[.*\](.*\.md)" . | while read line; do
  # Extract and verify file paths (manual verification)
  echo "$line"
done

# Check for broken internal links
cd /home/benjamin/.config
grep -r "\.claude/lib/workflow/command-initialization\.sh" .claude/ | wc -l
# Should show multiple references across commands and docs
```

**Expected Duration**: 3 hours

## Testing Strategy

### Unit Testing
- Test command-initialization.sh library functions in isolation
- Verify init_command_block() handles edge cases (missing state file, invalid paths)
- Test library sourcing with 2>/dev/null output suppression

### Integration Testing
- Run existing test suite at .claude/tests/integration/ after each phase
- Verify state persistence across refactored block boundaries
- Test error logging integration throughout command lifecycle
- Validate agent Task invocations still functional

### Progressive Operation Testing
- Test /expand automatic and manual phase expansion scenarios
- Test /collapse automatic and manual phase collapse scenarios
- Run roundtrip test (expand → collapse → verify original structure)
- Verify parallel expansion/collapse operations still supported

### Regression Testing
- Compare bash block count before/after consolidation (/expand: 32→8, /collapse: 29→8)
- Measure initialization overhead reduction (1,200+ lines eliminated)
- Verify 100% metadata compliance maintained
- Confirm error handling patterns (171 occurrences) preserved
- Validate state management patterns (379 occurrences) preserved

### Performance Validation
- Measure command execution time before/after optimization
- Compare state serialization overhead (fewer blocks = less overhead)
- Verify no performance degradation in any command

### Documentation Testing
- Validate markdown syntax in all refactored files
- Verify table of contents links in README.md
- Check for broken cross-references in documentation
- Ensure "Block N" pattern consistency across all commands

## Documentation Requirements

### New Documentation
- [ ] /home/benjamin/.config/.claude/lib/workflow/README.md - Document command-initialization.sh library with usage examples
- [ ] /home/benjamin/.config/.claude/commands/templates/workflow-command-template.md - Template for new command development
- [ ] /home/benjamin/.config/.claude/docs/concepts/patterns/command-optimization.md - Case study of optimization patterns

### Updated Documentation
- [ ] /home/benjamin/.config/.claude/docs/reference/standards/command-standards.md - Add bash block budget guidelines and consolidation triggers
- [ ] /home/benjamin/.config/.claude/commands/README.md - Add table of contents and hierarchical navigation
- [ ] /home/benjamin/.config/CLAUDE.md - Update output_formatting section with bash block budget reference
- [ ] /home/benjamin/.config/.claude/docs/reference/standards/command-reference.md - Add optimization notes and library references
- [ ] /home/benjamin/.config/.claude/docs/guides/commands/ - Update with refactoring best practices

### Documentation Standards
- Follow CommonMark specification
- Use Unicode box-drawing for diagrams (no emojis in file content)
- Include code examples with syntax highlighting
- Maintain bidirectional cross-references
- No historical commentary (present facts, not history)

## Dependencies

### External Dependencies
- Existing test suite at /home/benjamin/.config/.claude/tests/
- Library functions: state-persistence.sh, workflow-state-machine.sh, error-handling.sh
- Standards file: /home/benjamin/.config/CLAUDE.md

### Internal Dependencies
- Phase 2 depends on Phase 1 (library must exist before integration)
- Phase 3 depends on Phase 2 (commands must use library before consolidation)
- Phase 4 depends on Phase 3 (documentation reflects consolidated structure)
- Phase 5 depends on Phase 4 (test final documentation state)
- Phase 6 depends on Phase 5 (document validated patterns)

### Risk Mitigation
- **Risk**: Breaking existing functionality during refactoring
  - **Mitigation**: Run integration tests after each phase, maintain git history for rollback
- **Risk**: State persistence issues across new block boundaries
  - **Mitigation**: Extensive testing of state loading/saving, verify STATE_FILE integrity
- **Risk**: Error logging disruption
  - **Mitigation**: Verify error handling patterns preserved, test /errors and /repair workflows
- **Risk**: Agent integration failures
  - **Mitigation**: Test Task invocations end-to-end, verify prompt structure unchanged

## Rollback Procedures

### Phase-Level Rollback
If any phase introduces regressions:
1. Identify failing tests and root cause
2. Use git to revert changes from that phase
3. Document failure reason in plan
4. Revise phase approach and re-attempt

### Command-Level Rollback
If individual command refactoring fails:
1. Revert that command file only (git checkout HEAD~1 -- .claude/commands/command.md)
2. Continue with other commands
3. Document command-specific issues
4. Create follow-up task for problematic command

### Library Rollback
If command-initialization.sh library causes issues:
1. Revert library file
2. Revert all command integrations
3. Return to manual initialization patterns
4. Analyze library design issues

## Success Metrics

### Quantitative Metrics
- [ ] Initialization duplication reduced by 1,200+ lines (30-40 lines × 6 commands × 5 blocks)
- [ ] /expand bash blocks reduced from 32 to ≤8 (75% reduction)
- [ ] /collapse bash blocks reduced from 29 to ≤8 (72% reduction)
- [ ] 100% metadata compliance maintained across all commands
- [ ] All integration tests pass (0 failures)
- [ ] Documentation pattern consistency: 100% "Block N" adoption

### Qualitative Metrics
- [ ] Code maintainability improved through reduced duplication
- [ ] Developer experience enhanced with command template and guidelines
- [ ] Documentation navigability improved with table of contents
- [ ] Standards clarity enhanced with explicit bash block budget guidelines
- [ ] Command execution performance maintained or improved

### Validation Criteria
- [ ] All commands execute successfully with new library
- [ ] State persistence verified across all refactored block boundaries
- [ ] Error logging integration confirmed in /errors and /repair workflows
- [ ] Agent Task invocations functioning correctly
- [ ] Test suite passes at 100%
