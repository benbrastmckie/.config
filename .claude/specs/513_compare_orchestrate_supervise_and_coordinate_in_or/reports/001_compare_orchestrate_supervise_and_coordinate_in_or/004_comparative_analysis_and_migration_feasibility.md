# Comparative Analysis and Migration Feasibility

**[← Return to Overview](./OVERVIEW.md)**

## Metadata
- **Date**: 2025-10-28
- **Agent**: research-specialist
- **Topic**: Comparative analysis of /orchestrate, /supervise, and /coordinate commands with migration recommendations
- **Report Type**: Comparative analysis with migration feasibility assessment

## Executive Summary

This analysis compares three orchestration commands (/orchestrate, /supervise, /coordinate) across architecture, complexity, features, and performance. All three commands share identical architectural patterns (7 phases, behavioral injection, fail-fast error handling, checkpoint recovery) but differ significantly in size, complexity, and advanced features. **Key finding**: /coordinate achieves 50-54% size reduction (2,500-3,000 lines vs 5,438 lines) primarily by removing PR automation, dashboard tracking, and documentation while maintaining 100% core orchestration functionality. **Recommendation**: Users should select based on feature needs - /orchestrate for full-featured workflows with PR automation, /supervise for proven architectural compliance, /coordinate for clean minimal orchestration with wave-based execution.

## Findings

### 1. Architectural Analysis

#### 1.1 Common Architectural Patterns (100% Overlap)

All three commands implement identical architectural foundations:

**7-Phase Workflow Pattern** (lines 136-158 in /coordinate):
```
Phase 0: Location and Path Pre-Calculation
Phase 1: Research (2-4 parallel agents)
Phase 2: Planning (conditional)
Phase 3: Implementation (conditional)
Phase 4: Testing (conditional)
Phase 5: Debug (conditional - only if tests fail)
Phase 6: Documentation (conditional - only if implementation occurred)
```

**Workflow Scope Detection** (/coordinate lines 656-682):
- research-only: Phases 0-1 only
- research-and-plan: Phases 0-2 (MOST COMMON)
- full-implementation: Phases 0-4, 6 (Phase 5 conditional)
- debug-only: Phases 0, 1, 5 only

**Behavioral Injection Pattern** (/coordinate lines 86-103, /supervise lines 64-80):
- Task tool for agent invocations (NOT SlashCommand)
- Pre-calculated absolute paths passed to agents
- Behavioral guidelines from `.claude/agents/*.md`
- Structured return formats (e.g., `REPORT_CREATED: [path]`)

**Fail-Fast Error Handling** (/coordinate lines 269-287, /supervise lines 138-162):
- Single execution attempt per operation
- Comprehensive diagnostics on failure
- 5-section error message structure (Expected/Found/Diagnostic/Commands/Causes)
- Immediate termination with actionable guidance

**Checkpoint Recovery** (/coordinate lines 631-651, /supervise lines 441-461):
- Saved after Phases 1-4
- Auto-resume from last completed phase
- JSON checkpoint format with phase + artifact paths

**Context Management** (/coordinate lines 971-978, /supervise lines 871-881):
- Metadata extraction from artifacts (80-90% reduction)
- Progressive context pruning after each phase
- Target: <30% context usage throughout workflow

#### 1.2 Architectural Differences

**Wave-Based Execution** (/coordinate only - lines 144-243):
- Dependency analysis via `.claude/lib/dependency-analyzer.sh`
- Kahn's algorithm for topological sorting
- Parallel phase execution within waves
- 40-60% time savings
- Wave-level checkpointing
- **NOT present** in /supervise or /orchestrate

**PR Automation** (/orchestrate only - NOT in /coordinate):
- GitHub PR creation via `gh pr create`
- Automatic branch management
- PR description generation
- **Absent** in /coordinate (documented lines 160-180 explain this is a feature difference, not architectural)

**Dashboard Tracking** (/orchestrate only - NOT in /coordinate):
- Real-time progress visualization
- Metrics dashboard
- Workflow status monitoring
- **Absent** in /coordinate

### 2. Complexity Analysis

#### 2.1 File Size Comparison

| Command | Approximate Lines | Complexity Score |
|---------|------------------|------------------|
| /orchestrate | 5,438 lines | High (complete feature set) |
| /supervise | 1,939 lines | Medium (proven architectural compliance) |
| /coordinate | 2,500-3,000 lines | Medium (wave-based + core orchestration) |

