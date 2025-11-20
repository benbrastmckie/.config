# Model Rollback Guide

## Overview

This guide documents the procedure for rolling back agent model migrations when quality regressions or errors exceed acceptable thresholds. Model rollbacks are designed to be fast, safe, and reversible single-line changes to agent frontmatter.

## When to Rollback

### Automatic Rollback Triggers

Rollback MUST be initiated if any of these conditions are met:

1. **Error Rate Increase >5%**
   - Any agent shows >5% increase in invocation error rate
   - Measured over minimum 20 invocations
   - Compared against baseline metrics in `.claude/data/model_optimization_baseline.json`

2. **Quality Regressions in Automated Checks**
   - Commit message format validation <95% pass rate
   - Cross-reference link validity <100% (any broken links)
   - Conversion fidelity <90% similarity to baseline
   - Wave coordination accuracy <100% (any checkpoint errors)
   - Debugging root cause accuracy <85%

3. **User-Reported Quality Issues**
   - >3 user-reported quality issues per week for any single agent
   - Examples: malformed commit messages, broken cross-references, corrupted conversions

4. **Critical Failures**
   - File corruption or data loss
   - Broken workflows that prevent task completion
   - Systematic errors affecting multiple invocations

### Manual Rollback Decision

Rollback MAY be initiated for:
- Suspected quality degradation not yet meeting thresholds
- Risk mitigation during critical project phases
- Stakeholder concerns about agent behavior changes

## Rollback Process

### Step 1: Identify Affected Agent(s)

Determine which agents require rollback:

```bash
# Check recent error logs
grep "ERROR" .claude/data/logs/adaptive-planning.log | tail -20

# Review agent invocation metrics
cat .claude/data/model_optimization_phase*_results.md

# Identify failing agents
FAILING_AGENTS=("git-commit-helper" "spec-updater")  # Example
```

### Step 2: Backup Current State

Before rollback, capture current metrics for analysis:

```bash
# Create rollback report
ROLLBACK_DIR=".claude/data/rollbacks/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ROLLBACK_DIR"

# Copy current agent files
for agent in "${FAILING_AGENTS[@]}"; do
  cp ".claude/agents/${agent}.md" "$ROLLBACK_DIR/${agent}_post_migration.md"
done

# Copy metrics
cp .claude/data/model_optimization_*.json "$ROLLBACK_DIR/" 2>/dev/null
cp .claude/data/model_optimization_phase*.md "$ROLLBACK_DIR/" 2>/dev/null

# Document rollback reason
cat > "$ROLLBACK_DIR/ROLLBACK_REASON.md" << EOF
# Rollback Report

## Date
$(date +%Y-%m-%d\ %H:%M:%S)

## Affected Agents
${FAILING_AGENTS[@]}

## Trigger Condition
[Describe what triggered the rollback]

## Metrics at Rollback
[Include relevant error rates, quality metrics]

## Next Steps
[What analysis or fixes are needed before retry]
EOF
```

### Step 3: Revert Model Field

For each affected agent, revert the model field to baseline:

**Haiku → Sonnet Rollback** (5 agents):
```bash
AGENTS_TO_ROLLBACK=("git-commit-helper" "spec-updater" "doc-converter" "implementer-coordinator" "plan-expander")

for agent in "${AGENTS_TO_ROLLBACK[@]}"; do
  AGENT_FILE=".claude/agents/${agent}.md"

  echo "Rolling back $agent..."

  # Revert line 4: model field
  sed -i '4s/model: haiku-4.5/model: sonnet-4.5/' "$AGENT_FILE"

  # Revert line 5: model-justification field
  sed -i '5s/model-justification: .*/model-justification: Rollback to Sonnet 4.5 due to quality concerns/' "$AGENT_FILE"

  echo "  ✓ $agent rolled back to Sonnet 4.5"
done
```

**Opus → Sonnet Rollback** (debug-specialist):
```bash
AGENT_FILE=".claude/agents/debug-specialist.md"

echo "Rolling back debug-specialist..."

# Revert line 4: model field
sed -i '4s/model: opus-4.1/model: sonnet-4.5/' "$AGENT_FILE"

# Revert line 5: model-justification field
sed -i '5s/model-justification: .*/model-justification: Rollback to Sonnet 4.5 due to quality concerns/' "$AGENT_FILE"

echo "  ✓ debug-specialist rolled back to Sonnet 4.5"
```

