# Skills Integration Systematic Refactor Plan

## Plan Metadata
- **Plan ID**: 001_skills_integration_plan
- **Topic**: 075_skills_integration_systematic_refactor
- **Created**: 2025-10-23
- **Revised**: 2025-10-27
- **Status**: Active
- **Complexity**: 4.0/10 (reduced from 6.5/10 based on research findings)
- **Estimated Duration**: 3-5 weeks (reduced from 6-9 weeks)

## Objective
Integrate official Claude Code skills system into existing .claude/ configuration following the model-invoked automatic activation pattern. Skills provide expertise capsules (context-on-demand) while preserving the existing agent orchestration layer for workflow execution. This integration adopts battle-tested external skills before minimal custom development.

## Research Reports
- [Skills System Architecture](../reports/001_skills_system_architecture.md)
- [Claude Config Compliance](../reports/002_claude_config_compliance.md)
- [Documentation Standards](../reports/003_documentation_standards.md)
- [Integration Patterns](../reports/004_integration_patterns.md)
- [Claude Code Skills Documentation Analysis](../../488_research_https_docs_claude_com_en_docs_claude-code_skills_to_see_how_best_to_imp/reports/001_claude_code_skills_analysis.md) - **Official documentation alignment (2025-10-27)**

## Success Criteria
- Official skill format (YAML frontmatter) adopted for all skills
- External skills installed and tested (obra/superpowers, Anthropic document skills)
- 2 custom expertise skills created (code-standards-guidance, testing-protocols-guidance)
- Skills activate automatically via model-invoked pattern (no manual invocation infrastructure)
- Existing agent orchestration layer preserved and functional
- Documentation updated with skills-vs-agents distinction
- Context usage <30% maintained
- All 5 research reports integrated into implementation
- User can review progress at each stage before proceeding

## Risk Assessment
- **Low Risk**: Adopting external skills (obra/superpowers, Anthropic) - battle-tested, zero integration complexity
- **Low Risk**: Official skill format adoption - standard YAML frontmatter pattern
- **Medium Risk**: Skill activation accuracy - depends on description quality and trigger keywords
- **Low Risk**: Context window utilization - progressive disclosure handles this automatically
- **Medium Risk**: Custom skill quality - activation rates depend on well-crafted descriptions

## Complexity Assessment
**Overall Complexity**: 4.0/10

**Complexity Reduction Factors**:
- Eliminated invocation infrastructure (skills activate automatically via model)
- Removed registry system extensions (filesystem discovery suffices)
- Simplified custom skills to expertise-only (no procedural operations)
- No command integration needed (automatic activation)
- Adopts external skills first (zero development time)

**Estimated Duration**: 3-5 weeks

**Revised Phase Duration Breakdown**:
- Phase 0: 1 week (official skill template, validation, CLAUDE.md section)
- Phase 1: 1 week (install obra/superpowers + Anthropic, test activation)
- Phase 2: 1 week (create 2 custom expertise skills)
- Phase 3: 1 week (validation, description tuning, metrics)

**Key Architectural Decisions**:
- **Skills**: Expertise capsules with YAML frontmatter, automatic model-invoked activation
- **Agents**: Workflow orchestrators with behavioral markdown, manual Task tool invocation
- **Separation**: Skills provide knowledge on-demand, agents execute procedures
- **Integration**: Zero-complexity (no command modifications, no invocation wrappers)

## Implementation Phases

### Phase 0: Official Skill Format and Documentation
**Status**: Pending
**Objective**: Create official skill definition template aligned with Claude Code documentation
**Complexity**: 3/10
**Duration**: 1 week

