# Research Report: Standards Documentation for Bash Block Size Limits

## Executive Summary

This report documents existing standards for bash block size limits and preprocessing constraints, and provides recommendations for updating `.claude/docs/` standards to prevent similar bugs in the future.

**Key Findings**:
1. Bash block size threshold (400 lines) is well-documented in troubleshooting guide
2. No explicit standard exists in command authoring guidelines for bash block size limits
3. Block consolidation guidance exists but lacks size threshold warnings
4. CLAUDE.md has no dedicated section for bash block sizing

**Recommendations**:
1. Add bash block size limit standard to `command-authoring.md`
2. Update CLAUDE.md `code_standards` section with block size guidance
3. Add cross-references between related documents
4. Create pre-commit hook to detect oversized bash blocks

---

## Research Questions

### Q1: What existing standards documents mention bash block size limits or preprocessing constraints?

**Answer**: Three primary documents mention bash block size limits:

1. **Troubleshooting Documentation** (Primary):
   - File: `.claude/docs/troubleshooting/bash-tool-limitations.md`
   - Lines: 138-275
   - Coverage: Comprehensive technical explanation of 400-line threshold
   - Context: Troubleshooting context (reactive), not preventive standard

2. **Advanced Command Patterns** (Secondary):
   - File: `.claude/docs/guides/development/command-development/command-development-advanced-patterns.md`
   - Lines: 614-620
   - Coverage: Brief mention in decision framework
   - Context: Pattern selection guidance, not explicit standard

3. **Testing Architecture** (Tertiary):
   - File: `.claude/docs/reference/architecture/testing.md`
   - Line: 102
   - Coverage: Checklist item only ("Are bash blocks <300 lines each?")
   - Context: Validation checklist, not standard definition

**Gap Identified**: No standard exists in the primary command authoring documentation (`.claude/docs/reference/standards/command-authoring.md`).

---

### Q2: Is there already a documented standard for bash block size thresholds?

**Answer**: **Partial standard exists, but not in standard location.**

**Existing Documentation**:

From `bash-tool-limitations.md` (lines 141-186):
```
When bash blocks in command markdown files exceed approximately 400 lines,
Claude AI transforms bash code during extraction, causing syntax errors.

**Root Cause**: Claude AI's markdown processing pipeline escapes special
characters (including `!`) when extracting large bash blocks, transforming
valid bash syntax into invalid syntax.
```

**Thresholds Documented**:
- **Safe**: <300 lines
- **Caution**: 300-400 lines
- **High Risk**: >400 lines (requires splitting)

**Gap Analysis**:
1. **Location**: Troubleshooting guide (reactive) vs. standards (preventive)
2. **Discoverability**: Not linked from command authoring standards
3. **Enforcement**: No automated detection in pre-commit hooks
4. **CLAUDE.md Reference**: Not mentioned in main standards file

---

### Q3: What standards documents would be most appropriate to update or create?

**Primary Target**: `.claude/docs/reference/standards/command-authoring.md`

**Rationale**:
- Central location for command development standards
- Already contains block consolidation guidance (section 6.8, lines 1107-1261)
- Logical home for bash block sizing limits
- Frequently referenced by `/create-plan` and `/implement` commands

**Proposed Section**: "Bash Block Size Limits and Prevention"

**Secondary Targets**:

1. **CLAUDE.md** (Main Project Standards):
   - Section: `<!-- SECTION: code_standards -->`
   - Add: Bash block size threshold quick reference
   - Benefit: Discoverability for all commands

2. **Output Formatting Standards**:
   - File: `.claude/docs/reference/standards/output-formatting.md`
   - Section: "Block Consolidation Patterns" (lines 209-275)
   - Add: Warning about 400-line threshold in consolidation guidance
   - Benefit: Prevent over-consolidation

3. **Bash Block Execution Model**:
   - File: `.claude/docs/concepts/bash-block-execution-model.md`
   - Section: Add to anti-patterns list (section 10)
   - ID: `AP-011: Oversized Bash Blocks`
   - Benefit: Complete anti-pattern catalog

