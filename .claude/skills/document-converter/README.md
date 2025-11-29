# Document Converter Skill

Bidirectional document conversion skill for Markdown, Word (DOCX), and PDF formats.

## Purpose

This skill provides autonomous document conversion capabilities that Claude can invoke when conversion needs are detected. The skill architecture separates model-facing prompts (SKILL.md), detailed API reference (reference.md), and usage examples (examples.md) for optimal context efficiency.

## Skill Structure

This skill uses three primary documentation files:

- **SKILL.md**: Main skill definition and prompt loaded by Claude when skill is invoked (model-facing)
- **reference.md**: Detailed API reference, conversion options, and configuration parameters
- **examples.md**: Usage examples, common patterns, and troubleshooting scenarios

## Subdirectories

### scripts/
Core conversion scripts implementing format-specific logic:
- `convert-core.sh` - Shared conversion utilities and error handling
- `convert-markdown.sh` - Markdown conversion implementation
- `convert-docx.sh` - Word document conversion implementation
- `convert-pdf.sh` - PDF conversion implementation

### templates/
Conversion workflow templates:
- `batch-conversion.sh` - Template for batch conversion operations

## Quick Start

### Using the Skill
Claude automatically invokes this skill when document conversion needs are detected. For manual invocation, use the `/convert-docs` command.

### Developing the Skill
1. Modify SKILL.md for prompt changes (model-facing interface)
2. Update reference.md for API changes (detailed documentation)
3. Add examples.md entries for new patterns (usage documentation)
4. Implement format logic in scripts/ subdirectory

## Integration

This skill integrates with:
- `/convert-docs` command - Primary command interface
- `doc-converter` agent - Orchestrates conversion workflows
- Error logging system - Centralized error tracking

## Navigation

- [← Parent Directory](../README.md)
- [Skills Overview](../README.md)
- [Skills Authoring Standards](../../docs/reference/standards/skills-authoring.md)
