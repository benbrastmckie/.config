# Testing Standards

This guide is a redirect to the testing standards defined in the project's CLAUDE.md file.

## Quick Reference

For current testing standards, see:
- **CLAUDE.md Testing Protocols Section** - Primary source of truth for testing standards

## Key Testing Standards

The following standards are defined in CLAUDE.md:

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

### Coverage Requirements
- Aim for >80% coverage on new code
- All public APIs must have tests
- Critical paths require integration tests
- Regression tests for all bug fixes

## Related Documentation

- [Testing Patterns Guide](./testing-patterns.md) - Comprehensive testing patterns and examples
- [Migration Testing Guide](./migration-testing.md) - Testing migrated commands
- CLAUDE.md `testing_protocols` section - Complete testing standards

## See Also

- [Command Development Guide](./command-development-guide.md) - Includes testing requirements
- [Agent Development Guide](./agent-development-guide.md) - Agent testing patterns