#### Tasks
1. Create official skill definition template in `.claude/templates/skill-definition-template.md`
   - **File Structure**: Directory with `SKILL.md` (required YAML frontmatter)
   - **Required Fields**: `name` (lowercase-with-hyphens), `description` (capability + triggers, max 1024 chars)
   - **Optional Fields**: `allowed-tools` (tool restrictions for security)
   - **Content Type**: Expertise and knowledge (NOT procedural steps)
   - **Sections**: Overview, Expertise Areas, Activation Context, Knowledge Base (patterns/examples/anti-patterns), References
   - **Critical Distinction**: Skills contain descriptive expertise, NOT imperative procedures (no "YOU MUST", "EXECUTE NOW", "STEP 1/2/3")
   - Include comparison table (Skills vs Agents vs Utilities) from research report

2. Create skills README in `.claude/skills/README.md`
   - Document purpose: Expertise capsules for automatic context injection
   - Explain relationship to agents: Skills = knowledge (passive), Agents = workflow execution (active)
   - Activation model: Model-invoked automatic (description-driven triggers)
   - File structure: Flat directory `.claude/skills/{skill-name}/SKILL.md`
   - Tool access: `allowed-tools` restricts what Claude can do WHEN skill is active
   - Link to skills-vs-subagents decision guide

3. Update skills-vs-subagents decision guide (`.claude/docs/guides/skills-vs-subagents-decision.md`)
   - Add "Skills Format and Activation (Official Claude Code)" section
   - Document SKILL.md format (YAML frontmatter + markdown content)
   - Explain model-invoked activation vs manual invocation
   - Add decision criteria: temporal orchestration → agents, expertise on-demand → skills, deterministic logic → utilities
   - Include example skill vs agent distinction

4. Add skills section to CLAUDE.md
   - Define `<!-- SECTION: skills_system -->` with `[Used by: all commands, automatic activation]` metadata
   - List enabled skills by category (Code Quality, Collaboration, Documentation)
   - Explain automatic activation model (no explicit invocation)
   - Link to skills-integration-guide.md

5. Create skill file validation script (`.claude/lib/validate-skill.sh`)
   - Validate YAML frontmatter presence
   - Check required fields: `name`, `description`
   - Verify name format (lowercase-with-hyphens, max 64 chars)
   - Check description length (<1024 chars)
   - Verify SKILL.md filename (not arbitrary markdown files)
   - Extend pre-commit hook to run validation on `.claude/skills/` changes

#### Testing
- Validate template produces valid SKILL.md files
- Test validation script with compliant and non-compliant samples
- Verify README navigation links work correctly
- Test pre-commit hook rejects invalid skills

#### Success Criteria
- Official skill template created following Claude Code standards
- Validation script enforces YAML frontmatter requirements
- Documentation clearly distinguishes skills from agents
- Pre-commit hook validates skill format
- **USER REVIEW CHECKPOINT**: Review official format adoption before proceeding

#### Artifacts Created
- `.claude/templates/skill-definition-template.md` (official YAML format)
- `.claude/skills/README.md` (activation model, file structure)
- `.claude/docs/guides/skills-vs-subagents-decision.md` (extended with official format section)
- `.claude/lib/validate-skill.sh` (YAML frontmatter validation)
- `CLAUDE.md` (skills_system section with automatic activation documentation)

---

### Phase 1: External Skills Installation and Testing
**Status**: Pending
**Objective**: Install obra/superpowers and Anthropic document skills, test automatic activation
**Complexity**: 3/10
**Duration**: 1 week

#### Dependencies
- Phase 0 must be complete
- User approval of official skill format required

#### Rationale for Phase Restructure
Original plan proposed building invocation infrastructure (registry, metadata extraction, invocation wrappers) that contradicts official skills architecture. Skills activate automatically via model-invoked pattern based on description keywords. No manual invocation infrastructure needed. Phase 1 now focuses on adopting battle-tested external skills first.

#### Tasks
1. Install obra/superpowers community skills
   - Run `/plugin marketplace add obra/superpowers-marketplace`
   - Run `/plugin install superpowers@superpowers-marketplace`
   - Verify installation: `/plugin list` and `ls ~/.claude/skills/`
   - Document installed skills (20+ available)

