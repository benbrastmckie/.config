# Orchestration Commands Quick Reference

One-page reference for all orchestration commands, common patterns, troubleshooting, and validation.

## Commands Overview

| Command | Purpose | Phases | Delegation Rate | Use Case |
|---------|---------|--------|-----------------|----------|
| `/orchestrate` | Full-featured workflow | 7 | >90% | Complex multi-phase projects with PR automation |
| `/coordinate` | Wave-based parallel | 7 | >90% | Fast parallel implementation (40-60% time savings) |
| `/research` | Hierarchical research | 4 | >90% | Deep topic investigation with automatic decomposition |
| `/supervise` | Sequential workflow | 7 | >90% | Step-by-step orchestration with proven compliance |

**Common Features**:
- Parallel research (2-4 agents)
- Automated complexity evaluation
- Conditional debugging
- <30% context usage
- 100% file creation reliability

## Quick Start

### Basic Usage

```bash
# Research a topic
/research "API authentication patterns and best practices"

# Coordinate full workflow
/coordinate "implement OAuth 2.0 authentication"

# Supervise step-by-step
/supervise "research and plan user authentication system"

# Full orchestration with PR
/orchestrate "add JWT authentication to API"
```

### Common Options

```bash
# Dry run (validate without execution)
/coordinate "test workflow" --dry-run

# Specify output location
/research "topic" --output-dir specs/custom_location

# Resume from checkpoint
/coordinate "workflow" --resume

# Create PR after completion
/orchestrate "feature" --create-pr
```

## Workflow Phases

All orchestration commands follow this 7-phase structure:

```
Phase 0: Location Detection
  ↓
Phase 1: Research (2-4 parallel agents)
  ↓
Phase 2: Planning (complexity evaluation)
  ↓
Phase 3: Implementation (wave-based parallel)
  ↓
Phase 4: Testing (per Testing Protocols)
  ↓
Phase 5: Debugging (conditional, if tests fail)
  ↓
Phase 6: Documentation (summary + cross-references)
```

## Agent Invocation Pattern

### Correct Pattern (Imperative)

```markdown
**EXECUTE NOW**: USE the Bash tool to calculate paths:

```bash
source .claude/lib/core/unified-location-detection.sh
topic_dir=$(create_topic_structure "topic_name")
report_path="$topic_dir/reports/001_subtopic.md"
echo "REPORT_PATH: $report_path"
```

**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "Research authentication patterns"
- prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Research topic: Authentication patterns for REST APIs
    Output file: [insert $report_path from above]

**MANDATORY VERIFICATION**: After agent returns:

```bash
ls -la "$report_path"
[ -f "$report_path" ] || echo "ERROR: File missing"
```

**WAIT FOR**: Agent to return REPORT_CREATED: $report_path
```

### Anti-Pattern (Documentation-Only)

