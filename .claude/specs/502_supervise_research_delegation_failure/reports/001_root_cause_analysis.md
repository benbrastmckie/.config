# Root Cause Analysis: /supervise Research Delegation Failure

## Executive Summary

The `/supervise` command failed to invoke research subagents and instead executed bash commands directly, violating the orchestration pattern. Root cause: **Undermined imperative pattern** - the command contains imperative directives (`**EXECUTE NOW**`) but immediately undermines them with template disclaimers that signal "this is documentation, not an instruction to execute now."

**Impact**: 0% research agent delegation rate, workflow executed incorrectly.

## Evidence

### Symptom
From `/home/benjamin/.config/.claude/TODO3.md` (lines 12, 18, 26):
- AI executed `Bash(find /home/benjamin/.config/.claude -type d | sort)`
- AI executed `Bash(find /home/benjamin/.config/.claude -name "README.md" | sort)`
- AI executed `Bash(cat > /tmp/directory_analysis.sh << 'EOF'...)`

**Expected**: Task tool invocations to research-specialist agents
**Actual**: Direct bash command execution (orchestrator doing research work itself)

### Root Cause Location
File: `/home/benjamin/.config/.claude/commands/supervise.md`
Lines: 1050-1072

```markdown
1050: **EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.
1051:
1052: Task {
1053:   subagent_type: "general-purpose"
1054:   description: "Research ${TOPIC_NAME} with mandatory file creation"
1055:   prompt: "
1056:     Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md
1057:     ...
1069:   "
1070: }
1071:
1072: **Note**: The actual implementation will generate N Task calls based on RESEARCH_COMPLEXITY.
```

### Anti-Pattern Identification

**Pattern Name**: Undermined Imperative Pattern

**Characteristics**:
1. Line 1050: Contains imperative directive `**EXECUTE NOW**: USE the Task tool`
2. Lines 1052-1070: Contains YAML-style Task block (hybrid pattern - acceptable in isolation)
3. **Line 1072: Contains disclaimer** "**Note**: The actual implementation will generate N Task calls"

**Why This Fails**:
- The imperative on line 1050 says "DO THIS NOW"
- The note on line 1072 says "this is a TEMPLATE showing what the implementation SHOULD generate"
- The AI interprets this as: "The command is showing me an example of what I should eventually do, but not instructing me to do it right now"
- Result: AI treats the Task block as documentation rather than an executable instruction

### Validation Script Results

Running `/home/benjamin/.config/.claude/lib/validate-agent-invocation-pattern.sh`:

```
[Check 1] Detecting YAML-style Task blocks...
  ✓ No YAML-style Task blocks found (documentation examples OK)
```

**Why validation passed**: The script detected the imperative directive on line 1050 and classified this as the acceptable "hybrid pattern" (imperative + YAML syntax). However, the script does NOT detect undermining disclaimers like line 1072.

**Gap in validation**: The script should detect notes/comments that undermine imperative directives by suggesting the block is a template.

## Correct Pattern Comparison

### `/research` Command (WORKING)
File: `/home/benjamin/.config/.claude/commands/research.md`

```markdown
**EXECUTE NOW**: USE the Task tool for each subtopic with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert actual subtopic name] with mandatory artifact creation"
- timeout: 300000  # 5 minutes per research agent
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md
    ...
```

**Key Differences**:
1. Uses bullet-point syntax (not YAML-style curly braces)
2. No disclaimer undermining the imperative
3. Uses placeholder syntax `[insert actual subtopic name]` to signal parameters should be substituted
4. No "Note:" comments suggesting this is documentation

**Result**: >90% agent delegation rate (verified in Spec 497)

### Why Bullet-Point Pattern Works Better

1. **Visual clarity**: Bullet points clearly indicate parameters to be filled in
2. **No ambiguity**: Lacks curly braces that could be interpreted as code block syntax
3. **Direct imperative**: Instruction flows directly from imperative to parameters
4. **No undermining**: No disclaimers suggesting this is documentation

## Historical Context

From CLAUDE.md metadata, this same anti-pattern was discovered and fixed in:

**Spec 438** (2025-10-24): `/supervise` original fix
- Fixed 7 YAML blocks wrapped in markdown code fences
- Result: 0% → >90% delegation rate

**Spec 495** (2025-10-27): `/coordinate` and `/research` fixes
- Fixed 9 invocations in `/coordinate`, 3 in `/research`
- Result: 0% → >90% delegation rate, 100% file creation reliability

**Spec 497** (2025-10-27): Unified improvements across all orchestration commands
- Established Standard 11 (Imperative Agent Invocation Pattern)
- Created validation script
- Result: >90% delegation rate across `/orchestrate`, `/coordinate`, `/supervise`, `/research`

## Current Regression

**When regression occurred**: Between Spec 497 completion and 2025-10-27 18:00

**Likely cause**: Manual edit to `/supervise` that re-introduced the undermined imperative pattern.

**Evidence**: The file passes validation (line 1050 has imperative), but the disclaimer on line 1072 was either:
1. Added after validation was run
2. Not detected by validation script (gap in validation logic)

## Detailed Failure Mechanism

### Step-by-Step AI Processing

1. **AI reads line 1050**: "**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent."
   - AI notes: "I should invoke a Task tool"

2. **AI reads lines 1052-1070**: Task block with YAML-style syntax
   - AI notes: "Here's the structure of the Task invocation"

3. **AI reads line 1072**: "**Note**: The actual implementation will generate N Task calls based on RESEARCH_COMPLEXITY."
   - AI interprets: "This Task block is a TEMPLATE. I'm expected to generate similar calls later, not execute this one now"
   - AI decision: "I should proceed with the workflow and generate these Task calls when appropriate"

