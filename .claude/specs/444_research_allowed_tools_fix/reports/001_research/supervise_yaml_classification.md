# Supervise.md YAML Block Classification

## Metadata
- **Date**: 2025-10-24
- **Purpose**: Classify all 7 YAML blocks in supervise.md as structural templates (keep) or behavioral duplication (remove/refactor)
- **Context**: Implements Phase 2, Task 2.1 from documentation improvements plan (spec 441)
- **Standards Reference**: `.claude/docs/reference/template-vs-behavioral-distinction.md`

## Classification Summary

| Block | Lines | Type | Decision | Rationale |
|-------|-------|------|----------|-----------|
| 1 | 49-54 | Structural | **KEEP** | Shows Task invocation syntax (structural template) |
| 2 | 63-80 | Mixed | **REFACTOR** | Task syntax (structural) + STEP sequences (behavioral) |
| 3 | 682-829 | Behavioral | **REMOVE** | Full agent procedure duplicating research-specialist.md |
| 4 | 1082-1246 | Behavioral | **REMOVE** | Full agent procedure duplicating plan-architect.md |
| 5 | 1440-1615 | Behavioral | **REMOVE** | Full agent procedure duplicating code-writer.md |
| 6 | 1721-1925 | Behavioral | **REMOVE** | Full agent procedure duplicating test-specialist.md |
| 7 | 2246-2441 | Behavioral | **REMOVE** | Full agent procedure duplicating doc-writer.md |

**Key Finding**: Blocks 1-2 are documentation examples; Blocks 3-7 are agent invocation templates with embedded behavioral content that should be references instead.

## Detailed Classification

### Block 1 (Lines 49-54): SlashCommand Anti-Pattern Example

**Location**: After "**Wrong Pattern - Command Chaining**"

**Content**:
```yaml
# ❌ INCORRECT - Do NOT do this
SlashCommand {
  command: "/plan create auth feature"
}
```

**Classification**: **STRUCTURAL TEMPLATE** (documentation example)

**Analysis**:
- **Purpose**: Shows incorrect pattern for educational purposes
- **Structural Elements**: SlashCommand invocation syntax
- **Behavioral Elements**: None (just shows syntax)
- **Duplication**: Not duplicated elsewhere

**Decision**: **KEEP**
- **Rationale**: This is a documentation example showing what NOT to do
- **Value**: Developers learn by seeing wrong vs. right patterns side-by-side
- **No Behavioral Duplication**: Contains no STEP sequences or agent procedures
- **Structural Purpose**: Demonstrates command invocation syntax

**Note**: This block demonstrates an anti-pattern (SlashCommand) that the supervise command explicitly prohibits. Keeping it provides educational value.

---

### Block 2 (Lines 63-80): Task Invocation with Inline STEP Sequences

**Location**: After "**Correct Pattern - Direct Agent Invocation**"

**Content**:
```yaml
# ✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read behavioral guidelines: .claude/agents/plan-architect.md

    **EXECUTE NOW - MANDATORY PLAN CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create: ${PLAN_PATH}
    STEP 2: Analyze workflow and research findings...
    STEP 3: Use Edit tool to develop implementation phases...
    STEP 4: Return ONLY: PLAN_CREATED: ${PLAN_PATH}

    **MANDATORY VERIFICATION**: Orchestrator verifies file exists.
  "
}
```

**Classification**: **MIXED - Structural + Behavioral**

**Analysis**:
- **Structural Elements** (KEEP):
  - `Task { subagent_type, description, prompt }` - Invocation syntax
  - `Read behavioral guidelines: .claude/agents/plan-architect.md` - Reference pattern
  - `**EXECUTE NOW**` - Execution marker (orchestrator responsibility)
  - `**MANDATORY VERIFICATION**` - Checkpoint marker (orchestrator responsibility)

- **Behavioral Elements** (REMOVE):
  - `STEP 1: Use Write tool IMMEDIATELY...` - Agent internal procedure
  - `STEP 2: Analyze workflow and research findings...` - Agent internal procedure
  - `STEP 3: Use Edit tool to develop implementation phases...` - Agent internal procedure
  - `STEP 4: Return ONLY: PLAN_CREATED: ${PLAN_PATH}` - Agent internal procedure

**Duplication**: STEP sequences duplicate content that should be in `.claude/agents/plan-architect.md`

**Decision**: **REFACTOR**
- **Keep**: Task invocation structure, behavioral file reference, execution markers
- **Remove**: STEP 1/2/3/4 sequences (these are agent internal procedures)
- **Rationale**: This example currently violates the behavioral injection pattern by including agent procedures inline instead of just referencing the agent file

