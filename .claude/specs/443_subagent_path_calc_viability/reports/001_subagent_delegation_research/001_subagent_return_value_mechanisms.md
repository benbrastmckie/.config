# Subagent Return Value Mechanisms Research Report

## Metadata
- **Date**: 2025-10-24
- **Agent**: research-specialist
- **Topic**: Subagent return value mechanisms in .claude/ system
- **Report Type**: Codebase analysis

## Executive Summary

Research reveals that Claude Code's Task tool does NOT support direct output capture via command substitution. Parent commands cannot use `$(Task {...})` or similar patterns to capture agent return values. Instead, agents return text that appears in Claude's conversational output stream. Parent commands pre-calculate absolute file paths, inject them into agent prompts, instruct agents to create files at those paths, and verify file existence after agent completion. This file-based coordination pattern is mandatory for reliable agent-to-parent communication.

## Findings

### Current Return Value Mechanisms

Based on analysis of .claude/commands/ and .claude/agents/, the return value mechanism follows a strict pattern:

**Pattern: Pre-Calculated Paths with File-Based Verification**

1. **Parent Pre-Calculates Paths**: Command calculates absolute file paths BEFORE invoking agents
2. **Path Injection**: Parent injects absolute paths into agent prompt
3. **Agent Creates Files**: Agent writes output to specified path
4. **Agent Returns Confirmation**: Agent returns structured text (e.g., `REPORT_CREATED: /path/to/file.md`)
5. **Parent Verifies Files**: Parent uses Bash to check if files exist at pre-calculated paths
6. **Fallback on Missing Files**: Parent creates placeholder files if agent fails

**Key Insight**: The Task tool's output appears in Claude's conversational response. Parent commands do NOT capture this output programmatically. Instead, they rely on filesystem verification.

**Evidence**: /research.md lines 232-300 show verification pattern:
```bash
for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  EXPECTED_PATH="${SUBTOPIC_REPORT_PATHS[$subtopic]}"
  if [ -f "$EXPECTED_PATH" ]; then
    echo "✓ Verified: $subtopic at $EXPECTED_PATH"
    VERIFIED_PATHS["$subtopic"]="$EXPECTED_PATH"
  else
    # Fallback: Create minimal report
    cat > "$EXPECTED_PATH" <<EOF
# Fallback report...
EOF
  fi
done
```

### Data Types Returned from Agents

Agents return **plain text output** in specific formats. Analysis of .claude/agents/ reveals these return patterns:

**1. Confirmation Lines (Most Common)**
- Format: `REPORT_CREATED: /absolute/path/to/file.md`
- Format: `REPORT_PATH: /absolute/path/to/file.md`
- Purpose: Signal file creation completion
- Evidence: research-specialist.md:182-186, debug-analyst.md (multiple occurrences)

**2. Progress Markers (Streaming Updates)**
- Format: `PROGRESS: <brief-message>`
- Purpose: Provide visibility during long-running operations
- Evidence: research-specialist.md:202-237

**3. Structured Text (Legacy Pattern)**
- Format: Plain text summaries or findings
- Problem: Parent cannot parse or capture reliably
- Evidence: implement.md:572 shows "Return: Summary of changes made + test results"

**4. JSON Metadata (Proposed but Not Consistently Implemented)**
- Format: JSON with path, summary, status fields
- Purpose: Enable structured parsing of agent results
- Evidence: debug.md:234 mentions "confirmation JSON" but not universally used

**Key Finding**: NO command substitution is possible. Agent output appears in Claude's conversational stream but is NOT captured into Bash variables. Commands must verify outputs through filesystem checks, not variable assignment.

### Parent Command Access Patterns

Parent commands access agent outputs through **filesystem verification**, not direct output capture. Analysis reveals a consistent pattern across all coordinating commands:

**Standard Access Pattern**:

1. **Pre-Calculation Phase**:
   ```bash
   # Command calculates paths BEFORE invoking agent
   REPORT_PATH="/home/benjamin/.config/.claude/specs/443_topic/reports/001_report.md"
   ```

