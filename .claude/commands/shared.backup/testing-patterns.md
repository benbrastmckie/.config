# Testing Patterns

## Test Discovery
Commands check CLAUDE.md in priority order:
1. Project root CLAUDE.md
2. Subdirectory-specific CLAUDE.md
3. Language-specific test patterns

## Common Test Commands
- `:TestSuite` - Run all tests
- `:TestFile` - Test current file
- `:TestNearest` - Test at cursor
- `npm test` / `pytest` / `cargo test` - Language-specific

## Coverage Requirements
- Aim for >80% on new code
- All public APIs must have tests
- Critical paths require integration tests

## See Also
- [Phase Execution](phase-execution.md)
