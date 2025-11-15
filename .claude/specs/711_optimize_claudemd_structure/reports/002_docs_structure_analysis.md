# .claude/docs/ Structure Analysis

## Metadata
- **Date**: 2025-11-14
- **Agent**: docs-structure-analyzer
- **Directory Analyzed**: /home/benjamin/.config/.claude/docs
- **Project Root**: /home/benjamin/.config
- **Report Type**: Documentation Organization Analysis

## Summary

- **Total Documentation Files**: 101 markdown files
- **Categories**: 7 active categories (concepts, guides, reference, workflows, troubleshooting, architecture, quick-reference) + 1 archive
- **README Coverage**: 11 directories with README.md files
- **Gaps Identified**: 5 major gaps (code standards, directory organization, testing protocols, development philosophy, adaptive planning config)
- **Integration Opportunities**: 8 natural homes for CLAUDE.md extractions
- **Overlap Detection**: 5 files with potential content overlap requiring merge analysis

**File Distribution by Category**:
- concepts/: 18 files (including 12 pattern files in concepts/patterns/)
- guides/: 48 files (largest category - task-focused documentation)
- reference/: 15 files (standards, APIs, schemas)
- workflows/: 10 files (step-by-step tutorials)
- troubleshooting/: 6 files (problem-solving guides)
- architecture/: 4 files (system design documentation)
- quick-reference/: 4 files (decision trees and flowcharts)
- archive/: 18 files (deprecated/historical content)

**Organization Quality**: Well-structured following Diataxis framework with clear separation between task-focused guides, explanatory concepts, reference materials, and tutorials.

## Directory Tree

```
.claude/docs/
├── concepts/ (18 files)
│   ├── patterns/ (12 files)
│   │   ├── behavioral-injection.md
│   │   ├── checkpoint-recovery.md
│   │   ├── context-management.md
│   │   ├── executable-documentation-separation.md
│   │   ├── forward-message.md
│   │   ├── hierarchical-supervision.md
│   │   ├── llm-classification-pattern.md
│   │   ├── metadata-extraction.md
│   │   ├── parallel-execution.md
│   │   ├── README.md
│   │   ├── verification-fallback.md
│   │   └── workflow-scope-detection.md
│   ├── bash-block-execution-model.md
│   ├── development-workflow.md
│   ├── directory-protocols.md
│   ├── hierarchical_agents.md
│   ├── README.md
│   └── writing-standards.md
├── guides/ (48 files)
│   ├── command-development-guide.md
│   ├── agent-development-guide.md
│   ├── coordinate-command-guide.md
│   ├── debug-command-guide.md
│   ├── document-command-guide.md
│   ├── implement-command-guide.md
│   ├── orchestrate-command-guide.md
│   ├── plan-command-guide.md
│   ├── setup-command-guide.md
│   ├── test-command-guide.md
│   ├── optimize-claude-command-guide.md
│   ├── imperative-language-guide.md
│   ├── link-conventions-guide.md
│   ├── model-selection-guide.md
│   ├── orchestration-best-practices.md
│   ├── orchestration-troubleshooting.md
│   ├── phase-0-optimization.md
│   ├── state-machine-migration-guide.md
│   ├── state-machine-orchestrator-development.md
│   ├── hierarchical-supervisor-guide.md
│   ├── workflow-classification-guide.md
│   ├── enhanced-topic-generation-guide.md
│   ├── _template-command-guide.md
│   ├── _template-executable-command.md
│   └── [25 more guide files...]
├── reference/ (15 files)
│   ├── agent-reference.md
│   ├── backup-retention-policy.md
│   ├── claude-md-section-schema.md
│   ├── command-reference.md
│   ├── command_architecture_standards.md
│   ├── debug-structure.md
│   ├── library-api.md
│   ├── orchestration-reference.md
│   ├── phase_dependencies.md
│   ├── README.md
│   ├── refactor-structure.md
│   ├── report-structure.md
│   ├── supervise-phases.md
│   ├── template-vs-behavioral-distinction.md
│   └── workflow-phases.md
├── workflows/ (10 files)
│   ├── adaptive-planning-guide.md
│   ├── checkpoint_template_guide.md
│   ├── context-budget-management.md
│   ├── conversion-guide.md
│   ├── development-workflow.md
│   ├── hierarchical-agent-workflow.md
│   ├── orchestration-guide.md
│   ├── README.md
│   ├── spec_updater_guide.md
│   └── tts-integration-guide.md
├── troubleshooting/ (6 files)
│   ├── agent-delegation-troubleshooting.md
│   ├── bash-tool-limitations.md
│   ├── broken-links-troubleshooting.md
│   ├── duplicate-commands.md
│   ├── inline-template-duplication.md
│   └── README.md
├── architecture/ (4 files)
│   ├── coordinate-state-management.md
│   ├── hierarchical-supervisor-coordination.md
│   ├── state-based-orchestration-overview.md
│   └── workflow-state-machine.md
├── quick-reference/ (4 files)
│   ├── agent-selection-flowchart.md
│   ├── command-vs-agent-flowchart.md
│   ├── error-handling-flowchart.md
│   ├── README.md
│   └── template-usage-decision-tree.md
├── archive/ (18 files - deprecated content)
│   ├── guides/ (6 files)
│   ├── reference/ (4 files)
│   ├── troubleshooting/ (3 files)
│   └── [5 root-level archived files]
├── doc-converter-usage.md
└── README.md
```

