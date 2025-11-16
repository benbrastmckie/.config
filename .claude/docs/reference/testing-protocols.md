## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
Commands should check CLAUDE.md in priority order:
1. Project root CLAUDE.md for test commands
2. Subdirectory-specific CLAUDE.md files
3. Language-specific test patterns

### Claude Code Testing
- **Test Location**: `.claude/tests/`
- **Test Runner**: `./run_all_tests.sh`
- **Test Pattern**: `test_*.sh` (Bash test scripts)
- **Coverage Target**: ≥80% for modified code, ≥60% baseline
- **Test Categories**:
  - `test_parsing_utilities.sh` - Plan parsing functions
  - `test_command_integration.sh` - Command workflows
  - `test_progressive_*.sh` - Expansion/collapse operations
  - `test_state_management.sh` - Checkpoint operations
  - `test_shared_utilities.sh` - Utility library functions
  - `test_adaptive_planning.sh` - Adaptive planning integration (16 tests)
  - `test_revise_automode.sh` - /revise auto-mode integration (18 tests)
- **Validation Scripts**:
  - `validate_executable_doc_separation.sh` - Verifies executable/documentation separation pattern compliance (file size, guide existence, cross-references)

### Neovim Testing
- **Test Commands**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
- **Test Pattern**: `*_spec.lua`, `test_*.lua` files in `tests/` or adjacent to source
- **Linting**: `<leader>l` to run linter via nvim-lint
- **Formatting**: `<leader>mp` to format code via conform.nvim
- **Custom Tests**: See individual project documentation

### Coverage Requirements
- Aim for >80% coverage on new code
- All public APIs must have tests
- Critical paths require integration tests
- Regression tests for all bug fixes

### Test Isolation Standards
All tests MUST use isolation patterns to prevent production directory pollution.

**Key Requirements**:
- **Environment Overrides**: Set `CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"` to override location detection
- **Temporary Directories**: Use `mktemp` for unique test directories per run
- **Cleanup Traps**: Register `trap cleanup EXIT` to ensure cleanup on all exit paths
- **Validation**: Test runner detects and reports production directory pollution

**Detection Point**: `unified-location-detection.sh` checks `CLAUDE_SPECS_ROOT` first, preventing production directory creation when override is set.

**Reference Documentation**:
- [Test Isolation Standards](.claude/docs/reference/test-isolation-standards.md) - Complete standards and patterns
- [Library Header Documentation](.claude/lib/unified-location-detection.sh) - CLAUDE_SPECS_ROOT override mechanism (lines 44-68)
- [Test Template](.claude/tests/README.md) - Complete isolation pattern examples

**Utilities**:
- `.claude/scripts/detect-empty-topics.sh` - Detect and remove empty topic directories
- `.claude/tests/run_all_tests.sh` - Automated pollution detection (pre/post-test validation)

**Manual Testing Best Practices**:
When testing commands manually, always set isolation overrides:
```bash
export CLAUDE_SPECS_ROOT="/tmp/manual_test_$$"
export CLAUDE_PROJECT_DIR="/tmp/manual_test_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"

# Run command
/command-to-test "arguments"

# Cleanup
rm -rf "/tmp/manual_test_$$"
unset CLAUDE_SPECS_ROOT CLAUDE_PROJECT_DIR
```

This prevents empty directory creation during development and experimentation.
