## Directory Organization Standards
[Used by: /implement, /plan, /refactor, all development commands]

### Purpose

Clear directory organization prevents file misplacement, reduces confusion, and maintains architectural clarity. Each directory has a specific purpose and file placement follows consistent rules.

### Directory Structure

```
.claude/
├── scripts/        Standalone CLI tools (validate, fix, migrate)
├── lib/            Sourced function libraries (parsing, error handling)
├── commands/       Slash command definitions
│   └── templates/  Plan templates (YAML) for /plan-from-template
├── agents/         Specialized AI assistant definitions
│   └── templates/  Agent behavioral templates (sub-supervisor, etc.)
├── skills/         Model-invoked autonomous capabilities
├── docs/           Integration guides and standards
└── tests/          Test suites for system validation
```

### scripts/ - Standalone Operational Tools

**Purpose**: Command-line utilities for system management and validation

**Characteristics**:
- Standalone executables with CLI interfaces
- Include argument parsing (--dry-run, --verbose, --help)
- Complete end-to-end workflows
- Formatted output for human consumption
- May use external tools (npm, curl, git)

**Naming Convention**: `kebab-case-names.sh`

**Examples**:
- `validate-links.sh` - Comprehensive markdown link validation
- `validate-links-quick.sh` - Fast validation for recent file changes
- `detect-empty-topics.sh` - Find empty topic directories
- `validate-agent-behavioral-file.sh` - Validate agent behavioral files

**When to Use**:
- ✓ Building standalone command-line utility
- ✓ Task has complete workflow (input → processing → output)
- ✓ Need CLI argument parsing and formatted output
- ✓ System-level operation (validation, migration, analysis)

**Documentation**: See [scripts/README.md](../../scripts/README.md)

---

### lib/ - Sourced Function Libraries

**Purpose**: Reusable bash functions sourced by commands, agents, and utilities

**Characteristics**:
- Contain `.sh` files with modular functions
- Sourced via `source "$CLAUDE_PROJECT_DIR/.claude/lib/utility.sh"`
- Stateless, pure functions (no side effects)
- General-purpose, used by multiple callers
- Unit testable independently

**Naming Convention**: `kebab-case-names.sh`

**Examples**:
- `plan-parsing.sh` - Extract phases, tasks, metadata from plans
- `error-handling.sh` - Fail-fast error handling and retry logic
- `checkpoint-utils.sh` - State preservation for resumable workflows
- `metadata-extraction.sh` - 99% context reduction through metadata-only passing

**When to Use**:
- ✓ Building reusable functions for sourcing
- ✓ Logic called from multiple commands
- ✓ Functionality is building block, not complete task
- ✓ Pure functions without side effects
- ✓ General-purpose utilities (parsing, validation, transformation)

**Documentation**: See [lib/README.md](../../lib/README.md)

---

### commands/ - Slash Command Definitions

**Purpose**: Slash command markdown files defining development workflows

**Characteristics**:
- Markdown files with bash blocks and phase markers
- Invoked via `/command-name` in Claude Code
- Follow executable/documentation separation pattern
- Commands <250 lines (lean execution scripts)
- Comprehensive guides in `.claude/docs/guides/`

**Naming Convention**: `command-name.md`