### Step 4: Verify Rollback

Confirm agent files reverted correctly:

```bash
# Verify model field changes
for agent in "${AGENTS_TO_ROLLBACK[@]}"; do
  echo "=== $agent ==="
  grep "^model:" ".claude/agents/${agent}.md"
done

# Expected output: model: sonnet-4.5 for all
```

### Step 5: Run Validation Suite

Execute validation tests to confirm restoration:

```bash
# Run full validation suite
.claude/tests/test_model_optimization.sh --baseline

# Run agent-specific tests
for agent in "${AGENTS_TO_ROLLBACK[@]}"; do
  .claude/tests/test_model_optimization.sh --agent "$agent" --sample-size 10
done

# Verify no errors
if [ $? -eq 0 ]; then
  echo "✓ Validation suite passed - rollback successful"
else
  echo "✗ Validation failures detected - investigate"
fi
```

### Step 6: Update Rollback Documentation

Document the rollback in the optimization summary:

```bash
ROLLBACK_SUMMARY="$ROLLBACK_DIR/ROLLBACK_SUMMARY.md"

cat > "$ROLLBACK_SUMMARY" << EOF
# Rollback Summary

## Rollback Date
$(date +%Y-%m-%d\ %H:%M:%S)

## Agents Rolled Back
$(for agent in "${AGENTS_TO_ROLLBACK[@]}"; do echo "- $agent: Haiku → Sonnet"; done)
$(if [ -n "$DEBUG_ROLLBACK" ]; then echo "- debug-specialist: Opus → Sonnet"; fi)

## Root Cause Analysis
[Describe why the migration failed]

## Quality Metrics Before Rollback
[Include error rates, validation failures]

## Quality Metrics After Rollback
[Confirm restoration to baseline]

## Lessons Learned
[What should be done differently next time]

## Retry Strategy
[When and how to retry the migration]
EOF

# Link rollback summary to optimization data directory
ln -s "$ROLLBACK_SUMMARY" .claude/data/model_optimization_rollback_latest.md
```

### Step 7: Git Commit Rollback

Commit the rollback changes:

```bash
# Stage reverted agent files
git add .claude/agents/git-commit-helper.md \
        .claude/agents/spec-updater.md \
        .claude/agents/doc-converter.md \
        .claude/agents/implementer-coordinator.md \
        .claude/agents/plan-expander.md \
        .claude/agents/debug-specialist.md

# Create rollback commit
git commit -m "$(cat <<'EOF'
rollback(484): revert model migrations for 6 agents

Rollback triggered by: [trigger condition]

Agents rolled back:
- git-commit-helper: haiku → sonnet
- spec-updater: haiku → sonnet
- doc-converter: haiku → sonnet
- implementer-coordinator: haiku → sonnet
- plan-expander: haiku → sonnet
- debug-specialist: opus → sonnet

Quality metrics will be monitored to confirm restoration.

See .claude/data/rollbacks/[timestamp]/ROLLBACK_REASON.md for details.
EOF
)"

# Push to remote (if appropriate)
# git push origin [branch]
```

## Post-Rollback Actions

### Immediate Actions (Day 1)

1. **Monitor Error Rates**
   ```bash
   # Check for immediate improvements
   .claude/tests/test_model_optimization.sh --error-rate-comparison --threshold 5
   ```

2. **Run Integration Tests**
   ```bash
   # Validate workflows still function
   .claude/tests/test_model_optimization.sh --integration --workflows 5
   ```

3. **Notify Stakeholders**
   - Document rollback in project communication channels
   - Explain reason and expected timeline for resolution

### Short-Term Actions (Week 1)

1. **Root Cause Analysis**
   - Review logs and metrics to identify failure patterns
   - Determine if issue was model-related or implementation error
   - Document findings in `$ROLLBACK_DIR/ROOT_CAUSE_ANALYSIS.md`

2. **Quality Baseline Verification**
   - Confirm error rates return to baseline within 48 hours
   - Re-run validation suite daily for 7 days
   - Compare against original baseline metrics

