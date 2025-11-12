# Current .claude/ Infrastructure Analysis

## Metadata
- **Date**: 2025-11-07
- **Agent**: research-specialist
- **Topic**: Current .claude/ infrastructure analysis (commands, agents, documentation structure)
- **Report Type**: codebase analysis

## Executive Summary

The .claude/ infrastructure is a mature, well-organized system with 20 active slash commands, 19 specialized agents, 56 utility libraries, and 105+ documentation files organized using the Diataxis framework. Three orchestrator commands exist (/coordinate, /orchestrate, /supervise) with sizes ranging from 63KB to 183KB (1,779-5,439 lines). Documentation follows a clear pattern-based architecture with 10 core patterns documented in .claude/docs/concepts/patterns/. A complete agent registry system exists at .claude/agents/agent-registry.json tracking 19 agents with metadata and metrics. The infrastructure demonstrates excellent separation of concerns with commands in .claude/commands/, agents in .claude/agents/, utilities in .claude/lib/, and comprehensive documentation in .claude/docs/.

## Findings

### 1. Command Infrastructure

**Location**: `/home/benjamin/.config/.claude/commands/`

**Total Commands**: 20 active commands (23 files including README and shared/)

**Command Categories**:
- Primary Commands (7): implement, plan, plan-wizard, research, test, test-all, orchestrate
- Support Commands (3): debug, document, refactor
- Workflow Commands (5): revise, expand, collapse, coordinate, supervise
- Utility Commands (5): analyze, list, plan-from-template, setup, convert-docs

**Orchestrator Commands Analysis**:

1. **coordinate.md**
   - Size: 87KB / 2,334 lines
   - Status: Production-ready (recommended default)
   - Features: Wave-based parallel execution, fail-fast error handling
   - Architecture: Documented in `.claude/docs/architecture/coordinate-state-management.md`

2. **orchestrate.md**
   - Size: 183KB / 5,439 lines (largest command)
   - Status: In development (experimental features)
   - Features: Full-featured with PR automation, dashboard tracking
   - Note: May have inconsistent behavior due to feature experimentation

3. **supervise.md**
   - Size: 63KB / 1,779 lines (smallest orchestrator)
   - Status: In development (minimal reference)
   - Features: Sequential orchestration with proven architectural compliance
   - Documentation: `.claude/docs/guides/supervise-guide.md`, `.claude/docs/reference/supervise-phases.md`

**Command Architecture Features** (from README.md:49-80):
- Reference-based composition pattern using `commands/shared/` files
- 61.3% reduction in command file sizes through modularization (5,496 → 2,129 lines)
- Shared documentation files in `commands/shared/` (9 files totaling 3,367 lines extracted)
- Integration with utility libraries in `.claude/lib/`

**File References**:
- `/home/benjamin/.config/.claude/commands/README.md` (880 lines)
- `/home/benjamin/.config/.claude/commands/coordinate.md` (2,334 lines)
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (5,439 lines)
- `/home/benjamin/.config/.claude/commands/supervise.md` (1,779 lines)

### 2. Agent Infrastructure

**Location**: `/home/benjamin/.config/.claude/agents/`

**Total Agents**: 19 specialized agents (22 files - 19 agents + README + shared/ + prompts/)

**Agent Categories** (from agent-registry.json):

1. **Implementation Agents (5)**:
   - code-writer (hierarchical)
   - code-reviewer (specialized)
   - doc-writer (specialized)
   - implementation-executor (hierarchical)
   - implementer-coordinator (hierarchical)

2. **Research Agents (3)**:
   - research-specialist (specialized)
   - research-synthesizer (specialized)
   - implementation-researcher (specialized)

3. **Planning Agents (2)**:
   - plan-architect (hierarchical)
   - plan-structure-manager (hierarchical)

4. **Analysis Agents (4)**:
   - complexity-estimator (specialized)
   - metrics-specialist (specialized)
   - github-specialist (specialized)
   - spec-updater (specialized)

5. **Debugging Agents (2)**:
   - debug-specialist (specialized)
   - debug-analyst (specialized)

6. **Documentation Agents (2)**:
   - doc-converter (specialized)
   - test-specialist (specialized)