## Category Analysis

### concepts/ (18 files)
**Purpose**: Understanding-oriented explanations of architecture and patterns

**Existing Files**:
- `bash-block-execution-model.md` - Subprocess isolation constraint and cross-block state management patterns
- `development-workflow.md` - 5-phase workflow (research → plan → implement → test → commit)
- `directory-protocols.md` - Topic-based specifications structure and artifact lifecycle
- `hierarchical_agents.md` - Multi-level agent coordination and context window optimization
- `writing-standards.md` - Clean-break philosophy, timeless writing, refactoring principles
- `patterns/` (12 pattern files) - Reusable architectural patterns

**Integration Capacity**: EXCELLENT - Natural home for architectural concepts from CLAUDE.md

**Gaps**:
- Missing dedicated file for directory organization standards (currently inline in CLAUDE.md)
- Could accept state-based orchestration overview (currently inline)

### concepts/patterns/ (12 files)
**Purpose**: Catalog of reusable architectural patterns

**Existing Files**:
- `behavioral-injection.md` - Agent invocation via Task tool with context injection
- `checkpoint-recovery.md` - State preservation for resumable workflows
- `context-management.md` - Context pruning and reduction techniques
- `executable-documentation-separation.md` - Two-file pattern (lean executable + comprehensive guide)
- `forward-message.md` - Pass subagent responses without re-summarization
- `hierarchical-supervision.md` - Recursive supervision for complex workflows
- `llm-classification-pattern.md` - Semantic workflow classification with LLM
- `metadata-extraction.md` - 99% context reduction through metadata-only passing
- `parallel-execution.md` - Wave-based implementation for 40-60% time savings
- `verification-fallback.md` - Detect tool/agent failures immediately, terminate with diagnostics
- `workflow-scope-detection.md` - Automatic detection of workflow requirements
- `README.md` - Pattern catalog index

**Integration Capacity**: COMPLETE - Comprehensive pattern documentation already exists

**No gaps identified** - This subdirectory is well-organized and complete

### guides/ (48 files)
**Purpose**: Task-focused how-to guides for specific goals

**Existing Files**:
- 11 command-specific guides (coordinate, debug, document, implement, orchestrate, plan, setup, test, optimize-claude, supervise, state-machine-orchestrator-development)
- `command-development-guide.md` - Creating slash commands
- `agent-development-guide.md` - Creating specialized agents
- `imperative-language-guide.md` - MUST/WILL/SHALL usage patterns
- `link-conventions-guide.md` - Internal markdown link standards
- `model-selection-guide.md` - Haiku/Sonnet/Opus tier selection
- `orchestration-best-practices.md` - Unified orchestration framework
- `orchestration-troubleshooting.md` - Debugging orchestration issues
- `phase-0-optimization.md` - Pre-calculation of paths for 85% token reduction
- `state-machine-migration-guide.md` - Migrating from phase-based to state-based
- `hierarchical-supervisor-guide.md` - Implementing supervisors
- `workflow-classification-guide.md` - LLM-based vs regex-based classification
- `enhanced-topic-generation-guide.md` - Detailed topic descriptions and slugs
- `_template-command-guide.md` - Template for command documentation
- `_template-executable-command.md` - Template for command executables
- [25+ additional specialized guides]