2. Select skills to enable from obra/superpowers
   - **Collaboration**: dispatching-parallel-agents, requesting-code-review, receiving-code-review, using-git-worktrees, subagent-driven-development
   - **Testing**: test-driven-development, condition-based-waiting, testing-anti-patterns
   - **Debugging**: systematic-debugging, root-cause-tracing, verification-before-completion
   - **Meta**: writing-skills, sharing-skills, using-superpowers
   - **Skip**: brainstorming, writing-plans, executing-plans (conflict with /plan and /implement commands)

3. Install Anthropic document skills
   - Run `/plugin install document-skills@anthropic-agent-skills`
   - Verify installation: `/plugin list`
   - Test skills available: docx, pdf, pptx, xlsx

4. Test automatic activation
   - **Code editing test**: Edit .lua file → expect code-related skills to activate
   - **Multi-agent test**: Invoke /orchestrate → expect dispatching-parallel-agents to activate
   - **Document test**: Request PDF conversion → expect pdf skill to activate
   - **Debugging test**: Invoke /debug → expect systematic-debugging to activate
   - Measure dormant token usage (30-50 tokens per skill expected)
   - Measure activated token usage (500-2000 tokens per skill expected)

5. Update CLAUDE.md with enabled skills
   - Add `<!-- SECTION: skills_system -->` section
   - List enabled skills by category (Collaboration, Testing, Debugging, Documentation)
   - Document activation triggers for each skill
   - Explain automatic model-invoked pattern (no manual invocation)
   - Link to `.claude/docs/guides/skills-integration-guide.md`

6. Measure baseline performance
   - Baseline context usage with 0 skills installed
   - Context usage with 25+ skills installed (dormant state)
   - Context usage with 1-3 skills activated
   - Verify <30% context usage maintained
   - Document token savings vs manual standards injection

#### Testing
- Test each skill category independently
- Verify skills activate based on description keywords
- Validate no conflicts with existing commands/agents
- Measure token usage (dormant vs activated)
- Test progressive disclosure (supporting files load on-demand)

#### Success Criteria
- Obra/superpowers and Anthropic skills installed successfully
- Automatic activation verified for 5+ skills
- CLAUDE.md updated with skills documentation
- Context usage <30% maintained with all skills installed
- **USER REVIEW CHECKPOINT**: Review activation behavior and performance before custom skills

#### Artifacts Created
- `CLAUDE.md` (skills_system section with 25+ enabled skills)
- Performance baseline metrics (token usage, activation accuracy)
- Skills activation test results

---

### Phase 2: Custom Expertise Skills
**Status**: Pending
**Objective**: Create 2 project-specific expertise skills (code-standards-guidance, testing-protocols-guidance)
**Complexity**: 4/10
**Duration**: 1 week

#### Dependencies
- Phase 1 must be complete
- User approval of external skills integration required

#### Rationale: Pure Expertise, Not Procedures
Original plan proposed skills with procedural operations ("Read CLAUDE.md", "Detect file type", "Extract standards"). This conflicts with official skills architecture where skills provide knowledge on-demand, not execute operations. Revised approach: Skills contain language-specific patterns, conventions, and examples directly in SKILL.md content.

#### Tasks
1. Create code-standards-guidance skill (`.claude/skills/code-standards-guidance/SKILL.md`)
   - **YAML frontmatter**:
     - `name: code-standards-guidance`
     - `description`: "Provides language-specific code quality guidance aligned with project CLAUDE.md standards. Use when writing or reviewing code, checking naming conventions, error handling patterns, or code organization. Activates for .lua, .py, .js, .sh files and code review tasks."
     - `allowed-tools: Read` (read-only access to CLAUDE.md for standards lookup)

   - **Content sections**:
     - **Overview**: Purpose and scope of code guidance
     - **Expertise Areas**: General principles (indentation, line length, naming, error handling)
     - **Lua Standards**: Module organization, function naming, error handling (pcall), documentation
     - **Bash Standards**: ShellCheck compliance, quoting, error handling (bash -e)
     - **Python Standards**: PEP 8, type hints, docstrings, black formatting
     - **Activation Context**: When skill activates (file editing, code review, naming discussions)
     - **Anti-Patterns**: Common mistakes (emojis, mixing tabs/spaces, unquoted variables)
     - **References**: Links to CLAUDE.md, PEP 8, ShellCheck

