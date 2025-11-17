# Standards Inconsistencies in Behavioral Injection Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Standards Inconsistencies in Behavioral Injection
- **Report Type**: codebase analysis
- **Overview Report**: [OVERVIEW.md](OVERVIEW.md)
- **Related Reports**:
  - [Missing Recommendations from Overview](001_missing_recommendations_from_overview.md)
  - [Implementation Gaps in Plan Phases](002_implementation_gaps_in_plan_phases.md)
  - [Documentation Tension Between Robustness Patterns](004_documentation_tension_between_robustness_patterns.md)

## Executive Summary

Analysis reveals significant tension between behavioral injection standards and command execution enforcement standards. The research command contains STEP-based procedural patterns (lines 43, 92) that behavioral-injection.md classifies as "behavioral content" requiring extraction to agent files, while command_architecture_standards.md Standard 0 classifies identical patterns as "execution enforcement" requiring inline presence. This contradiction creates implementation uncertainty and risks degrading either delegation rates or file creation reliability depending on which standard is followed.

## Findings

### Finding 1: Contradictory Classification of STEP Patterns

**Location**: /home/benjamin/.config/.claude/commands/research.md lines 43, 92

**Pattern Observed**:
```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - Topic Decomposition
### STEP 2 (REQUIRED BEFORE STEP 3) - Path Pre-Calculation
```

**Tension Point**:
- **behavioral-injection.md** (lines 101-106, 206-209): Classifies "STEP sequences" as "behavioral content" that MUST be referenced from agent files, not duplicated inline
- **template-vs-behavioral-distinction.md** (lines 100-106): Lists "STEP instruction count: <5 per command file" as violation indicator, stating "behavioral content should be in agent files"
- **command_architecture_standards.md Standard 0** (lines 79-185): Presents nearly identical STEP patterns as examples of proper "execution enforcement" that MUST be inline

**Evidence of Contradiction**:

From behavioral-injection.md (line 272-287):
```markdown
❌ BAD - Duplicating agent behavioral guidelines inline:

**STEP 1 (REQUIRED BEFORE STEP 2)**: Use Write tool to create file at ${REPORT_PATH}
**STEP 2 (REQUIRED BEFORE STEP 3)**: Conduct research
**STEP 3 (REQUIRED BEFORE STEP 4)**: Populate Report File
```

From command_architecture_standards.md Standard 0 (lines 146-159):
```markdown
✅ GOOD - Imperative, enforceable:

**STEP 1: CREATE FILE** (Do this FIRST, before research)
Use Write tool to create: ${REPORT_PATHS[$TOPIC]}

**STEP 2: RESEARCH**
[research instructions]

**STEP 3: RETURN CONFIRMATION**
Return ONLY: REPORT_CREATED: ${REPORT_PATHS[$TOPIC]}
```

**Impact**: Same STEP pattern marked as anti-pattern in one document and correct pattern in another.

### Finding 2: Agent vs Command STEP Sequences Lack Clear Distinction Criteria

**Analysis**: Behavioral-injection.md prohibits STEP sequences in commands but provides insufficient criteria for distinguishing:
- **Agent behavioral STEPs** (internal workflow, must be in agent files)
- **Command orchestration STEPs** (coordination sequence, must be in command files)

**Current Research Command STEPs** (lines 43-150):
- STEP 1: Topic Decomposition (orchestrator decomposes topic, delegates to agent)
- STEP 2: Path Pre-Calculation (orchestrator calculates paths before agent invocation)

**Question**: Are these "command orchestration steps" (Standard 0 enforcement) or "agent behavioral steps" (Standard 12 duplication)?

**Insufficient Guidance**: Neither behavioral-injection.md nor template-vs-behavioral-distinction.md provides decision criteria for this classification.

### Finding 3: Structural Template Definition Excludes Orchestration Sequences

**From template-vs-behavioral-distinction.md** (lines 26-87):

**Structural Templates** (MUST be inline):
- Task invocation syntax
- Bash execution blocks
- JSON schemas
- Verification checkpoints
- Critical warnings

**Behavioral Content** (MUST be referenced):
- Agent STEP sequences
- File creation workflows
- Agent verification steps
- Output format specifications

