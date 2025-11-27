# Standards Conformance Analysis for Subagent Converter Refactor

## Metadata
- **Date**: 2025-11-23
- **Agent**: research-specialist
- **Topic**: Plan revision insights for standards conformance
- **Report Type**: Standards analysis for plan revision
- **Related Plan**: /home/benjamin/.config/.claude/specs/923_subagent_converter_skill_strategy/plans/001-subagent-converter-refactor-plan.md
- **Workflow**: research-and-revise

## Executive Summary

Analysis reveals **critical inconsistencies** between the existing plan and documented standards. The plan proposes removing STEP 0/STEP 3.5 skill delegation patterns which are still documented as valid in skills-authoring.md (lines 233-254), creating documentation drift. Additionally, the skills/README.md and directory-organization.md both reference command-skill delegation via STEP 0/STEP 3.5 as an active integration pattern, requiring coordinated updates across 5+ documentation files.

## Findings

### 1. Standards Documentation Inconsistency

**Issue**: The plan removes STEP 0/STEP 3.5 skill patterns, but these are documented as valid patterns in multiple locations.

**Evidence**:

**skills-authoring.md** (lines 233-256) documents "Command Delegation Pattern" as the standard:
```markdown
Commands that delegate to skills MUST follow this pattern:

**STEP 0**: Check for skill availability
...
**STEP 3.5**: Delegate to skill if available (between mode detection and script mode)
```

**skills/README.md** (lines 162-171) documents command-skill integration:
```markdown
### From Commands

Commands can delegate to skills when available:

/convert-docs ./documents ./output
→ Checks for document-converter skill
→ Delegates to skill if available
→ Falls back to script mode if not
```

**directory-organization.md** (lines 174-178) documents command-skill integration pattern:
```markdown
**Integration Patterns**:
1. **Autonomous**: Claude detects need and loads skill automatically
2. **Command Delegation**: Commands check availability and delegate via STEP 0/STEP 3.5
3. **Agent Auto-Loading**: Agents use `skills:` frontmatter field
```

**Recommendation**: Plan must include Phase 3 documentation updates as CRITICAL (not minor), with explicit list of files requiring changes:
- `.claude/docs/reference/standards/skills-authoring.md` (lines 233-363)
- `.claude/skills/README.md` (lines 162-171)
- `.claude/docs/concepts/directory-organization.md` (lines 174-178)
- `CLAUDE.md` skills_architecture section

### 2. Agent Skills Field Already Configured

**Finding**: The `doc-converter.md` agent already has `skills: document-converter` in frontmatter (line 4).

**Evidence** from `/home/benjamin/.config/.claude/agents/doc-converter.md`:
```yaml
---
allowed-tools: Read, Grep, Glob, Bash, Write
description: Bidirectional document conversion between Markdown, Word (DOCX), and PDF formats
skills: document-converter
model: haiku-4.5
...
---
```

**Impact on Plan**: Phase 2.1 "Verify Agent Configuration" and 2.2 "Update Agent for Parallel Default" can be simplified. The agent already references the skill correctly. Only parallel default handling needs addition.

### 3. Behavioral Injection Pattern Compliance

**Standard Reference**: behavioral-injection.md (lines 52-63) defines command role separation:
```markdown
Every orchestrating command begins with explicit role declaration:

## YOUR ROLE

You are the ORCHESTRATOR for this workflow. Your responsibilities:
1. Calculate artifact paths and workspace structure
2. Invoke specialized subagents via Task tool
3. Aggregate and forward subagent results
4. DO NOT execute implementation work yourself
```

**Current convert-docs.md Issue**: Lines 14-19 show mixed role:
```markdown
**YOUR ROLE**: You are the CONVERSION COORDINATOR with two execution paths.
- **DO NOT** convert files yourself using Read/Write/Bash tools directly
- **Script Mode**: ONLY invoke the conversion script via Bash tool
- **Agent Mode**: ONLY use Task tool to invoke doc-converter agent
```