**Corrected Version** (showing proper behavioral injection):
```yaml
# ✅ CORRECT - Behavioral injection pattern
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **CONTEXT INJECTION**:
    - Workflow: ${WORKFLOW_DESCRIPTION}
    - Report artifacts: ${REPORT_PATHS[@]}
    - Output path: ${PLAN_PATH}

    **EXECUTE NOW**: Create implementation plan at specified path following
    all procedures in plan-architect.md behavioral guidelines.

    **MANDATORY VERIFICATION**: Orchestrator will verify file exists.
  "
}
```

**Line-by-Line Breakdown**:
- Lines 64-67: **STRUCTURAL** (Task invocation syntax) - KEEP
- Line 69: **STRUCTURAL** (Behavioral file reference) - KEEP
- Line 71: **STRUCTURAL** (EXECUTE NOW marker) - KEEP
- Lines 73-76: **BEHAVIORAL** (STEP sequences) - REMOVE
- Line 78: **STRUCTURAL** (MANDATORY VERIFICATION marker) - KEEP

**Impact**:
- **Current**: ~150 lines showing both structural and behavioral content
- **After Refactor**: ~15 lines showing only structural template + context injection
- **Reduction**: 90% (matches research findings)

---

### Block 3 (Lines 682-829): Research Agent Template

**Location**: After research phase introduction

**Content Preview**:
```yaml
# Research Agent Template (repeated for each topic)
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/research-specialist.md

    **PRIMARY OBLIGATION - File Creation**

    **ABSOLUTE REQUIREMENT**: Creating the report file is your PRIMARY task...

    **STEP 1 (REQUIRED BEFORE STEP 2) - Create Report File**

    **EXECUTE NOW - File Creation FIRST**

    YOU MUST use Write tool IMMEDIATELY to create this EXACT file:
    Path: ${REPORT_PATHS[i]}

    [... 147 lines of detailed agent procedures ...]
  "
}
```

**Classification**: **BEHAVIORAL DUPLICATION** (agent procedures inline)

**Analysis**:
- **Structural Elements** (minimal):
  - Task invocation syntax (lines 684-687)
  - Behavioral file reference (line 688)

- **Behavioral Elements** (extensive):
  - **PRIMARY OBLIGATION blocks** (lines 690-703)
  - **STEP 1/2/3/4 sequences** with detailed procedures
  - **File creation workflows** (lines 706-737)
  - **Verification steps** (lines 734-736)
  - **Research methodology** (lines 740-767)
  - **Output format specifications** (lines 771-829)

**Duplication**: All STEP sequences and PRIMARY OBLIGATION content should be in `.claude/agents/research-specialist.md`, not inline

**Decision**: **REMOVE** (extract to agent file if missing, replace with lean context injection)

**Rationale**:
1. **Violates Single Source of Truth**: Agent behavioral content duplicated in command file
2. **Maintenance Burden**: Changes to research procedures require updating multiple files
3. **Context Bloat**: 147 lines per invocation (supervise may invoke 2-4 research agents)
4. **Behavioral Injection Pattern**: Should reference agent file with context injection only

**Corrected Version**:
```yaml
# Research Agent Template (repeated for each topic)
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **CONTEXT**:
    - Topic: ${TOPIC_NAME}
    - Output path: ${REPORT_PATHS[i]}
    - Workflow: ${WORKFLOW_DESCRIPTION}
  "
}
```

**Impact**:
- **Current**: ~147 lines per invocation
- **After**: ~12 lines per invocation
- **Reduction**: 92% per invocation
- **Aggregate**: If 3 research agents invoked, saves ~405 lines

**Target**: Ensure `.claude/agents/research-specialist.md` contains all behavioral content (PRIMARY OBLIGATION, STEP sequences, verification procedures)

---

### Block 4 (Lines 1082-1246): Planning Agent Template

**Location**: After planning phase introduction

**Content Pattern**: Similar to Block 3 - extensive STEP sequences for plan creation

**Classification**: **BEHAVIORAL DUPLICATION**

**Analysis**:
- Full plan creation procedure with STEP 1/2/3/4/5
- File creation workflows
- Template structures for plan content
- Verification checkpoints

**Decision**: **REMOVE** (replace with context injection referencing `.claude/agents/plan-architect.md`)

**Impact**: ~164 lines → ~12 lines (93% reduction)

---

### Block 5 (Lines 1440-1615): Implementation Agent Template

**Location**: After implementation phase introduction

**Content Pattern**: Similar to Blocks 3-4 - extensive implementation procedures

**Classification**: **BEHAVIORAL DUPLICATION**

**Analysis**:
- Implementation execution procedures
- Checkpoint management
- Test-before-commit workflows
- Error handling procedures

**Decision**: **REMOVE** (replace with context injection referencing `.claude/agents/code-writer.md`)

**Impact**: ~175 lines → ~12 lines (93% reduction)

---

### Block 6 (Lines 1721-1925): Testing Agent Template

**Location**: After testing phase introduction