**Agent Consolidation History** (from README.md:9-21):
- 2025-10-27: 22 → 19 agents (14% reduction)
- Consolidations: expansion-specialist + collapse-specialist → plan-structure-manager (95% overlap eliminated)
- Refactorings: git-commit-helper → `.claude/lib/git-commit-utils.sh` (deterministic logic to library)
- Total savings: 1,168 lines of code

**Agent Registry System**:

**Location**: `/home/benjamin/.config/.claude/agents/agent-registry.json`

**Registry Structure**:
```json
{
  "schema_version": "1.0.0",
  "last_updated": "2025-10-27T03:23:49Z",
  "agents": {
    "agent-name": {
      "type": "specialized|hierarchical|documentation",
      "category": "implementation|research|planning|analysis|debugging|documentation",
      "description": "...",
      "tools": ["Read", "Write", ...],
      "metrics": {
        "total_invocations": 0,
        "successful_invocations": 0,
        "failed_invocations": 0,
        "average_duration_seconds": 0.0,
        "last_invocation": null
      },
      "dependencies": [],
      "behavioral_file": ".claude/agents/agent-name.md"
    }
  }
}
```

**Registry Features**:
- Complete metadata tracking for all 19 agents
- Performance metrics (invocations, success rate, duration)
- Type classification (specialized, hierarchical, documentation)
- Category grouping (implementation, research, planning, etc.)
- Tool inventory per agent
- Behavioral file path references

**Registry Utilities**:
- **Location**: `/home/benjamin/.config/.claude/lib/agent-registry-utils.sh`
- **Functions**: `register_agent()`, `update_agent_metrics()`, `get_agent_info()`
- **Schema Validation**: `.claude/agents/agent-registry-schema.json`

**Agent Subdirectories**:
- `agents/prompts/` - Agent evaluation prompt templates (4 files)
- `agents/shared/` - Shared protocols and guidelines (3 files)
  - `progress-streaming-protocol.md`
  - `error-handling-guidelines.md`

**File References**:
- `/home/benjamin/.config/.claude/agents/README.md` (686 lines)
- `/home/benjamin/.config/.claude/agents/agent-registry.json` (386 lines, 19 agents)
- `/home/benjamin/.config/.claude/lib/agent-registry-utils.sh` (100+ lines)

### 3. Documentation Structure

**Location**: `/home/benjamin/.config/.claude/docs/`

**Total Documentation**: 105 markdown files

**Documentation Framework**: Diataxis (docs/README.md:7-14)
- **Reference** - Information-oriented quick lookup materials (15 files)
- **Guides** - Task-focused how-to guides (30 files)
- **Concepts** - Understanding-oriented explanations (4+ files + patterns)
- **Workflows** - Learning-oriented tutorials (7+ files)

**Documentation Categories**:

1. **Reference Documentation** (15 files)
   - command-reference.md - Complete command catalog
   - agent-reference.md - Complete agent catalog
   - command_architecture_standards.md - 11 standards for commands/agents
   - library-api.md - Utility library documentation
   - phase_dependencies.md - Wave-based parallel execution syntax
   - orchestration-reference.md - Unified orchestration reference
   - workflow-phases.md - Detailed phase descriptions
   - claude-md-section-schema.md - CLAUDE.md format spec
   - supervise-phases.md - /supervise phase reference
   - backup-retention-policy.md
   - debug-structure.md, refactor-structure.md, report-structure.md
   - template-vs-behavioral-distinction.md

2. **Guides Documentation** (30 files)
   - command-development-guide.md - Command creation
   - agent-development-guide.md - Agent creation and invocation
   - orchestration-best-practices.md - Unified 7-phase framework
   - orchestration-troubleshooting.md - Debugging orchestration
   - phase-0-optimization.md - 85% token reduction, 25x speedup
   - model-selection-guide.md - Haiku/Sonnet/Opus selection
   - imperative-language-guide.md - MUST/WILL/SHALL usage
   - setup-command-guide.md - /setup usage patterns
   - testing-patterns.md, testing-standards.md
   - Using and integration guides (15+ files)