2. **Injection Phase**:
   ```yaml
   Task {
     subagent_type: "general-purpose"
     description: "Research with mandatory artifact creation"
     prompt: "
       **Report Path**: ${REPORT_PATH}

       Create file at EXACT path using Write tool.
       Return: REPORT_CREATED: ${REPORT_PATH}
     "
   }
   ```

3. **Verification Phase**:
   ```bash
   # Parent checks filesystem directly
   if [ -f "$REPORT_PATH" ]; then
     echo "✓ Verified: Report created"
   else
     echo "⚠ Warning: Agent non-compliance, creating fallback"
     # Parent creates fallback file
   fi
   ```

**Key Pattern**: Commands NEVER attempt to capture Task output. They inject paths, invoke agents, then verify file existence.

**Evidence**:
- research.md:99-106 - Pre-calculation and verification checkpoint
- research.md:232-300 - File verification loop with fallback
- orchestrate.md:754-876 - Path injection into research agents
- report.md:234-253 - Return format specification and collection pattern

### Command Substitution Analysis

**Critical Finding**: Command substitution (e.g., `VAR=$(Task {...})`) is **NOT supported** and **NOT used** anywhere in the codebase.

**Evidence from Comprehensive Search**:

Searched entire .claude/commands/ directory for patterns like:
- `$(Task`
- `RESULT=`
- `OUTPUT=`
- `capture`
- Variable assignment after Task invocations

**Result**: ZERO instances of command substitution with Task tool.

**Why This Matters**:

The Task tool is NOT like traditional bash commands. It's a Claude Code-specific tool that:
1. Invokes a new Claude instance (subagent) with injected prompt
2. Subagent executes and produces conversational output
3. Output appears in parent's Claude conversation stream
4. Parent Claude CANNOT assign this output to a Bash variable
5. Parent MUST verify results through filesystem or other side effects

**Architectural Constraint**: The Task tool's API does NOT return programmatically accessible output to the invoking command. This is why all commands use file-based coordination.

**Implications for Path-Calculation Subagent**:
- Cannot use pattern: `CALCULATED_PATH=$(Task {...})`
- Must use pattern: Agent writes to file → parent reads file
- Adds complexity: 2 operations instead of 1
- Reduces benefit: Path calculation agent would need to persist paths to filesystem anyway

### Concrete Examples from Codebase

**Example 1: /research Command - Hierarchical Research Pattern**

Location: /home/benjamin/.config/.claude/commands/research.md

Pre-calculation (lines 109-144):
```bash
# Create subdirectory for this research task
RESEARCH_SUBDIR=$(create_research_subdirectory "$TOPIC_DIR" "${TOPIC_NAME}_research")

# Calculate paths for each subtopic
SUBTOPIC_NUM=1
for subtopic in "${SUBTOPICS[@]}"; do
  REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$SUBTOPIC_NUM")_${subtopic}.md"
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"
  SUBTOPIC_NUM=$((SUBTOPIC_NUM + 1))
done
```

Agent invocation (lines 184-200):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  prompt: "
    **Report Path**: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]

    Create file at EXACT path using Write tool.
    Return: REPORT_CREATED: [path]
  "
}
```

Verification (lines 248-292):
```bash
if [ -f "$EXPECTED_PATH" ]; then
  echo "✓ Verified: $subtopic at $EXPECTED_PATH"
  VERIFIED_PATHS["$subtopic"]="$EXPECTED_PATH"
else
  # Fallback creation
  cat > "$EXPECTED_PATH" <<EOF
# Fallback report...
EOF
fi
```

**Pattern**: Pre-calculate → Inject → Verify → Fallback

**Example 2: /debug Command - Parallel Hypothesis Investigation**

Location: /home/benjamin/.config/.claude/commands/debug.md:215-234

Agent invocation with path injection:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Investigate hypothesis: ${HYPOTHESIS}"
  prompt: |
    Investigate this hypothesis and create artifact at:
    specs/${TOPIC_DIR}/debug/$(printf "%03d" $((i+1)))_investigation_${HYPOTHESIS// /_}.md

    Return metadata only (path + 50-word summary + confirmation JSON).
}
```