**Recommendation**: After refactor, maintain explicit role clarification but simplify to:
```markdown
**YOUR ROLE**: You are the CONVERSION COORDINATOR.
- **Primary Path**: Invoke doc-converter agent via Task tool
- **Fallback Path**: Only invoke convert-core.sh script if agent fails
- **DO NOT** execute conversion yourself using Read/Write/Bash tools
```

### 4. Library Infrastructure Exists

**Finding**: The conversion library infrastructure exists at `/home/benjamin/.config/.claude/lib/convert/`:
- `convert-core.sh` - Main orchestration
- `convert-docx.sh` - DOCX conversion functions
- `convert-pdf.sh` - PDF conversion functions
- `convert-gemini.sh` - Gemini API integration
- `convert-markdown.sh` - Markdown utilities

**Impact on Plan**: Phase 1.4 (Script Fallback) correctly references `convert-core.sh`. The plan's fallback approach is compatible with existing infrastructure.

### 5. Three-Tier Sourcing Pattern Required

**Standard Reference**: code-standards.md (lines 34-86) mandates three-tier sourcing:
```bash
# 2. Source Critical Libraries (Tier 1 - FAIL-FAST REQUIRED)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2; exit 1
}
```

**Current convert-docs.md Issue**: STEP 4 (lines 417-419) uses simpler pattern:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh" || {
  echo "CRITICAL ERROR: Cannot source convert-core.sh"
```

**Recommendation**: While convert-core.sh is Tier 3 (command-specific), if it loads Tier 1 libraries internally, the error pattern is acceptable. However, STEP 1.5 (error logging setup) at lines 246-252 should be verified for compliance:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "CRITICAL ERROR: Cannot load error-handling library"
  exit 1
}
```
This pattern is compliant - it uses `2>/dev/null` for output suppression with fail-fast handler.

### 6. Output Formatting Standards

**Standard Reference**: output-formatting.md (lines 366-625) defines console summary format:
```markdown
All artifact-producing commands MUST use this 4-section format:
=== [Command] Complete ===
Summary: [2-3 sentence narrative]
Phases: [if applicable]
Artifacts: [emoji-prefixed paths]
Next Steps: [actionable commands]
```

**Current convert-docs.md Issue**: STEP 6 (lines 571-594) uses different format:
```markdown
Mode: [SKILL|SCRIPT|AGENT]
Input: $input_dir ($file_count files)
Output: $output_dir ($output_count files converted)
Log: $output_dir/conversion.log
```

**Recommendation**: Plan should add requirement to update STEP 6 output format to match console summary standards:
```markdown
=== Document Conversion Complete ===

Summary: Converted $output_count files from $input_dir to $output_dir using agent-based conversion with document-converter skill.

Artifacts:
  Converted: $output_dir/ ($output_count files)
  Log: $output_dir/conversion.log

Next Steps:
  Review log: cat $output_dir/conversion.log
  Check quality: ls -la $output_dir/
```

### 7. STEP Numbering Convention

**Finding**: Current convert-docs.md uses fractional STEPs (0, 0.5, 1, 1.5, 2, 3, 3.5, 4, 5, 6). This is inconsistent with other commands that use integer numbering.

**Plan Addresses This**: Phase 1.2 correctly proposes natural numbering (1, 2, 3, 4, 5, 6).

### 8. Skills Integration Pattern Discrepancy

**Critical Finding**: There are TWO documented patterns for command-skill integration:

**Pattern A** (Direct Delegation - skills-authoring.md):
```markdown
STEP 0: Check skill availability
STEP 3.5: Delegate to skill if available
```

**Pattern B** (Agent Auto-Loading - skills/README.md lines 175-182):
```yaml
# .claude/agents/my-agent.md
---
skills: skill-name
---
```

