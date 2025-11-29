# Claude Code Skills

Project-level skills for autonomous capabilities in Claude Code workflows.

## What Are Skills?

Skills are **model-invoked** capabilities that Claude automatically uses when it detects relevant needs. Unlike slash commands (user-invoked) or agents (task delegation), skills enable autonomous composition and discovery.

**Key Characteristics**:
- **Autonomous**: Claude decides when to invoke (no explicit command needed)
- **Progressive disclosure**: Metadata scanned first, full content loaded only when relevant
- **Composable**: Multiple skills can work together automatically
- **Scoped**: Project skills (`.claude/skills/`) are shared via git

## Skills vs Commands vs Agents

| Aspect | Skills | Slash Commands | Agents |
|--------|--------|----------------|--------|
| Invocation | Autonomous (model-invoked) | Explicit (`/cmd`) | Explicit (Task delegation) |
| Scope | Single focused capability | Quick shortcuts | Complex orchestration |
| Discovery | Automatic | Manual | Manual delegation |
| Context | Main conversation | Main conversation | Separate context window |
| Composition | Auto-composition | Manual chaining | Coordinates skills |

## Available Skills

### [document-converter](document-converter/README.md)

**Description**: Convert between Markdown, DOCX, and PDF formats bidirectionally. Handles text extraction from PDF/DOCX, markdown to document conversion.

**Use When**: Converting document formats, extracting structured content from Word or PDF files, generating documents from markdown.

**Capabilities**:
- DOCX ↔ Markdown conversion
- PDF → Markdown extraction
- Markdown → PDF generation
- Intelligent tool selection (MarkItDown, Pandoc, PyMuPDF4LLM, Typst, XeLaTeX)
- Batch processing with concurrent conversions
- Quality validation and reporting

**Documentation**:
- [SKILL.md](./document-converter/SKILL.md) - Core skill definition
- [reference.md](./document-converter/reference.md) - Technical reference and API
- [examples.md](./document-converter/examples.md) - Usage examples
- [Skill Guide](../docs/guides/skills/document-converter-skill-guide.md) - Complete guide

**Integration**:
- Autonomous: Claude auto-invokes when analyzing PDFs or generating documents
- Command: `/convert-docs` delegates to skill when available
- Agent: `doc-converter` agent auto-loads skill via `skills:` field

**Example Usage**:
```
User: "Analyze the research papers in ./pdfs/"
→ Claude detects PDF analysis need
→ Invokes document-converter skill automatically
→ Converts PDFs to Markdown
→ Analyzes extracted content
```

## Skill Structure

Each skill follows this structure:

```
.claude/skills/<skill-name>/
├── SKILL.md                    # Required: metadata + core instructions
├── reference.md                # Optional: detailed documentation
├── examples.md                 # Optional: usage examples
├── scripts/                    # Optional: helper scripts
└── templates/                  # Optional: workflow templates
```

### SKILL.md Requirements

**Metadata Section** (YAML frontmatter):
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

**Core Instructions Section**:
- Conversion capabilities overview
- Tool priority matrix
- Usage patterns
- Quality considerations
- Error handling

**Size Target**: < 500 lines (for token efficiency via progressive disclosure)

## Creating New Skills

### 1. Create Skill Directory

```bash
mkdir -p .claude/skills/<skill-name>/{scripts,templates}
```

### 2. Write SKILL.md

```markdown
---
name: skill-name
description: Discoverable description with trigger keywords
allowed-tools: Bash, Read, Glob, Write
model: haiku-4.5
fallback-model: sonnet-4.5
---

# Skill Name

Core capabilities and usage instructions...
```

**Key Points**:
- Description must be discoverable (include keywords Claude would search for)
- Keep under 500 lines for token efficiency
- Focus comments on WHAT code does, not WHY

### 3. Add Reference Documentation (Optional)

Create `reference.md` for detailed API docs, tool specifications, benchmarks, etc.

### 4. Add Usage Examples (Optional)

Create `examples.md` with practical usage patterns and integration examples.

### 5. Test Discoverability

Test with fresh Claude instance to ensure skill triggers when expected.

## Using Skills

### Autonomous Invocation

Skills automatically trigger when Claude detects relevant needs:

```
User: "Convert the Word documents to markdown"
→ Claude detects conversion need
→ Loads document-converter skill
→ Executes conversion
→ Returns results
```

### Explicit Invocation

Force skill usage with explicit language:

```
"Use the document-converter skill to convert ./docs to markdown"
```

### From Commands

Commands delegate to agents that load skills:

```bash
/convert-docs ./documents ./output
# 1. Command invokes doc-converter agent via Task tool
# 2. Agent has skills: document-converter in frontmatter
# 3. Agent loads skill and executes conversion
# 4. Falls back to script mode if agent fails
```