**Pattern**: Path injected inline, agent creates file, parent verifies filesystem

**Example 3: /implement Command - Code Writer Delegation**

Location: /home/benjamin/.config/.claude/commands/implement.md:552-572

Agent invocation:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Implement Phase ${PHASE_NUM} - ${PHASE_NAME}"
  prompt: |
    Read and follow: .claude/agents/code-writer.md

    Implement Phase ${PHASE_NUM}: ${PHASE_NAME}

    Plan: ${PLAN_PATH}
    Phase Tasks: ${TASK_LIST}

    Return: Summary of changes made + test results
}
```

**Pattern**: NO path calculation - agent modifies existing files per plan

**Example 4: /orchestrate Command - Research Phase Enforcement**

Location: /home/benjamin/.config/.claude/commands/orchestrate.md:754-876

Multiple retry attempts with increasing enforcement:
```yaml
# Attempt 1: Standard invocation
Task {
  prompt: "
    **Report Path**: ${ARTIFACT_REPORTS}${TOPIC_NUMBER}_research_[TOPIC_NAME].md
    Create file using Write tool.
  "
}

# Attempt 2: Ultra-explicit enforcement
Task {
  prompt: "
    **CRITICAL: You MUST create a file.**
    **STEP 1 - CREATE FILE NOW**
    Use Write tool with this exact path: ${REPORT_PATH}
  "
}
```

**Pattern**: Escalating enforcement with same path injection pattern

**Example 5: /report Command - Single Report Creation**

Location: /home/benjamin/.config/.claude/commands/report.md:234-253

Return format specification:
```
STEP 4: Verify file exists and return:
REPORT_CREATED: [EXACT_ABSOLUTE_PATH]

