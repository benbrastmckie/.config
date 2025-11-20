# Architecture Standards: Dependencies and Content Separation

**Related Documents**:
- [Overview](overview.md) - Standards index and fundamentals
- [Validation](validation.md) - Execution enforcement patterns
- [Integration](integration.md) - Agent invocation patterns

---

## Standard 12: Structural vs Behavioral Content Separation

Commands MUST distinguish between structural templates (inline) and behavioral content (referenced).

### Requirement - Structural Templates MUST Be Inline

Commands MUST include the following structural templates inline:

1. **Task Invocation Syntax**: `Task { subagent_type, description, prompt }` structure
   - Rationale: Commands must parse this structure to invoke agents correctly

2. **Bash Execution Blocks**: `**EXECUTE NOW**: bash commands`
   - Rationale: Commands must execute these operations directly

3. **JSON Schemas**: Data structure definitions for agent communication
   - Rationale: Commands must parse and validate data structures

4. **Verification Checkpoints**: `**MANDATORY VERIFICATION**: file existence checks`
   - Rationale: Orchestrator (command) is responsible for verification

5. **Critical Warnings**: `**CRITICAL**: error conditions and constraints`
   - Rationale: Execution-critical constraints that commands must enforce immediately

### Prohibition - Behavioral Content MUST NOT Be Duplicated

Commands MUST NOT duplicate agent behavioral content inline. Instead, reference agent files via behavioral injection pattern:

Behavioral content includes:
1. **Agent STEP Sequences**: `STEP 1/2/3` procedural instructions
   - Location: `.claude/agents/*.md` files ONLY
   - Pattern: "Read and follow: .claude/agents/[name].md" with context injection

2. **File Creation Workflows**: `PRIMARY OBLIGATION` blocks defining agent internal procedures
   - Location: `.claude/agents/*.md` files ONLY

3. **Agent Verification Steps**: Agent-internal quality checks before returning
   - Location: `.claude/agents/*.md` files ONLY

4. **Output Format Specifications**: Templates showing how agent should format responses
   - Location: `.claude/agents/*.md` files ONLY

### Rationale

- Single source of truth: Agent behavioral guidelines exist in one location only
- Maintenance burden reduction: 50-67% reduction by eliminating duplication
- Context efficiency: 90% code reduction per agent invocation (150 lines -> 15 lines)
- Synchronization elimination: No need to manually sync behavioral content across files

### Enforcement

Validation criteria:
- STEP instruction count in commands: <5 (behavioral content should be in agent files)
- Agent invocation size: <50 lines per Task block (context injection only)
- PRIMARY OBLIGATION presence: Zero occurrences in command files (agent files only)
- Behavioral file references: All agent invocations should reference behavioral files

Metrics when properly applied:
- 90% reduction in code per agent invocation
- <30% context window usage throughout workflows
- 100% file creation success rate
- Elimination of synchronization burden

### Standard 0 and Standard 12 Reconciliation

**Apparent Tension**: Standard 0 (Execution Enforcement) prescribes inline execution steps, while Standard 12 prescribes referencing behavioral content.

**Resolution**: Apply ownership-based decision criteria.

**Standard 0 applies to** command-owned execution (INLINE):
- Multi-phase orchestration coordination
- Agent preparation and context injection
- Cross-agent workflow progression
- Verification checkpoints

**Standard 12 applies to** agent-owned behavior (REFERENCE):
- File creation workflows
- Research procedures
- Quality check sequences
- Agent output formatting

**Ownership Decision Test**:
```
Ask: "Who executes this STEP sequence?"
- Command/orchestrator -> INLINE (Standard 0)
- Agent/subagent -> REFERENCE (Standard 12)
- Ambiguous -> Default to REFERENCE (fail-safe for context management)
```

---

## Standard 13: Project Directory Detection

### Pattern

Commands MUST use `CLAUDE_PROJECT_DIR` for project-relative paths

### Rationale

- `${BASH_SOURCE[0]}` is unavailable in SlashCommand execution context
- Git-based detection handles worktrees correctly
- Consistent with library implementation patterns
- Eliminates library sourcing failures that require AI-driven recovery

### Implementation

```bash
# Detect project directory if not already set
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
```

### Anti-Pattern

```bash
# INCORRECT - Fails in SlashCommand context
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
```

### When `${BASH_SOURCE[0]}` IS Appropriate

- Standalone test scripts (`.claude/tests/*.sh`)
- Utility scripts executed directly (not via SlashCommand)
- Library files that are sourced (not executed)

### Context Awareness

Commands and scripts have fundamentally different execution contexts:

| Context | Path Detection | Reliability | Use Case |
|---------|---------------|-------------|----------|
| SlashCommand | `CLAUDE_PROJECT_DIR` (git/pwd) | 100% | All command files |
| Standalone Script | `${BASH_SOURCE[0]}` | 100% | Test files, utilities |
| Sourced Library | `${BASH_SOURCE[0]}` | 100% | Library files |

### Error Diagnostics

When library sourcing fails, provide enhanced diagnostics:

```bash
if [ -f "$LIB_DIR/library-sourcing.sh" ]; then
  source "$LIB_DIR/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  echo ""
  echo "Expected location: $LIB_DIR/library-sourcing.sh"
  echo ""
  echo "Diagnostic information:"
  echo "  CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR}"
  echo "  LIB_DIR: ${LIB_DIR}"
  echo "  Current directory: $(pwd)"
  echo ""
  exit 1
fi
```

---

## Standard 14: Executable/Documentation File Separation

### Requirement

Commands MUST separate executable logic from comprehensive documentation into distinct files

### Pattern: Two-file architecture for all commands