2. Create testing-protocols-guidance skill (`.claude/skills/testing-protocols-guidance/SKILL.md`)
   - **YAML frontmatter**:
     - `name: testing-protocols-guidance`
     - `description`: "Provides testing strategy guidance aligned with project CLAUDE.md testing protocols. Use when writing tests, planning test coverage, selecting test frameworks, or debugging test failures. Activates for *_spec.lua, test_*.sh, and test planning discussions."
     - `allowed-tools: Read, Bash` (read CLAUDE.md, run tests for demonstration)

   - **Content sections**:
     - **Overview**: Purpose and scope of testing guidance
     - **Expertise Areas**: Claude Code testing (location, runner, patterns, coverage), Neovim testing (commands, patterns, linting, formatting)
     - **Test Coverage Guidelines**: >80% for new code, public API requirements, critical paths, regression tests
     - **Activation Context**: When skill activates (test writing, coverage planning, debugging failures)
     - **Testing Patterns**: Unit test structure (Lua example), integration test pattern (Bash example)
     - **Anti-Patterns**: Testing implementation details, brittle tests, missing edge cases, no regression tests
     - **References**: Links to CLAUDE.md ## Testing Protocols, .claude/tests/ examples

3. Update CLAUDE.md with skills references
   - Extend `<!-- SECTION: skills_system -->` with custom skills
   - Add Code Quality section listing code-standards-guidance
   - Add Testing section listing testing-protocols-guidance
   - Document activation triggers and use cases
   - Note that systematic-debugging comes from obra/superpowers (no custom debugging skill)

4. Test automatic activation
   - **Code editing test**: Edit .lua file → code-standards-guidance activates with Lua standards
   - **Code review test**: Review Python code → code-standards-guidance activates with PEP 8 guidance
   - **Test writing test**: Create test_*.sh file → testing-protocols-guidance activates
   - **Test planning test**: Discuss coverage strategy → testing-protocols-guidance activates
   - Verify descriptions trigger activation accurately

5. Validate skill portability
   - Test code-standards-guidance on different project (different CLAUDE.md)
   - Verify skill reads project-specific standards dynamically
   - Validate guidance adapts to project standards
   - Confirm no hard-coded project assumptions

#### Testing
- Test each expertise skill independently
- Validate activation accuracy (precision/recall)
- Verify content is expertise (patterns, examples) not procedures (STEP 1/2/3)
- Test skill portability across projects
- Measure token usage (dormant vs activated)

#### Success Criteria
- 2 custom expertise skills created with official YAML format
- Skills contain knowledge content (NOT procedural operations)
- Automatic activation verified for both skills
- Skills portable to other projects with different CLAUDE.md
- CLAUDE.md updated with custom skills references
- **USER REVIEW CHECKPOINT**: Review expertise content quality before validation phase

#### Artifacts Created
- `.claude/skills/code-standards-guidance/SKILL.md` (expertise on code quality, naming, error handling)
- `.claude/skills/testing-protocols-guidance/SKILL.md` (expertise on test strategy, patterns, coverage)
- `CLAUDE.md` (extended skills_system section with custom skills)

---

### Phase 3: Validation, Optimization, and Documentation
**Status**: Pending
**Objective**: Optimize skill descriptions, validate integration, document patterns, capture final metrics
**Complexity**: 3/10
**Duration**: 1 week

#### Dependencies
- Phase 2 must be complete
- User approval of custom expertise skills required