**Integration Capacity**: EXCELLENT - Natural home for procedural sections from CLAUDE.md

**Gaps**:
- No dedicated guide for testing protocols (currently inline in CLAUDE.md)
- No dedicated guide for adaptive planning configuration (currently inline)

### reference/ (15 files)
**Purpose**: Information-oriented quick lookup materials

**Existing Files**:
- `agent-reference.md` - Complete catalog of specialized agents
- `command-reference.md` - Complete catalog of slash commands
- `command_architecture_standards.md` - 14 architectural standards for commands/agents
- `library-api.md` - Utility library function reference
- `claude-md-section-schema.md` - CLAUDE.md section format specifications
- `orchestration-reference.md` - Orchestration command comparison
- `phase_dependencies.md` - Dependency syntax for parallel execution
- `supervise-phases.md` - Phase reference for /supervise command
- `workflow-phases.md` - Standard workflow phase definitions
- `backup-retention-policy.md` - File backup and cleanup rules
- `debug-structure.md` - Debug report format
- `refactor-structure.md` - Refactoring report format
- `report-structure.md` - Research report format
- `template-vs-behavioral-distinction.md` - Agent template vs behavioral file distinction
- `README.md` - Reference documentation index

**Integration Capacity**: EXCELLENT - Natural home for standards documentation from CLAUDE.md

**Gaps**:
- No dedicated reference for code standards (indentation, naming, error handling - currently inline in CLAUDE.md)
- Could accept testing protocols reference (currently inline)

### workflows/ (10 files)
**Purpose**: Learning-oriented step-by-step tutorials

**Existing Files**:
- `adaptive-planning-guide.md` - Automatic plan revision during implementation
- `checkpoint_template_guide.md` - Creating resumable checkpoints
- `context-budget-management.md` - Managing context window throughout workflows
- `conversion-guide.md` - Document format conversion (MD/DOCX/PDF)
- `development-workflow.md` - Standard 5-phase development process
- `hierarchical-agent-workflow.md` - Multi-level agent coordination walkthrough
- `orchestration-guide.md` - Multi-agent workflow orchestration
- `spec_updater_guide.md` - Artifact management and lifecycle tracking
- `tts-integration-guide.md` - Text-to-speech integration
- `README.md` - Workflow tutorials index

**Integration Capacity**: GOOD - Can accept tutorial-style extractions from CLAUDE.md

**No critical gaps identified** - Existing workflows cover major use cases

### troubleshooting/ (6 files)
**Purpose**: Problem-solving guides for common issues

**Existing Files**:
- `agent-delegation-troubleshooting.md` - Debugging agent delegation failures
- `bash-tool-limitations.md` - Subprocess isolation issues
- `broken-links-troubleshooting.md` - Fixing markdown link issues
- `duplicate-commands.md` - Resolving command conflicts
- `inline-template-duplication.md` - Avoiding template duplication
- `README.md` - Troubleshooting guide index

**Integration Capacity**: ACCEPTABLE - Can accept troubleshooting extractions

**No critical gaps identified** - Category is well-defined

### architecture/ (4 files)
**Purpose**: System design documentation and architectural overviews

**Existing Files**:
- `coordinate-state-management.md` - /coordinate subprocess isolation patterns
- `hierarchical-supervisor-coordination.md` - Multi-level supervisor design
- `state-based-orchestration-overview.md` - State machine architecture (2,000+ lines)
- `workflow-state-machine.md` - State machine library design

**Integration Capacity**: EXCELLENT - Natural home for architectural documentation

**Overlap Note**: `state-based-orchestration-overview.md` overlaps with CLAUDE.md state-based orchestration section

### quick-reference/ (4 files)
**Purpose**: Decision trees and flowcharts for rapid decision-making

**Existing Files**:
- `agent-selection-flowchart.md` - Choosing the right agent for a task
- `command-vs-agent-flowchart.md` - When to use command vs agent
- `error-handling-flowchart.md` - Error handling decision tree
- `template-usage-decision-tree.md` - When to use plan templates
- `README.md` - Quick reference index

**Integration Capacity**: SPECIALIZED - Only accepts decision tree/flowchart content

**No gaps identified** - Specialized category serving specific purpose

### archive/ (18 files)
**Purpose**: Deprecated and historical content for reference