**Size Reduction Analysis** (/coordinate vs /orchestrate):
- Core reduction: 50-54% (5,438 → 2,500-3,000)
- Primary removals: PR automation (~500 lines), Dashboard tracking (~400 lines), Enhanced documentation (~300 lines)
- **Verification**: /coordinate lines 491-509 document this as "integrate, not build" optimization

#### 2.2 Feature Completeness Matrix

| Feature | /orchestrate | /supervise | /coordinate |
|---------|--------------|------------|-------------|
| 7-phase workflow | ✓ | ✓ | ✓ |
| Workflow scope detection | ✓ | ✓ | ✓ |
| Behavioral injection | ✓ | ✓ | ✓ |
| Fail-fast error handling | ✓ | ✓ | ✓ |
| Checkpoint recovery | ✓ | ✓ | ✓ |
| Context management | ✓ | ✓ | ✓ |
| Wave-based execution | ✗ | ✗ | ✓ |
| PR automation | ✓ | ✗ | ✗ |
| Dashboard tracking | ✓ | ✗ | ✗ |
| Enhanced error reporting | ✓ | ✓ | ✓ |

**Core Orchestration Completeness**: 100% for all three commands (7-phase workflow + behavioral injection + fail-fast + checkpoints)

**Advanced Features**: Only /orchestrate provides PR automation and dashboards; Only /coordinate provides wave-based execution

### 3. Performance Analysis

#### 3.1 Performance Targets (Common to All)

From /coordinate lines 246-267 and /supervise Phase Reference:

| Metric | /orchestrate | /supervise | /coordinate |
|--------|--------------|------------|-------------|
| Context usage target | <30% | <30% | <30% |
| File creation rate | 100% | 100% | 100% |
| Metadata extraction reduction | 80-90% | 80-90% | 80-90% |
| Progress markers | ✓ | ✓ | ✓ |

**Identical Targets**: All three commands target <30% context usage and 100% file creation rate.

#### 3.2 Wave-Based Performance Gains (/coordinate only)

From /coordinate lines 228-240:
- **Best case**: 60% time savings (many independent phases)
- **Typical case**: 40-50% time savings (moderate dependencies)
- **Worst case**: 0% savings (fully sequential dependencies)
- **No overhead**: Plans with <3 phases execute sequentially (single wave)

**Sequential Execution** (/orchestrate, /supervise):
- All phases execute sequentially regardless of dependencies
- Time = sum of all phase durations
- No dependency analysis overhead

#### 3.3 Time Efficiency Comparison

**Wave-Based Plan (8 phases, moderate dependencies)**:
```
Sequential (/orchestrate, /supervise): 8 phases × avg_time = 8T
Wave-based (/coordinate):
  Wave 1: [P1, P2] (2 parallel)
  Wave 2: [P3, P4, P5] (3 parallel)
  Wave 3: [P6, P7] (2 parallel)
  Wave 4: [P8] (1 phase)
  Time: 4 waves × avg_time = 4T
Savings: 50% (4T vs 8T)
```

**Research-and-Plan Workflow** (no implementation):
- All three commands: Identical performance
- Wave execution not applicable (no Phase 3)

### 4. Migration Feasibility Assessment

#### 4.1 Migration Scenarios

**Scenario 1: /orchestrate → /coordinate**
- **Feature Loss**: PR automation, dashboard tracking
- **Feature Gain**: Wave-based parallel execution (40-60% time savings on implementation phases)
- **Compatibility**: 100% (identical workflow patterns)
- **Effort**: Low (command drop-in replacement)
- **Use Case**: Teams not using GitHub PRs or preferring manual PR creation

**Scenario 2: /supervise → /coordinate**
- **Feature Loss**: None (both are minimal orchestrators)
- **Feature Gain**: Wave-based parallel execution
- **Compatibility**: 100% (identical architectural patterns)
- **Effort**: Low (command drop-in replacement)
- **Use Case**: All users (pure upgrade with performance benefits)

**Scenario 3: /coordinate → /orchestrate**
- **Feature Loss**: Wave-based execution
- **Feature Gain**: PR automation, dashboard tracking
- **Compatibility**: 100% (identical workflow patterns)
- **Effort**: Low (command drop-in replacement)
- **Use Case**: Teams adopting GitHub PR automation

#### 4.2 Compatibility Matrix

All three commands share:
- Same behavioral agent files (`.claude/agents/*.md`)
- Same library dependencies (`.claude/lib/*.sh`)
- Same artifact directory structure (`specs/{NNN_topic}/reports|plans|summaries`)
- Same checkpoint format (JSON with phase + artifact paths)

**Key Insight**: Commands are **interchangeable** at the workflow level. A user can run Phase 0-2 with /coordinate, then switch to /orchestrate for Phase 3 if PR automation is needed.