4. **AI continues to next bash block** (lines 1074-1078):
   ```bash
   # Emit progress marker after agent invocations complete
   emit_progress "1" "All research agents invoked - awaiting completion"
   ```
   - AI interprets: "This bash block is for AFTER agent invocations, so I must have missed where I'm supposed to invoke them"
   - AI decision: "I'll execute the workflow directly using my own tools instead of delegating"

5. **Result**: AI uses Read/Grep/Bash tools directly instead of Task tool

### Psychological Factor: Template Assumption

The phrase "The actual implementation will generate N Task calls" creates a mental model where:
- "Implementation" = some future execution phase or code generator
- "Will generate" = future tense, not imperative present
- "N Task calls" = multiple calls should be created programmatically

This mental model is incompatible with "execute this single Task invocation right now."

## Fix Requirements

### Immediate Fix (Lines 1050-1072)

**Option 1: Remove Disclaimer** (simplest)
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

For EACH topic (1 to $RESEARCH_COMPLEXITY), invoke with these parameters:

- subagent_type: "general-purpose"
- description: "Research [topic_name] with mandatory file creation"
- timeout: 300000
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Report Path: ${REPORT_PATHS[i]} (absolute path, pre-calculated by orchestrator)
    ...
```

**Option 2: Strengthen Imperative** (more explicit)
```markdown
**EXECUTE NOW - Invoke $RESEARCH_COMPLEXITY Research Agents in Parallel**

YOU MUST invoke the Task tool $RESEARCH_COMPLEXITY times (once per topic) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [topic_name] with mandatory file creation"
- timeout: 300000
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md
    ...

**CRITICAL**: All Task invocations must occur in a SINGLE MESSAGE for parallel execution.
```

**Option 3: Use Proven `/research` Pattern** (most reliable)
```markdown
**EXECUTE NOW**: USE the Task tool for each research topic with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert research topic name] with mandatory artifact creation"
- timeout: 300000
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert topic from WORKFLOW_DESCRIPTION]
    - Report Path: [insert absolute path from REPORT_PATHS array]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: [insert RESEARCH_COMPLEXITY value]

    **CRITICAL**: Before writing report file, ensure parent directory exists:
    Use Bash tool: mkdir -p "$(dirname "[insert report path]")"

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [insert report path]
```

### Validation Script Enhancement

Add check for undermining disclaimers:

```bash
# Check 6: Detect undermining disclaimers after imperative directives
echo "[Check 6] Detecting undermining disclaimers..."

# Find all "**EXECUTE NOW**" lines
EXEC_NOW_LINES=$(grep -n "\*\*EXECUTE NOW\*\*" "$COMMAND_FILE" | cut -d: -f1)

for line in $EXEC_NOW_LINES; do
  # Check next 25 lines for undermining phrases
  CONTEXT=$(sed -n "$line,$((line + 25))p" "$COMMAND_FILE")

  if echo "$CONTEXT" | grep -q -E "(\*\*Note\*\*:.*will generate|\*\*Note\*\*:.*should generate|actual implementation|template|example only)"; then
    echo "  ❌ VIOLATION: Undermining disclaimer found after EXECUTE NOW"
    echo "     Line $line: EXECUTE NOW directive undermined by template language"
    VIOLATIONS_FOUND=1
  fi
done
```

## Recommendations

### Priority 1: Immediate Fix
1. Replace lines 1050-1072 in `/supervise` with Option 3 (proven `/research` pattern)
2. Remove all undermining disclaimers throughout the file
3. Re-run validation script to confirm

### Priority 2: Validation Enhancement
1. Add Check 6 to validation script (detect undermining disclaimers)
2. Run enhanced validation on all orchestration commands
3. Create pre-commit hook to prevent future regressions

### Priority 3: Documentation
1. Add "Undermined Imperative Pattern" to anti-pattern documentation
2. Update Command Development Guide with clear examples
3. Add to troubleshooting guide: "If agents aren't being invoked, check for template disclaimers"

## Related Specifications

- **Spec 438**: Original `/supervise` agent delegation fix
- **Spec 495**: `/coordinate` and `/research` agent delegation fixes
- **Spec 497**: Unified improvements across orchestration commands
- **Spec 057**: `/supervise` robustness improvements (bootstrap fallback removal)

## Cross-References

- [Command Architecture Standards](.claude/docs/reference/command_architecture_standards.md#standard-11)
- [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md#anti-pattern-documentation)
- [Orchestration Troubleshooting Guide](.claude/docs/guides/orchestration-troubleshooting.md)
- [Validation Script](../../lib/validate-agent-invocation-pattern.sh)

## Appendix: Full Failure Timeline

| Time | Event | Status |
|------|-------|--------|
| 2025-10-24 | Spec 438 completed | `/supervise` fixed, >90% delegation |
| 2025-10-27 13:00 | Spec 497 completed | All orchestration commands verified |
| 2025-10-27 ~16:00 | Manual edit to `/supervise` | Regression introduced (lines 1050-1072) |
| 2025-10-27 17:05 | User runs `/supervise` | Command fails to invoke research agents |
| 2025-10-27 18:14 | `/research` invoked for diagnosis | Root cause identified |

## Conclusion

The `/supervise` command's failure to invoke research subagents is caused by an **undermined imperative pattern** where line 1072's disclaimer ("**Note**: The actual implementation will generate N Task calls") contradicts the imperative directive on line 1050. This creates ambiguity that causes the AI to interpret the Task block as documentation rather than an executable instruction.

**Fix**: Replace with proven `/research` command's bullet-point pattern that lacks template disclaimers and uses clear placeholder syntax.

**Prevention**: Enhance validation script to detect undermining disclaimers after imperative directives.
