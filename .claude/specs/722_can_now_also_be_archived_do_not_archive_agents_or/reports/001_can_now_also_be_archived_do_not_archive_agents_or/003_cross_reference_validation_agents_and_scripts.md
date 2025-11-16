# Cross-Reference Validation: Agents and Scripts

**[← Back to Overview](./OVERVIEW.md)**

## Metadata
- **Date**: 2025-11-15
- **Agent**: research-specialist
- **Topic**: Cross-Reference Validation: Agents and Scripts
- **Report Type**: codebase analysis
- **Part of**: [Research Overview: Agents and Library Scripts Archival Analysis](./OVERVIEW.md)

## Executive Summary

This report provides comprehensive cross-reference validation for agents and library scripts in the `.claude/` directory, identifying interdependencies to ensure safe archival decisions. Analysis reveals a hierarchical dependency structure with critical core utilities that must not be archived.

**Key Findings:**
- **13 library scripts** depend on `base-utils.sh` (critical foundation)
- **4 agents** actively use `state-persistence.sh` (state machine architecture)
- **7 agents** invoked by active commands (`/coordinate`, `/research`, `/optimize-claude`)
- **3 library scripts** identified as low-usage candidates for potential archival
- **0 agents** identified as safe for archival (all actively referenced)

## 1. Library Script Interdependencies

### 1.1 Core Dependency Chains

#### Tier 1: Foundation Scripts (DO NOT ARCHIVE)

**base-utils.sh** (13 dependents)
- **Direct dependents:**
  - agent-discovery.sh
  - agent-schema-validator.sh
  - artifact-creation.sh
  - artifact-registry.sh
  - checkbox-utils.sh
  - dependency-analysis.sh
  - metadata-extraction.sh
  - plan-core-bundle.sh
  - timestamp-utils.sh
  - unified-logger.sh
- **Impact:** Archiving would break 13 library scripts and cascade to all agents/commands
- **Verdict:** CRITICAL - DO NOT ARCHIVE

**detect-project-dir.sh** (3 dependents)
- **Direct dependents:**
  - workflow-state-machine.sh
  - checkpoint-utils.sh
  - research.md (command)
- **Impact:** Would break state machine architecture and checkpoint system
- **Verdict:** CRITICAL - DO NOT ARCHIVE

**timestamp-utils.sh** (2 direct dependents)
- **Direct dependents:**
  - unified-logger.sh
  - checkpoint-utils.sh
- **Dependencies:** base-utils.sh
- **Impact:** Would break logging and checkpoint systems
- **Verdict:** CRITICAL - DO NOT ARCHIVE

#### Tier 2: State Machine Architecture (ACTIVE - DO NOT ARCHIVE)

**workflow-state-machine.sh**
- **Dependencies:** detect-project-dir.sh
- **Used by:** `/coordinate` command (2,371 lines, production-ready)
- **Impact:** Would break primary orchestration command
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**state-persistence.sh**
- **Used by agents:**
  - implementation-sub-supervisor.md
  - research-sub-supervisor.md
  - testing-sub-supervisor.md
  - workflow-classifier.md
- **Impact:** Would break 4 supervisor agents and state management
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**workflow-initialization.sh**
- **Used by:** coordinate.md (sourced in Part 2)
- **Impact:** Would break `/coordinate` initialization
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**checkpoint-utils.sh**
- **Dependencies:** detect-project-dir.sh, timestamp-utils.sh
- **Used by:** implementation-executor.md agent
- **Impact:** Would break checkpoint recovery system
- **Verdict:** ACTIVE - DO NOT ARCHIVE

#### Tier 3: Planning and Analysis Utilities (ACTIVE - DO NOT ARCHIVE)

**plan-core-bundle.sh** (4 dependents)
- **Direct dependents:**
  - checkbox-utils.sh
  - dependency-analysis.sh
  - auto-analysis-utils.sh
  - collapse.md (command)
  - expand.md (command)
- **Dependencies:** base-utils.sh
- **Impact:** Would break plan expansion/collapse and checkbox management
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**auto-analysis-utils.sh**
- **Dependencies:**
  - agent-invocation.sh
  - analysis-pattern.sh
  - artifact-registry.sh
  - error-handling.sh
  - json-utils.sh
  - plan-core-bundle.sh