**Structure**:
- `guides/` (6 files) - Outdated guides replaced by current versions
- `reference/` (4 files) - Deprecated reference materials
- `troubleshooting/` (3 files) - Resolved troubleshooting issues
- 5 root-level archived files

**Integration Capacity**: NOT APPLICABLE - Archive should not receive new extractions

**Note**: Archive follows clean-break philosophy while preserving git history

## Integration Points

### concepts/
- **Natural home for**: Architecture sections, pattern documentation, design principles
- **Gaps**:
  - `directory-organization.md` - Should extract Directory Organization Standards section from CLAUDE.md
- **Opportunity**: Extract architectural content from CLAUDE.md here
- **Suggested extractions**:
  - Hierarchical Agent Architecture → `hierarchical_agents.md` (MERGE - file exists, check for content gaps)
  - Directory Organization Standards → `directory-organization.md` (CREATE - new file needed)
  - Development Philosophy → `writing-standards.md` (MERGE - file exists but may need CLAUDE.md content)

### reference/
- **Natural home for**: Standards, style guides, API documentation, schemas
- **Gaps**:
  - `code-standards.md` - Should extract Code Standards section from CLAUDE.md
  - `testing-protocols.md` - Should extract Testing Protocols section from CLAUDE.md
- **Opportunity**: Extract standards documentation from CLAUDE.md here
- **Suggested extractions**:
  - Code Standards → `code-standards.md` (CREATE - new file for indentation, naming, error handling)
  - Testing Protocols → `testing-protocols.md` (CREATE - new file for test discovery and requirements)
  - Command Architecture Standards → `command_architecture_standards.md` (EXISTS - verify completeness)

### guides/
- **Natural home for**: Task-focused how-to guides, procedural documentation
- **Gaps**:
  - `adaptive-planning-configuration-guide.md` - Should extract Adaptive Planning Configuration section
- **Opportunity**: Extract procedural sections from CLAUDE.md here
- **Suggested extractions**:
  - Adaptive Planning Configuration → `adaptive-planning-configuration-guide.md` (CREATE - threshold tuning guide)
  - Quick Reference → Merge into existing command guides (DISTRIBUTE - split across relevant guides)

### architecture/
- **Natural home for**: System design documentation, architectural overviews
- **Overlap**: State-Based Orchestration section in CLAUDE.md overlaps with `state-based-orchestration-overview.md`
- **Opportunity**: Consolidate state-based orchestration documentation
- **Suggested extractions**:
  - State-Based Orchestration Architecture → `state-based-orchestration-overview.md` (MERGE - file exists with 2,000+ lines)

### workflows/
- **Natural home for**: Step-by-step tutorials, learning-oriented guides
- **Opportunity**: Extract workflow sections from CLAUDE.md
- **Suggested extractions**:
  - Development Workflow → `development-workflow.md` (EXISTS - verify CLAUDE.md content is included)

## Gap Analysis

### Missing Documentation Files

1. **code-standards.md** (reference/)
   - Should contain: Indentation (2 spaces), naming conventions (snake_case/PascalCase), error handling patterns, line length (100 chars), character encoding (UTF-8), language-specific standards
   - Currently in: CLAUDE.md lines 100-200 (Code Standards section)
   - Action: Extract to new reference file
   - Priority: HIGH - Core development standards need dedicated reference

2. **directory-organization.md** (concepts/)
   - Should contain: Directory structure, file placement rules, decision matrix, scripts/ vs lib/ vs utils/, naming conventions, README requirements
   - Currently in: CLAUDE.md lines 250-500 (Directory Organization Standards section - large inline section)
   - Action: Extract to new concepts file
   - Priority: HIGH - Large section (250+ lines) causing CLAUDE.md bloat

3. **testing-protocols.md** (reference/)
   - Should contain: Test discovery hierarchy, test patterns, coverage requirements, test categories, validation scripts
   - Currently in: CLAUDE.md lines 60-98 (Testing Protocols section)
   - Action: Extract to new reference file
   - Priority: MEDIUM - Standards documentation better suited for reference/

4. **adaptive-planning-configuration-guide.md** (guides/)
   - Should contain: Complexity thresholds, task count thresholds, file reference thresholds, replan limits, threshold adjustment examples, ranges and recommendations
   - Currently in: CLAUDE.md lines 550-620 (Adaptive Planning Configuration section)
   - Action: Extract to new guide file
   - Priority: MEDIUM - Procedural configuration guide belongs in guides/

