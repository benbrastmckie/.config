# Implementation Plan: Research Command Path Resolution

## Metadata
- **Plan ID**: 001_research_command_path_resolution_plan
- **Topic**: 077_research_command_path_resolution
- **Type**: Enhancement
- **Status**: Planning
- **Created**: 2025-10-23
- **Complexity**: Medium
- **Estimated Duration**: 3-4 hours

## Objective
Streamline path resolution in the /research command by creating a dedicated utility function that handles topic-to-path calculation, while maintaining conformance to directory protocols and keeping the command simple and maintainable.

## Success Criteria
- [ ] Path resolution logic extracted to reusable utility function
- [ ] /research command remains under 300 lines with clear focus
- [ ] All directory protocol requirements satisfied (topic-based structure, numbered directories)
- [ ] Utility function has comprehensive test coverage (≥80%)
- [ ] No regression in existing /research command functionality
- [ ] Documentation updated with usage examples

## Research Context
This plan addresses findings from:
- Report 001: Current path resolution is embedded in /research command (~50 lines)
- Report 002: Claude Code skills pattern not appropriate for this use case
- Report 003: Library function approach recommended for simplicity and testability

## Implementation Phases

### Phase 1: Create Path Resolution Utility
**Objective**: Extract and enhance path resolution logic into dedicated library function

**Tasks**:
- [ ] Create `.claude/lib/research-path-utils.sh` with core path resolution function
- [ ] Implement `calculate_research_output_path()` function with parameters:
  - `topic` (required) - The research topic/question
  - `output_type` (required) - "report" or "plan" or "summary"
  - `base_dir` (optional) - Base specs directory (default: `.claude/specs`)
- [ ] Add topic sanitization (convert spaces to underscores, lowercase, remove special chars)
- [ ] Add sequential numbering logic (find next available NNN_topic directory)
- [ ] Add directory creation with proper structure (topic/reports/, topic/plans/, etc.)
- [ ] Include comprehensive input validation and error handling
- [ ] Add debug logging for path calculations

**Testing**:
- [ ] Create `test_research_path_utils.sh` with test cases:
  - Topic sanitization (spaces, special characters, uppercase)
  - Sequential numbering (new topic, existing topic)
  - Directory creation (permissions, structure)
  - Error handling (invalid inputs, write failures)
  - Edge cases (empty topic, very long topic names)
- [ ] Verify test coverage ≥80%

**Complexity**: 4/10
**Estimated Time**: 1.5 hours

---

### Phase 2: Update /research Command Integration
**Objective**: Replace inline path resolution with utility function call

**Tasks**:
- [ ] Source `.claude/lib/research-path-utils.sh` in /research command
- [ ] Replace inline path calculation logic with `calculate_research_output_path()` calls
- [ ] Update error handling to use utility function's validation
- [ ] Simplify command logic by removing redundant path manipulation code
- [ ] Verify command line count reduced (target: <300 lines)
- [ ] Ensure all existing /research functionality preserved

**Testing**:
- [ ] Run existing /research integration tests
- [ ] Test edge cases previously handled inline:
  - Topics with special characters
  - Very long topic names
  - Existing vs new topic directories
- [ ] Verify output paths match directory protocol expectations
- [ ] Test both report and plan generation workflows

**Complexity**: 3/10
**Estimated Time**: 1 hour

---

### Phase 3: Documentation and Validation
**Objective**: Document utility function and validate complete workflow

**Tasks**:
- [ ] Add comprehensive function documentation to `research-path-utils.sh`:
  - Function signature and parameters
  - Return values and exit codes
  - Usage examples
  - Error conditions
- [ ] Update `.claude/lib/README.md` with new utility reference
- [ ] Update `/research` command documentation with simplified logic notes
- [ ] Add usage example to [Command Development Guide](.claude/docs/guides/command-development-guide.md)
- [ ] Run full test suite: `./run_all_tests.sh`
- [ ] Perform integration test with real /research command invocations
- [ ] Verify no regressions in /orchestrate (which uses /research)

**Testing**:
- [ ] Documentation review checklist:
  - All parameters documented
  - Examples are copy-paste ready
  - Error conditions clearly explained
- [ ] End-to-end validation:
  - `/research "new topic"` creates proper directory structure
  - `/research "existing topic"` uses existing directory
  - Output paths conform to directory protocols

**Complexity**: 2/10
**Estimated Time**: 1 hour

---

## Risk Assessment

### High Risks
None identified

### Medium Risks
- **Path calculation regression**: Existing /research behavior might change inadvertently
  - *Mitigation*: Comprehensive test coverage, integration tests before/after
- **Directory protocol violation**: New utility might not fully conform to spec updater expectations
  - *Mitigation*: Review directory protocol documentation, test with /orchestrate workflow

### Low Risks
- **Performance impact**: Additional function sourcing overhead
  - *Mitigation*: Negligible for command execution time, library sourcing is fast

## Dependencies
- Existing `.claude/lib/` utilities (error-handling.sh, unified-logger.sh)
- Directory protocols from CLAUDE.md
- Existing /research command tests for regression validation

## Rollback Plan
If implementation causes issues:
1. Revert /research command to inline path resolution
2. Keep utility function for future use
3. Document lessons learned for next iteration

## Notes
- **Approach Decision**: Library function chosen over Claude Code skill because:
  - Path calculation is deterministic computation, not AI-appropriate task
  - Requires tight integration with bash scripting environment
  - Benefits from direct testing and version control
  - Skills are better suited for document processing/analysis tasks
- **Simplicity Focus**: Keep /research command focused on workflow coordination, delegate path complexity to utility
- **Reusability**: Utility function may benefit other commands (e.g., /plan, /debug) that create topic directories
