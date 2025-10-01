# Command Standardization Checklist

This document provides a checklist for ensuring all slash commands have consistent standards integration.

## Standardization Status

### Commands with Full Standards Integration

| Command | Standards Section | Integration Section | Terminology | Status |
|---------|------------------|-------------------|-------------|--------|
| /document | ✓ Excellent | ✓ Present | ✓ CLAUDE.md | ✓ Complete |
| /test | ✓ Good | ✓ Present | ✓ CLAUDE.md | ✓ Complete |
| /implement | ✓ Excellent | ✓ Added | ✓ CLAUDE.md | ✓ Complete |
| /setup | ✓ Excellent | ✓ Added | ✓ CLAUDE.md | ✓ Complete |
| /plan | ✓ Moderate | Partial | ✓ CLAUDE.md | Needs enhancement |
| /refactor | ✓ Moderate | Missing | Mixed terms | Needs enhancement |
| /test-all | ✓ Adequate | Missing | ✓ CLAUDE.md | Needs minor update |

### Commands Needing Standards Integration

| Command | Current State | Priority | Actions Needed |
|---------|--------------|---------|----------------|
| /debug | No integration | Medium | Add standards discovery section |
| /orchestrate | No integration | Medium | Add standards enforcement for subagents |
| /validate-setup | Basic | Low | Add standards validation checks |

## Standardization Pattern

Every primary development command should have:

### 1. Standards Discovery and Application Section

```markdown
## Standards Discovery and Application

### Discovery Process
1. **Locate CLAUDE.md**: [How to find]
2. **Check Subdirectory Standards**: [Subdirectory rules]
3. **Parse Relevant Sections**: [Which sections]
4. **Handle Missing Standards**: [Fallback behavior]

### Standards Sections Used
- **[Section Name]**: [What is extracted]

### Application
[How standards influence command behavior]

### Compliance Verification
[How compliance is checked]

### Fallback Behavior
[What happens when standards missing]
```

### 2. Consistent Terminology

Use these terms consistently:
- **Primary term**: "CLAUDE.md" (not "standards file" or "project standards")
- **Secondary**: "project standards" when referring to content
- **Specific**: "coding standards", "testing protocols", "documentation policy" for sections

### 3. Integration Section

```markdown
## Integration with Other Commands

### Standards Flow
[Show position in workflow]

### How [Command] Uses Standards
[Specific usage patterns]

### Example Flow
[Concrete example]
```

## Command-Specific Requirements

### /document
- ✓ Already has excellent standards integration
- ✓ Uses Documentation Policy section
- ✓ Has fallback behavior documented
- **Action**: None needed (reference implementation)

### /test
- ✓ Good standards integration
- ✓ Uses Testing Protocols section
- ✓ Priority-based discovery
- **Action**: Minor terminology standardization

### /test-all
- ✓ References CLAUDE.md for test commands
- Missing: Detailed discovery process
- **Action**: Add discovery section matching /test pattern

### /implement
- ✓ Comprehensive standards integration added (Phase 3)
- ✓ Complete discovery, application, compliance sections
- ✓ Integration with other commands documented
- **Action**: None needed (completed in Phase 3)

### /setup
- ✓ Comprehensive command support added (Phase 4)
- ✓ Generates parseable CLAUDE.md for other commands
- ✓ Integration section showing support for all commands
- **Action**: None needed (completed in Phase 4)

### /plan
- Moderate standards integration
- Has discovery section but lacks detail
- Missing: Application examples, compliance checks
- **Action**: Enhance with concrete examples

### /refactor
- Moderate standards integration
- Uses standards for validation
- Missing: Integration section, terminology inconsistent
- **Action**: Add integration section, standardize terms

### /debug
- No standards integration
- Should reference standards for code analysis
- Missing: Discovery, application, integration
- **Action**: Add full standards integration section

### /orchestrate
- No standards integration
- Should ensure subagents follow standards
- Missing: Standards enforcement documentation
- **Action**: Add section on standards propagation to subagents

### /validate-setup
- Basic integration
- Should validate command-CLAUDE.md integration
- Missing: Command integration validation
- **Action**: Enhance to check parseability

## Implementation Priority

### Phase 5A: High Priority (This Phase)
- [x] /implement - Comprehensive enhancement (Phase 3)
- [x] /setup - Command support enhancement (Phase 4)
- [ ] Terminology standardization across all commands
- [ ] Command-standards matrix documentation

### Phase 5B: Medium Priority (Future)
- [ ] /debug - Add standards discovery section
- [ ] /orchestrate - Add standards enforcement
- [ ] /plan - Enhance with examples
- [ ] /refactor - Add integration section

### Phase 5C: Low Priority (Future)
- [ ] /test-all - Minor enhancement
- [ ] /validate-setup - Enhanced validation
- [ ] Other utility commands

## Validation Checklist

For each command, verify:

- [ ] Has "Standards Discovery and Application" section (or equivalent)
- [ ] Documents which CLAUDE.md sections it uses
- [ ] Shows how standards influence behavior
- [ ] Has fallback behavior documented
- [ ] Uses "CLAUDE.md" terminology consistently
- [ ] Has "Integration with Other Commands" section (if primary command)
- [ ] Includes concrete examples
- [ ] Cross-references related commands

## Testing Standards Integration

### Manual Testing
```bash
# 1. Check for standards section
grep -A 5 "Standards Discovery\|Standards Integration" .claude/commands/*.md

# 2. Check terminology consistency
grep -i "standards file\|project standards" .claude/commands/*.md

# 3. Count commands with integration sections
grep -l "Integration with Other Commands" .claude/commands/*.md | wc -l
```

### Expected Results
- All primary commands have standards sections
- Terminology is consistent (uses "CLAUDE.md")
- Integration sections present in primary commands
- Examples show concrete usage

## References

- [Standards Integration Pattern](standards-integration-pattern.md) - Template
- [Command Standards Flow](command-standards-flow.md) - Workflow diagram
- [Research Report 033](../specs/reports/033_slash_command_standards_integration_analysis.md) - Original analysis

## Notes

This checklist should be consulted when:
- Adding new slash commands
- Updating existing commands
- Reviewing standards integration completeness
- Planning future enhancements

Last updated: 2025-10-01 (Phase 5 implementation)
