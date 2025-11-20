# Architecture Standards: Testing and Validation

**Related Documents**:
- [Overview](overview.md) - Standards index and fundamentals
- [Validation](validation.md) - Execution enforcement patterns
- [Error Handling](error-handling.md) - Library sourcing, return codes

---

## Testing Standards

### Validation Criteria

Before committing changes to command or agent files:

#### Test 1: Execution Without External Files

Temporarily move `.claude/commands/shared/` and `.claude/templates/` to backup location:
```bash
mv .claude/commands/shared .claude/commands/shared.backup
mv .claude/templates .claude/templates.backup
```

Execute the command:
```bash
# Test each command
/orchestrate "Simple test feature"
/implement specs/plans/test_plan.md
/revise "Update test" specs/plans/test_plan.md
/setup
```

**PASS**: Command completes successfully
**FAIL**: Command cannot find necessary information

Restore directories:
```bash
mv .claude/commands/shared.backup .claude/commands/shared
mv .claude/templates.backup .claude/templates
```

#### Test 2: Critical Pattern Presence

For each command file, verify presence of:
```bash
# Search for critical patterns
grep -c "Step [0-9]:" .claude/commands/commandname.md  # Should be >=5
grep -c "CRITICAL:" .claude/commands/commandname.md    # Should match expected count
grep -c "```bash" .claude/commands/commandname.md      # Should be >=3
grep -c "```yaml" .claude/commands/commandname.md      # Should be >=2
grep -c "Task {" .claude/commands/commandname.md       # Should be >=1 if uses agents
```

#### Test 3: Template Completeness

Extract all templates and verify they are complete:
```bash
# Find all Task invocations
grep -A 20 "Task {" .claude/commands/commandname.md

# Verify each has:
# - subagent_type
# - description
# - prompt with complete instructions
# - No [See...] references in prompt body
```

#### Test 4: Reference Pattern Validation

Check that external references follow correct pattern:
```bash
# Find all external references
grep -n "**See**:" .claude/commands/commandname.md