1. **Executable Command File** (`.claude/commands/command-name.md`)
   - Purpose: Lean execution script for AI interpreter
   - Size: Target <250 lines (simple commands), max 1,200 lines (complex orchestrators)
   - Content: Bash blocks, phase markers, minimal inline comments (WHAT not WHY)
   - Documentation: Single-line reference to guide file only
   - Audience: AI executor (Claude during command execution)

2. **Command Guide File** (`.claude/docs/guides/command-name-command-guide.md`)
   - Purpose: Complete task-focused documentation for human developers
   - Size: Unlimited (typically 500-5,000 lines)
   - Content: Architecture, examples, troubleshooting, design decisions
   - Cross-reference: Links back to executable file
   - Audience: Human developers, maintainers, contributors

### Rationale

Mixed-purpose command files combining execution with documentation cause four critical failures:

1. **Recursive Invocation Bugs**: Claude misinterprets documentation as conversational instructions
2. **Permission Denied Errors**: Claude tries to execute `.md` files as bash scripts
3. **Infinite Loops**: Multiple recursive invocations occur before execution begins
4. **Context Bloat**: 520+ lines of documentation load before first executable instruction

**Evidence**: Pre-migration meta-confusion rate: 75% (15/20 test runs). Post-migration: 0% (0/100 test runs).

### Enforcement Criteria

**Size Limits**:
```bash
# Simple commands (most commands)
if [ "$lines" -gt 250 ]; then
  echo "FAIL: Exceeds 250-line target for simple commands"
fi

# Complex orchestrators (/coordinate, /orchestrate, /supervise)
if [ "$lines" -gt 1200 ]; then
  echo "FAIL: Exceeds 1,200-line maximum for orchestrators"
fi
```

**Cross-Reference Requirement**:

Executable file MUST include:
```markdown
**Documentation**: See `.claude/docs/guides/command-name-command-guide.md`
```

Guide file MUST include:
```markdown
**Executable**: `.claude/commands/command-name.md`
```

### Migration Results (7 commands completed 2025-11-07)

| Command | Original | New | Reduction | Guide | Status |
|---------|----------|-----|-----------|-------|--------|
| `/coordinate` | 2,334 | 1,084 | 54% | 1,250 | Done |
| `/orchestrate` | 5,439 | 557 | 90% | 4,882 | Done |
| `/implement` | 2,076 | 220 | 89% | 921 | Done |
| `/plan` | 1,447 | 229 | 84% | 460 | Done |
| `/debug` | 810 | 202 | 75% | 375 | Done |
| `/document` | 563 | 168 | 70% | 669 | Done |
| `/test` | 200 | 149 | 26% | 666 | Done |

**Average Reduction**: 70% in executable file size
**Guide Growth**: Average 1,300 lines of comprehensive documentation
**Reliability**: 100% execution success rate (vs 25% pre-migration)

### Benefits Achieved

1. **Meta-Confusion Elimination**: 0% incident rate (was 75% before migration)
2. **Context Reduction**: 70% average reduction freeing context for execution state
3. **Independent Evolution**: Logic changes don't touch docs, doc updates don't risk breaking execution
4. **Unlimited Documentation**: Guides have no size limit, can be comprehensive without bloat
5. **Fail-Fast Execution**: Lean files obviously executable, errors immediate and clear
6. **Scalable Pattern**: Templates enable 60-80% faster new command creation

### Relationship to Other Standards

**Standard 12 (Structural vs Behavioral Separation)**:
- Standard 12: Determines WHAT content (structural templates inline vs behavioral guidelines referenced)
- Standard 14: Determines WHERE content goes (executable vs guide file)
- Combined: Standard 12 determines inline/referenced, Standard 14 determines command/guide

**Standard 11 (Imperative Agent Invocation)**:
- Both prevent conversational interpretation of executable content

**Standard 0 (Execution Enforcement)**:
- Standard 0: Defines imperative vs descriptive language patterns
- Standard 14: Applies imperative language exclusively in executable files

---

## File Organization Standards

### Directory Structure

```
.claude/
├── commands/              # Primary command files (EXECUTION-CRITICAL)
│   ├── orchestrate.md    # Must contain complete execution steps
│   ├── implement.md      # Must contain complete execution steps
│   └── shared/           # Reference files only (SUPPLEMENTAL)
├── agents/               # Agent definition files (EXECUTION-CRITICAL)
│   ├── research-specialist.md
│   ├── plan-architect.md
│   └── *.md
├── templates/            # Reusable templates (REFERENCE-OK)
│   └── *.md
└── docs/                 # Standards and architecture (REFERENCE-OK)
    ├── reference/        # Architecture standards
    └── guides/           # Command guides
```

### File Size Guidelines

**Command Files**:
- **Target**: 500-2000 lines (varies by command complexity)
- **Minimum**: 300 lines (simpler commands)
- **Maximum**: 3000 lines (complex orchestration commands)
- **Warning Signs**:
  - <300 lines: Likely missing execution details
  - <200 lines: Almost certainly broken by over-extraction
  - >3500 lines: Consider splitting into separate commands

**Reference Files** (shared/, templates/, docs/):
- **Target**: 100-1000 lines
- **Purpose**: Extended examples, background, alternatives
- **Rule**: No file in shared/ should be required reading for command execution

### Content Allocation

**80/20 Rule**:
- 80% of execution-critical content stays in command file
- 20% supplemental context can go to reference files

**Critical Mass Principle**:
- Command file must contain enough detail to execute independently
- Reference files enhance understanding but aren't required for execution

---

## Related Documentation

- [Architecture Standards Overview](overview.md)
- [Validation Standards](validation.md)
- [Integration Patterns](integration.md)
- [Testing Standards](testing.md)
- [Template vs Behavioral Distinction](./template-vs-behavioral-distinction.md)
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)