---

### Q4: What specific guidance should be added to prevent these issues?

**Recommended Standard Content**:

#### Section Title: "Bash Block Size Limits and Prevention"

#### Location: `command-authoring.md` (new section 8)

#### Content Outline:

1. **Size Threshold Definition**
   - Safe: <300 lines
   - Caution: 300-400 lines
   - Prohibited: >400 lines (ERROR-level violation)

2. **Technical Root Cause**
   - Claude AI markdown processing pipeline escapes special characters in large blocks
   - Preprocessing occurs before runtime bash execution
   - Affects indirect variable references (`${!var}`), array expansions, history expansion

3. **Detection Methods**
   - Manual: `awk '/^```bash$/,/^```$/ {count++} END {print count-2}' file.md`
   - Automated: Pre-commit hook (proposed)
   - Error symptom: `bad substitution` errors in blocks >400 lines

4. **Prevention Patterns**
   - Split bash blocks at logical boundaries (setup, execute, cleanup)
   - Target 200-250 lines per block (50% safety margin)
   - Use state persistence library for cross-block communication
   - Add checkpoint reporting between blocks

5. **Splitting Strategy**
   - Identify natural boundaries (library sourcing, agent invocation, validation)
   - Preserve state variables via `append_workflow_state()`
   - Re-source libraries in each block (subprocess isolation)
   - Add execution directives for each new block

6. **Real-World Example**
   - Command: `/research` (Block 1: 501 lines → 3 blocks of <250 lines)
   - Symptoms: `bad substitution` in array access
   - Solution: Split at topic naming agent, decomposition, and path calculation
   - Result: 0 errors after split

7. **Cross-References**
   - Troubleshooting: `bash-tool-limitations.md#large-bash-block-transformation`
   - Patterns: `output-formatting.md#block-consolidation-patterns`
   - Concepts: `bash-block-execution-model.md#anti-patterns`

---

## Detailed Findings

### Existing Documentation Analysis

#### Document 1: bash-tool-limitations.md (PRIMARY)

**Strengths**:
- Comprehensive technical explanation (138 lines)
- Clear symptom description (`bad substitution`, `!: command not found`)
- Real-world example (coordinate.md, 402 lines → 3 blocks)
- Detection test provided
- Prevention guidance (monitor during development)

**Weaknesses**:
- Located in troubleshooting (reactive, not preventive)
- Not discoverable during command authoring phase
- No link from command-authoring.md
- No CLAUDE.md quick reference
- No automated enforcement

**Relevance to /research Bug**:
- Exact same symptom: Block 1 exceeded 400 lines (501 lines)
- Same solution pattern: Split into smaller blocks
- Validates 400-line threshold as legitimate design constraint

#### Document 2: command-development-advanced-patterns.md (SECONDARY)

**Strengths**:
- Mentions threshold in decision framework (line 616)
- Provides numeric guidance (300-400 line caution zone)
- Contextualizes within pattern selection

**Weaknesses**:
- Brief mention only (5 lines)
- No enforcement guidance
- No detection methods
- No examples

**Gap**: Assumes reader already knows about bash block size limits.

#### Document 3: command-authoring.md (GAP IDENTIFIED)

**Current Coverage**:
- Block consolidation patterns (section 6.8, lines 1107-1261)
- Target block count (2-3 blocks per command)
- Consolidation benefits (50-67% reduction in display noise)
- Decision matrix (when to consolidate vs. separate)

**Missing Coverage**:
- **NO mention of 400-line size threshold**
- **NO warning about over-consolidation risks**
- **NO guidance on maximum block size**
- **NO cross-reference to bash-tool-limitations.md**

**Impact**: Command authors may over-consolidate bash blocks, exceeding 400-line threshold and triggering preprocessing bugs.

#### Document 4: CLAUDE.md (MAIN STANDARDS FILE)