The plan proposes abandoning Pattern A entirely and using only Pattern B. This is architecturally sound because:
1. Pattern A relies on Claude processing natural language delegation ("Use the document-converter skill to...")
2. Pattern B has explicit infrastructure (skills: field) with documented behavior
3. Research Report 001 confirms Pattern A has reliability issues

**However**, the standards documentation must be updated to reflect this change. Pattern A should be marked as **deprecated** or **removed**, not left undocumented.

### 9. Error Logging Integration

**Standard Reference**: CLAUDE.md error_logging section requires:
1. Source error-handling library with fail-fast
2. Initialize error log: `ensure_error_log_exists`
3. Set workflow metadata: `COMMAND_NAME`, `WORKFLOW_ID`, `USER_ARGS`
4. Log errors: `log_command_error "$error_type" "$error_message" "$error_details"`

**Current convert-docs.md Status**: STEP 1.5 (lines 243-267) is compliant with all requirements.

**Plan Impact**: The refactored command must preserve this error logging integration.

### 10. Skill SKILL.md Completeness

**Finding**: `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` includes complete conversion matrix (lines 58-99), all 6 conversion directions documented.

**Plan Impact**: Phase 2.3 "Verify Skill Completeness" is already satisfied. This task can be marked as verification-only, not implementation.

## Recommendations

### Critical (Must Address)

1. **Expand Phase 3 Scope**: Documentation updates are NOT minor - they affect architectural understanding. Mark as MEDIUM complexity, not LOW.

2. **Add Explicit File List**: Phase 3 must enumerate ALL files requiring updates:
   - `.claude/docs/reference/standards/skills-authoring.md`
   - `.claude/skills/README.md`
   - `.claude/docs/concepts/directory-organization.md`
   - `CLAUDE.md` skills_architecture section
   - `.claude/docs/concepts/patterns/behavioral-injection.md` (if referencing skill patterns)

3. **Preserve Error Logging**: Ensure refactored STEP structure maintains STEP 1.5 error logging initialization.

4. **Update Console Summary Format**: Add STEP 6 output format update to align with output-formatting.md standards.

### Important (Should Address)

5. **Mark Pattern A as Deprecated**: In documentation updates, explicitly state that direct command-to-skill delegation (STEP 0/3.5) is deprecated in favor of agent-based loading.

6. **Simplify Phase 2**: Agent already has `skills: document-converter`. Phase 2.1 verification is already passing. Focus Phase 2 on parallel default handling only.

7. **Add Documentation Drift Test**: Consider adding a test that validates command-documentation alignment (e.g., grep for STEP 0/STEP 3.5 patterns across docs after changes).

### Minor (Nice to Have)

8. **Role Clarification Update**: Align convert-docs.md role description with behavioral-injection.md orchestrator pattern.

9. **Testing Commands Update**: Plan testing section uses `/convert-docs test/ output/ --use-agent` which won't work after --use-agent removal. Update test commands.

## References

### Files Analyzed
- `/home/benjamin/.config/.claude/commands/convert-docs.md` (full file)
- `/home/benjamin/.config/.claude/agents/doc-converter.md` (lines 1-50)
- `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` (lines 1-100)
- `/home/benjamin/.config/.claude/docs/reference/standards/skills-authoring.md` (lines 230-394)
- `/home/benjamin/.config/.claude/skills/README.md` (lines 160-333)
- `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md` (full file)
- `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` (lines 1-200)
- `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md` (lines 360-650)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (full file)

### Existing Plan Reference
- `/home/benjamin/.config/.claude/specs/923_subagent_converter_skill_strategy/plans/001-subagent-converter-refactor-plan.md`

### Library Structure Verified
- `/home/benjamin/.config/.claude/lib/convert/convert-core.sh`
- `/home/benjamin/.config/.claude/lib/convert/convert-docx.sh`
- `/home/benjamin/.config/.claude/lib/convert/convert-pdf.sh`
- `/home/benjamin/.config/.claude/lib/convert/convert-gemini.sh`
- `/home/benjamin/.config/.claude/lib/convert/convert-markdown.sh`