# For each reference:
# - Verify inline instructions appear BEFORE the reference
# - Reference should supplement, not replace
# - Section should be executable without following the reference
```

---

## Review Checklist

Use this checklist when reviewing pull requests that modify command or agent files:

### Command File Changes

- [ ] **Execution Enforcement**: Are critical steps marked with "EXECUTE NOW", "YOU MUST", or "MANDATORY"?
- [ ] **Verification Checkpoints**: Are verification steps explicit with "if [ ! -f ]" checks?
- [ ] **Fallback Mechanisms**: Do agent-dependent operations include fallback creation?
- [ ] **Agent Template Enforcement**: Are agent prompts marked "THIS EXACT TEMPLATE (No modifications)"?
- [ ] **Checkpoint Reporting**: Do major steps include explicit completion reporting?
- [ ] **Execution Steps**: Are numbered steps still present and complete?
- [ ] **Tool Examples**: Are tool invocation examples still inline and copy-paste ready?
- [ ] **Critical Warnings**: Are CRITICAL/IMPORTANT/NEVER statements still present?
- [ ] **Templates**: Are agent prompts, JSON schemas, bash scripts complete (not truncated)?
- [ ] **Decision Logic**: Are conditions, thresholds, and branches specific?
- [ ] **Error Handling**: Are recovery procedures specific with actions?
- [ ] **References**: Do external references supplement (not replace) inline instructions?
- [ ] **File Size**: Is file size >300 lines? (Flag if <300)
- [ ] **Bash Block Size**: Are bash blocks <300 lines each? (Split if >300, transform errors at ~400)
- [ ] **Annotations**: Are structural annotations present ([EXECUTION-CRITICAL], etc.)?
- [ ] **Testing**: Has the command been executed successfully after changes?

### Agent File Changes (Standard 0.5)

**Subagent Prompt Enforcement**:
- [ ] **Imperative Language**: All critical steps use "YOU MUST", "EXECUTE NOW", "ABSOLUTE REQUIREMENT"?
- [ ] **Role Declaration**: Uses "YOU MUST perform" instead of "I am a specialized agent"?
- [ ] **Sequential Dependencies**: Steps marked "STEP N (REQUIRED BEFORE STEP N+1)"?
- [ ] **File Creation Priority**: File creation marked as "PRIMARY OBLIGATION" or "ABSOLUTE REQUIREMENT"?
- [ ] **Verification Checkpoints**: "MANDATORY VERIFICATION" blocks present after critical operations?
- [ ] **Template Enforcement**: Output formats marked "THIS EXACT TEMPLATE (No modifications)"?
- [ ] **Passive Voice Elimination**: Zero "should/may/can" in critical sections, all use "MUST/WILL/SHALL"?
- [ ] **Completion Criteria**: Explicit checklist with "ALL REQUIRED" marker present?
- [ ] **Why This Matters Context**: Enforcement rationale provided for critical operations?
- [ ] **Checkpoint Reporting**: "CHECKPOINT REQUIREMENT" blocks present at major milestones?
- [ ] **Fallback Integration**: Compatible with command-level fallback mechanisms?

**Quality Scoring**: Does the agent file score 95+/100 on the enforcement rubric (9.5+ categories at full strength)?

### Reference File Changes

- [ ] **Supplemental**: Does content supplement command files (not replace)?
- [ ] **Independence**: Can command files execute without reading this reference?
- [ ] **Organization**: Is content organized by topic with clear headings?
- [ ] **Links**: Are links back to command files present and accurate?
- [ ] **Examples**: Are extended examples genuinely additional (not the only examples)?

### Refactoring Changes

- [ ] **Extraction Justification**: Is extracted content truly supplemental?
- [ ] **Inline Retention**: Do command files still have enough detail to execute?
- [ ] **Reference Pattern**: Do references follow "inline first, reference after" pattern?
- [ ] **Test Results**: Have all testing standards tests passed?
- [ ] **Validation**: Can commands execute with shared/ directory temporarily removed?

---

## Enforcement

### Pre-Commit Validation

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Validate command file integrity

for cmd in .claude/commands/*.md; do
  # Skip if not modified in this commit
  git diff --cached --name-only | grep -q "$cmd" || continue

  # Check line count (minimum 300 lines for main commands)
  LINES=$(wc -l < "$cmd")
  if [ "$LINES" -lt 300 ] && [[ "$cmd" =~ (orchestrate|implement|revise|setup).md ]]; then
    echo "ERROR: $cmd has only $LINES lines (minimum 300 for main commands)"
    echo "This suggests execution details have been over-extracted."
    exit 1
  fi

  # Check for critical patterns
  STEPS=$(grep -c "Step [0-9]:" "$cmd")
  if [ "$STEPS" -lt 3 ]; then
    echo "WARNING: $cmd has only $STEPS numbered steps (expected >=3)"
  fi

  # Check for complete Task examples
  TASKS=$(grep -c "Task {" "$cmd")
  COMPLETE_TASKS=$(grep -A 10 "Task {" "$cmd" | grep -c "prompt: |")
  if [ "$TASKS" -gt 0 ] && [ "$COMPLETE_TASKS" -lt "$TASKS" ]; then
    echo "ERROR: $cmd has incomplete Task invocation templates"
    exit 1
  fi
done

echo "Command file validation passed"
```

### Continuous Integration

Add to CI pipeline:
```bash
# Test command execution (basic smoke tests)
.claude/tests/test_command_execution.sh

# Validate command file structure
.claude/tests/test_command_structure.sh

# Check for anti-patterns
.claude/tests/test_command_antipatterns.sh
```

---

## Refactoring Guidelines

### When to Extract Content

**Safe to Extract** (Move to reference files):
1. **Extended Background**: Historical context, design rationale
2. **Alternative Approaches**: Other ways to solve similar problems
3. **Additional Examples**: Beyond the 1-2 core examples needed inline
4. **Troubleshooting Guides**: Edge case handling and debugging tips
5. **Deep Dives**: Detailed explanations of algorithms or patterns
6. **Related Reading**: Links to external documentation or research