3. **Concepts Documentation** (4 core + patterns/)
   - hierarchical_agents.md - Multi-level agent coordination
   - directory-protocols.md - Topic-based artifact organization
   - development-workflow.md - Workflow patterns
   - writing-standards.md - Development philosophy
   - patterns/ - 10 architectural patterns (see section 4)

4. **Workflows Documentation** (7 files)
   - orchestration-guide.md - Multi-agent workflow tutorial
   - context-budget-management.md - Context optimization
   - adaptive-planning-guide.md - Adaptive planning tutorial
   - development-workflow.md - Development patterns
   - hierarchical-agent-workflow.md - Agent coordination
   - conversion-guide.md - Document conversion workflows
   - Other specialized workflow guides

**Documentation Subdirectories**:
- `docs/architecture/` - Architecture documentation (coordinate-state-management.md)
- `docs/concepts/patterns/` - Architectural patterns catalog (10 patterns)
- `docs/quick-reference/` - Quick reference materials (4 files)
- `docs/troubleshooting/` - Troubleshooting guides (4 files)
- `docs/archive/` - Archived documentation (organized by type)

**File References**:
- `/home/benjamin/.config/.claude/docs/README.md` (150+ lines)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/README.md` (128 lines)

### 4. Patterns Infrastructure

**Location**: `/home/benjamin/.config/.claude/docs/concepts/patterns/`

**Pattern Catalog**: 10 core architectural patterns (patterns/README.md:10-35)

**Pattern Categories**:

1. **Agent Coordination Patterns (3)**:
   - behavioral-injection.md - Commands inject context via file reads
   - hierarchical-supervision.md - Multi-level agent coordination with recursive supervision
   - forward-message.md - Direct subagent response passing without paraphrasing

2. **Context Management Patterns (2)**:
   - metadata-extraction.md - Extract title + summary + paths for 95-99% context reduction
   - context-management.md - Techniques for <30% context usage throughout workflows

3. **Reliability Patterns (2)**:
   - verification-fallback.md - MANDATORY VERIFICATION checkpoints for 100% file creation
   - checkpoint-recovery.md - State preservation and restoration for resilient workflows

4. **Performance Patterns (2)**:
   - parallel-execution.md - Wave-based and concurrent agent execution for 40-60% time savings
   - workflow-scope-detection.md - Conditional phase execution based on workflow type

**Pattern Documentation Features** (patterns/README.md):
- Authoritative source designation ("single source of truth")
- Pattern relationships diagram (patterns/README.md:55-67)
- Pattern selection guide matrix (patterns/README.md:96-105)
- Performance metrics documentation (patterns/README.md:107-114)
- Integration with command/agent development guides

**Pattern Performance Metrics** (patterns/README.md:107-114):
- File Creation Rate: 100% (10/10 tests)
- Context Reduction: 95-99%
- Time Savings: 40-60%
- Context Usage: <30% throughout workflows
- Reliability: Zero file creation failures

**Anti-Patterns Documentation**:
- Inline template duplication (patterns/README.md:37-51)
- Detection criteria (>50 lines per invocation, STEP sequences in commands)
- Fix strategy (extract to .claude/agents/*.md)
- Cross-reference to troubleshooting guide

**File References**:
- `/home/benjamin/.config/.claude/docs/concepts/patterns/README.md` (128 lines)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md`
- `/home/benjamin/.config/.claude/docs/concepts/patterns/metadata-extraction.md`
- `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md`
- Plus 7 additional pattern files

### 5. Library Infrastructure

**Location**: `/home/benjamin/.config/.claude/lib/`

**Total Libraries**: 56 shell script utilities

**Library Categories** (based on naming patterns):

1. **Agent Management (5)**:
   - agent-discovery.sh
   - agent-invocation.sh
   - agent-registry-utils.sh
   - agent-schema-validator.sh
   - validate-agent-invocation-pattern.sh

2. **Plan Management (8)**:
   - plan-core-bundle.sh (consolidated 3 utilities)
   - parse-template.sh
   - substitute-variables.sh
   - template-integration.sh
   - complexity-utils.sh
   - complexity-thresholds.sh
   - checkbox-utils.sh
   - dependency-analysis.sh, dependency-analyzer.sh

3. **State Management (4)**:
   - checkpoint-utils.sh
   - checkpoint-580.sh
   - unified-logger.sh (consolidated 2 loggers)
   - timestamp-utils.sh

