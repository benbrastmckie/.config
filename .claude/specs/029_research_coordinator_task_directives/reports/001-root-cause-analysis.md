# Research Coordinator Failure Root Cause Analysis

## Metadata
- **Date**: 2025-12-08
- **Agent**: primary-agent (manual analysis)
- **Topic**: research-coordinator agent failure to invoke research-specialist
- **Report Type**: root cause analysis

## Executive Summary

The research-coordinator agent fails to invoke research-specialist sub-agents because STEP 3 contains **documentation examples** wrapped in code fences rather than **executable imperative directives**. The agent understands conceptually what it should do but has no concrete instruction to execute.

## Findings

### Finding 1: Documentation vs Executable Code Pattern
- **Description**: research-coordinator.md STEP 3 contains Task invocation examples wrapped in markdown code fences (` ```markdown `), making them documentation patterns instead of executable instructions
- **Location**: /home/benjamin/.config/.claude/agents/research-coordinator.md:207-307
- **Evidence**: The example text begins with "**Example Parallel Invocation** (3 topics):" followed by code fences
- **Impact**: Agent reads examples as documentation, not as instructions to execute

### Finding 2: Missing Imperative Directive Pattern
- **Description**: STEP 3 uses descriptive language ("prepare Task invocations", "use parallel pattern") instead of imperative directives like "**EXECUTE NOW**: USE the Task tool..."
- **Location**: /home/benjamin/.config/.claude/agents/research-coordinator.md:198-206
- **Evidence**: "**Actions**: 1. **Prepare Task Invocations**: For each topic, prepare a Task tool invocation"
- **Impact**: Agent has no concrete instruction to trigger Task tool usage

### Finding 3: Template Pattern Propagation
- **Description**: The coordinator-template.md contains the same documentation pattern, which was replicated into research-coordinator.md
- **Location**: /home/benjamin/.config/.claude/agents/templates/coordinator-template.md:187-230
- **Evidence**: Template shows "Example Parallel Invocation" with code fences
- **Impact**: All coordinators derived from template inherit this non-executable pattern

### Finding 4: Hard Barrier Works Correctly
- **Description**: The hard barrier validation in create-plan correctly detects when reports aren't created
- **Location**: /home/benjamin/.config/.claude/commands/create-plan.md Block 1f
- **Evidence**: Error output shows "HARD BARRIER FAILED - Report validation failed"
- **Impact**: The validation layer functions correctly; the issue is in agent behavior

## Recommendations

1. **Rewrite STEP 3 with Imperative Directives**: Replace documentation examples with actual `**EXECUTE NOW**: USE the Task tool...` patterns that Claude recognizes as executable instructions

2. **Use Dynamic Task Generation**: Instead of static examples, STEP 3 should instruct the agent to dynamically generate Task invocations for each topic in the TOPICS array

3. **Update Coordinator Template**: Fix coordinator-template.md to use imperative patterns so future coordinators work correctly

4. **Add Self-Validation in Coordinator**: Add a checkpoint in STEP 3 that verifies Task tool was actually used before proceeding to STEP 4

## References

- /home/benjamin/.config/.claude/agents/research-coordinator.md (lines 198-307)
- /home/benjamin/.config/.claude/agents/templates/coordinator-template.md (lines 187-230)
- /home/benjamin/.config/.claude/commands/create-plan.md (Blocks 1e-exec, 1f)
- /home/benjamin/.config/.claude/output/create-plan-output.md (error trace)