**Never Extract** (Must stay inline):
1. **Step-by-step execution procedures**: The core workflow
2. **Tool invocation patterns**: Task, Bash, Read, Write, Edit examples
3. **Decision flowcharts**: If/then logic with specific conditions
4. **Critical warnings**: CRITICAL, IMPORTANT, NEVER, ALWAYS statements
5. **Template structures**: Complete agent prompts, JSON schemas, bash scripts
6. **Error recovery procedures**: Specific actions for each error type
7. **Parameter specifications**: Required/optional parameters with types
8. **Parsing patterns**: Regex patterns, jq queries, grep commands

### Correct Refactoring Process

**Before Refactoring**:
1. Identify duplicated content across command files
2. Classify each duplicated section using "Safe to Extract" vs "Never Extract" lists
3. For "Safe to Extract" content: Move to reference files
4. For "Never Extract" content: Keep inline but consider standardizing format

**After Refactoring**:
1. Test each command by executing it
2. Verify Claude can complete tasks without reading external files
3. Check that all critical patterns are still visible
4. Validate that execution flow is clear from command file alone

**Refactoring Checklist**:
- [ ] Execution steps remain inline and numbered
- [ ] Tool invocation examples are complete (not truncated)
- [ ] Critical warnings still present in command file
- [ ] Templates are copy-paste ready (not referencing external files)
- [ ] Decision logic includes all conditions and thresholds
- [ ] Error recovery procedures include specific actions
- [ ] Command can be executed by reading only the command file
- [ ] External references provide supplemental context only
- [ ] File size reduction is secondary to execution clarity

---

## Agent File Standards

Agent definition files follow similar principles to command files:

**REQUIRED Inline Content**:
- Agent role and purpose
- Tool restrictions and allowed tools list
- Behavioral constraints and guidelines
- Output format specifications
- Success criteria and completion markers
- Error handling procedures
- Examples of agent task patterns

**Reference Pattern for Agents**:
```markdown
## Research Specialist Agent

### Role
You are a specialized research agent focused on analyzing codebases and gathering implementation guidance.

### Allowed Tools
- Read, Grep, Glob: For codebase analysis
- WebSearch, WebFetch: For best practices research
- Write: For creating research reports

### Behavioral Guidelines

**Research Process**:
1. **Analyze Context**: Review research topic and current codebase
2. **Gather Information**: Search codebase and external sources
3. **Synthesize Findings**: Organize into structured report
4. **Validate Completeness**: Ensure all research questions answered

**Output Format**:
Create research report with these sections:
- ## Overview: 2-3 sentence summary
- ## Current State: Analysis of existing implementation
- ## Best Practices: Industry standards for 2025
- ## Recommendations: Specific implementation guidance
- ## References: Sources and links

**Quality Criteria**:
- Actionable: Recommendations must be specific and implementable
- Contextual: Consider existing codebase patterns
- Current: Use 2025 best practices, not outdated patterns
- Comprehensive: Cover all aspects of research topic

**For Extended Research Methodologies**: See [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) for advanced techniques.
```

---

## Examples from Codebase

### Good Example: Current `/implement` Plan Hierarchy Update

**Location**: `.claude/commands/implement.md` lines 184-269

This section demonstrates correct inline content:
- Complete Task invocation template with full agent prompt
- Step-by-step update workflow
- Error handling procedures
- Checkpoint state structure
- All hierarchy levels documented

### Bad Example: Broken `/orchestrate` Research Phase

**Location**: `.claude/commands/orchestrate.md` lines 414-436 (after commit 40b9146)

This section demonstrates incorrect reference-only pattern:
- Only high-level bullet points
- "See shared/workflow-phases.md for comprehensive details"
- Missing complexity score calculation formula
- Missing parallel agent invocation pattern
- Missing CRITICAL warning about single message
- Cannot execute without reading external file

---

## Related Documentation

- [Architecture Standards Overview](overview.md)
- [Validation Standards](validation.md)
- [Error Handling](error-handling.md)
- [Dependencies](dependencies.md)
- [Integration Patterns](integration.md)