#### Rationale for Phase Simplification
Original plan proposed extensive command integration (updating /implement, /orchestrate, /test-all, /debug) and agent migration. This is unnecessary because skills activate automatically based on context. Commands require ZERO modifications - skills provide supplemental expertise passively when relevant. Phase 3 now focuses solely on validation and documentation.

#### Tasks
1. Optimize skill activation descriptions
   - **Tune descriptions**: Adjust trigger keywords based on observed activation patterns
   - **Add specificity**: Ensure descriptions mention specific file types, use cases, contexts
   - **Test edge cases**: Verify skills don't activate in inappropriate contexts
   - **Measure accuracy**: Calculate activation precision (relevant activations / total activations) and recall (activations / should-activate scenarios)
   - **Target**: ≥70% activation accuracy for all skills

2. Collect comprehensive performance metrics
   - **Baseline (0 skills)**: Token usage for typical workflows
   - **Dormant state (25+ skills)**: Token overhead when skills inactive
   - **Activated state (1-3 skills)**: Token usage when skills provide expertise
   - **Context utilization**: Verify <30% maintained across workflows
   - **Activation frequency**: Track how often each skill activates
   - **Expected findings**: 30-50 tokens per dormant skill, 500-2000 tokens when activated

3. Update skills-vs-subagents decision guide
   - Extend `.claude/docs/guides/skills-vs-subagents-decision.md` with official format section (completed in Phase 0, verify completeness)
   - Add example scenarios: code-standards-guidance (skill) vs implementation-executor (agent) vs topic-utils.sh (utility)
   - Document decision tree: temporal orchestration → agent, expertise on-demand → skill, deterministic logic → utility
   - Include activation model comparison table

4. Create skills integration guide
   - Document: `.claude/docs/guides/skills-integration-guide.md`
   - **Section 1**: Hybrid architecture (skills for expertise, agents for orchestration)
   - **Section 2**: When to create skills (expertise capsules, standards guidance, methodology knowledge)
   - **Section 3**: Official skill format (YAML frontmatter, description guidelines, content structure)
   - **Section 4**: Activation optimization (description specificity, trigger keywords, anti-patterns)
   - **Section 5**: Testing and validation (activation accuracy, portability testing)
   - Reference all 5 research reports

5. Run validation suite
   - **Pre-commit validation**: Test skill file validation script with compliant/non-compliant samples
   - **Timeless writing validation**: Scan all new documentation for temporal markers
   - **Activation validation**: Test all 27+ skills (25 external + 2 custom) activate correctly
   - **Portability validation**: Test custom skills on different project with different CLAUDE.md

6. Document final integration state
   - Update `.claude/docs/concepts/patterns/README.md` with skills integration summary (1 paragraph linking to skills-integration-guide.md)
   - Update `CLAUDE.md` with final enabled skills list (25+ external, 2 custom)
   - Document preservation of agent orchestration layer (no agents replaced, skills augment)
   - Note zero command modifications required (automatic activation)

#### Testing
- Test all skills activate correctly based on descriptions
- Validate custom skills portable across projects
- Verify documentation completeness and navigation
- Measure final performance metrics
- Test pre-commit validation rejects invalid skills

#### Success Criteria
- Skill activation accuracy ≥70% for all skills
- Context usage <30% maintained with all skills installed
- Custom skills portable to other projects
- Complete documentation (integration guide, decision guide updates)
- Validation suite passes (pre-commit, activation, portability)
- Performance metrics captured (baseline, dormant, activated)
- **FINAL USER REVIEW CHECKPOINT**: Review complete integration and metrics before production

#### Artifacts Created
- `.claude/docs/guides/skills-integration-guide.md` (complete integration documentation)
- `.claude/docs/guides/skills-vs-subagents-decision.md` (extended with examples and decision tree)
- `.claude/docs/concepts/patterns/README.md` (skills integration summary paragraph)
- `CLAUDE.md` (final skills_system section with 27+ enabled skills)
- Performance metrics report (token usage, activation accuracy, context utilization)
- Validation test results (activation tests, portability tests)