4. **Artifact Management (3)**:
   - artifact-creation.sh
   - artifact-registry.sh
   - metadata-extraction.sh

5. **Location Detection (2)**:
   - unified-location-detection.sh
   - detect-project-dir.sh

6. **Context Management (3)**:
   - context-metrics.sh
   - context-pruning.sh
   - validate-context-reduction.sh

7. **Workflow Utilities (7)**:
   - workflow-detection.sh
   - workflow-initialization.sh
   - workflow-scope-detection.sh
   - topic-decomposition.sh
   - topic-utils.sh
   - overview-synthesis.sh
   - deps-utils.sh

8. **Git Utilities (2)**:
   - git-utils.sh
   - git-commit-utils.sh

9. **Document Conversion (4)**:
   - convert-core.sh
   - convert-docx.sh
   - convert-markdown.sh
   - convert-pdf.sh

10. **Analysis and Optimization (7)**:
    - analyze-metrics.sh
    - analysis-pattern.sh
    - auto-analysis-utils.sh
    - optimize-claude-md.sh
    - detect-testing.sh
    - monitor-model-usage.sh
    - verification-helpers.sh

11. **Error Handling and Logging (3)**:
    - error-handling.sh
    - base-utils.sh (common error(), warn(), info())
    - audit-imperative-language.sh

12. **Backup and Recovery (2)**:
    - backup-command-file.sh
    - rollback-command-file.sh

13. **Specialized Utilities (6)**:
    - generate-readme.sh
    - library-sourcing.sh
    - source-libraries-snippet.sh
    - json-utils.sh
    - progress-dashboard.sh
    - validation utilities

**Library Consolidation History** (commands/README.md:68-72):
- plan-core-bundle.sh - Consolidates 3 planning utilities (1,159 lines)
- unified-logger.sh - Consolidates 2 loggers (717 lines)
- base-utils.sh - Common error/warn/info functions (~100 lines)

**File References**:
- 56 shell script files in `/home/benjamin/.config/.claude/lib/`
- Documentation in `.claude/docs/reference/library-api.md`
- Usage examples in `.claude/docs/guides/using-utility-libraries.md`

### 6. Integration Points

**Command-Agent Integration**:
- Commands invoke agents via behavioral injection pattern (docs/concepts/patterns/behavioral-injection.md)
- Agent registry tracks which commands use which agents
- Shared protocols in `agents/shared/` used by all agents
- Agent discovery via `lib/agent-discovery.sh`

**Command-Library Integration**:
- All commands source utilities from `.claude/lib/`
- Standardized library sourcing via `lib/library-sourcing.sh`
- Common functions (error(), warn(), info()) from `lib/base-utils.sh`
- Checkpoint recovery pattern via `lib/checkpoint-utils.sh`

**Documentation Integration**:
- Commands reference `docs/guides/` for implementation patterns
- Agents reference `docs/concepts/patterns/` for architectural patterns
- CLAUDE.md references documentation sections with `[Used by: commands]` metadata
- Cross-references between guides, reference docs, and patterns

**Registry Integration**:
- Agent registry tracked in `agents/agent-registry.json`
- Artifact registry in `lib/artifact-registry.sh`
- Performance metrics in `.claude/data/metrics/*.jsonl`
- Logging in `.claude/data/logs/`

**Architecture Documentation Integration**:
- Orchestrator-specific architecture docs (e.g., `docs/architecture/coordinate-state-management.md`)
- Pattern catalog as authoritative source (docs/concepts/patterns/README.md)
- Cross-references from commands to architectural patterns
- Troubleshooting guides linked to specific patterns

### 7. Organizational Patterns

**Directory Structure Principles**:
1. **Separation of Concerns**:
   - Commands (workflow execution) in `.claude/commands/`
   - Agents (specialized behaviors) in `.claude/agents/`
   - Libraries (reusable utilities) in `.claude/lib/`
   - Documentation (guides/reference) in `.claude/docs/`

2. **Hierarchical Organization**:
   - Subdirectories for specialized content (`agents/shared/`, `commands/shared/`)
   - Documentation organized by Diataxis framework (reference, guides, concepts, workflows)
   - Archive directory for deprecated content (`docs/archive/`)