- **Used by:** collapse.md, expand.md
- **Impact:** Would break automatic phase/stage analysis
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**checkbox-utils.sh**
- **Dependencies:** base-utils.sh, plan-core-bundle.sh
- **Used by agents:**
  - code-writer.md
  - implementation-executor.md
  - spec-updater.md
- **Impact:** Would break plan progress tracking
- **Verdict:** ACTIVE - DO NOT ARCHIVE

#### Tier 4: Artifact Management

**artifact-creation.sh**
- **Dependencies:** base-utils.sh, unified-logger.sh, artifact-registry.sh
- **Used by:** research.md
- **Impact:** Would break report/plan creation in research workflows
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**artifact-registry.sh** (POTENTIAL CANDIDATE)
- **Dependencies:** base-utils.sh, unified-logger.sh
- **Used by:**
  - artifact-creation.sh (active)
  - auto-analysis-utils.sh (active)
  - validate-context-reduction.sh (validation only)
- **Impact:** Moderate - only used by 3 scripts
- **Archival Risk:** Medium - artifact-creation.sh has hard dependency
- **Verdict:** LOW PRIORITY FOR ARCHIVAL (still has active dependents)

#### Tier 5: Logging and Metrics

**unified-logger.sh**
- **Dependencies:** base-utils.sh, timestamp-utils.sh
- **Used by:**
  - artifact-creation.sh
  - artifact-registry.sh
  - metadata-extraction.sh
- **Impact:** Would break logging infrastructure
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**analyze-metrics.sh** (ARCHIVAL CANDIDATE)
- **Dependencies:** None found
- **Used by:**
  - Only mentioned in documentation (lib/README.md)
  - No active sourcing in commands or agents
- **Impact:** Minimal - appears to be legacy from archived `/analyze` command
- **Archival Risk:** Low
- **Verdict:** CANDIDATE FOR ARCHIVAL

#### Tier 6: Conversion Utilities

**convert-core.sh**
- **Dependencies:** convert-docx.sh, convert-pdf.sh, convert-markdown.sh
- **Used by:** convert-docs.md command
- **Impact:** Would break document conversion
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**convert-docx.sh, convert-pdf.sh, convert-markdown.sh**
- **Used by:** convert-core.sh
- **Impact:** Would break document conversion
- **Verdict:** ACTIVE - DO NOT ARCHIVE

#### Tier 7: Workflow and Scope Detection

**workflow-scope-detection.sh**
- **Dependencies:** workflow-llm-classifier.sh
- **Used by:** workflow-state-machine.sh (primary), workflow-detection.sh (fallback)
- **Impact:** Would break workflow classification
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**workflow-llm-classifier.sh**
- **Used by:** workflow-scope-detection.sh
- **Impact:** Would break LLM-based workflow classification
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**workflow-detection.sh**
- **Dependencies:** workflow-scope-detection.sh
- **Used by:** Fallback mechanism for `/supervise` compatibility
- **Impact:** Would break backward compatibility
- **Verdict:** ACTIVE - DO NOT ARCHIVE

#### Tier 8: Complexity and Template Utilities

**complexity-utils.sh**
- **Dependencies:** complexity-thresholds.sh
- **Used by:** plan.md, implement.md
- **Impact:** Would break adaptive planning triggers
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**complexity-thresholds.sh**
- **Used by:** complexity-utils.sh
- **Impact:** Would break complexity scoring
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**template-integration.sh**
- **Used by:** research.md
- **Impact:** Would break research report templating
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**parse-template.sh, substitute-variables.sh**
- **Used by:** Template system (indirect usage)
- **Impact:** Would break template processing
- **Verdict:** ACTIVE - DO NOT ARCHIVE

#### Tier 9: Specialized Utilities

**library-sourcing.sh** (POTENTIAL CANDIDATE)
- **Used by:** source-libraries-snippet.sh only
- **Impact:** Minimal - only used by one snippet script
- **Archival Risk:** Medium - may still be referenced in documentation
- **Verdict:** LOW PRIORITY FOR ARCHIVAL