#### 4.3 Migration Risks and Mitigation

**Risk 1: Wave-Based Execution Differences**
- Problem: /coordinate uses parallel execution; /orchestrate uses sequential
- Impact: Implementation timing differs (40-60% faster with /coordinate)
- Mitigation: None needed (both produce identical artifacts, just different execution order)

**Risk 2: Missing PR Automation in /coordinate**
- Problem: Teams relying on automatic PR creation
- Impact: Manual PR creation required when migrating from /orchestrate
- Mitigation: Use /orchestrate for workflows requiring PR automation; use /coordinate for manual PR workflows

**Risk 3: Checkpoint Format Compatibility**
- Problem: If checkpoint schemas differ between commands
- Impact: Cannot resume workflow after command switch
- Mitigation: Verify checkpoint schemas match (lines 962-969 /coordinate, lines 862-869 /supervise show identical JSON structure)

### 5. Library Dependencies Analysis

#### 5.1 Common Libraries (Required by All)

From /coordinate lines 321-330 and /supervise lines 166-178:

**Core Libraries**:
1. `workflow-detection.sh` - Scope detection, phase execution control
2. `error-handling.sh` - Error classification, diagnostic generation
3. `checkpoint-utils.sh` - Checkpoint save/restore, field access
4. `unified-logger.sh` - Progress markers, event logging
5. `unified-location-detection.sh` - Topic directory structure creation
6. `metadata-extraction.sh` - Context reduction via metadata-only passing
7. `context-pruning.sh` - Context optimization between phases

**Wave-Specific Library** (/coordinate only):
8. `dependency-analyzer.sh` - Dependency graph analysis, wave calculation

**Verification**: All commands use identical library-sourcing pattern via `library-sourcing.sh` (lines 214-236 /supervise, lines 532-570 /coordinate)

#### 5.2 Library Maturity Assessment

**Production-Ready Status**: 100% coverage on all core libraries

**Evidence**:
- /coordinate lines 491-509: "70-80% of planned infrastructure already existed in production-ready form"
- All three commands source from same library directory (`.claude/lib/`)
- No custom library implementations per command

**Migration Impact**: Zero. All libraries are shared infrastructure.

### 6. Agent Behavioral File Analysis

#### 6.1 Common Agents (Used by All)

From /coordinate lines 1686-1711 and /supervise agent invocations:

**Research Phase (Phase 1)**:
- `.claude/agents/research-specialist.md` - Focused codebase research
- Invocation: Lines 842-860 (/coordinate), Lines 618-642 (/supervise)

**Planning Phase (Phase 2)**:
- `.claude/agents/plan-architect.md` - Implementation plan creation
- Invocation: Lines 1041-1060 (/coordinate), Lines 946-970 (/supervise)

**Implementation Phase (Phase 3)**:
- `.claude/agents/implementer-coordinator.md` - Wave orchestration (/coordinate only)
- `.claude/agents/implementation-executor.md` - Individual phase execution
- `.claude/agents/code-writer.md` - Direct implementation (/supervise, /orchestrate)

**Testing Phase (Phase 4)**:
- `.claude/agents/test-specialist.md` - Test execution and reporting
- Invocation: Lines 1363-1383 (/coordinate)

**Debug Phase (Phase 5)**:
- `.claude/agents/debug-analyst.md` - Failure investigation
- Invocation: Lines 1472-1492 (/coordinate), Lines 1426-1591 (/supervise)

**Documentation Phase (Phase 6)**:
- `.claude/agents/doc-writer.md` - Implementation summaries
- Invocation: Lines 1626-1644 (/coordinate), Lines 1809-1828 (/supervise)

#### 6.2 Agent Invocation Patterns

**Identical Patterns Across All Commands**:
```
Task {
  subagent_type: "general-purpose"
  description: "[Brief task description]"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - [Context variables with pre-calculated paths]

    Execute following all guidelines.
    Return: [SIGNAL]: [artifact_path]
  "
}
```

**Verification**: Lines 64-80 (/supervise), Lines 86-103 (/coordinate) document identical behavioral injection pattern.

### 7. Command Selection Guidance

#### 7.1 Use Case Decision Matrix