**Missing Category**: Command orchestration sequences (multi-step coordination logic)

**Example**: The /research command STEP 1 (decompose topic) and STEP 2 (calculate paths) are neither:
- Pure structural templates (they're multi-line procedural sequences)
- Agent behavioral content (they're orchestrator responsibilities, not agent workflows)

**Gap**: No classification guidance for orchestrator procedural sequences.

## Recommendations

### Recommendation 1: Add Third Category - "Orchestration Sequences" (High Priority)

**Action**: Update template-vs-behavioral-distinction.md to include a third category between structural templates and behavioral content.

**Proposed Addition** (after line 87):

```markdown
**Orchestration Sequences** (MUST be inline in command files):
- Command STEP sequences that coordinate agent delegation
- Multi-phase workflow logic (Phase 0 → Phase 1 → Phase 2)
- Path pre-calculation procedures
- Agent invocation preparation steps
- Cross-agent coordination logic

**Distinguishing from Behavioral Content**:
- **Agent behavioral**: Internal agent workflow (file creation → research → verification)
- **Orchestration sequence**: Command coordination workflow (decompose → calculate paths → invoke agents → aggregate)

**Rule**: If the STEP sequence coordinates BETWEEN agents or prepares FOR agent invocation, it's orchestration (inline). If the STEP sequence executes WITHIN an agent, it's behavioral (reference).
```

**Justification**: Resolves the classification ambiguity for /research command STEP patterns and provides clear decision criteria.

### Recommendation 2: Clarify Standard 0 vs Standard 12 Relationship (Critical)

**Action**: Add explicit reconciliation section to command_architecture_standards.md after Standard 12.

**Proposed Section**:

```markdown
### Standard 0 and Standard 12 Reconciliation

**Apparent Tension**: Standard 0 shows STEP patterns as "execution enforcement" (inline). Standard 12 prohibits STEP patterns as "behavioral duplication" (extract to agent files).

**Resolution**: STEP pattern ownership determines placement:

**Command-Owned STEPs** (Standard 0 - Inline Required):
- Orchestration coordination (decompose topic, calculate paths)
- Agent preparation (path pre-calculation, context assembly)
- Multi-phase progression (Phase 0 → 1 → 2)
- Cross-agent aggregation (collect results, synthesize)

**Agent-Owned STEPs** (Standard 12 - Reference Required):
- File creation workflows (create → populate → verify)
- Research procedures (search → analyze → document)
- Internal quality checks (validate → test → confirm)

**Decision Test**: Ask "Who executes this STEP?"
- Command/orchestrator → Inline (Standard 0)
- Agent/subagent → Reference (Standard 12)
```

**Justification**: Eliminates contradiction by establishing ownership-based classification.

### Recommendation 3: Update Behavioral-Injection.md Anti-Pattern Examples (Medium Priority)

**Action**: Revise behavioral-injection.md lines 263-287 to distinguish agent STEPs from command STEPs.

**Current Anti-Pattern** (line 272-287):
```markdown
❌ BAD - Duplicating agent behavioral guidelines inline:

**STEP 1 (REQUIRED BEFORE STEP 2)**: Use Write tool to create file at ${REPORT_PATH}
```

**Problem**: This example doesn't clarify whether it's in a command file (duplicating agent behavior) or showing agent behavior pattern.

**Proposed Revision**:
```markdown
❌ BAD - Duplicating agent behavioral guidelines in command file:

Task {
  prompt: "
    [Context injection here]

    **STEP 1 (REQUIRED BEFORE STEP 2)**: Use Write tool to create file
    **STEP 2 (REQUIRED BEFORE STEP 3)**: Conduct research
    **STEP 3 (REQUIRED BEFORE STEP 4)**: Populate report file
  "
}

This duplicates agent behavioral guidelines. Instead, reference agent file:

✅ GOOD:
Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Report Path: ${REPORT_PATH}
  "
}
```

**Justification**: Makes clear the anti-pattern is DUPLICATING agent STEPs in command prompts, not having orchestration STEPs in command files.

### Recommendation 4: Add Decision Tree Flowchart (Medium Priority)

**Action**: Create visual decision tree in template-vs-behavioral-distinction.md or quick-reference/ to help classify STEP patterns.

**Proposed Flowchart**:
```
Does this STEP sequence appear in a command file?
│
├─ YES → Who owns the execution?
│        │
│        ├─ Command/Orchestrator (coordinates agents) → INLINE (orchestration sequence)
│        │
│        └─ Agent (within Task prompt) → EXTRACT to agent file (behavioral duplication)
│
└─ NO (appears in agent file) → KEEP in agent file (agent behavioral content)
```

**Justification**: Provides quick visual reference for classification decisions during development.

### Recommendation 5: Audit Existing Commands for Misclassified Patterns (Low Priority)

**Action**: Review all commands in .claude/commands/ to identify STEP patterns and verify correct classification.

**Commands to Audit**:
- /home/benjamin/.config/.claude/commands/research.md (lines 43, 92 - verified as orchestration sequences)
- /home/benjamin/.config/.claude/commands/coordinate.md (check for STEP patterns)
- /home/benjamin/.config/.claude/commands/collapse.md (check for STEP patterns)
- /home/benjamin/.config/.claude/commands/expand.md (check for STEP patterns)
- /home/benjamin/.config/.claude/commands/revise.md (check for STEP patterns)
- /home/benjamin/.config/.claude/commands/convert-docs.md (check for STEP patterns)

**Verification Criteria**:
- Command orchestration STEPs: Keep inline (correct)
- Agent behavioral STEPs in Task prompts: Extract to agent files (needs fix)
- Unclear ownership: Clarify through ownership test (Recommendation 2)

**Justification**: Ensures consistency across all commands after standards clarification.

## References

### Documentation Files Analyzed

1. **/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md**
   - Lines 101-106: STEP sequences classified as behavioral content
   - Lines 206-209: Structural vs behavioral distinction
   - Lines 263-287: Anti-pattern examples showing STEP duplication

2. **/home/benjamin/.config/.claude/docs/reference/template-vs-behavioral-distinction.md**
   - Lines 26-87: Structural templates vs behavioral content definitions
   - Lines 100-106: Agent STEP sequences classification
   - Lines 335-339: Validation criteria (STEP instruction count <5)

3. **/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md**
   - Lines 50-199: Standard 0 - Execution Enforcement patterns
   - Lines 146-159: STEP pattern examples marked as correct inline usage
   - Lines 1355-1454: Standard 12 - Structural vs Behavioral Content Separation
   - Lines 1667-1675: Relationship between Standard 12 and Standard 14

4. **/home/benjamin/.config/.claude/docs/reference/agent-reference.md**
   - Lines 561-562: research-specialist allowed tools (does NOT include Bash)
   - Clarifies agent vs command tool responsibilities

### Command Files Analyzed

5. **/home/benjamin/.config/.claude/commands/research.md**
   - Line 43: `### STEP 1 (REQUIRED BEFORE STEP 2) - Topic Decomposition`
   - Line 92: `### STEP 2 (REQUIRED BEFORE STEP 3) - Path Pre-Calculation`
   - Lines 43-150: Complete orchestration sequence analysis

6. **/home/benjamin/.config/.claude/commands/coordinate.md**
   - Lines 1-150: Checked for STEP patterns (found minimal procedural sequences)
   - Uses state machine architecture, different pattern from /research

### Commands Identified with STEP Patterns (via Grep)

7. Files with PRIMARY OBLIGATION or STEP patterns:
   - /home/benjamin/.config/.claude/commands/coordinate.md
   - /home/benjamin/.config/.claude/commands/research.md
   - /home/benjamin/.config/.claude/commands/collapse.md
   - /home/benjamin/.config/.claude/commands/convert-docs.md
   - /home/benjamin/.config/.claude/commands/revise.md
   - /home/benjamin/.config/.claude/commands/expand.md

### Key Finding Sources

- **Contradiction Evidence**: behavioral-injection.md lines 272-287 vs command_architecture_standards.md lines 146-159
- **Missing Category**: template-vs-behavioral-distinction.md lines 26-87 (no orchestration sequence category)
- **Insufficient Criteria**: behavioral-injection.md lines 101-106, template-vs-behavioral-distinction.md lines 100-106 (no agent vs command STEP distinction)
