---
allowed-tools: Bash, Read, Grep, Glob, Task
argument-hint: <feature/module/file> [test-type]
description: Run project-specific tests based on CLAUDE.md testing protocols
command-type: primary
dependent-commands: debug, test-all, document
---

# /test - Project Test Runner

YOU ARE EXECUTING AS the /test command.

**Documentation**: See `.claude/docs/guides/test-command-guide.md`

---

## Phase 0: Discover Testing Protocols

```bash
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Parse arguments
TARGET="${1:-}"
TEST_TYPE="${2:-all}"

if [ -z "$TARGET" ]; then
  echo "Usage: /test <feature/module/file> [test-type]"
  echo "Test types: unit, integration, all, nearest, file, suite"
  exit 1
fi

echo "Target: $TARGET"
echo "Test Type: $TEST_TYPE"
```

## Phase 1: Identify Test Scope and Commands

```bash
# Load testing protocols from CLAUDE.md
CLAUDE_MD=$(find "$CLAUDE_PROJECT_DIR" -maxdepth 1 -name "CLAUDE.md" | head -1)

if [ -f "$CLAUDE_MD" ]; then
  # Extract testing_protocols section
  TEST_PROTOCOLS=$(sed -n '/<!-- SECTION: testing_protocols -->/,/<!-- END_SECTION: testing_protocols -->/p' "$CLAUDE_MD")
  echo "✓ Testing protocols loaded from CLAUDE.md"
else
  echo "⚠️  CLAUDE.md not found - Using smart detection"
fi

# Detect project type and test framework
PROJECT_TYPE="unknown"

if [ -f "package.json" ]; then
  PROJECT_TYPE="node"
elif [ -f "Cargo.toml" ]; then
  PROJECT_TYPE="rust"
elif [ -f "go.mod" ]; then
  PROJECT_TYPE="go"
elif [ -d "tests/" ] && ls tests/*_spec.lua > /dev/null 2>&1; then
  PROJECT_TYPE="lua"
elif [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
  PROJECT_TYPE="python"
fi

echo "Detected project type: $PROJECT_TYPE"
```

## Phase 2: Execute Tests

**EXECUTE NOW**: Run tests using discovered protocols or delegate to test specialist.

For simple test execution:
```bash
# Execute based on project type
case "$PROJECT_TYPE" in
  node)
    npm test -- "$TARGET"
    ;;
  rust)
    cargo test "$TARGET"
    ;;
  go)
    go test "$TARGET"
    ;;
  python)
    pytest "$TARGET"
    ;;
  lua)
    # Neovim testing
    echo "Run :TestNearest, :TestFile, or :TestSuite in Neovim"
    ;;
  *)
    # Delegate to test specialist agent for complex detection
    echo "Using test specialist for framework detection..."
    ;;
esac
```

For complex scenarios, delegate to specialized agent:
```
Task tool invocation with subagent_type="general-purpose"
Prompt: "Execute tests for target '${TARGET}' with test type '${TEST_TYPE}'.

REQUIREMENTS:
- Discover test framework and commands from CLAUDE.md or project structure
- Identify appropriate test scope (file, module, feature, suite)
- Execute tests with verbose output and coverage if available
- Parse results and identify failures
- Suggest fixes for any test failures using enhanced error analysis

Return:
- Test execution summary (passed/failed/skipped)
- Coverage metrics if available
- Failure analysis with suggested fixes
- Performance metrics if notable
"
```

## Phase 3: Analyze Results and Report

```bash
# Parse test results
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo ""
  echo "✓ All tests passed"
else
  echo ""
  echo "❌ Test failures detected"
  echo "Exit code: $TEST_EXIT_CODE"

  # Enhanced error analysis available
  echo ""
  echo "For detailed failure analysis:"
  echo "  /debug \"test failure in $TARGET\""
fi

echo ""
echo "=== Test Execution Complete ==="
```

---

**Troubleshooting**: See guide for test framework setup, error analysis, and debugging strategies.