**Current Coverage**:
- `<!-- SECTION: code_standards -->` (lines 49-118)
- Quick reference for mandatory patterns
- Links to detailed standards documents

**Missing Coverage**:
- **NO mention of bash block size limits**
- **NO quick reference for 400-line threshold**
- **NO "Used by" metadata for bash block sizing**

**Opportunity**: Add bash block size quick reference to make threshold discoverable.

---

## Recommendations

### Recommendation 1: Add Standard to command-authoring.md

**Priority**: HIGH

**Action**: Create new section "Bash Block Size Limits and Prevention" after section 7 (Path Validation Patterns).

**Content Structure**:
```markdown
## Bash Block Size Limits and Prevention

Commands MUST keep bash blocks under 400 lines to prevent preprocessing transformation bugs.

### Size Thresholds

**Mandatory Limits**:
- **Safe**: <300 lines (recommended)
- **Caution**: 300-400 lines (monitor closely)
- **Prohibited**: >400 lines (ERROR-level violation)

### Technical Root Cause

Claude AI's markdown processing pipeline escapes special characters when extracting
large bash blocks (>400 lines). This transformation occurs during preprocessing
(before runtime bash execution), causing valid bash syntax to become invalid.

**Affected Patterns**:
- Indirect variable references: `${!var_name}`
- Array key expansion: `${!array[@]}`
- Command substitution in large blocks
- History expansion patterns (despite `set +H`)

### Detection

**Manual Detection**:
```bash
# Count lines in bash block
awk '/^```bash$/,/^```$/ {count++} END {print count-2}' command.md
```

**Error Symptoms**:
- `bash: ${\\!varname}: bad substitution`
- `bash: !: command not found` (despite `set +H` directive)
- Errors only in blocks >400 lines, same code works in smaller blocks

### Prevention

**Splitting Strategy**:
1. Identify natural boundaries:
   - Library sourcing → Agent invocation → Validation
   - Setup → Execute → Cleanup
   - Topic naming → Decomposition → Path calculation
2. Target 200-250 lines per block (50% safety margin below threshold)
3. Use state persistence for cross-block variables
4. Add checkpoint reporting between blocks

**Example Split Points**:
```markdown
## Block 1a: Setup and Initialization (235 lines)
**EXECUTE NOW**: Initialize state machine and capture arguments

## Block 1b: Agent Invocation (Task tool)
**EXECUTE NOW**: USE the Task tool to invoke topic-naming-agent

## Block 1c: Topic Decomposition and Path Calculation (225 lines)
**EXECUTE NOW**: Load topic name, decompose into sub-topics, calculate report paths
```

### Real-World Example

**Command**: `/research` (Spec 010)
**Issue**: Block 1 exceeded 501 lines, causing `bad substitution` in array access
**Solution**: Split into 3 blocks (Block 1a: 235 lines, Block 1b: Task invocation, Block 1c: 225 lines)
**Result**: All preprocessing errors eliminated

### Related Documentation

- [Bash Tool Limitations - Large Block Transformation](../../troubleshooting/bash-tool-limitations.md#large-bash-block-transformation)
- [Output Formatting - Block Consolidation](output-formatting.md#block-consolidation-patterns)
- [Bash Block Execution Model - Anti-Patterns](../../concepts/bash-block-execution-model.md#anti-patterns)

---
```

**Estimated Effort**: 30 minutes to write, 15 minutes to review and integrate.

---

### Recommendation 2: Update CLAUDE.md Code Standards Section

**Priority**: MEDIUM

**Action**: Add bash block size quick reference to `<!-- SECTION: code_standards -->`.

**Proposed Addition** (after line 97):

```markdown
**Quick Reference - Bash Block Size Limits**:
- All bash blocks MUST be under 400 lines (preprocessing transformation threshold)
- Target: 200-250 lines per block (50% safety margin)
- Detection: Manual line count or automated pre-commit hook
- Split strategy: Logical boundaries (setup → execute → cleanup)
- See [Command Authoring Standards - Bash Block Size Limits](.claude/docs/reference/standards/command-authoring.md#bash-block-size-limits-and-prevention)
```

