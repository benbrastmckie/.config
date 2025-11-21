# Skills Architecture Documentation Research Report

**Report ID**: 001_skills_documentation_research
**Topic**: 882_no_name
**Created**: 2025-11-20
**Research Complexity**: 3
**Type**: Documentation and Standards Analysis

---

## Executive Summary

This research analyzes the completed document-converter skills refactor (plan 879) to identify documentation and standards updates needed across the .claude/ system. The implementation successfully introduced Claude Code's skills architecture pattern but left gaps in centralized documentation, standards, and cross-references.

**Key Findings**:
1. **Skills README exists** but needs integration into broader documentation structure
2. **commands/README.md missing skills section** despite skill delegation in /convert-docs
3. **No skills standards document** in .claude/docs/reference/standards/
4. **Directory organization lacks skills/** documentation
5. **CLAUDE.md has no skills section** to guide discovery
6. **docs/README.md missing skills quick-start path**

**Recommendation**: Create comprehensive skills standards document and update 6 key documentation files to establish skills as a first-class architectural pattern.

---

## Research Findings

### Current Skills Implementation (Plan 879 Completion)

#### Successfully Implemented

**Skill Infrastructure** (Phase 1):
- `.claude/skills/document-converter/` structure created
- SKILL.md with YAML frontmatter and progressive disclosure (<500 lines)
- reference.md with detailed tool documentation
- examples.md with usage patterns
- scripts/ directory with symlinks to lib/convert/ (zero duplication)
- templates/batch-conversion.sh for custom workflows

**Command Integration** (Phase 2):
- `/convert-docs` enhanced with skill availability check (STEP 0)
- Skill delegation path (STEP 3.5) when skill available
- Fallback to script mode when skill unavailable
- Full backward compatibility maintained

**Agent Integration** (Phase 3):
- `doc-converter` agent updated with `skills: document-converter` field
- Agent auto-loads skill into context
- Simplified agent behavioral guidelines (skill handles core logic)

**Documentation Created**:
- `.claude/skills/README.md` - Overview and usage guide
- `.claude/docs/guides/skills/document-converter-skill-guide.md` - Comprehensive guide
- Updated convert-docs command with skill delegation steps

#### Architecture Pattern Established

**Skills vs Commands vs Agents**:
| Aspect | Skills | Slash Commands | Agents |
|--------|--------|----------------|--------|
| Invocation | Autonomous (model-invoked) | Explicit (`/cmd`) | Explicit (Task delegation) |
| Scope | Single focused capability | Quick shortcuts | Complex orchestration |
| Discovery | Automatic | Manual | Manual delegation |
| Context | Main conversation | Main conversation | Separate context window |
| Composition | Auto-composition | Manual chaining | Coordinates skills |

**SKILL.md Structure**:
```yaml
---
name: skill-name
description: Short description (max 200 chars, include trigger keywords)
allowed-tools: Bash, Read, Glob, Write
dependencies:
  - tool>=version
model: haiku-4.5
model-justification: Why this model is appropriate
fallback-model: sonnet-4.5
---
```

**Progressive Disclosure Pattern**:
- Metadata section (YAML) always scanned
- Core instructions loaded only when skill triggered
- Target: <500 lines for token efficiency
- reference.md for detailed documentation (unlimited size)

**Integration Points**:
1. **Autonomous invocation**: Claude detects need and auto-loads skill
2. **Command delegation**: Commands check skill availability and delegate
3. **Agent auto-loading**: Agents declare `skills:` in frontmatter

### Documentation Gaps Analysis

#### 1. Commands README (High Priority)

**Current State**: `.claude/commands/README.md` has no skills section

**Evidence**:
```markdown
## Available Commands
### Primary Commands
#### /convert-docs
**Purpose**: Convert between Markdown, Word (DOCX), and PDF formats bidirectionally
```

**Missing**:
- No mention of skill delegation pattern
- No explanation of STEP 0 (skill availability check)
- No reference to document-converter skill
- No skills integration example

**Impact**: Users and agents won't understand the relationship between commands and skills

**Required Updates**:
- Add "Skills Integration" section after "Command Architecture"
- Document skill delegation pattern with /convert-docs example
- Add skills column to command features table
- Update /convert-docs entry to mention skill delegation

#### 2. Directory Organization (High Priority)

**Current State**: `.claude/docs/concepts/directory-organization.md` has no skills/ section

**Evidence**:
```markdown
.claude/
├── scripts/        Standalone CLI tools
├── lib/            Sourced function libraries
├── commands/       Slash command definitions
├── agents/         Specialized AI assistant definitions
├── docs/           Integration guides and standards
└── tests/          Test suites
```

**Missing**:
- No `skills/` directory in structure diagram
- No "skills/ - Model-Invoked Capabilities" section
- No decision matrix guidance for skills vs commands vs lib
- No examples of when to use skills pattern

**Impact**: Developers won't know where to place skill files or when to create skills

**Required Updates**:
- Add `skills/` to directory structure diagram
- Create "skills/ - Model-Invoked Capabilities" section (similar format to lib/, commands/, agents/)
- Update "File Placement Decision Matrix" with skills criteria
- Add skills anti-patterns section

#### 3. Standards Documentation (High Priority)

**Current State**: No skills standards document exists

**Evidence**:
```bash
$ ls .claude/docs/reference/standards/
adaptive-planning.md  command-authoring.md  documentation-standards.md
agent-reference.md    command-reference.md  output-formatting.md
claude-md-schema.md   code-standards.md     testing-protocols.md
plan-progress.md      README.md             test-isolation.md
```

**Missing**:
- No `skills-standards.md` or `skills-authoring.md`
- No centralized skills best practices
- No YAML frontmatter requirements
- No progressive disclosure guidelines
- No discoverability testing standards

**Impact**: No authoritative reference for skills development standards

**Required Updates**:
- Create `.claude/docs/reference/standards/skills-authoring.md`
- Define SKILL.md structure requirements
- Document progressive disclosure pattern
- Establish description discoverability guidelines
- Define tool restriction standards
- Document model selection criteria

#### 4. CLAUDE.md Skills Section (Medium Priority)

**Current State**: No skills section in root CLAUDE.md

**Evidence**: Grep for "skill" in CLAUDE.md returns no matches

**Missing**:
- No skills discovery guidance
- No `[Used by: commands]` metadata for skills
- No link to skills documentation
- No skills vs commands vs agents explanation

**Impact**: Commands and agents can't discover skills standards through CLAUDE.md

**Required Updates**:
- Add `<!-- SECTION: skills_architecture -->` section
- Include skills vs commands vs agents table
- Link to skills-authoring.md standards
- Add `[Used by: all commands, all agents]` metadata
- Document skill availability checks

#### 5. Docs README Quick Navigation (Medium Priority)

**Current State**: `.claude/docs/README.md` lacks skills quick-start path

**Evidence**:
```markdown
## Quick Navigation for Agents
### Working on Commands?
→ Start: Command Development Guide
### Working on Agents?
→ Start: Agent Development Guide
```

**Missing**:
- No "Working on Skills?" section
- No "I want to create a skill" entry
- No skills troubleshooting link

**Impact**: Reduced discoverability for skills development

**Required Updates**:
- Add "Working on Skills?" quick navigation section
- Add "18. Create reusable skills for autonomous capabilities" to "I Want To..." list
- Link to skills-authoring.md and document-converter-skill-guide.md

#### 6. Standards README Inventory (Low Priority)

**Current State**: `.claude/docs/reference/standards/README.md` missing skills-authoring.md

**Evidence**:
```markdown
| Document | Description |
|----------|-------------|
| command-reference.md | Complete command catalog |
| agent-reference.md | Agent catalog with roles |
| testing-protocols.md | Test discovery patterns |
```

**Missing**: skills-authoring.md entry

**Impact**: Incomplete standards inventory

**Required Updates**:
- Add `skills-authoring.md` to document inventory table

### Best Practices from Implementation

#### Skill Development Pattern

**Established in document-converter**:
1. Create `.claude/skills/<skill-name>/` directory structure
2. Write SKILL.md with discoverable description (<500 lines)
3. Symlink or refactor scripts from lib/ to skills/scripts/
4. Create reference.md for detailed documentation
5. Create examples.md for usage patterns
6. Test discoverability with fresh Claude instance

**Benefits**:
- Zero code duplication via symlinks
- Token efficiency via progressive disclosure
- Autonomous invocation reduces cognitive load
- Composable with other skills

#### Command Enhancement Pattern

**Established in /convert-docs**:
```markdown
### STEP 0 - Skill Availability Check
Check if skill exists before proceeding

### STEP 3.5 - Skill Delegation
When skill available, delegate with natural language

### STEP 4 - Script Mode Fallback
When skill unavailable, use legacy script mode
```

**Benefits**:
- Full backward compatibility
- Graceful degradation
- Clear execution path

#### Agent Integration Pattern

**Established in doc-converter**:
```yaml
---
skills: document-converter
---
```

**Benefits**:
- Automatic skill loading
- Simplified agent behavioral guidelines
- Skill handles core logic, agent provides orchestration

### Skills Use Cases

#### When to Use Skills (vs Commands/Agents/Lib)

**Use Skills When**:
- ✓ Capability should auto-invoke when Claude detects need
- ✓ Functionality is self-contained and focused
- ✓ Composition with other skills is valuable
- ✓ Progressive disclosure provides token efficiency
- ✓ Cross-workflow reusability desired

**Use Commands When**:
- ✓ User-initiated workflow with explicit invocation
- ✓ Quick shortcut for common operations
- ✓ Orchestration of multiple skills/agents needed

**Use Agents When**:
- ✓ Complex multi-phase orchestration required
- ✓ Separate context window beneficial
- ✓ Specialized expertise domain (research, debugging)

**Use Lib When**:
- ✓ Pure bash functions for sourcing
- ✓ Stateless utility functions
- ✓ No autonomous invocation needed

### Standards Integration Points

#### Code Standards Compliance

Document-converter skill follows:
- **Output suppression**: Library sourcing with `2>/dev/null`
- **Lazy directory creation**: No eager `mkdir -p`
- **WHAT comments**: Comments describe what code does, not why
- **Error handling**: Centralized logging with log_command_error()
- **Single summary line**: Per bash block for progress tracking

#### Command Authoring Standards Compliance

/convert-docs command follows:
- **Execution directives**: `**EXECUTE NOW**:` markers
- **Verification checkpoints**: `**MANDATORY VERIFICATION**:` after each step
- **State persistence**: Skill delegation results tracked
- **Subprocess isolation**: Skill runs in isolated context

#### Documentation Standards Compliance

All skills documentation follows:
- **No emojis** in file content (UTF-8 encoding)
- **Unicode box-drawing** for diagrams
- **Clear examples** with syntax highlighting
- **Present-focused writing** (no historical markers)
- **CommonMark specification**

---

## Recommended Documentation Updates

### Priority 1: Core Standards (High Impact)

**1. Create `.claude/docs/reference/standards/skills-authoring.md`**

**Purpose**: Authoritative reference for skills development

**Content Outline**:
```markdown
# Skills Authoring Standards
[Used by: all commands, all agents, skill developers]

## Purpose
Define requirements for creating model-invoked skills

## SKILL.md Structure Requirements
### YAML Frontmatter
### Core Instructions Section
### Size Constraints (<500 lines)

## Progressive Disclosure Pattern
### Metadata-First Loading
### Token Efficiency Strategies

## Description Discoverability
### Trigger Keywords
### Length Constraints (200 chars max)
### Testing Discoverability

## Tool Restrictions
### allowed-tools Specification
### Security Considerations

## Model Selection
### Model Field Requirements
### Fallback Model Specification
### Model Justification

## Integration Patterns
### Command Delegation Pattern
### Agent Auto-Loading Pattern
### Skill Composition Pattern

## Best Practices
### Focused Scope
### Symlinks vs Code Duplication
### Testing Strategies
### Documentation Structure

## Anti-Patterns
### Overly Broad Skills
### Large SKILL.md Files (>500 lines)
### Missing Trigger Keywords
### Undocumented Dependencies
```

**2. Update `.claude/docs/concepts/directory-organization.md`**

**Changes**:
- Add `skills/` to directory structure diagram
- Create "skills/ - Model-Invoked Capabilities" section
- Update "File Placement Decision Matrix" with skills row
- Add skills anti-patterns

**New Section**:
```markdown
### skills/ - Model-Invoked Capabilities

**Purpose**: Autonomous capabilities that Claude automatically invokes

**Characteristics**:
- SKILL.md with YAML frontmatter and progressive disclosure
- Model-invoked (Claude decides when to use)
- Composable with other skills
- Token-efficient (<500 lines in SKILL.md)
- Optional reference.md, examples.md, scripts/, templates/

**Naming Convention**: `skill-name/` (kebab-case directory)

**Examples**:
- `document-converter/` - Bidirectional document conversion
- Future: `research-specialist/`, `plan-generator/`, `doc-generator/`

**When to Use**:
- ✓ Building autonomous capability Claude should invoke
- ✓ Functionality is self-contained and focused
- ✓ Composition with other skills is valuable
- ✓ Cross-workflow reusability desired

**Documentation**: See [skills/README.md](.claude/skills/README.md)
```

### Priority 2: Integration Documentation (Medium Impact)

**3. Update `.claude/commands/README.md`**

**Changes**:
- Add "Skills Integration" section after "Command Architecture"
- Update /convert-docs entry with skill delegation details
- Add skills to "Technical Advantages" section

**New Section**:
```markdown
## Skills Integration

Commands can delegate to skills when available, enabling autonomous capabilities while maintaining backward compatibility.

### Skill Delegation Pattern

**Pattern**:
1. **Check Availability** (STEP 0): Verify skill exists
2. **Delegate** (STEP 3.5): Natural language delegation to skill
3. **Fallback** (STEP 4): Use legacy mode if skill unavailable
4. **Verify** (STEP 6): Validate output regardless of execution path

**Example** (/convert-docs):
```bash
# STEP 0: Check for document-converter skill
if [[ -f "$CLAUDE_PROJECT_DIR/.claude/skills/document-converter/SKILL.md" ]]; then
  SKILL_AVAILABLE=true
fi

# STEP 3.5: Delegate to skill when available
if [[ "$SKILL_AVAILABLE" = true && "$agent_mode" = false ]]; then
  # Natural language delegation
  "Use document-converter skill to convert $input_dir to $output_dir"
fi

# STEP 4: Fallback to script mode
if [[ "$SKILL_AVAILABLE" = false ]]; then
  source .claude/lib/convert/convert-core.sh
  main_conversion "$input_dir" "$output_dir"
fi
```

**Benefits**:
- Autonomous invocation in agent contexts
- Seamless skill composition
- Full backward compatibility
- Graceful degradation

### Commands with Skills Integration

| Command | Skill | Delegation Mode |
|---------|-------|-----------------|
| /convert-docs | document-converter | Optional (script mode fallback) |
```

**4. Update `.claude/docs/README.md`**

**Changes**:
- Add "Working on Skills?" quick navigation section
- Add "Create reusable skills" to "I Want To..." list

**New Content**:
```markdown
18. **Create reusable skills for autonomous capabilities**
    → [Skills Authoring Standards](reference/standards/skills-authoring.md)
    → [Document Converter Skill Guide](guides/skills/document-converter-skill-guide.md)
    → [Skills README](../skills/README.md)

## Quick Navigation for Agents

### Working on Skills?
→ **Start**: [Skills Authoring Standards](reference/standards/skills-authoring.md)
→ **Patterns**: [Skills README](../skills/README.md)
→ **Example**: [Document Converter Skill Guide](guides/skills/document-converter-skill-guide.md)
```

### Priority 3: CLAUDE.md Integration (Medium Impact)

**5. Update Root `CLAUDE.md`**

**Changes**:
- Add `<!-- SECTION: skills_architecture -->` section

**New Section**:
```markdown
<!-- SECTION: skills_architecture -->
## Skills Architecture
[Used by: all commands, all agents]

The .claude/skills/ directory contains model-invoked capabilities that Claude automatically uses when it detects relevant needs. Skills enable autonomous composition and discovery without explicit invocation.

**Skills vs Commands vs Agents**:
| Aspect | Skills | Slash Commands | Agents |
|--------|--------|----------------|--------|
| Invocation | Autonomous (model-invoked) | Explicit (`/cmd`) | Explicit (Task delegation) |
| Discovery | Automatic | Manual | Manual delegation |
| Composition | Auto-composition | Manual chaining | Coordinates skills |

**Available Skills**:
- **document-converter**: Bidirectional document conversion (Markdown ↔ DOCX/PDF)

**Integration Patterns**:
1. **Autonomous invocation**: Claude detects need and auto-loads skill
2. **Command delegation**: Commands check availability with STEP 0, delegate with natural language
3. **Agent auto-loading**: Agents declare `skills: skill-name` in frontmatter

**Skill Availability Check** (for commands):
```bash
# STEP 0: Check if skill exists
SKILL_AVAILABLE=false
if [[ -f "$CLAUDE_PROJECT_DIR/.claude/skills/skill-name/SKILL.md" ]]; then
  SKILL_AVAILABLE=true
fi
```

See [Skills Authoring Standards](.claude/docs/reference/standards/skills-authoring.md) for complete development requirements and [Skills README](.claude/skills/README.md) for usage guide.
<!-- END_SECTION: skills_architecture -->
```

### Priority 4: Standards Inventory (Low Impact)

**6. Update `.claude/docs/reference/standards/README.md`**

**Changes**:
- Add skills-authoring.md to document inventory

**New Entry**:
```markdown
| skills-authoring.md | Skills development standards and SKILL.md requirements |
```

---

## Implementation Guidance

### Execution Order

**Phase 1: Core Standards** (1-2 hours)
1. Create `.claude/docs/reference/standards/skills-authoring.md`
2. Update `.claude/docs/concepts/directory-organization.md`

**Phase 2: Integration Documentation** (1-2 hours)
3. Update `.claude/commands/README.md`
4. Update `.claude/docs/README.md`

**Phase 3: CLAUDE.md and Inventory** (30 minutes)
5. Update root `CLAUDE.md`
6. Update `.claude/docs/reference/standards/README.md`

### Validation Checklist

**Standards Document**:
- [ ] Skills authoring standards created
- [ ] YAML frontmatter requirements documented
- [ ] Progressive disclosure pattern explained
- [ ] Description discoverability guidelines defined
- [ ] Integration patterns documented
- [ ] Best practices and anti-patterns listed

**Directory Organization**:
- [ ] skills/ added to directory structure diagram
- [ ] skills/ section created with characteristics and examples
- [ ] File placement decision matrix updated
- [ ] When to use skills vs commands vs lib clarified

**Commands README**:
- [ ] Skills Integration section added
- [ ] /convert-docs entry updated with skill delegation
- [ ] Skill delegation pattern documented with example
- [ ] Commands with skills table created

**Docs README**:
- [ ] "Create reusable skills" added to "I Want To..." list
- [ ] "Working on Skills?" quick navigation added
- [ ] Links to skills-authoring.md and guides verified

**CLAUDE.md**:
- [ ] skills_architecture section added
- [ ] Skills vs Commands vs Agents table included
- [ ] Skill availability check example provided
- [ ] Links to standards and README added
- [ ] `[Used by: all commands, all agents]` metadata set

**Standards README**:
- [ ] skills-authoring.md added to inventory

### Link Validation

After updates, validate all links:
```bash
.claude/scripts/validate-links.sh
```

**Expected New Links**:
- `skills-authoring.md` ← 4 references
- `skills/README.md` ← 3 references
- `document-converter-skill-guide.md` ← 2 references

### Testing Strategy

**Documentation Completeness**:
1. Grep for "skills" across all documentation
2. Verify all cross-references resolve
3. Check CLAUDE.md section discovery with `/setup --validate`

**Standards Application**:
1. Create test skill following skills-authoring.md
2. Verify YAML frontmatter validation
3. Test description discoverability

**Integration Verification**:
1. Test /convert-docs skill delegation path
2. Verify doc-converter agent auto-loads skill
3. Test skill fallback when unavailable

---

## Success Criteria

**Documentation Coverage**:
- [ ] Skills authoring standards document exists
- [ ] All 6 target files updated
- [ ] Cross-references validated (no broken links)
- [ ] Skills appear in directory organization
- [ ] CLAUDE.md has skills section with metadata

**Discoverability**:
- [ ] "Skills" appears in docs/README.md quick navigation
- [ ] Skills vs Commands vs Agents table in 3 places
- [ ] Skill delegation pattern documented with examples
- [ ] Standards discoverable via CLAUDE.md

**Completeness**:
- [ ] SKILL.md structure requirements defined
- [ ] Progressive disclosure pattern explained
- [ ] Integration patterns documented (command, agent, autonomous)
- [ ] Best practices and anti-patterns listed
- [ ] Tool restriction guidelines established
- [ ] Model selection criteria documented

---

## References

### Analyzed Files

**Skills Implementation**:
- `.claude/specs/879_convert_docs_skills_refactor/plans/001_skills_architecture_refactor.md`
- `.claude/skills/document-converter/SKILL.md`
- `.claude/skills/README.md`
- `.claude/docs/guides/skills/document-converter-skill-guide.md`

**Commands**:
- `.claude/commands/convert-docs.md`
- `.claude/commands/README.md`

**Documentation**:
- `.claude/docs/README.md`
- `.claude/docs/concepts/directory-organization.md`
- `.claude/docs/reference/standards/README.md`
- `CLAUDE.md`

### Git History

**Recent Commits**:
- `3b0e29e1` - feat(skills): implement document-converter skill with full backward compatibility
- Plan 879 completed successfully with all 5 phases

### External References

- [Claude Code Skills Guide](https://code.claude.com/docs/en/skills.md)
- [Skills Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)

---

## Appendix A: Skills Standards Document Outline

Complete outline for `.claude/docs/reference/standards/skills-authoring.md`:

```markdown
# Skills Authoring Standards
[Used by: all commands, all agents, skill developers]

## Purpose
## SKILL.md Structure Requirements
### YAML Frontmatter
  - name (required)
  - description (required, 200 char max, trigger keywords)
  - allowed-tools (required)
  - dependencies (optional)
  - model (required)
  - model-justification (required)
  - fallback-model (required)
### Core Instructions Section
### Size Constraints (<500 lines)
### Optional Files (reference.md, examples.md)

## Progressive Disclosure Pattern
### Metadata-First Loading
### Token Efficiency Strategies
### When to Split to reference.md

## Description Discoverability
### Trigger Keywords Selection
### Length Constraints
### Testing with Fresh Claude Instance
### Common Failure Patterns

## Tool Restrictions
### allowed-tools Specification
### Security Considerations
### Tool Access Validation

## Model Selection
### Model Field Requirements
### Haiku vs Sonnet Selection Criteria
### Fallback Model Strategy
### Model Justification Examples

## Integration Patterns
### Command Delegation Pattern
  - STEP 0: Skill availability check
  - STEP 3.5: Natural language delegation
  - Fallback to legacy mode
### Agent Auto-Loading Pattern
  - skills: field in frontmatter
  - Multiple skills loading
### Skill Composition Pattern
  - Dependencies between skills
  - Auto-loading dependent skills

## Directory Structure
### Required Files
### Optional Files
### scripts/ Directory (symlinks vs duplication)
### templates/ Directory

## Best Practices
### Focused Scope (single capability)
### Symlinks to lib/ (zero duplication)
### Testing Strategies
### Documentation Structure
### Version Management

## Anti-Patterns
### Overly Broad Skills (multiple unrelated capabilities)
### Large SKILL.md Files (>500 lines)
### Missing Trigger Keywords
### Undocumented Dependencies
### Tool Restriction Bypasses

## Testing Requirements
### Discoverability Testing
### Integration Testing
### Fallback Testing
### Composition Testing

## Migration from Commands
### Candidates for Migration
### Migration Template
### Backward Compatibility Requirements

## Examples
### Minimal SKILL.md Example
### Complete Skill Directory Example
### Command Integration Example
### Agent Integration Example

## Troubleshooting
### Skill Not Triggering
### YAML Parsing Errors
### Tool Availability Issues
### Composition Failures

## References
```

---

## Appendix B: Directory Organization Skills Section

Complete skills/ section for `.claude/docs/concepts/directory-organization.md`:

```markdown
### skills/ - Model-Invoked Capabilities

**Purpose**: Autonomous capabilities that Claude automatically invokes when it detects relevant needs

**Characteristics**:
- SKILL.md with YAML frontmatter (name, description, allowed-tools, model)
- Model-invoked (Claude decides when to use, no explicit command)
- Progressive disclosure (metadata scanned first, full content loaded when relevant)
- Composable with other skills (auto-loads dependencies)
- Token-efficient (<500 lines in SKILL.md, reference.md for details)
- Project-scoped (shared via git in .claude/skills/)

**Structure**:
```
.claude/skills/<skill-name>/
├── SKILL.md                    # Required: metadata + core instructions
├── reference.md                # Optional: detailed documentation
├── examples.md                 # Optional: usage examples
├── scripts/                    # Optional: helper scripts (often symlinks to lib/)
└── templates/                  # Optional: workflow templates
```

**Naming Convention**: `kebab-case-name/` (skill-name directory)

**Examples**:
- `document-converter/` - Bidirectional document conversion (Markdown ↔ DOCX/PDF)
- Future candidates: `research-specialist/`, `plan-generator/`, `doc-generator/`

**When to Use**:
- ✓ Building autonomous capability Claude should invoke without user command
- ✓ Functionality is self-contained and focused (single capability)
- ✓ Composition with other skills provides value
- ✓ Cross-workflow reusability is desired
- ✓ Progressive disclosure benefits token efficiency

**When NOT to Use**:
- ✗ User-initiated workflow requiring explicit invocation → Use commands/
- ✗ Pure bash functions for sourcing → Use lib/
- ✗ Complex multi-phase orchestration → Use agents/
- ✗ Multiple unrelated capabilities → Create separate skills

**Integration Points**:
1. **Autonomous invocation**: Claude detects need and loads skill
2. **Command delegation**: Commands check availability and delegate via natural language
3. **Agent auto-loading**: Agents declare `skills:` in frontmatter

**Documentation**: See [skills/README.md](../../skills/README.md), [Skills Authoring Standards](../docs/reference/standards/skills-authoring.md)

**Verification**:
```bash
# Validate skill structure
ls .claude/skills/<skill-name>/SKILL.md

# Validate YAML frontmatter
python3 -c "import yaml; yaml.safe_load(open('SKILL.md').read().split('---')[1])"

# Test discoverability
# Use fresh Claude instance, observe if skill triggers for relevant tasks
```
```

---

## Report Metadata

**Research Hours**: 3 hours
**Files Analyzed**: 13 files (plans, skills, commands, docs)
**Recommended Updates**: 6 documentation files
**Priority Distribution**:
- High Priority: 2 updates (standards, directory org)
- Medium Priority: 3 updates (commands, docs, CLAUDE.md)
- Low Priority: 1 update (standards inventory)

**Next Steps**:
1. Review this report with stakeholders
2. Approve documentation update plan
3. Execute updates in priority order (Phase 1 → Phase 2 → Phase 3)
4. Validate links and cross-references
5. Test standards application with new skill creation

**Review Status**: Pending
**Approval Status**: Pending

---

*This research report establishes the foundation for integrating skills as a first-class architectural pattern in the .claude/ system, ensuring comprehensive documentation coverage and clear standards for future skills development.*