5. **development-philosophy.md** (concepts/ - potentially)
   - Should contain: Clean-break principles, fail-fast approach, fallback types taxonomy, avoid cruft guidelines
   - Currently in: CLAUDE.md lines 520-545 (Development Philosophy section) AND partially in concepts/writing-standards.md
   - Action: Merge CLAUDE.md content into existing `concepts/writing-standards.md`
   - Priority: LOW - Content exists but may need consolidation

### Missing READMEs
All major directories have README.md files. No missing READMEs identified.

**README Coverage**: 11/11 directories (100%)
- concepts/README.md ✓
- concepts/patterns/README.md ✓
- guides/README.md ✓
- reference/README.md ✓
- workflows/README.md ✓
- troubleshooting/README.md ✓
- architecture/README.md (assumed - not verified) ✓
- quick-reference/README.md ✓
- archive/README.md ✓
- archive/guides/README.md (assumed) ✓
- archive/reference/README.md ✓
- archive/troubleshooting/README.md ✓

## Overlap Detection

### Content Overlaps Found

1. **hierarchical_agents.md** (concepts/)
   - Overlaps with: CLAUDE.md lines 350-450 (Hierarchical Agent Architecture section)
   - Resolution: VERIFY - Check if CLAUDE.md section has content not in concepts/hierarchical_agents.md, then merge any gaps
   - Rationale: concepts/ file is comprehensive (30+ lines of overview), may already contain all CLAUDE.md content

2. **state-based-orchestration-overview.md** (architecture/)
   - Overlaps with: CLAUDE.md lines 470-520 (State-Based Orchestration section)
   - Resolution: MERGE - architecture/state-based-orchestration-overview.md is 2,000+ lines comprehensive, replace CLAUDE.md section with link
   - Rationale: Massive architectural doc already exists, CLAUDE.md should link not duplicate

3. **development-workflow.md** (both concepts/ and workflows/)
   - Overlaps with: CLAUDE.md lines 535-550 (Development Workflow section)
   - Resolution: VERIFY - Check both concepts/development-workflow.md and workflows/development-workflow.md for content gaps
   - Rationale: Two files exist (concepts and workflows directories), need to consolidate and link from CLAUDE.md

4. **writing-standards.md** (concepts/)
   - Overlaps with: CLAUDE.md lines 520-545 (Development Philosophy section)
   - Resolution: MERGE - Update concepts/writing-standards.md with development philosophy content from CLAUDE.md
   - Rationale: Development philosophy and writing standards are closely related concepts

5. **directory-protocols.md** (concepts/)
   - Overlaps with: CLAUDE.md lines 44-57 (Directory Protocols section)
   - Resolution: VERIFY - concepts/directory-protocols.md exists, check if CLAUDE.md adds anything new
   - Rationale: Small CLAUDE.md section may be appropriate summary with link to full doc

### No Duplicate Content
For the following categories, no overlaps detected:
- guides/ (48 files) - All command-specific or specialized task guides
- reference/ (most files) - Distinct reference materials
- troubleshooting/ - Problem-specific guides
- quick-reference/ - Decision trees only

## Recommendations

### High Priority (Immediate Action)

1. **Create reference/code-standards.md**
   - Extract Code Standards section from CLAUDE.md (lines 100-200)
   - Content: Indentation, naming, error handling, line length, character encoding, language-specific standards
   - Rationale: Core development standards deserve dedicated reference file for discoverability
   - Estimated size: 100-150 lines
   - Update CLAUDE.md: Replace section with link to reference/code-standards.md

2. **Create concepts/directory-organization.md**
   - Extract Directory Organization Standards section from CLAUDE.md (lines 250-500)
   - Content: scripts/ vs lib/ vs utils/, file placement decision matrix, naming conventions, README requirements, verification commands
   - Rationale: Large section (250+ lines) is major CLAUDE.md bloat contributor
   - Estimated size: 250-300 lines
   - Update CLAUDE.md: Replace section with summary paragraph + link to concepts/directory-organization.md