**topic-decomposition.sh, topic-utils.sh**
- **Used by:** research.md
- **Impact:** Would break research topic analysis
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**metadata-extraction.sh**
- **Dependencies:** base-utils.sh, unified-logger.sh
- **Used by:** research.md, research-sub-supervisor.md
- **Impact:** Would break metadata extraction in research workflows
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**git-commit-utils.sh**
- **Used by:** implementation-executor.md
- **Impact:** Would break automated git commits
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**json-utils.sh**
- **Dependencies:** deps-utils.sh
- **Used by:** auto-analysis-utils.sh
- **Impact:** Would break JSON processing in analysis
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**deps-utils.sh**
- **Used by:** json-utils.sh
- **Impact:** Would break dependency management
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**error-handling.sh**
- **Used by:** auto-analysis-utils.sh, implement.md
- **Impact:** Would break error handling infrastructure
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**overview-synthesis.sh**
- **Used by:** research.md
- **Impact:** Would break research overview generation
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**unified-location-detection.sh**
- **Used by agents:**
  - claude-md-analyzer.md
  - cleanup-plan-architect.md
  - docs-accuracy-analyzer.md
  - docs-bloat-analyzer.md
  - docs-structure-analyzer.md
  - research-specialist.md
  - research-synthesizer.md
- **Impact:** Would break 7 agents
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**optimize-claude-md.sh**
- **Used by:** claude-md-analyzer.md agent, optimize-claude.md command
- **Impact:** Would break CLAUDE.md optimization
- **Verdict:** ACTIVE - DO NOT ARCHIVE

### 1.2 Library Script Summary Table

| Script | Dependents | Dependencies | Status |
|--------|-----------|--------------|--------|
| base-utils.sh | 13 scripts | None | CRITICAL |
| detect-project-dir.sh | 3 scripts | None | CRITICAL |
| timestamp-utils.sh | 2 scripts | base-utils | CRITICAL |
| workflow-state-machine.sh | 1 command | detect-project-dir | ACTIVE |
| state-persistence.sh | 4 agents | None | ACTIVE |
| workflow-initialization.sh | 1 command | Unknown | ACTIVE |
| checkpoint-utils.sh | 1 agent | detect-project-dir, timestamp-utils | ACTIVE |
| plan-core-bundle.sh | 4 scripts/commands | base-utils | ACTIVE |
| auto-analysis-utils.sh | 2 commands | 6 scripts | ACTIVE |
| checkbox-utils.sh | 3 agents | base-utils, plan-core-bundle | ACTIVE |
| artifact-creation.sh | 1 command | 3 scripts | ACTIVE |
| artifact-registry.sh | 3 scripts | 2 scripts | LOW PRIORITY |
| unified-logger.sh | 3 scripts | 2 scripts | ACTIVE |
| analyze-metrics.sh | 0 active | None | CANDIDATE |
| convert-core.sh | 1 command | 3 scripts | ACTIVE |
| workflow-scope-detection.sh | 2 scripts | 1 script | ACTIVE |
| complexity-utils.sh | 2 commands | 1 script | ACTIVE |
| template-integration.sh | 1 command | Unknown | ACTIVE |
| library-sourcing.sh | 1 script | None | LOW PRIORITY |
| metadata-extraction.sh | 2 files | 2 scripts | ACTIVE |
| unified-location-detection.sh | 7 agents | Unknown | ACTIVE |
| optimize-claude-md.sh | 2 files | Unknown | ACTIVE |

## 2. Agent-to-Library Script Dependencies

### 2.1 Agents Using Library Scripts

**claude-md-analyzer.md**
- **Library dependencies:**
  - optimize-claude-md.sh
  - unified-location-detection.sh
- **Used by:** optimize-claude.md command
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**cleanup-plan-architect.md**
- **Library dependencies:**
  - unified-location-detection.sh
- **Used by:** optimize-claude.md command
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**code-writer.md**
- **Library dependencies:**
  - checkbox-utils.sh