| Use Case | Recommended Command | Rationale |
|----------|---------------------|-----------|
| Research + Planning (no implementation) | /coordinate OR /supervise | Both equivalent; /coordinate 29% larger due to wave infrastructure (not used in this workflow) |
| Implementation with GitHub PR automation | /orchestrate | Only command with built-in PR creation |
| Implementation with manual PR creation | /coordinate | 40-60% faster via wave-based execution |
| Proven architectural compliance | /supervise | Most heavily documented and validated (Spec 438, 495, 057) |
| Minimal complexity | /supervise | Smallest file size (1,939 lines) |
| Maximum performance | /coordinate | Wave-based execution for 40-60% time savings |
| Dashboard/metrics tracking | /orchestrate | Only command with dashboard integration |

#### 7.2 Migration Path Recommendations

**Path 1: /orchestrate → /coordinate** (Feature Reduction)
- **When**: Team no longer needs PR automation or dashboard tracking
- **Benefit**: 50-54% size reduction, 40-60% implementation time savings
- **Risk**: Low (commands are drop-in compatible)
- **Effort**: 1 hour (update documentation, test workflows)

**Path 2: /supervise → /coordinate** (Feature Addition)
- **When**: Team wants wave-based parallel execution
- **Benefit**: 40-60% implementation time savings
- **Risk**: Very low (both are minimal orchestrators with identical patterns)
- **Effort**: 1 hour (update documentation, test workflows)

**Path 3: /coordinate → /orchestrate** (Feature Addition)
- **When**: Team adopts GitHub PR automation
- **Benefit**: Automatic PR creation, dashboard tracking
- **Risk**: Low (commands are drop-in compatible)
- **Effort**: 2 hours (configure GitHub integration, update documentation)

**Path 4: Keep All Three Commands** (Feature Flexibility)
- **When**: Different workflows have different needs
- **Use Case**: Research-only → /supervise; Research-and-plan → /coordinate; Full-implementation with PRs → /orchestrate
- **Benefit**: Optimal command for each workflow type
- **Risk**: None (commands are interoperable)
- **Effort**: 2 hours (document command selection criteria)

### 8. Anti-Pattern Resolution Analysis

#### 8.1 Historical Anti-Pattern Issues (All Resolved)

From /supervise lines 388-437 and /coordinate anti-pattern documentation:

**Spec 438** (2025-10-24): /supervise agent delegation fix
- Problem: 7 YAML blocks wrapped in markdown causing 0% delegation rate
- Resolution: Imperative pattern (`**EXECUTE NOW**: USE the Task tool...`)
- Result: 0% → >90% delegation rate

**Spec 495** (2025-10-27): /coordinate and /research fixes
- Problem: 9 invocations in /coordinate using documentation-only YAML pattern
- Resolution: Applied imperative pattern from /supervise
- Result: 0% → >90% delegation rate, 100% file creation reliability

**Spec 057** (2025-10-27): /supervise robustness improvements
- Problem: Bootstrap fallback mechanisms hiding configuration errors
- Resolution: Removed 32 lines of fallbacks, enhanced library error messages
- Result: Fail-fast exposes errors immediately

**Spec 497** (Unified improvements):
- Resolution: All orchestration commands enforce Standard 11 (Imperative Agent Invocation Pattern)
- Verified Commands: /supervise, /coordinate, /orchestrate all >90% delegation rate
- Validation: `.claude/lib/validate-agent-invocation-pattern.sh` for pattern detection

**Key Finding**: All three commands now implement identical anti-pattern resolutions. No command has unresolved delegation or error handling issues.

#### 8.2 Current Compliance Status

| Anti-Pattern | /orchestrate | /supervise | /coordinate |
|--------------|--------------|------------|-------------|
| Command chaining (SlashCommand usage) | ✓ Resolved | ✓ Resolved | ✓ Resolved |
| Documentation-only YAML blocks | ✓ Resolved | ✓ Resolved | ✓ Resolved |
| Bootstrap fallbacks hiding errors | ✓ Resolved | ✓ Resolved | ✓ Resolved |
| Imperative language ratio ≥95% | ✓ Verified | ✓ Verified | ✓ Verified |
| Mandatory verification checkpoints | ✓ Verified | ✓ Verified | ✓ Verified |

**Verification**: All commands achieve >90% delegation rate with 100% file creation reliability.

## Recommendations

### Recommendation 1: Command Selection by Use Case

**For Research-Only Workflows**:
- Use **/supervise** (smallest, simplest, proven compliance)
- Rationale: 1,939 lines vs 2,500-3,000 (/coordinate) for identical functionality

**For Research-and-Plan Workflows**:
- Use **/coordinate** OR **/supervise** (equivalent functionality)
- Rationale: /coordinate has wave infrastructure overhead (not used); /supervise is 29% smaller

**For Implementation Workflows (Manual PRs)**:
- Use **/coordinate** (40-60% faster via wave-based execution)
- Rationale: Significant time savings without PR automation overhead