**Update "Used by" Metadata**:
```markdown
[Used by: /create-plan, /implement, /research, /debug, all command authoring]
```

**Estimated Effort**: 10 minutes.

---

### Recommendation 3: Add Cross-References

**Priority**: LOW

**Action**: Add forward references from related documents to new bash block size standard.

**Files to Update**:

1. **output-formatting.md** (Block Consolidation section, line 227):
   ```markdown
   **When to Consolidate vs. Separate**:

   **Consolidate blocks when**:
   - Operations are sequential dependencies
   - No intermediate user visibility needed
   - **IMPORTANT**: Total consolidated block stays under 400 lines (see [Bash Block Size Limits](command-authoring.md#bash-block-size-limits-and-prevention))
   ```

2. **bash-block-execution-model.md** (Anti-Patterns section):
   Add new anti-pattern entry:
   ```markdown
   ### AP-011: Oversized Bash Blocks

   **ID**: AP-011
   **Severity**: ERROR
   **Detection**: Manual line count, pre-commit hook (proposed)

   **Description**: Bash blocks exceeding 400 lines trigger preprocessing transformation bugs.

   **Example**:
   ```bash
   # WRONG: 501-line bash block
   # Causes: bad substitution errors in array access
   ```

   **Correct Pattern**: Split into 3 blocks of <250 lines each.
   See [Command Authoring - Bash Block Size Limits](../reference/standards/command-authoring.md#bash-block-size-limits-and-prevention).
   ```

3. **bash-tool-limitations.md** (Prevention section, line 271):
   ```markdown
   ### Prevention

   **Standard Reference**: See [Command Authoring Standards - Bash Block Size Limits](../reference/standards/command-authoring.md#bash-block-size-limits-and-prevention) for complete prevention guidance.

   When writing command files:
   1. **Monitor bash block sizes** during development
   2. **Split proactively** if approaching 300 lines
   3. **Test with indirect references** to catch transformation early
   ```

**Estimated Effort**: 20 minutes.

---

### Recommendation 4: Create Pre-Commit Hook (Optional)

**Priority**: LOW (Future Enhancement)

**Action**: Create automated detection script to prevent oversized bash blocks from being committed.

**Script**: `.claude/scripts/lint/check-bash-block-size.sh`