```markdown
❌ INCORRECT - Do not use this pattern:

The research phase invokes agents:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC}"
  prompt: "..."
}
```
```

**Problem**: Code fence wrapper prevents execution (0% delegation rate).

## Troubleshooting Quick Checks

### 1. Command Starts?

```bash
/command-name "test" 2>&1 | head -20
```

**Look for**: Library sourcing errors, function verification failures

**Fix**: Check `.claude/lib/` exists, verify SCRIPT_DIR

### 2. Agents Delegating?

```bash
/command-name "test" 2>&1 | grep "PROGRESS:"
```

**Look for**: PROGRESS: markers (indicates agent execution)

**Fix**: Run `.claude/lib/util/validate-agent-invocation-pattern.sh`

### 3. Files Created?

```bash
find .claude/specs -name "*.md" -mmin -5
ls .claude/TODO*.md 2>/dev/null
```

**Look for**: Files in `specs/NNN_topic/`, NO TODO files

**Fix**: Add MANDATORY VERIFICATION checkpoints

### 4. Validation Passing?

```bash
./.claude/tests/test_orchestration_commands.sh
```

**Look for**: All 12 tests passing (0 failures)

**Fix**: See error messages for specific issues

## Common Problems & Solutions

### Problem: 0% Delegation Rate

**Symptoms**:
- No PROGRESS: markers
- Output in TODO1.md files
- No reports created

**Diagnosis**:
```bash
./.claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/command-name.md
```

**Solution**: Remove code fences around Task invocations, add `**EXECUTE NOW**` directives

**Details**: See [Orchestration Troubleshooting Guide](../guides/orchestration-troubleshooting.md#section-2-agent-delegation-issues)

### Problem: Bootstrap Failure

**Symptoms**:
- Command exits immediately
- "Failed to source" errors

**Diagnosis**:
```bash
ls -la .claude/lib/
source .claude/lib/library-name.sh
```

**Solution**: Verify library files exist and are readable

**Details**: See [Orchestration Troubleshooting Guide](../guides/orchestration-troubleshooting.md#section-1-bootstrap-failures)

### Problem: Files Wrong Location

**Symptoms**:
- Reports in TODO files
- Missing topic number prefix

**Diagnosis**:
```bash
find . -name "*.md" -mmin -10 -ls
```

**Solution**: Pre-calculate paths, inject into agent prompts

**Details**: See [Orchestration Troubleshooting Guide](../guides/orchestration-troubleshooting.md#section-3-file-creation-problems)

### Problem: Silent Failures

**Symptoms**:
- Command completes but files missing
- No error messages

**Diagnosis**:
```bash
grep -i "error\|warning" [command output]
```

**Solution**: Remove bootstrap fallbacks, add fail-fast error handling

**Details**: See [Orchestration Troubleshooting Guide](../guides/orchestration-troubleshooting.md#section-4-error-handling)

## Validation Commands

### Quick Validation

```bash
# Validate specific command
./.claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/command-name.md

# Run full test suite
./.claude/tests/test_orchestration_commands.sh

# Check delegation rate manually
/command-name "test" 2>&1 | tee output.log
grep -c "PROGRESS:" output.log
grep -c "USE the Task tool" .claude/commands/command-name.md
# Delegation rate = PROGRESS / invocation count (target: >90%)
```

### Integration Testing

```bash
# Test each command
/coordinate "research authentication patterns"
/research "API security best practices"
/supervise "plan authentication implementation"

# Verify file locations
ls -la .claude/specs/*/reports/
ls -la .claude/specs/*/plans/

# Verify no TODO files
ls .claude/TODO*.md  # Should fail with "No such file"
```

## File Locations

### Artifacts Created

```
.claude/specs/NNN_topic/
├── reports/
│   ├── 001_subtopic1.md
│   ├── 002_subtopic2.md
│   └── OVERVIEW.md (research synthesis)
├── plans/
│   └── 001_implementation_plan.md
├── summaries/
│   └── 001_implementation_summary.md
└── debug/
    └── 001_debug_report.md (if needed)
