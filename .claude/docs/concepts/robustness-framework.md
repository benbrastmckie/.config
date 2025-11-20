# Robustness Framework

**Path**: docs → concepts → robustness-framework.md

[Used by: /implement, /plan, /coordinate, all command and agent development]

Unified index of 9 robustness patterns for building reliable, maintainable commands and agents that achieve 100% success rates across diverse execution environments.

## Purpose

This framework consolidates scattered robustness guidance into a central pattern index, eliminating the discovery burden of reading 4+ research reports. Each pattern includes clear "When to Apply" guidance and "How to Test" validation methods.

## Pattern Index

### Pattern 1: Fail-Fast Verification

**Description**: Validate file creation and critical operations immediately after execution, exposing failures with clear diagnostics rather than masking them with silent fallbacks.

**When to Apply**:
- After any Write tool invocation
- After delegating file creation to agents
- After critical bash commands that create files
- When workflow depends on file existence

**How to Test**:
```bash
# Test verification checkpoint exists
grep -q "MANDATORY VERIFICATION" command_file.md

# Test verification includes diagnostics
grep -q "troubleshooting" command_file.md
```

**Complete Documentation**: [Verification and Fallback Pattern](patterns/verification-fallback.md)

**Cross-References**:
- Code Standards → Pattern 5 (Comprehensive Testing)
- Command Architecture Standards → Standard 11 (Return Format Protocol)

### Pattern 2: Agent Behavioral Injection

**Description**: Inject execution context, artifact paths, and role clarifications into agent prompts through file content rather than tool invocations, enabling hierarchical multi-agent patterns.

**When to Apply**:
- When orchestrating multiple agents
- When file paths must be calculated before agent execution
- When context usage exceeds 30% threshold
- When preventing role ambiguity in hierarchical workflows

**How to Test**:
```bash
# Test role clarification present
grep -q "YOU ARE THE ORCHESTRATOR" command_file.md

# Test path injection before agent invocation
grep -B 10 "Task tool" command_file.md | grep -q "REPORT_PATH"

# Test agent invocation uses Task (not SlashCommand)
! grep -q "SlashCommand" command_file.md || echo "ERROR: Use Task tool"
```

**Complete Documentation**: [Behavioral Injection Pattern](patterns/behavioral-injection.md)

**Cross-References**:
- Command Architecture Standards → Standard 0 (Execution Enforcement)
- Context Management → Hierarchical Supervision Integration

### Pattern 3: Library Integration

**Description**: Source library functions for shared functionality (path calculation, artifact creation, error handling) to ensure consistency across commands.

**When to Apply**:
- When calculating artifact paths
- When creating topic directories
- When implementing error handling
- When managing checkpoints

**How to Test**:
```bash
# Test library sourcing present
grep -q "source.*/.claude/lib/" command_file.md

# Test library function usage
grep -q "get_or_create_topic_dir\|create_topic_artifact\|save_checkpoint" command_file.md
```

**Complete Documentation**: [Library API Reference](../reference/library-api/overview.md)

**Cross-References**:
- Defensive Programming → Section 1 (Input Validation)
- Command Development Guide → Section 3 (Library Integration)

### Pattern 4: Lazy Directory Creation

**Description**: Create directories on-demand when needed rather than eagerly at workflow start, avoiding permission errors and filesystem clutter.

**When to Apply**:
- Before creating files in new directories
- When implementing artifact creation workflows
- When directory existence is uncertain

**How to Test**:
```bash
# Test directory creation before file write
grep -B 5 "Write tool" command_file.md | grep -q "mkdir -p\|get_or_create_topic_dir"

# Test idempotent directory creation
grep -q "mkdir -p" command_file.md
```

**Complete Documentation**: [Defensive Programming](patterns/defensive-programming.md) → Section 4 (Idempotent Operations)

**Cross-References**:
- Code Standards → Standard 13 (Absolute Paths)
- Library API → `get_or_create_topic_dir` function

### Pattern 5: Comprehensive Testing

**Description**: Validate all file creation operations, cross-references, and behavioral compliance using layered test strategies (file existence, content validation, link validation, behavioral compliance).

**When to Apply**:
- After completing implementation phases
- Before committing changes
- When adding new commands or agents
- When documenting patterns

**How to Test**:
```bash
# Layer 1: File existence
test -f expected_file.md || echo "ERROR: File missing"

# Layer 2: Content validation
grep -q "expected section" expected_file.md

# Layer 3: Cross-reference validation
grep -q "expected-link.md" referencing_file.md

# Layer 4: Agent behavioral compliance
# See testing-protocols.md for behavioral test suite
```

**Complete Documentation**: [Testing Protocols](../reference/standards/testing-protocols.md)

**Cross-References**:
- Command Development Guide → Section 4 (Testing)
- Agent Development Guide → Section 3 (Behavioral Compliance)

### Pattern 6: Absolute Paths