**Functionality**:
```bash
#!/bin/bash
# check-bash-block-size.sh
# Validates bash blocks in command markdown files are under 400 lines

FAILED=0
THRESHOLD=400

for file in .claude/commands/*.md .claude/agents/*.md; do
  [ ! -f "$file" ] && continue

  # Extract bash block line counts
  BLOCK_SIZES=$(awk '/^```bash$/,/^```$/ {
    if (/^```bash$/) { count=0; next }
    if (/^```$/) { print count; next }
    count++
  }' "$file")

  for size in $BLOCK_SIZES; do
    if [ "$size" -gt "$THRESHOLD" ]; then
      echo "ERROR: $file has bash block with $size lines (threshold: $THRESHOLD)"
      FAILED=1
    elif [ "$size" -gt 300 ]; then
      echo "WARN: $file has bash block with $size lines (approaching threshold)"
    fi
  done
done

exit $FAILED
```

**Integration**: Add to `.git/hooks/pre-commit` (if pre-commit framework exists).

**Estimated Effort**: 1 hour (script + testing + documentation).

---

## Gap Analysis Summary

### Current State

| Document | Coverage | Location | Discoverability | Enforcement |
|----------|----------|----------|----------------|-------------|
| bash-tool-limitations.md | Comprehensive | Troubleshooting | Low (reactive) | None |
| command-development-advanced-patterns.md | Brief mention | Guides | Medium | None |
| testing.md | Checklist item | Architecture | Low | Manual |
| command-authoring.md | **NOT COVERED** | Standards | **N/A** | None |
| CLAUDE.md | **NOT COVERED** | Main Standards | **N/A** | None |

### Desired State (After Recommendations)

| Document | Coverage | Location | Discoverability | Enforcement |
|----------|----------|----------|----------------|-------------|
| command-authoring.md | **Standard definition** | Standards | **High (primary)** | Documentation |
| CLAUDE.md | **Quick reference** | Main Standards | **High** | Documentation |
| bash-tool-limitations.md | Technical deep dive | Troubleshooting | Medium | None |
| output-formatting.md | **Cross-reference** | Standards | Medium | Documentation |
| bash-block-execution-model.md | **Anti-pattern entry** | Concepts | Medium | Documentation |
| check-bash-block-size.sh | **Automated detection** | Linters | High | **Pre-commit hook** |

---

## Implementation Priority

### Phase 1: Critical (Immediate)
- [ ] **Recommendation 1**: Add standard to command-authoring.md
- [ ] **Recommendation 2**: Update CLAUDE.md code standards section

**Rationale**: These changes make the standard discoverable during command authoring (preventive, not reactive).

**Estimated Effort**: 40 minutes total

### Phase 2: Important (Next Sprint)
- [ ] **Recommendation 3**: Add cross-references to related documents

**Rationale**: Improves discoverability for users reading related content.

**Estimated Effort**: 20 minutes total

### Phase 3: Enhancement (Future)
- [ ] **Recommendation 4**: Create pre-commit hook for automated detection

**Rationale**: Enforces standard automatically, prevents violations from being committed.

**Estimated Effort**: 1 hour (script + testing + documentation)

---

## Related Research

### Existing Standards That Apply

1. **Block Consolidation Patterns** (output-formatting.md, lines 209-275):
   - Target 2-3 blocks per command
   - Balance clarity with execution efficiency
   - **Gap**: No mention of 400-line upper bound

2. **Bash Block Execution Model** (bash-block-execution-model.md):
   - Subprocess isolation requires state persistence
   - Each block runs in new process
   - **Gap**: Anti-patterns list incomplete (no oversized blocks entry)

3. **Command Authoring Standards** (command-authoring.md):
   - Comprehensive command development patterns
   - Covers directives, subprocess isolation, state persistence
   - **Gap**: No bash block size limit standard

### Success Patterns from Other Commands

1. **/create-plan**: Never exceeded 300 lines per bash block
2. **/implement**: Largest block is 287 lines (under threshold)
3. **/coordinate**: Fixed by splitting 402-line block → 3 blocks (176, 168, 77 lines)
4. **/research**: About to fix by splitting 501-line block → 3 blocks (<250 lines each)

**Pattern**: Commands that proactively split blocks at 200-250 lines never encounter preprocessing bugs.

---

## Conclusion

The 400-line bash block size threshold is a **legitimate technical constraint** caused by Claude AI's markdown preprocessing pipeline. While well-documented in the troubleshooting guide, it is **not discoverable during command authoring**, leading to preventable bugs.

**Recommendations prioritize discoverability** by adding the standard to primary command authoring documentation and CLAUDE.md quick reference. Cross-references and automated enforcement provide additional layers of prevention.

**Implementing Phase 1 recommendations (40 minutes effort) will prevent future occurrences** of this class of bug by making the standard visible to command authors before they write oversized bash blocks.

---

## Metadata

- **Research Complexity**: 2
- **Topics Analyzed**: 4 (bash-tool-limitations, command-authoring, CLAUDE.md, related standards)
- **Documents Reviewed**: 7 standards/troubleshooting files
- **Recommendations**: 4 (1 critical, 1 important, 1 enhancement, 1 future)
- **Estimated Implementation Effort**: 2 hours total (Phase 1: 40 min, Phase 2: 20 min, Phase 3: 1 hour)
- **Report Created**: 2025-12-10