---

## Implementation Notes

### Preservation Strategy
- **PRESERVE**: All orchestration infrastructure (commands, agents, utilities, behavioral injection)
- **PRESERVE**: Progressive plan structures (L0 → L1 → L2 expansion via plan-structure-manager)
- **PRESERVE**: Adaptive planning (complexity-based replanning)
- **PRESERVE**: Checkpoint recovery (resumable workflows)
- **ADOPT**: External skills (obra/superpowers, Anthropic document skills)
- **CREATE**: 2 custom expertise skills (code-standards-guidance, testing-protocols-guidance)
- **NO REPLACEMENTS**: No agent migration (skills augment, not replace)

### Zero-Integration Complexity
- **Commands**: No modifications required (skills activate automatically)
- **Agents**: No modifications required (skills provide supplemental expertise)
- **Utilities**: No modifications required (skills are passive)
- **Infrastructure**: No invocation wrappers, no registry extensions, no metadata extraction for skills
- **Activation**: Model-invoked automatic based on description keywords

### Context Management Strategy
- **Dormant skills**: 30-50 tokens per skill (25+ skills = 750-1250 tokens = 0.4-0.6%)
- **Activated skills**: 500-2000 tokens per skill (progressive disclosure)
- **Progressive disclosure**: Supporting files (reference.md, examples.md) load only when needed
- **Target maintained**: <30% context usage
- **No manual pruning**: Context efficiency handled automatically by Claude's model

### Risk Mitigation
- **Low-risk external skills first**: Obra/superpowers and Anthropic are battle-tested
- **Minimal custom development**: Only 2 custom skills created
- **User review checkpoints**: 3 checkpoints (Phase 0, Phase 1, Phase 2)
- **Validation testing**: Activation accuracy, portability, performance metrics
- **Rollback strategy**: Uninstall plugins (`/plugin uninstall`), remove `.claude/skills/` directory

### Rollback Strategy
- **Phase 0 rollback**: Remove skill template, validation script, CLAUDE.md section (1 week development time)
- **Phase 1 rollback**: Uninstall external plugins via `/plugin uninstall` (10 minutes)
- **Phase 2 rollback**: Remove custom skill directories (5 minutes)
- **Phase 3 rollback**: Not applicable (validation and documentation only)
- **Full rollback time**: <2 hours to restore pre-skills state

---

## Revision History

### 2025-10-27 - Official Skills Format Alignment
**Changes**: Comprehensive revision based on official Claude Code skills documentation analysis
**Reason**: Original plan conflated skills (expertise capsules) with agents (workflow orchestrators), proposed invocation infrastructure incompatible with official skills architecture
**Research Report**: [Claude Code Skills Documentation Analysis](../../488_research_https_docs_claude_com_en_docs_claude-code_skills_to_see_how_best_to_imp/reports/001_claude_code_skills_analysis.md)

**Critical Misalignments Resolved**:

1. **Activation Model** (CRITICAL):
   - **Before**: Manual invocation via `invoke_skill()` wrapper, behavioral injection pattern
   - **After**: Automatic model-invoked activation based on `description` field keywords
   - **Impact**: Eliminated entire Phase 1 invocation infrastructure (skills-invocation.sh, registry extensions)

2. **File Format** (CRITICAL):
   - **Before**: Agent-style behavioral markdown with enforcement patterns (YOU MUST, EXECUTE NOW, STEP 1/2/3)
   - **After**: Official YAML frontmatter (`name`, `description`, `allowed-tools`) + descriptive expertise content
   - **Impact**: Phase 0 template completely rewritten for official format