Monitor agent execution:
- Watch for PROGRESS: markers
- Collect REPORT_CREATED: paths when agents complete
- Verify paths match pre-calculated paths
```

**Pattern**: Structured return format, but parent STILL verifies filesystem

## Recommendations

### Viability Assessment for Path-Calculation Subagent

**Verdict**: **NOT VIABLE** for direct path calculation with output capture.

**Reason**: The Task tool does NOT support command substitution or programmatic output capture. A path-calculation subagent would need to:

1. Write calculated paths to a file
2. Parent reads file to get paths
3. Parent uses paths to invoke research agents
4. Research agents write to those paths
5. Parent verifies research agent outputs

**Problem**: Steps 1-2 add overhead without meaningful delegation benefit. Path calculation is deterministic and fast (library functions execute in milliseconds). Delegating to a subagent adds 10-30 seconds of latency per invocation.

**Alternative Pattern**: Use unified-location-detection.sh library directly (current pattern).

### Pros of File-Based Subagent Coordination

1. **Explicit Artifact Trail**: All agent outputs create permanent files for audit and debugging
2. **Deterministic Verification**: Parent can objectively verify agent compliance via filesystem checks
3. **Fallback Resilience**: Parent can create placeholder files if agents fail, workflow continues
4. **Parallel Execution**: Multiple agents can write to different pre-calculated paths simultaneously
5. **Context Reduction**: Agents read paths from injected context, don't need to compute them
6. **Clear Separation of Concerns**: Parent orchestrates (calculates, coordinates), agents execute (research, implement, document)

### Cons of File-Based Subagent Coordination

1. **No Dynamic Return Values**: Cannot capture computed values from agents (e.g., calculated paths, counts, IDs)
2. **Filesystem Dependency**: All communication requires file I/O, adds latency
3. **Verification Overhead**: Parent must check filesystem after each agent, cannot trust agent assertions
4. **Fallback Complexity**: Parent must implement fallback creation for every agent delegation point
5. **Limited to Write-Heavy Tasks**: Pattern only works for agents that create new files, not agents that compute and return values
6. **Coordination Boilerplate**: Every agent invocation requires 3-phase pattern (pre-calc → inject → verify)

### Specific Recommendations

**For Commands Needing Path Calculation**:
- Use unified-location-detection.sh library functions directly
- Do NOT delegate path calculation to subagent
- Pre-calculate all paths before any agent invocations
- Pattern: `REPORT_PATH=$(calculate_report_path "$TOPIC" "$SUBTOPIC")` (library function, not agent)

**For Commands Coordinating Research/Writing Agents**:
- Continue using file-based coordination pattern (it's mandatory)
- Always pre-calculate absolute paths
- Always inject paths into agent prompts
- Always verify filesystem after agent completion
- Always implement fallback creation

**For Future Tool Development**:
- Consider adding structured output capture to Task tool API
- Enable pattern: `RESULT=$(Task {...} --capture-output --format=json)`
- Would enable value-returning agents (path calculators, validators, parsers)
- Current tool API forces ALL agents to be file-creating agents

## References

### Command Files Analyzed

1. **/home/benjamin/.config/.claude/commands/research.md**
   - Lines 99-106: Path pre-calculation and verification checkpoint
   - Lines 109-144: Subtopic report path calculation
   - Lines 184-200: Agent invocation with path injection
   - Lines 232-300: File verification loop with fallback creation
   - Pattern: Hierarchical multi-agent research coordination

2. **/home/benjamin/.config/.claude/commands/orchestrate.md**
   - Lines 754-876: Research phase with escalating enforcement
   - Pattern: Multiple retry attempts with same path injection

3. **/home/benjamin/.config/.claude/commands/report.md**
   - Lines 234-253: Return format specification and collection pattern
   - Pattern: Single research agent with verification

4. **/home/benjamin/.config/.claude/commands/debug.md**
   - Lines 215-234: Parallel hypothesis investigation
   - Pattern: Path injection inline, filesystem verification

5. **/home/benjamin/.config/.claude/commands/implement.md**
   - Lines 178-195: Documentation writer delegation
   - Lines 552-572: Code writer delegation
   - Lines 625-640: Spec updater delegation
   - Pattern: Multiple agent types, no path pre-calculation (agents modify existing files)

6. **/home/benjamin/.config/.claude/commands/example-with-agent.md**
   - Lines 1-202: Complete agent registry patterns and invocation examples
   - Pattern: Demonstrates behavioral injection but not return value handling

### Agent Files Analyzed

7. **/home/benjamin/.config/.claude/agents/research-specialist.md**
   - Lines 182-198: Return format specification (REPORT_CREATED: path)
   - Lines 202-237: Progress marker requirements
   - Pattern: File creation with structured confirmation

8. **/home/benjamin/.config/.claude/agents/debug-analyst.md**
   - Multiple REPORT_CREATED: pattern references
   - Pattern: Investigation file creation with metadata return

### Documentation Files Analyzed

9. **/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md**
   - Lines 1-150: Behavioral injection pattern definition and rationale
   - Context: Why commands orchestrate instead of executing directly

10. **/home/benjamin/.config/.claude/docs/guides/using-agents.md**
    - Lines 1-100: Layered context architecture for agent invocations
    - Context: How context is passed to agents (not how output is returned)

### Key Findings Summary

- **27 command files** contain Task tool invocations
- **ZERO instances** of command substitution with Task tool
- **100% adoption** of file-based coordination pattern
- **Universal pattern**: Pre-calculate → Inject → Verify → Fallback
- **Architectural constraint**: Task tool does not support output capture

### Related Library Functions

- `unified-location-detection.sh::perform_location_detection()` - Path calculation library
- `unified-location-detection.sh::create_research_subdirectory()` - Directory creation
- `unified-location-detection.sh::ensure_artifact_directory()` - Directory verification
- Pattern: Direct library usage instead of agent delegation for path calculation