3. **Develop Mitigation Strategy**
   - Identify what changes needed before retry
   - Consider phased rollout (1 agent at a time)
   - Add additional validation checks if needed

### Long-Term Actions (Month 1)

1. **Retry Decision**
   - After 30 days of stable baseline metrics
   - With enhanced validation or modified approach
   - Starting with lowest-risk agent first

2. **Process Improvements**
   - Update testing procedures based on lessons learned
   - Add automated monitoring for early warning signs
   - Enhance rollback triggers if needed

3. **Documentation Updates**
   - Update model selection guide with failure insights
   - Add case study to agent development guide
   - Share learnings with team

## Rollback Testing (Pre-Migration)

Before performing actual migrations, test the rollback procedure:

```bash
# Create test rollback directory
TEST_ROLLBACK_DIR=".claude/tests/fixtures/rollback_test"
mkdir -p "$TEST_ROLLBACK_DIR"

# Copy agent files to test location
cp .claude/agents/git-commit-helper.md "$TEST_ROLLBACK_DIR/"

# Simulate migration (Sonnet → Haiku)
sed -i '4s/sonnet-4.5/haiku-4.5/' "$TEST_ROLLBACK_DIR/git-commit-helper.md"

# Verify migration
grep "^model:" "$TEST_ROLLBACK_DIR/git-commit-helper.md"
# Expected: model: haiku-4.5

# Simulate rollback (Haiku → Sonnet)
sed -i '4s/haiku-4.5/sonnet-4.5/' "$TEST_ROLLBACK_DIR/git-commit-helper.md"

# Verify rollback
grep "^model:" "$TEST_ROLLBACK_DIR/git-commit-helper.md"
# Expected: model: sonnet-4.5

echo "✓ Rollback procedure test passed"

# Cleanup
rm -rf "$TEST_ROLLBACK_DIR"
```

## Rollback Risk Mitigation

### Pre-Rollback Checklist

Before executing rollback:
- [ ] Rollback trigger condition documented
- [ ] Backup of current state created
- [ ] Rollback procedure tested in isolation
- [ ] Team notified of pending rollback
- [ ] Validation suite ready to run
- [ ] Git history clean (no uncommitted changes)

### Rollback Validation Checklist

After rollback execution:
- [ ] All agent model fields reverted correctly
- [ ] Validation suite passes (0 failures)
- [ ] Error rates return to baseline within 48 hours
- [ ] No new quality issues introduced
- [ ] Rollback documented in git history
- [ ] Rollback report completed
- [ ] Team notified of rollback completion

## Emergency Rollback

For critical production issues requiring immediate rollback:

```bash
# Fast rollback (all 6 agents)
for agent in git-commit-helper spec-updater doc-converter implementer-coordinator plan-expander debug-specialist; do
  sed -i '4s/model: .*/model: sonnet-4.5/' ".claude/agents/${agent}.md"
done

# Immediate commit
git add .claude/agents/*.md
git commit -m "emergency: rollback all model optimizations"

# Skip validation (run post-rollback)
echo "Emergency rollback complete. Run validation suite ASAP."
```

## Rollback Metrics Tracking

Monitor these metrics after rollback to confirm restoration:

| Metric | Baseline | Target Post-Rollback | Measurement Window |
|--------|----------|---------------------|-------------------|
| Error Rate (all agents) | ≤2% | ≤2% | 48 hours |
| Commit Message Format | 100% | ≥98% | 24 hours |
| Cross-Reference Validity | 100% | 100% | 24 hours |
| Conversion Fidelity | ≥95% | ≥95% | 72 hours |
| Wave Coordination | 100% | 100% | 48 hours |
| Debugging Accuracy | ≥75% | ≥75% | 7 days |

## Related Documentation

- [Model Selection Guide](model-selection-guide.md) - Criteria for model selection
- [Agent Development Guide](agent-development/agent-development-fundamentals.md) - Agent frontmatter format
- [Model Optimization Plan](../../specs/484_research_which_commands_or_agents_in_claude_could_/plans/001_model_optimization_implementation.md) - Original implementation plan

## Revision History

- **2025-10-26**: Initial rollback guide created for Phase 1 baseline setup