**Subdirectory - commands/templates/**:
- Plan templates (YAML) for `/plan-from-template`
- 11 template categories (CRUD, refactoring, testing, etc.)
- Variable substitution system

**Examples**:
- `coordinate.md` - Multi-agent workflow orchestration
- `implement.md` - Execute implementation plans phase-by-phase
- `plan.md` - Create implementation plans
- `templates/crud-api.yaml` - CRUD API plan template

**Documentation**: See [commands/README.md](../../commands/README.md)

---

### agents/ - Specialized AI Assistants

**Purpose**: Behavioral definitions for specialized subagents

**Characteristics**:
- Markdown files defining agent behavior and expertise
- Invoked via Task tool with behavioral injection pattern
- Follow executable/documentation separation (<400 lines)
- Comprehensive guides in `.claude/docs/guides/`

**Naming Convention**: `agent-name.md` or `domain-specialist.md`

**Subdirectory - agents/templates/**:
- Reusable agent behavioral templates
- Standard sections and patterns
- Currently: `sub-supervisor-template.md`

**Examples**:
- `research-sub-supervisor.md` - Coordinates 2-4 research agents
- `implementation-researcher.md` - Analyzes codebase before implementation
- `debug-analyst.md` - Investigates root causes in parallel
- `templates/sub-supervisor-template.md` - Template for hierarchical supervisors

**Documentation**: See [agents/README.md](../../agents/README.md), [agents/templates/README.md](../../agents/templates/README.md)

---

### skills/ - Model-Invoked Capabilities

**Purpose**: Autonomous capabilities that Claude automatically invokes when relevant needs are detected

**Characteristics**:
- **Autonomous**: Claude decides when to invoke (no explicit command needed)
- **Progressive disclosure**: Metadata scanned first, full content loaded only when relevant
- **Composable**: Multiple skills can work together automatically
- **Token efficient**: SKILL.md under 500 lines, details in reference.md
- Invoked via natural language or through command delegation

**Naming Convention**: `kebab-case/` directory names with `SKILL.md` inside

**Directory Structure**:
```
skills/<skill-name>/
├── SKILL.md                    # Required: metadata + core instructions
├── reference.md                # Optional: detailed documentation
├── examples.md                 # Optional: usage examples
├── scripts/                    # Optional: helper scripts (symlink to lib/)
└── templates/                  # Optional: workflow templates
```

**Examples**:
- `document-converter/` - Bidirectional document conversion (Markdown, DOCX, PDF)

**When to Use**:
- Task is a focused, single capability (not a complex workflow)
- Claude should auto-invoke when detecting relevant needs
- Multiple agents/commands would benefit from shared capability
- Progressive disclosure improves token efficiency

**When NOT to Use** (use commands/agents instead):
- Task requires explicit user invocation (use commands/)
- Task requires complex orchestration (use agents/)
- Task is a complete end-to-end workflow (use commands/)

**Integration Patterns**:
1. **Autonomous**: Claude detects need and loads skill automatically
2. **Agent Auto-Loading**: Agents use `skills:` frontmatter field to auto-load skills

**Documentation**: See [skills/README.md](../../skills/README.md), [Skills Authoring Standards](../reference/standards/skills-authoring.md)

---

### docs/ - Integration Guides and Standards

**Purpose**: Comprehensive documentation for patterns, guides, and reference materials

**Structure**:
```
docs/
├── concepts/       Core patterns and architectural concepts
├── guides/         Task-focused how-to guides
├── reference/      API references and catalogs
├── workflows/      End-to-end workflow tutorials
└── troubleshooting/ Problem-solving guides
```

**Documentation**: See [docs/README.md](../README.md)

---

### File Placement Decision Matrix

| Question | scripts/ | lib/ | commands/ | agents/ | skills/ |
|----------|----------|------|-----------|---------|---------|
| Standalone executable? | ✓ | ✗ | ✗ | ✗ | ✗ |
| Needs CLI arguments? | ✓ | ✗ | ✗ | ✗ | ✗ |
| Sourced by other code? | ✗ | ✓ | ✗ | ✗ | ✗ |
| Complete workflow? | ✓ | ✗ | ✓ | ✓ | ✗ |
| Reusable function? | ✗ | ✓ | ✗ | ✗ | ✗ |
| User-facing command? | ✗ | ✗ | ✓ | ✗ | ✗ |
| AI agent behavioral? | ✗ | ✗ | ✗ | ✓ | ✗ |
| Model-invoked capability? | ✗ | ✗ | ✗ | ✗ | ✓ |
| Auto-discoverable? | ✗ | ✗ | ✗ | ✗ | ✓ |
| Single focused capability? | ✗ | ✗ | ✗ | ✗ | ✓ |

### Decision Process

**1. Is it a user-facing slash command?**
→ YES: `commands/command-name.md`
→ NO: Continue

**2. Is it an AI agent behavioral file?**
→ YES: `agents/agent-name.md`
→ NO: Continue

**3. Is it a model-invoked autonomous capability?**
→ YES: `skills/skill-name/SKILL.md`
→ NO: Continue

**4. Is it a standalone executable tool?**
→ YES: `scripts/tool-name.sh`
→ NO: Continue

**5. Is it a reusable function library?**
→ YES: `lib/library-name.sh`
→ NO: Consult with team

### Anti-Patterns

**Wrong Locations**:
- ✗ Agent templates in `.claude/templates/` (should be `agents/templates/`)
- ✗ Plan templates in `.claude/templates/` (should be `commands/templates/`)
- ✗ Validation scripts in `lib/` (should be `scripts/`)
- ✗ Sourced libraries in `scripts/` (should be `lib/`)
- ✗ Standalone executables in `lib/` (should be `scripts/`)
- ✗ Skills without SKILL.md (should have `skills/<name>/SKILL.md`)
- ✗ Skills in `commands/` (should be `skills/` for model-invoked capabilities)

**Naming Violations**:
- ✗ CamelCase for bash scripts (use kebab-case)
- ✗ Underscores in new files (prefer hyphens: `file-name.sh` not `file_name.sh`)
- ✗ Generic names (`utils.sh`, `helpers.sh`, `common.sh`)
- ✗ Missing `.sh` extension for bash scripts

**Organizational Violations**:
- ✗ Creating subdirectories without README.md
- ✗ Mixing executable and library functions in one file
- ✗ Duplicating functionality across directories
- ✗ Cross-directory circular dependencies

### Directory README Requirements

**Every directory must have README.md containing**:

1. **Purpose**: Clear explanation of directory role (1-2 sentences)
2. **Characteristics**: What types of files belong here (bulleted list)
3. **Examples**: 3-5 concrete examples with brief descriptions
4. **When to Use**: Decision criteria for file placement
5. **Documentation Links**: Cross-references to related directories

**Optional sections**:
- vs Other Directories (comparison tables)
- Decision Matrix (when to use this vs alternatives)
- Common Patterns (idioms specific to this directory)
- Best Practices (directory-specific guidelines)

**Example README structure**:
```markdown
# Directory Name

Purpose statement.

## Characteristics
- Characteristic 1
- Characteristic 2

## Examples
- example-1.sh - Description
- example-2.sh - Description

## When to Use
Decision criteria.

## Documentation
Links to related directories and guides.
```

### Verification

**Check file placement**:
```bash
# Verify no misplaced files
ls .claude/templates/  # Should not exist
ls .claude/agents/templates/  # Should contain agent templates
ls .claude/commands/templates/  # Should contain plan templates
```

**Validate naming conventions**:
```bash
# Find CamelCase violations
find .claude/scripts .claude/lib -name "*[A-Z]*"

# Find missing .sh extensions
find .claude/scripts .claude/lib -type f ! -name "*.sh" ! -name "README.md"
```

**Verify README coverage**:
```bash
# Check all directories have READMEs
for dir in scripts lib commands agents docs utils tests; do
  test -f .claude/$dir/README.md || echo "Missing: .claude/$dir/README.md"
done
```

### References

- [scripts/README.md](../../scripts/README.md) - Standalone operational tools
- [lib/README.md](../../lib/README.md) - Sourced function libraries (includes vs scripts/ comparison)
- [skills/README.md](../../skills/README.md) - Model-invoked capabilities guide
- [.claude/README.md](../../README.md) - Complete directory structure guide
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - Creating slash commands
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) - Creating specialized agents
- [Skills Authoring Standards](../reference/standards/skills-authoring.md) - Skills compliance requirements