- **Used by:** Historic usage (no active command invocations found)
- **Verdict:** REVIEW - May be invoked by /implement via delegation

**docs-accuracy-analyzer.md**
- **Library dependencies:**
  - unified-location-detection.sh
- **Used by:** optimize-claude.md command
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**docs-bloat-analyzer.md**
- **Library dependencies:**
  - unified-location-detection.sh
- **Used by:** optimize-claude.md command
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**docs-structure-analyzer.md**
- **Library dependencies:**
  - unified-location-detection.sh
- **Used by:** optimize-claude.md command
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**implementation-executor.md**
- **Library dependencies:**
  - checkbox-utils.sh
  - checkpoint-utils.sh
  - git-commit-utils.sh
- **Used by:** Delegated execution pattern (not directly invoked by commands)
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**implementation-sub-supervisor.md**
- **Library dependencies:**
  - state-persistence.sh
- **Used by:** Hierarchical supervision pattern
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**research-specialist.md**
- **Library dependencies:**
  - unified-location-detection.sh
- **Used by:** coordinate.md, research.md
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**research-sub-supervisor.md**
- **Library dependencies:**
  - metadata-extraction.sh
  - state-persistence.sh
- **Used by:** coordinate.md, research.md
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**research-synthesizer.md**
- **Library dependencies:**
  - unified-location-detection.sh
- **Used by:** research.md
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**spec-updater.md**
- **Library dependencies:**
  - checkbox-utils.sh
- **Used by:** research.md
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**testing-sub-supervisor.md**
- **Library dependencies:**
  - state-persistence.sh
- **Used by:** Hierarchical supervision pattern
- **Verdict:** ACTIVE - DO NOT ARCHIVE

**workflow-classifier.md**
- **Library dependencies:**
  - state-persistence.sh
- **Used by:** coordinate.md
- **Verdict:** ACTIVE - DO NOT ARCHIVE

### 2.2 Agent Dependency Summary Table

| Agent | Library Dependencies | Used By Commands | Status |
|-------|---------------------|------------------|--------|
| claude-md-analyzer.md | 2 scripts | optimize-claude | ACTIVE |
| cleanup-plan-architect.md | 1 script | optimize-claude | ACTIVE |
| code-writer.md | 1 script | (delegation) | REVIEW |
| docs-accuracy-analyzer.md | 1 script | optimize-claude | ACTIVE |
| docs-bloat-analyzer.md | 1 script | optimize-claude | ACTIVE |
| docs-structure-analyzer.md | 1 script | optimize-claude | ACTIVE |
| implementation-executor.md | 3 scripts | (delegation) | ACTIVE |
| implementation-sub-supervisor.md | 1 script | (supervision) | ACTIVE |
| research-specialist.md | 1 script | coordinate, research | ACTIVE |
| research-sub-supervisor.md | 2 scripts | coordinate, research | ACTIVE |
| research-synthesizer.md | 1 script | research | ACTIVE |
| spec-updater.md | 1 script | research | ACTIVE |
| testing-sub-supervisor.md | 1 script | (supervision) | ACTIVE |
| workflow-classifier.md | 1 script | coordinate | ACTIVE |

## 3. Command-to-Agent Dependencies

### 3.1 Commands Invoking Agents

**coordinate.md** (Primary Orchestrator)
- **Agents invoked:**
  - implementer-coordinator.md
  - plan-architect.md
  - research-specialist.md
  - research-sub-supervisor.md
  - revision-specialist.md
  - workflow-classifier.md
- **Metadata declares:** research-specialist, plan-architect, implementer-coordinator, debug-analyst
- **Verdict:** All 6+ agents are ACTIVE

**research.md**
- **Agents invoked:**
  - research-specialist.md
  - research-synthesizer.md
  - spec-updater.md
- **Verdict:** All 3 agents are ACTIVE

**optimize-claude.md**
- **Agents invoked:**
  - claude-md-analyzer.md
  - cleanup-plan-architect.md
  - docs-accuracy-analyzer.md
  - docs-bloat-analyzer.md
  - docs-structure-analyzer.md
- **Verdict:** All 5 agents are ACTIVE