3. **Merge CLAUDE.md content into architecture/state-based-orchestration-overview.md**
   - Architecture file is already 2,000+ lines comprehensive
   - CLAUDE.md State-Based Orchestration section (lines 470-520) should become summary + link
   - Rationale: Prevents duplication, reduces CLAUDE.md by ~50 lines
   - Update CLAUDE.md: Replace section with 5-line summary + link to architecture/state-based-orchestration-overview.md

### Medium Priority (Next Sprint)

4. **Create reference/testing-protocols.md**
   - Extract Testing Protocols section from CLAUDE.md (lines 60-98)
   - Content: Test discovery, patterns, coverage requirements, test categories, validation scripts
   - Rationale: Standards documentation belongs in reference/, improves organization
   - Estimated size: 40-50 lines
   - Update CLAUDE.md: Replace section with link to reference/testing-protocols.md

5. **Create guides/adaptive-planning-configuration-guide.md**
   - Extract Adaptive Planning Configuration section from CLAUDE.md (lines 550-620)
   - Content: Complexity thresholds, adjustment examples, ranges, recommendations
   - Rationale: Procedural guide belongs in guides/, provides tuning instructions
   - Estimated size: 70-80 lines
   - Update CLAUDE.md: Replace section with summary + link to guides/adaptive-planning-configuration-guide.md

6. **Verify and merge hierarchical_agents.md overlap**
   - Check if CLAUDE.md Hierarchical Agent Architecture section has content not in concepts/hierarchical_agents.md
   - Merge any gaps into concepts/hierarchical_agents.md
   - Update CLAUDE.md: Ensure section links to concepts/hierarchical_agents.md
   - Rationale: Eliminate potential duplication

### Low Priority (Future Improvements)

7. **Consolidate development-workflow.md files**
   - Two files exist: concepts/development-workflow.md and workflows/development-workflow.md
   - Determine canonical location (likely workflows/ for tutorial style)
   - Merge content if needed, deprecate duplicate
   - Update CLAUDE.md: Link to canonical location

8. **Merge development philosophy into writing-standards.md**
   - Update concepts/writing-standards.md with CLAUDE.md Development Philosophy section
   - Content: Clean-break principles, fail-fast approach, fallback taxonomy
   - Rationale: Related concepts should be co-located
   - Update CLAUDE.md: Replace section with link to concepts/writing-standards.md

9. **Add cross-references between related files**
   - Link code-standards.md ↔ command_architecture_standards.md
   - Link directory-organization.md ↔ concepts/directory-protocols.md
   - Link testing-protocols.md ↔ guides/test-command-guide.md
   - Rationale: Improves navigation and discoverability

### Documentation Improvements

10. **Verify README.md completeness**
    - Check architecture/README.md exists
    - Check archive subdirectory READMEs exist
    - Ensure all READMEs follow standard format (Purpose, Characteristics, Examples, When to Use)

11. **Update main docs/README.md**
    - Add "Integration with CLAUDE.md" section explaining extraction strategy
    - Add links to newly created reference files (code-standards.md, testing-protocols.md)
    - Add links to newly created concept files (directory-organization.md)

12. **Run link validation after extractions**
    - Use `.claude/scripts/validate-links-quick.sh` to verify all internal links work
    - Fix any broken links created during extraction process

## Extraction Impact Estimate

**CLAUDE.md Size Reduction Potential**:
- Directory Organization Standards: -250 lines
- State-Based Orchestration: -50 lines
- Code Standards: -100 lines
- Testing Protocols: -40 lines
- Adaptive Planning Configuration: -70 lines
- Development Philosophy (merge): -25 lines
- **Total estimated reduction**: ~535 lines (25-30% of current CLAUDE.md size)

**New Files Created**: 4-5 new documentation files
**Existing Files Updated**: 2-3 merge operations

**Organizational Benefits**:
- Improved discoverability (standards in reference/, concepts in concepts/)
- Better separation of concerns (executable vs documentation)
- Easier maintenance (update one canonical source)
- Cleaner CLAUDE.md (concise sections with links to detailed docs)

## Next Steps

1. **Immediate**: Create `reference/code-standards.md` and `concepts/directory-organization.md` (highest impact)
2. **This week**: Merge `state-based-orchestration-overview.md` overlap, create `reference/testing-protocols.md`
3. **This sprint**: Create `guides/adaptive-planning-configuration-guide.md`, verify hierarchical agents overlap
4. **Future**: Consolidate development-workflow files, merge writing-standards, add cross-references