3. **Reference-Based Composition**:
   - Commands reference shared documentation files
   - Agents reference shared protocol files
   - Documentation cross-references authoritative sources
   - No duplication of architectural patterns

4. **Metadata-Driven Discovery**:
   - Agent registry with complete metadata
   - Command frontmatter with tool/dependency info
   - CLAUDE.md sections marked with `[Used by: commands]`
   - Documentation headers indicate purpose and audience

**Naming Conventions**:
- Commands: lowercase-with-dashes.md
- Agents: role-specialist.md or role-type.md
- Libraries: function-purpose.sh
- Documentation: descriptive-name.md
- Patterns: pattern-name.md in concepts/patterns/

**File Size Management**:
- Large commands modularized (orchestrate.md: 5,439 lines)
- Shared files extracted (commands/shared/, agents/shared/)
- Library consolidation (3 → 1 for planning utils)
- Documentation split by Diataxis categories

## Recommendations

### 1. Agent Registry Enhancement

**Current State**: Complete agent registry exists with 19 agents tracked, but metrics show zero invocations (all agents have `"total_invocations": 0`).

**Recommendation**: Implement active metrics collection
- Add metric logging to agent invocation pattern (lib/agent-invocation.sh)
- Track invocation timestamps, duration, and success/failure status
- Enable performance analysis via `lib/analyze-metrics.sh`
- Use metrics data to inform agent optimization decisions

**Impact**: Enables data-driven agent performance optimization and identifies frequently used vs underutilized agents.

### 2. Orchestrator Command Consolidation Analysis

**Current State**: Three orchestrator commands with significant size variation (1,779-5,439 lines) and different maturity levels.

**Recommendation**: Conduct detailed feature analysis to determine consolidation path
- Document unique features of each orchestrator (coordinate, orchestrate, supervise)
- Identify overlapping functionality (estimated 40-60% overlap)
- Create migration path for users from larger commands to recommended /coordinate
- Archive or deprecate redundant orchestrators once migration complete

**Impact**: Reduces maintenance burden, clarifies user choice, improves documentation consistency.

### 3. Pattern Documentation Enhancement

**Current State**: 10 well-documented patterns with performance metrics, but integration with agent development could be stronger.

**Recommendation**: Create pattern application checklist for agent development
- Add "Patterns Used" section to agent behavioral files
- Create pattern selection decision tree for new agent development
- Document pattern combinations that work well together
- Add pattern compliance testing to agent validation

**Impact**: Improves consistency in agent design, reduces pattern violations, enhances architectural coherence.

### 4. Library Discovery Improvement

**Current State**: 56 utility libraries exist but discovery mechanisms are limited to documentation.

**Recommendation**: Create library registry similar to agent registry
- Track library dependencies and usage patterns
- Document library API signatures and examples
- Create library selection guide for common tasks
- Add library usage metrics to identify critical vs unused utilities

**Impact**: Improves library discoverability, enables deprecation of unused utilities, supports consolidation opportunities.

### 5. Documentation Navigation Enhancement

**Current State**: 105 documentation files well-organized by Diataxis framework, but navigation could be improved.

**Recommendation**: Create interactive documentation index
- Add topic-based quick navigation (beyond current "I Want To..." section)
- Create visual documentation map showing relationships
- Add search functionality or tags for documentation discovery
- Implement documentation health checks (broken links, outdated content)

**Impact**: Reduces time to find relevant documentation, improves onboarding experience, maintains documentation quality.

### 6. Command Shared Files Organization

**Current State**: 9 shared documentation files in `commands/shared/` successfully extracted from commands, saving 3,367 lines of duplication.

**Recommendation**: Extend shared files pattern to agents
- Create `agents/shared/behavioral-templates/` for common behavioral patterns
- Extract repeated agent behavioral sections (e.g., file creation protocol, progress streaming)
- Use reference-based composition in agent files similar to commands
- Document agent composition patterns in agent development guide

**Impact**: Further reduces duplication, improves agent behavioral consistency, simplifies agent updates.

### 7. Architecture Documentation Strategy