Commands do NOT load skills directly. Skill context is loaded
by agents via the `skills:` frontmatter field.

### From Agents

Agents can auto-load skills via `skills:` frontmatter field:

```yaml
---
name: doc-converter
skills: document-converter
---
```

## Best Practices

### Skill Design

1. **Focused Scope**: Single capability per skill (don't combine unrelated features)
2. **Discoverable Description**: Include keywords Claude would search for
3. **Token Efficiency**: Keep SKILL.md under 500 lines
4. **Progressive Disclosure**: Metadata always visible, details loaded when needed
5. **Tool Restrictions**: Use `allowed-tools` to limit tool access
6. **Clear Documentation**: Reference.md for detailed docs, SKILL.md for essentials

### Integration

1. **Composition**: Design skills to work together (e.g., document-converter + research-specialist)
2. **Command Fallback**: Commands should check skill availability and fall back gracefully
3. **Agent Loading**: Agents can auto-load skills via `skills:` field
4. **Testing**: Test discoverability with fresh Claude instances

### Documentation

1. **SKILL.md**: Core instructions only (< 500 lines)
2. **reference.md**: Detailed technical reference
3. **examples.md**: Practical usage patterns
4. **Skill Guide**: Complete guide in `.claude/docs/guides/skills/`

## Migration from Commands

### Pattern for Migrating Commands to Skills

**Candidates for Skills Migration**:
1. Research workflows → `research-specialist` skill
2. Planning workflows → `plan-generator` skill
3. Documentation generation → `doc-generator` skill
4. Testing orchestration → `test-orchestrator` skill

**Migration Template**:
1. Create `.claude/skills/{skill-name}/` structure
2. Write SKILL.md with discoverable description
3. Move/symlink logic to scripts/
4. Enhance command with skill delegation
5. Update agent with `skills:` field
6. Test and document

**Example** (document-converter):
```bash
# 1. Create skill structure
mkdir -p .claude/skills/document-converter/{scripts,templates}

# 2. Write SKILL.md (core instructions < 500 lines)
# Include discoverable description with keywords

# 3. Symlink existing scripts (zero duplication)
cd .claude/skills/document-converter/scripts
ln -s ../../../lib/convert/convert-core.sh .

# 4. Update doc-converter agent with skills: document-converter
# Agent will auto-load skill via frontmatter

# 5. Update /convert-docs command to invoke agent (agent loads skill)

# 6. Test autonomous invocation and command delegation
```

## Troubleshooting

### Skill Not Triggering

**Symptom**: Skill doesn't auto-invoke when expected.

**Diagnosis**:
1. Check skill is in `.claude/skills/<skill-name>/`
2. Verify SKILL.md exists with valid YAML frontmatter
3. Check description includes trigger keywords

**Solution**:
```bash
# Verify skill structure
ls .claude/skills/<skill-name>/SKILL.md

# Validate YAML frontmatter
python3 -c "import yaml; yaml.safe_load(open('SKILL.md').read().split('---')[1])"

# Test explicit invocation
"Use <skill-name> skill to <task description>"
```

### YAML Parsing Errors

**Symptom**: "Invalid YAML frontmatter" error.

**Solution**:
```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('SKILL.md').read().split('---')[1])"
```

**Common Issues**:
- Missing closing `---`
- Incorrect indentation (use spaces, not tabs)
- Unquoted strings with special characters

### Skill Not Loading in Agent

**Symptom**: Agent doesn't load skill despite `skills:` field.

**Diagnosis**:
1. Check `skills:` field in agent frontmatter
2. Verify skill name matches directory name
3. Check skill exists in `.claude/skills/`

**Solution**:
```yaml
# .claude/agents/your-agent.md
---
skills: skill-name  # Must match .claude/skills/skill-name/
---
```

## References

### Project Documentation

- [Document Converter Skill Guide](../docs/guides/skills/document-converter-skill-guide.md)
- [Directory Organization](../docs/concepts/directory-organization.md)
- [Command Authoring Standards](../docs/reference/standards/command-authoring.md)
- [Code Standards](../docs/reference/standards/code-standards.md)

### External Documentation

- [Claude Code Skills Guide](https://code.claude.com/docs/en/skills.md)
- [Skills Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)

## Changelog

### 2025-11-20

**Skills Added**:
- document-converter: Bidirectional document conversion (Markdown ↔ DOCX/PDF)

**Documentation**:
- Created skills README
- Created document-converter skill guide
- Added skills section to project docs

**Integration**:
- Enhanced /convert-docs command with skill delegation
- Updated doc-converter agent with skills: field
- Established migration pattern for future skills

## Navigation

- [← Parent Directory](../README.md)
- [Subdirectory: document-converter/](document-converter/README.md)
- [Related: Commands](../commands/README.md)
- [Related: Agents](../agents/README.md)