3. **Skills vs Agents Distinction** (HIGH):
   - **Before**: Skills described as procedural operations ("Read CLAUDE.md", "Detect file type", "Extract standards")
   - **After**: Skills contain pure expertise (patterns, conventions, examples) - NO procedural operations
   - **Impact**: Phase 2 (formerly Phase 4) custom skills simplified to knowledge-only content

4. **Integration Complexity** (HIGH):
   - **Before**: Extensive command integration (Phase 5), agent migration, behavioral prompt updates
   - **After**: Zero command modifications (automatic activation), zero agent migration
   - **Impact**: Phases 5-6 consolidated into single Phase 3 (validation only)

**Structural Changes**:

1. **Phase Count**: 6 phases → 3 phases
   - **Phase 0**: Documentation foundation → Official skill format and documentation
   - **Phase 1**: Skills registry infrastructure → External skills installation and testing (combined old Phases 1-3)
   - **Phase 2**: Custom meta-level enforcement skills → Custom expertise skills (former Phase 4, revised)
   - **Phase 3**: Validation, optimization, documentation (former Phases 5-6 consolidated, simplified)
   - **Removed**: Phases 2-3 (now part of Phase 1), Phase 5 (command integration unnecessary)

2. **Complexity and Duration**:
   - **Complexity**: 6.5/10 → 4.0/10 (38% reduction)
   - **Duration**: 6-9 weeks → 3-5 weeks (44% reduction)
   - **Rationale**: Eliminated invocation infrastructure, removed command integration, simplified custom skills

3. **Infrastructure Simplification**:
   - **Removed**: skills-invocation.sh, registry extensions, metadata extraction for skills, context pruning for skills
   - **Kept**: validate-skill.sh (YAML format validation only)
   - **Rationale**: Official skills use filesystem discovery and automatic progressive disclosure

**Documentation Updates**:

1. **Objective**: Rewritten to emphasize model-invoked activation and expertise capsules
2. **Success Criteria**: Updated to focus on official format adoption, automatic activation, zero integration complexity
3. **Risk Assessment**: Revised to reflect official skills architecture risks (activation accuracy, skill quality)
4. **Preservation Strategy**: Clarified NO agent migration (skills augment, not replace)
5. **Implementation Notes**: Added "Zero-Integration Complexity" section

**Research Integration**:

- All 5 recommendations from research report implemented
- Official documentation patterns adopted (YAML frontmatter, description-driven activation)
- Skills-vs-agents distinction clarified throughout
- External skills adoption prioritized over custom development
- Skill portability emphasized (project-agnostic expertise)

**No Changes To**:

- Project goals (integrate skills system)
- Preservation strategy (orchestration layer maintained)
- External skills selection (obra/superpowers, Anthropic)
- Validation approach (activation testing, performance metrics)
- User review checkpoints (maintained at each phase boundary)

---

### 2025-10-26 - Compliance Revision
**Changes**: Updated plan to comply with .claude/docs/ writing standards
**Reason**: Align with timeless writing principles and remove temporal markers
**Standards Applied**:
- [Writing Standards](../../docs/concepts/writing-standards.md)
- [Command Architecture Standards](../../docs/reference/command_architecture_standards.md)

**Modifications**:
1. **Metadata**: Updated TBD values (Complexity: 6.5/10, Duration: 6-9 weeks)
2. **Temporal Markers Removed**:
   - "revised from 7.5/10" → "6.5/10"
   - "revised from 8-12 weeks" → "6-9 weeks"
   - "discovered 2025-10-26" → removed, infrastructure described as present state
   - "reduced from 6/10" → removed from phase headers
3. **Present-Tense Descriptions**:
   - "Updated X" → "X (extended with...)" or "X (integrated with...)"
   - All artifact descriptions now use present-state language
4. **Infrastructure Section**: Reframed as current capabilities rather than recent discoveries
5. **Phase Duration**: Converted time reduction notes to positive duration breakdown

**No Functional Changes**: Plan scope, phases, tasks, and technical approach unchanged. Only documentation style updated for standards compliance.