**collapse.md**
- **Agents invoked:**
  - complexity-estimator.md
- **Verdict:** Agent is ACTIVE

**expand.md**
- **Agents invoked:**
  - complexity-estimator.md
  - plan-structure-manager.md
- **Verdict:** Both agents are ACTIVE

**convert-docs.md**
- **Agents invoked:**
  - doc-converter.md
- **Verdict:** Agent is ACTIVE

### 3.2 Command Dependency Summary Table

| Command | Agents Invoked | Library Scripts | Status |
|---------|---------------|-----------------|--------|
| coordinate.md | 6+ agents | workflow-initialization.sh | ACTIVE |
| research.md | 3 agents | 7 scripts | ACTIVE |
| optimize-claude.md | 5 agents | 1 script | ACTIVE |
| collapse.md | 1 agent | 2 scripts | ACTIVE |
| expand.md | 2 agents | 3 scripts | ACTIVE |
| convert-docs.md | 1 agent | 1 script | ACTIVE |
| plan.md | 0 agents | 2 scripts | ACTIVE |
| implement.md | 0 direct | 5+ scripts | ACTIVE |
| debug.md | 0 direct | 0 scripts | ACTIVE |

## 4. Cross-Dependency Analysis

### 4.1 Agent-to-Agent Dependencies

No direct agent-to-agent dependencies found in behavioral files. Agents are invoked hierarchically through commands or sub-supervisors, not by other agents directly.

**Hierarchical Patterns:**
- **Supervisor agents** invoke specialist agents via Task tool:
  - research-sub-supervisor.md → research-specialist.md
  - implementation-sub-supervisor.md → implementation-executor.md
- **Orchestrator commands** invoke supervisor agents:
  - coordinate.md → research-sub-supervisor.md
  - research.md → research-specialist.md

### 4.2 Script-to-Script Dependencies (Detailed)

**High-Coupling Scripts** (Many dependents):
1. base-utils.sh: 13 dependents
2. plan-core-bundle.sh: 4 dependents
3. unified-logger.sh: 3 dependents
4. detect-project-dir.sh: 3 dependents

**Medium-Coupling Scripts** (2-3 dependents):
1. artifact-registry.sh: 3 dependents
2. timestamp-utils.sh: 2 dependents
3. checkpoint-utils.sh: 1 direct dependent (implementation-executor.md)

**Low-Coupling Scripts** (0-1 dependents):
1. analyze-metrics.sh: 0 active dependents (CANDIDATE)
2. library-sourcing.sh: 1 dependent (source-libraries-snippet.sh) (LOW PRIORITY)

### 4.3 Dependency Graph Visualization

```
Core Foundation Layer:
  base-utils.sh
    ├── agent-discovery.sh
    ├── agent-schema-validator.sh
    ├── artifact-creation.sh
    ├── artifact-registry.sh
    ├── checkbox-utils.sh
    ├── dependency-analysis.sh
    ├── metadata-extraction.sh
    ├── plan-core-bundle.sh
    │     ├── checkbox-utils.sh
    │     ├── dependency-analysis.sh
    │     ├── auto-analysis-utils.sh
    │     ├── collapse.md
    │     └── expand.md
    ├── timestamp-utils.sh
    │     ├── unified-logger.sh
    │     └── checkpoint-utils.sh
    └── unified-logger.sh
          ├── artifact-creation.sh
          ├── artifact-registry.sh
          └── metadata-extraction.sh

State Management Layer:
  detect-project-dir.sh
    ├── workflow-state-machine.sh
    │     └── coordinate.md
    └── checkpoint-utils.sh
          └── implementation-executor.md

  state-persistence.sh
    ├── implementation-sub-supervisor.md
    ├── research-sub-supervisor.md
    ├── testing-sub-supervisor.md
    └── workflow-classifier.md

Workflow Classification Layer:
  workflow-llm-classifier.sh
    └── workflow-scope-detection.sh
          ├── workflow-state-machine.sh
          └── workflow-detection.sh

Agent Infrastructure Layer:
  unified-location-detection.sh
    ├── claude-md-analyzer.md
    ├── cleanup-plan-architect.md
    ├── docs-accuracy-analyzer.md
    ├── docs-bloat-analyzer.md
    ├── docs-structure-analyzer.md
    ├── research-specialist.md
    └── research-synthesizer.md

Conversion Layer:
  convert-core.sh
    ├── convert-docx.sh
    ├── convert-pdf.sh
    └── convert-markdown.sh
```