**Description**: Use absolute paths throughout command and agent execution to avoid directory-dependent failures.

**When to Apply**:
- When calculating artifact paths
- When sourcing library functions
- When passing file paths to agents
- When reading/writing files

**How to Test**:
```bash
# Test absolute path usage
grep -q "CLAUDE_PROJECT_DIR" command_file.md
grep -q '\$CLAUDE_PROJECT_DIR' command_file.md

# Test no relative paths in critical operations
! grep -E '^\.\./|^\.\/' command_file.md || echo "WARNING: Relative paths detected"
```

**Complete Documentation**: [Code Standards](../reference/standards/code-standards.md) → Standard 13

**Cross-References**:
- Library API → Path calculation functions
- Defensive Programming → Section 1 (Input Validation)

### Pattern 7: Error Context

**Description**: Structure error messages with WHICH operation, WHAT failed, and WHERE it occurred to enable rapid debugging.

**When to Apply**:
- In all error messages
- When implementing validation checkpoints
- When reporting agent failures
- When handling bash command failures

**How to Test**:
```bash
# Test structured error format
grep -q "ERROR:.*-.*-" command_file.md

# Test error includes location
grep "ERROR:" command_file.md | grep -q "Phase\|Step\|Line"
```

**Complete Documentation**: [Error Enhancement Guide](../guides/patterns/error-enhancement-guide.md)

**Cross-References**:
- Defensive Programming → Section 5 (Error Context)
- Code Standards → General Principles (Error Handling)

### Pattern 8: Idempotent Operations

**Description**: Design operations that can be safely executed multiple times without changing the result beyond the initial application.

**When to Apply**:
- When creating directories (`mkdir -p`)
- When sourcing libraries (with guards)
- When updating existing files
- When implementing resumable workflows

**How to Test**:
```bash
# Test directory creation idempotent
grep -q "mkdir -p" command_file.md

# Test operations safe to repeat
# Run command twice, verify identical result
```

**Complete Documentation**: [Defensive Programming](patterns/defensive-programming.md) → Section 4

**Cross-References**:
- Library API → Checkpoint utilities
- Command Development Guide → Resumable Workflows

### Pattern 10: Return Format Protocol

**Description**: Standardize how agents and library functions return results, using structured formats (paths, status codes, JSON) for reliable parsing.

**When to Apply**:
- When designing agent outputs
- When implementing library functions
- When parsing bash command results
- When coordinating multi-agent workflows

**How to Test**:
```bash
# Test agent return format documented
grep -q "Agent MUST return" command_file.md

# Test return format includes expected fields
grep -q "file_path\|status\|error_message" command_file.md
```

**Complete Documentation**: [Command Architecture Standards](../reference/architecture/overview.md) → Standard 11

**Cross-References**:
- Behavioral Injection → Agent Communication Protocol
- Library API → Function Return Values

## Pattern Selection Guide

**When building a new command**:
1. Start with Pattern 3 (Library Integration) for path calculation
2. Add Pattern 6 (Absolute Paths) for all file operations
3. Add Pattern 1 (Fail-Fast Verification) after critical operations
4. Add Pattern 7 (Error Context) for all error messages
5. Validate with Pattern 5 (Comprehensive Testing)

**When orchestrating agents**:
1. Apply Pattern 2 (Behavioral Injection) for context injection
2. Apply Pattern 10 (Return Format Protocol) for agent outputs
3. Apply Pattern 1 (Fail-Fast Verification) after agent completion
4. Apply Pattern 5 (Comprehensive Testing) for behavioral compliance

**When implementing file operations**:
1. Apply Pattern 6 (Absolute Paths) for all paths
2. Apply Pattern 4 (Lazy Directory Creation) before writes
3. Apply Pattern 8 (Idempotent Operations) for directories
4. Apply Pattern 1 (Fail-Fast Verification) after writes

## Validation Methods

**Pre-commit Validation**:
- Run tests for affected commands: `bash .claude/tests/test_*.sh`
- Verify link integrity: `.claude/scripts/validate-links-quick.sh`
- Check command syntax and structure manually

**Integration Validation**:
- Cross-reference accuracy: All links point to existing files
- Pattern completeness: All 9 patterns documented
- Standards conformance: ≥95/100 audit scores

## Related Documentation

**Pattern Details**:
- [Defensive Programming Patterns](patterns/defensive-programming.md)
- [Verification and Fallback Pattern](patterns/verification-fallback.md)
- [Behavioral Injection Pattern](patterns/behavioral-injection.md)
- [Context Management](patterns/context-management.md)

**Standards**:
- [Code Standards](../reference/standards/code-standards.md)
- [Command Architecture Standards](../reference/architecture/overview.md)
- [Testing Protocols](../reference/standards/testing-protocols.md)

**Guides**:
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md)
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md)
- [Error Enhancement Guide](../guides/patterns/error-enhancement-guide.md)
- [Library API Reference](../reference/library-api/overview.md)
