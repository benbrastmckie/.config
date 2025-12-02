# Standards Integration Pattern

## Overview

The standards integration pattern enables commands to extract, validate, and enforce project standards from CLAUDE.md during workflow execution. This pattern is used by `/plan`, `/revise`, `/implement`, and `/debug` commands to ensure generated artifacts align with established project conventions or explicitly propose standards changes through a Phase 0 mechanism.

## Purpose

- **Standards Awareness**: Commands receive relevant CLAUDE.md standards sections for context-aware artifact generation
- **Automatic Validation**: Generated plans, implementations, and documentation automatically reference and align with standards
- **Controlled Evolution**: Standards changes are explicit, justified, and user-visible through Phase 0 protocol
- **Reusable Utilities**: Standards extraction utilities are shared across multiple commands for consistency

## Components

### Standards Extraction Library

Location: `.claude/lib/plan/standards-extraction.sh`

**Functions**:
- `extract_claude_section(section_name)` - Extract single named section from CLAUDE.md
- `extract_planning_standards()` - Extract all 6 planning-relevant sections
- `format_standards_for_prompt()` - Format sections for agent prompt injection

**Planning-Relevant Sections**:
1. `code_standards` - Informs Technical Design phase requirements  
2. `testing_protocols` - Shapes Testing Strategy section
3. `documentation_policy` - Guides Documentation Requirements
4. `error_logging` - Ensures error handling integration in phases
5. `clean_break_development` - Influences refactoring approach
6. `directory_organization` - Validates file placement in tasks

### Agent Enhancement Requirements

Agents receiving standards must:
1. Add "Standards Integration" subsection to requirements analysis
2. Add "Standards Divergence Protocol" section with Phase 0 template
3. Update completion criteria to validate standards content
4. Include divergence metadata fields in generated artifacts

### Command Integration Pattern

Commands must:
1. Source standards-extraction library in Block 2
2. Extract and format standards before agent invocation  
3. Inject standards into agent prompt under "**Project Standards**" heading
4. Detect Phase 0 in Block 3 after artifact creation
5. Display divergence warning if Phase 0 detected

## Usage Examples

### Extract Single Section

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh"

# Extract code standards
content=$(extract_claude_section "code_standards")
echo "$content"
```

### Extract All Planning Standards

```bash
# Get all 6 planning-relevant sections
standards=$(extract_planning_standards)
echo "$standards" | grep "^SECTION:"
```

### Format for Agent Prompt

```bash
# Format with markdown headers
formatted=$(format_standards_for_prompt)

# Inject into agent prompt
Task {
  prompt: "
    **Project Standards**:
    ${formatted}
    
    Follow provided standards or create Phase 0 if divergence needed.
  "
}
```

### Detect Phase 0 in Generated Plan

```bash
# Check for standards divergence
if grep -q "^### Phase 0: Standards Revision" "$PLAN_PATH"; then
  echo "⚠️  STANDARDS DIVERGENCE DETECTED"
  
  # Extract metadata
  justification=$(grep "^\- \*\*Divergence Justification\*\*:" "$PLAN_PATH" | sed 's/.*: //')
  echo "Justification: $justification"
fi
```

## Phase 0: Standards Revision Protocol

When agents detect Major Divergence from existing standards, they must create Phase 0:

```markdown
### Phase 0: Standards Revision [NOT STARTED]
dependencies: []

**Objective**: Update project standards to support [feature] by revising [sections]

**Divergence Summary**:
- **Current Standard**: [quote from Project Standards]
- **Proposed Change**: [new approach]
- **Conflict**: [why current standard blocks implementation]

**Justification**:
1. What limitations motivate this change?
2. What benefits does new approach provide?
3. What is migration path for existing code?
4. What are risks/downsides?

**Tasks**:
- [ ] Update CLAUDE.md section with new standards
- [ ] Document migration strategy
- [ ] Update command/agent files referencing old standards
- [ ] Add deprecation notice if phasing out
- [ ] Update validation scripts

**User Warning**:
⚠️  This plan proposes project-wide standards changes. Review Phase 0 carefully.
```

### Divergence Metadata

Plans with Phase 0 must include:

```markdown
- **Standards Divergence**: true
- **Divergence Level**: Major
- **Divergence Justification**: [brief description]
- **Standards Sections Affected**: [list]
```

## Integration Checklist

### For Command Authors

- [ ] Source standards-extraction.sh in Block 2 with fail-fast handler
- [ ] Extract standards with `format_standards_for_prompt()`
- [ ] Inject `${FORMATTED_STANDARDS}` into agent prompt
- [ ] Persist standards to workflow state
- [ ] Detect Phase 0 in Block 3 with grep
- [ ] Display divergence warning if detected
- [ ] Handle graceful degradation if extraction fails

### For Agent Authors

- [ ] Add "Standards Integration" to STEP 1 requirements analysis
- [ ] Add "Standards Divergence Protocol" section with templates
- [ ] Update completion criteria to validate standards content
- [ ] Document divergence severity levels (Minor/Moderate/Major)
- [ ] Include Phase 0 template in behavioral guidelines
- [ ] Add divergence metadata field specifications

## Error Handling

### Graceful Degradation

If CLAUDE.md not found or extraction fails, commands continue without standards:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  log_command_error "file_error" "Standards library unavailable" "{}"
  echo "WARNING: Proceeding without standards" >&2
  FORMATTED_STANDARDS=""
}
```

**Behavior**:
- Log error to centralized error log
- Display warning to user
- Set `FORMATTED_STANDARDS=""` for empty prompt injection
- Continue command execution normally

## Best Practices

1. **Always Use Fail-Fast**: Source library with `|| { exit 1 }` handler
2. **Log Extraction Errors**: Use `log_command_error()` for diagnostics
3. **Persist to State**: Save standards for Block 3 access
4. **Make Warnings Prominent**: Use ⚠️ emoji and clear messaging
5. **Test Both Paths**: With and without CLAUDE.md present
6. **Parse Standards Actively**: Agents must actually read and reference sections
7. **Justify Divergence**: Phase 0 rationale must answer "why" thoroughly

## Troubleshooting

**Standards not in agent prompt**: Check Block 2 extraction logs, verify persistence
**Agent ignoring standards**: Add Standards Integration section to agent behavioral file
**Phase 0 not detected**: Verify grep pattern matches `### Phase 0: Standards Revision` exactly
**Warning not displayed**: Check Block 3 has divergence detection code after plan verification
**CLAUDE.md not found**: Accept graceful degradation or check project directory

## Related Documentation

- [Code Standards](.claude/docs/reference/standards/code-standards.md)
- [Command Authoring Standards](.claude/docs/reference/standards/command-authoring.md)
- [Plan Command Guide](.claude/docs/guides/commands/plan-command-guide.md)
- [Plan-Architect Agent](.claude/agents/plan-architect.md)
- [Standards Extraction Library](.claude/lib/plan/standards-extraction.sh)

## Version History

- **v1.0** (2025-11-29): Initial pattern with /plan integration