```

### Utility Libraries

```
.claude/lib/
├── unified-location-detection.sh    (topic directory creation)
├── metadata-extraction.sh           (report/plan metadata)
├── checkpoint-utils.sh              (state persistence)
├── workflow-detection.sh            (scope detection)
├── error-handling.sh                (fail-fast utilities)
└── context-pruning.sh               (context management)
```

### Agent Files

```
.claude/agents/
├── research-specialist.md           (research subtopics)
├── research-synthesizer.md          (aggregate findings)
├── plan-architect.md                (create plans)
├── implementer-coordinator.md       (implementation)
├── test-specialist.md               (run tests)
├── debug-analyst.md                 (investigate failures)
├── code-writer.md                   (write code)
└── doc-writer.md                    (documentation)
```

## Performance Metrics

### Expected Metrics (Spec 497)

| Metric | Before Fixes | After Fixes | Improvement |
|--------|-------------|-------------|-------------|
| Agent delegation rate | 0-70% | >90% | +30-90% |
| File creation reliability | 70% | 100% | +30% |
| Bootstrap reliability | Variable | 100% | Consistent |
| Context usage | 80-100% | <30% | -50-70% |
| Parallel execution | Disabled | 40-60% savings | Enabled |

### Verification Checklist

After running any orchestration command, verify:

- [ ] PROGRESS: markers visible in output
- [ ] Files created in `.claude/specs/NNN_topic/` directories
- [ ] NO TODO*.md files created
- [ ] Agent return signals visible (REPORT_CREATED:, PLAN_CREATED:)
- [ ] Error messages include diagnostic commands
- [ ] Tests passing (if implementation phase)
- [ ] Validation script passes: `.claude/lib/util/validate-agent-invocation-pattern.sh`

## Emergency Procedures

### Rollback Command Changes

```bash
# List backups
ls -la .claude/commands/*.backup-*

# Compare current with backup
diff .claude/commands/coordinate.md \
     .claude/commands/coordinate.md.backup-20251027_144342

# Restore backup
cp .claude/commands/coordinate.md.backup-20251027_144342 \
   .claude/commands/coordinate.md

# Verify rollback
./.claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
```

### Fix Immediate Issues

```bash
# Bootstrap failure: Check libraries
ls -la .claude/lib/

# Delegation failure: Validate patterns
./.claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/[command].md

# File creation failure: Check verification checkpoints
grep -n "MANDATORY VERIFICATION" .claude/commands/[command].md

# Run full diagnostics
./.claude/tests/test_orchestration_commands.sh
```

## Standards Compliance

All orchestration commands must comply with:

**Standard 11** (Imperative Agent Invocation):
- Imperative instructions (`**EXECUTE NOW**`)
- No code block wrappers around Task invocations
- Agent behavioral file references (`.claude/agents/*.md`)
- Explicit completion signals

**Standard 0** (Execution Enforcement):
- Mandatory verification checkpoints
- Fail-fast error handling
- Diagnostic commands in all errors

**See**: [Command Architecture Standards](./command_architecture_standards.md)

## Key References

### Documentation
- [Orchestration Troubleshooting Guide](../guides/orchestration-troubleshooting.md) - Complete diagnostic procedures
- [Command Development Guide](../guides/command-development-guide.md) - Creating commands
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Agent invocation patterns
- [Command Architecture Standards](./command_architecture_standards.md) - All standards

### Utilities
- Validation: `.claude/lib/util/validate-agent-invocation-pattern.sh`
- Testing: `.claude/tests/test_orchestration_commands.sh`
- Backup: `.claude/lib/util/backup-command-file.sh`
- Rollback: `.claude/lib/util/rollback-command-file.sh`

### Case Studies
- Spec 438: `/supervise` agent delegation fix
- Spec 495: `/coordinate` and `/research` fixes
- Spec 057: `/supervise` robustness improvements
- Spec 497: Unified improvements (this implementation)

## Tips & Best Practices

1. **Always validate before committing**: Run `.claude/lib/util/validate-agent-invocation-pattern.sh`
2. **Test after changes**: Run `.claude/tests/test_orchestration_commands.sh`
3. **Verify file locations**: Check `specs/NNN_topic/` directories
4. **Monitor delegation rate**: Look for PROGRESS: markers
5. **Use fail-fast errors**: Remove bootstrap fallbacks
6. **Add verification checkpoints**: Ensure 100% file creation
7. **Reference behavioral files**: Don't duplicate agent guidelines
8. **Pre-calculate paths**: Use Bash tool before agent invocation
9. **Use imperative language**: `MUST`, `EXECUTE NOW`, `MANDATORY`
10. **Test from different directories**: Commands should work from anywhere

---

**Last Updated**: 2025-10-27 (Spec 497)
**Verification Status**: All 12 tests passing, >90% delegation rate, 100% file creation reliability