**Current State**: Architecture docs exist for /coordinate (`docs/architecture/coordinate-state-management.md`) but not for /orchestrate or /supervise.

**Recommendation**: Complete architecture documentation for all orchestrators
- Document /orchestrate architecture (state management, PR automation, dashboard)
- Document /supervise architecture (sequential orchestration, phase execution)
- Create architectural comparison matrix for the three orchestrators
- Use architecture docs to inform consolidation decisions (Recommendation #2)

**Impact**: Enables informed decision-making on orchestrator consolidation, improves maintainability, supports debugging.

### 8. Registry-Driven Development Workflow

**Current State**: Agent registry and artifact registry exist but aren't actively used in development workflows.

**Recommendation**: Integrate registry systems into development commands
- Use agent registry in `/plan` to suggest appropriate agents for tasks
- Use artifact registry in `/list` to show cross-references between artifacts
- Add registry validation to `/setup` command
- Create registry reporting tools for project health metrics

**Impact**: Enables data-driven planning, improves artifact discoverability, supports project health monitoring.

## References

### Commands
- `/home/benjamin/.config/.claude/commands/README.md` - Command directory overview (880 lines)
- `/home/benjamin/.config/.claude/commands/coordinate.md` - Production orchestrator (2,334 lines)
- `/home/benjamin/.config/.claude/commands/orchestrate.md` - Full-featured orchestrator (5,439 lines)
- `/home/benjamin/.config/.claude/commands/supervise.md` - Minimal orchestrator (1,779 lines)
- `/home/benjamin/.config/.claude/commands/shared/` - 9 shared documentation files

### Agents
- `/home/benjamin/.config/.claude/agents/README.md` - Agent directory overview (686 lines)
- `/home/benjamin/.config/.claude/agents/agent-registry.json` - Complete agent registry (386 lines, 19 agents)
- `/home/benjamin/.config/.claude/agents/research-specialist.md` - Research agent behavioral file (671 lines)
- `/home/benjamin/.config/.claude/agents/shared/` - Shared protocols (3 files)
- `/home/benjamin/.config/.claude/agents/prompts/` - Evaluation prompts (4 files)

### Libraries
- `/home/benjamin/.config/.claude/lib/` - 56 utility libraries
- `/home/benjamin/.config/.claude/lib/agent-registry-utils.sh` - Registry management (100+ lines)
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Location detection
- `/home/benjamin/.config/.claude/lib/plan-core-bundle.sh` - Planning utilities (1,159 lines consolidated)
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` - Logging utilities (717 lines consolidated)

### Documentation
- `/home/benjamin/.config/.claude/docs/README.md` - Documentation index (Diataxis framework)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/README.md` - Pattern catalog (10 patterns)
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` - Complete command catalog
- `/home/benjamin/.config/.claude/docs/reference/agent-reference.md` - Complete agent catalog
- `/home/benjamin/.config/.claude/docs/guides/` - 30 task-focused guides
- `/home/benjamin/.config/.claude/docs/reference/` - 15 reference documents
- `/home/benjamin/.config/.claude/docs/concepts/` - 4 core concepts + patterns
- `/home/benjamin/.config/.claude/docs/workflows/` - 7 workflow tutorials

### Architecture
- `/home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md` - /coordinate architecture
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md` - Multi-level coordination
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` - Artifact organization
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - 11 architecture standards

### Patterns
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` - Agent invocation pattern
- `/home/benjamin/.config/.claude/docs/concepts/patterns/metadata-extraction.md` - 95-99% context reduction
- `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md` - 100% file creation
- `/home/benjamin/.config/.claude/docs/concepts/patterns/parallel-execution.md` - 40-60% time savings
- Plus 6 additional patterns in `/home/benjamin/.config/.claude/docs/concepts/patterns/`

### Registry and Data
- `/home/benjamin/.config/.claude/agents/agent-registry.json` - Agent metadata and metrics
- `/home/benjamin/.config/.claude/agents/agent-registry-schema.json` - Registry schema
- `/home/benjamin/.config/.claude/data/registry/` - Registry data directory
- `/home/benjamin/.config/.claude/data/logs/` - Logging directory
- `/home/benjamin/.config/.claude/data/metrics/` - Metrics data