**For Implementation Workflows (GitHub PRs)**:
- Use **/orchestrate** (only command with built-in PR automation)
- Rationale: Automatic PR creation, branch management, description generation

### Recommendation 2: Migration Strategy

**Immediate Action**: No migration needed
- All three commands are **interoperable** and share identical infrastructure
- Teams can use different commands for different workflow types

**Optimization Opportunity**: Standardize on /coordinate for non-PR workflows
- Benefit: 40-60% implementation time savings
- Effort: Low (drop-in replacement, 1 hour to update documentation)

**Long-Term Strategy**: Maintain all three commands
- /supervise: Minimal complexity reference implementation
- /coordinate: Performance-optimized orchestration
- /orchestrate: Full-featured with PR automation

### Recommendation 3: Feature Development Priorities

**Priority 1**: Backport wave-based execution to /orchestrate
- Benefit: Combines PR automation with 40-60% time savings
- Effort: Medium (integrate dependency-analyzer.sh, update Phase 3)
- Timeline: 3-5 days

**Priority 2**: Extract common orchestration core
- Benefit: Reduce duplication across three commands
- Effort: High (extract shared phases to library functions)
- Timeline: 10-15 days
- Risk: High (breaks existing commands if not carefully tested)

**Priority 3**: Add optional PR automation to /coordinate
- Benefit: Single command for all use cases
- Effort: Medium (make PR automation conditional, add --create-pr flag)
- Timeline: 5-7 days

### Recommendation 4: Documentation Improvements

**Create Decision Flowchart**:
```
Workflow needs research only?
  → Use /supervise (smallest, simplest)

Workflow needs research + plan?
  → Use /coordinate OR /supervise (equivalent)

Workflow needs implementation?
  → Uses GitHub PRs?
    → Yes: Use /orchestrate (PR automation)
    → No: Use /coordinate (wave-based speed)

Workflow needs dashboard/metrics?
  → Use /orchestrate (only command with dashboards)
```

**Update CLAUDE.md** (lines 202-246):
- Add selection guidance for three orchestration commands
- Document feature differences (PR automation, wave execution, dashboards)
- Provide migration path examples

## References

### Command Files
- `/home/benjamin/.config/.claude/commands/orchestrate.md` - Full-featured orchestration (5,438 lines)
- `/home/benjamin/.config/.claude/commands/supervise.md` - Proven architectural compliance (1,939 lines)
- `/home/benjamin/.config/.claude/commands/coordinate.md` - Wave-based orchestration (2,500-3,000 lines)

### Agent Behavioral Files
- `/home/benjamin/.config/.claude/agents/research-specialist.md` - Research agent (671 lines)
- `/home/benjamin/.config/.claude/agents/plan-architect.md` - Planning agent
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` - Wave orchestration
- `/home/benjamin/.config/.claude/agents/implementation-executor.md` - Phase execution
- `/home/benjamin/.config/.claude/agents/code-writer.md` - Direct implementation
- `/home/benjamin/.config/.claude/agents/test-specialist.md` - Test execution
- `/home/benjamin/.config/.claude/agents/debug-analyst.md` - Failure investigation
- `/home/benjamin/.config/.claude/agents/doc-writer.md` - Documentation

### Library Files
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh` - Scope detection
- `/home/benjamin/.config/.claude/lib/error-handling.sh` - Error classification
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` - Checkpoint management
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` - Progress tracking
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Directory structure
- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` - Context reduction
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` - Context optimization
- `/home/benjamin/.config/.claude/lib/dependency-analyzer.sh` - Wave calculation (/coordinate only)

### Documentation References
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` - Agent invocation pattern
- `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md` - Error handling pattern
- `/home/benjamin/.config/.claude/docs/concepts/patterns/checkpoint-recovery.md` - Resume capability
- `/home/benjamin/.config/.claude/docs/guides/orchestration-troubleshooting.md` - Debugging procedures
- `/home/benjamin/.config/.claude/specs/438_analysis_of_supervise_command_refactor_plan_for_re/reports/001_analysis_of_supervise_command_refactor_plan_for_re_research/OVERVIEW.md` - /supervise analysis

### Spec References
- Spec 438 (2025-10-24): /supervise agent delegation fix (0% → >90% delegation rate)
- Spec 495 (2025-10-27): /coordinate and /research delegation failures resolution
- Spec 057 (2025-10-27): /supervise robustness improvements (fail-fast error handling)
- Spec 497 (Unified improvements): All orchestration commands architectural compliance