**Content Pattern**: Similar to Blocks 3-5 - extensive testing procedures

**Classification**: **BEHAVIORAL DUPLICATION**

**Analysis**:
- Test discovery and execution procedures
- Coverage analysis steps
- Failure reporting workflows

**Decision**: **REMOVE** (replace with context injection referencing `.claude/agents/test-specialist.md`)

**Impact**: ~204 lines → ~12 lines (94% reduction)

---

### Block 7 (Lines 2246-2441): Documentation Agent Template

**Location**: After documentation phase introduction

**Content Pattern**: Similar to Blocks 3-6 - extensive documentation procedures

**Classification**: **BEHAVIORAL DUPLICATION**

**Analysis**:
- Summary generation procedures
- Cross-reference creation
- Report integration workflows

**Decision**: **REMOVE** (replace with context injection referencing `.claude/agents/doc-writer.md`)

**Impact**: ~195 lines → ~12 lines (94% reduction)

---

## Summary of Decisions

### Keep (2 Blocks - Documentation Examples)

1. **Block 1 (lines 49-54)**: SlashCommand anti-pattern example
   - **Type**: Structural template (documentation)
   - **Action**: Keep as-is
   - **Reason**: Educational value, no behavioral duplication

### Refactor (1 Block - Documentation Example with Behavioral Content)

2. **Block 2 (lines 63-80)**: Task invocation with inline STEP sequences
   - **Type**: Mixed (structural + behavioral)
   - **Action**: Remove STEP sequences, keep structural syntax
   - **Reason**: Demonstrates correct invocation pattern but currently includes behavioral duplication

### Remove (5 Blocks - Agent Templates)

3. **Block 3 (lines 682-829)**: Research agent template
4. **Block 4 (lines 1082-1246)**: Planning agent template
5. **Block 5 (lines 1440-1615)**: Implementation agent template
6. **Block 6 (lines 1721-1925)**: Testing agent template
7. **Block 7 (lines 2246-2441)**: Documentation agent template

**Removal Strategy**:
- Extract any missing behavioral content to appropriate `.claude/agents/*.md` files
- Replace with lean context injection (12-15 lines per invocation)
- Maintain Task invocation structure (structural template)
- Remove all STEP sequences, PRIMARY OBLIGATION blocks, and detailed procedures

---

## Aggregate Impact

### Before Refactor
- **Documentation examples**: 2 blocks (~30 lines) - 1 clean, 1 with behavioral duplication
- **Agent templates**: 5 blocks (~885 lines total)
- **Total**: ~915 lines for YAML blocks

### After Refactor
- **Documentation examples**: 2 blocks (~15 lines) - both clean
- **Agent templates**: 5 blocks (~60 lines total)
- **Total**: ~75 lines for YAML blocks

### Reduction
- **Lines removed**: ~840 lines
- **Percentage reduction**: 92%
- **Maintenance files**: 1 (supervise.md only, not 6 files)

---

## Verification Strategy

After refactoring, verify:

1. **Pattern Detection**:
   ```bash
   # Count YAML blocks
   grep -c '```yaml' .claude/commands/supervise.md
   # Expected: 2 (documentation examples only)

   # Count STEP sequences in command file
   grep -c "STEP [0-9]" .claude/commands/supervise.md
   # Expected: 0 (all removed to agent files)

   # Count PRIMARY OBLIGATION in command file
   grep -c "PRIMARY OBLIGATION" .claude/commands/supervise.md
   # Expected: 0 (all in agent files)
   ```

2. **Behavioral Files Complete**:
   ```bash
   # Verify each agent file contains required procedures
   for agent in research-specialist plan-architect code-writer test-specialist doc-writer; do
     if [ ! -f ".claude/agents/${agent}.md" ]; then
       echo "Missing: ${agent}.md"
     else
       # Check for STEP sequences
       step_count=$(grep -c "STEP [0-9]" ".claude/agents/${agent}.md")
       echo "${agent}.md: ${step_count} STEP instructions"
     fi
   done
   ```

3. **Regression Test**:
   ```bash
   # Run updated regression test
   .claude/tests/test_supervise_delegation.sh
   # Expected: Test 2 reports 2 YAML blocks (documentation examples)
   ```

---

## Next Steps

Per Phase 2, Task 2.2:
1. Create corrected refactor instructions with pattern verification (Phase 0)
2. Document exact grep patterns for Block 2 and Blocks 3-7
3. Provide before/after examples for each replacement
4. Update regression test to detect actual patterns

---

## References

- **Standards**: `.claude/docs/reference/template-vs-behavioral-distinction.md`
- **Diagnostic**: `.claude/specs/444_research_allowed_tools_fix/reports/001_research/OVERVIEW.md`
- **Target File**: `.claude/commands/supervise.md` (2,520 lines)
- **Implementation Plan**: Phase 2 of spec 441 documentation improvements