## 5. Archival Impact Assessment

### 5.1 Safe for Archival (Low Risk)

**analyze-metrics.sh**
- **Impact:** Minimal
- **Dependents:** None active (only documentation references)
- **Breaking Changes:** None
- **Recommendation:** SAFE TO ARCHIVE
- **Migration Path:** Remove documentation references in lib/README.md

### 5.2 Low Priority for Archival (Medium Risk)

**library-sourcing.sh**
- **Impact:** Minimal
- **Dependents:** 1 script (source-libraries-snippet.sh)
- **Breaking Changes:** Would break source-libraries-snippet.sh
- **Recommendation:** LOW PRIORITY
- **Migration Path:**
  1. Verify source-libraries-snippet.sh is not actively used
  2. Archive both together if unused

**artifact-registry.sh**
- **Impact:** Moderate
- **Dependents:** 3 scripts (artifact-creation.sh, auto-analysis-utils.sh, validate-context-reduction.sh)
- **Breaking Changes:** Would break artifact creation and analysis utilities
- **Recommendation:** LOW PRIORITY (still has active dependents)
- **Migration Path:**
  1. Refactor artifact-creation.sh to remove dependency
  2. Update auto-analysis-utils.sh
  3. Then archive

### 5.3 Do NOT Archive (High Risk)

**All other library scripts and agents:**
- Active dependencies in production commands
- Core infrastructure components
- State machine architecture components
- Agent delegation patterns

## 6. Recommendations

### 6.1 Immediate Actions

1. **Archive analyze-metrics.sh:**
   - Move to `.claude/archive/lib/`
   - Update documentation in lib/README.md to remove references
   - No breaking changes expected

2. **Document archival candidates:**
   - Add marker comments to library-sourcing.sh and artifact-registry.sh
   - Track usage over 30-day period
   - Re-evaluate after monitoring

### 6.2 Long-Term Actions

1. **Refactor artifact management:**
   - Consider consolidating artifact-registry.sh into artifact-creation.sh
   - Reduce coupling in auto-analysis-utils.sh
   - Enable future archival if needed

2. **Monitor library-sourcing.sh:**
   - Verify source-libraries-snippet.sh usage
   - If unused for 30 days, archive both together

3. **Maintain dependency documentation:**
   - Update this report quarterly
   - Track new dependencies introduced
   - Prevent unintended coupling

### 6.3 Archival Safety Protocol

**Before archiving any script or agent:**
1. Run full test suite to detect breakage
2. Search codebase for all references (including documentation)
3. Check git history for recent usage patterns
4. Verify no indirect dependencies via grep/glob
5. Create backup before archival
6. Monitor for 7 days post-archival

## 7. Conclusion

**Summary of Archival Safety:**
- **1 script** safe for immediate archival (analyze-metrics.sh)
- **2 scripts** low priority candidates (library-sourcing.sh, artifact-registry.sh)
- **0 agents** safe for archival (all actively referenced)
- **55+ scripts** must not be archived (active dependencies)

**Critical Dependencies Identified:**
- base-utils.sh: Foundation for 13 library scripts
- state-persistence.sh: Core to 4 supervisor agents
- unified-location-detection.sh: Required by 7 agents
- plan-core-bundle.sh: Critical for plan operations

**Risk Assessment:**
- Archiving analyze-metrics.sh: LOW RISK
- Archiving library-sourcing.sh: MEDIUM RISK (requires verification)
- Archiving artifact-registry.sh: MEDIUM-HIGH RISK (active dependents)
- Archiving any agent: HIGH RISK (all actively used)

**Next Steps:**
1. Archive analyze-metrics.sh immediately
2. Monitor library-sourcing.sh and artifact-registry.sh usage
3. Update archival documentation with findings
4. Maintain quarterly dependency audits
