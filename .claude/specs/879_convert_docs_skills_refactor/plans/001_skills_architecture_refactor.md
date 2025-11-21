# /convert-docs Skills Architecture Refactor Plan

**Plan ID**: 001_skills_architecture_refactor
**Topic**: 879_convert_docs_skills_refactor
**Created**: 2025-11-20
**Complexity**: High (Level 2 with multiple phases)
**Type**: Refactor + Feature Enhancement

---

## Executive Summary

Refactor the `/convert-docs` command infrastructure to implement Claude Code skills pattern, creating a reusable `document-converter` skill that enables autonomous document conversion within agent workflows while maintaining the existing command interface.

**Current State**:
- Command-based document conversion (`.claude/commands/convert-docs.md`)
- Script mode (direct tool invocation) and agent mode (doc-converter subagent)
- Conversion libraries in `.claude/lib/convert/`
- Tool-specific modules (convert-docx.sh, convert-pdf.sh, convert-markdown.sh)

**Target State**:
- Skills-based architecture with `document-converter` skill
- Autonomous invocation capability within agent contexts
- Maintained command compatibility with enhanced skill integration
- Progressive disclosure pattern for optimal token efficiency
- Standards-compliant implementation following all .claude/docs/ patterns

**Success Criteria**:
1. New `.claude/skills/document-converter/` skill created with SKILL.md
2. Skill enables autonomous document conversion when Claude detects conversion needs
3. Existing `/convert-docs` command enhanced to leverage skill infrastructure
4. All conversion tests pass (5 test files in `.claude/tests/`)
5. Documentation updated following project standards
6. Zero regression in conversion quality or performance

---

## Research Findings

### Claude Code Skills Architecture

**Key Characteristics**:
- **Model-invoked**: Claude autonomously decides when to use skill (vs user-invoked slash commands)
- **Progressive disclosure**: Metadata scanned first, full content loaded only when relevant
- **Tool access control**: `allowed-tools` in YAML frontmatter restricts tool usage
- **Composition**: Multiple skills can be used together automatically
- **Scope hierarchy**: Plugin skills > Project skills (.claude/skills/) > Personal skills (~/.claude/skills/)

**Skills vs Commands vs Agents**:
| Aspect | Skills | Slash Commands | Agents |
|--------|--------|-----------------|--------|
| Invocation | Autonomous (model-invoked) | Explicit (`/cmd`) | Explicit (Task delegation) |
| Scope | Single focused capability | Quick shortcuts | Complex orchestration |
| Discovery | Automatic | Manual | Manual delegation |
| Context | Main conversation context | Main conversation | Separate context window |
| Composition | Auto-composition | Manual chaining | Coordinates skills |

**Best Practices**:
1. Keep SKILL.md under 500 lines for token efficiency
2. Write discoverable descriptions (200 char max, include trigger keywords)
3. Test across all target models (Haiku requires more explicit guidance)
4. Use reference.md for detailed documentation
5. Document dependencies and version requirements
6. Focus comments on WHAT code does, not WHY

### Document Conversion Patterns

**Tool Selection Matrix** (from existing implementation):
- **DOCX → Markdown**: MarkItDown (75-80% fidelity) → Pandoc (68% fidelity fallback)
- **PDF → Markdown**: MarkItDown → PyMuPDF4LLM (fast fallback)
- **Markdown → DOCX**: Pandoc (95%+ quality)
- **Markdown → PDF**: Pandoc + Typst → Pandoc + XeLaTeX (fallback)

**Current Infrastructure**:
- `convert-core.sh`: Main orchestration (tool detection, file discovery, validation)
- `convert-docx.sh`: DOCX-specific conversion functions
- `convert-pdf.sh`: PDF-specific conversion functions
- `convert-markdown.sh`: Markdown utilities
- `doc-converter.md`: Agent behavioral guidelines (Haiku 4.5 model)

**Performance Metrics**:
- Script mode: <0.5s overhead
- Agent mode: ~2-3s initialization overhead
- Conversion quality: 75-95% fidelity depending on format

### Project Standards Integration

**Command Authoring Standards** (.claude/docs/reference/standards/command-authoring.md):
- Execution directives required (`**EXECUTE NOW**:`)
- Task tool invocation without code block wrappers
- Subprocess isolation patterns
- State persistence patterns
- Mandatory verification checkpoints

**Code Standards** (.claude/docs/reference/standards/code-standards.md):
- Output suppression patterns (library sourcing with `2>/dev/null`)
- Lazy directory creation (no eager `mkdir -p $RESEARCH_DIR`)
- WHAT not WHY comments
- Error handling with centralized logging
- Single summary line per bash block

**Output Formatting** (.claude/docs/reference/standards/output-formatting.md):
- Suppress success output, preserve error visibility
- Minimize bash block count (target 2-3 blocks per command)
- Single summary line per block
- Console summaries use 4-section format (Summary/Phases/Artifacts/Next Steps)

**Directory Organization** (.claude/docs/concepts/directory-organization.md):
- `.claude/skills/`: Project-level skills (team-shared via git)
- Skills structure: `SKILL.md` (required) + optional reference.md, scripts/, templates/
- Integration with agents via `skills:` YAML field in agent definitions

---

## Architecture Design

### Skill Structure

```
.claude/skills/document-converter/
├── SKILL.md                    # Required: metadata + core instructions
├── reference.md                # Detailed tool documentation and quality metrics
├── examples.md                 # Usage examples and common patterns
├── scripts/
│   ├── convert-core.sh        # Symlink or refactored from lib/convert/
│   ├── convert-docx.sh        # Symlink or refactored from lib/convert/
│   ├── convert-pdf.sh         # Symlink or refactored from lib/convert/
│   ├── convert-markdown.sh    # Symlink or refactored from lib/convert/
│   └── tool-detect.sh         # Tool availability detection
└── templates/
    └── batch-conversion.sh    # Batch processing template
```

### SKILL.md Design (Progressive Disclosure)

**Metadata Section** (always scanned):
```yaml
---
name: document-converter
description: Convert between Markdown, DOCX, and PDF formats bidirectionally. Handles text extraction from PDF/DOCX, markdown to document conversion. Use when converting document formats or extracting structured content from Word or PDF files.
allowed-tools: Bash, Read, Glob, Write
dependencies:
  - pandoc>=2.0
  - python3>=3.8
  - markitdown (optional, recommended)
  - pymupdf4llm (optional, recommended)
model: haiku-4.5
model-justification: Orchestrates external conversion tools with minimal AI reasoning required
fallback-model: sonnet-4.5
---
```

**Core Instructions Section** (loaded when skill is triggered):
- Conversion capabilities overview
- Tool priority matrix
- Batch processing guidance
- Quality considerations
- Progress streaming protocol

**Size Target**: <500 lines (current convert-docs.md is 420 lines - needs optimization)

### Integration Points

**1. Command Enhancement** (`/convert-docs`):
```markdown
## Task

**STEP 1**: Check if document-converter skill is available.

If skill exists, delegate to skill for autonomous handling.
Otherwise, execute existing script/agent mode logic.

**STEP 2**: Invoke skill via natural language delegation...
```

**2. Agent Integration** (`doc-converter.md`):
```yaml
---
name: doc-converter
skills: document-converter
allowed-tools: Read, Grep, Glob, Bash, Write
---
```

Agent automatically loads skill into context when invoked.

**3. Autonomous Usage** (within other workflows):
- Research agent analyzing PDF reports → skill auto-triggers
- Documentation agent converting markdown → skill auto-triggers
- No explicit `/convert-docs` invocation needed

### Migration Strategy

**Option A: Symlinks (Minimal Refactor)**
- Skill scripts/ directory contains symlinks to existing lib/convert/
- Zero code duplication
- Maintains existing lib/ structure
- Quick migration path

**Option B: Move + Update (Full Refactor)**
- Move conversion code from lib/convert/ to skills/document-converter/scripts/
- Update all references in commands/agents
- Cleaner architectural separation
- More invasive changes

**Recommendation**: Start with Option A (symlinks), migrate to Option B after validation.

---

## Implementation Phases

### Phase 1: Skill Infrastructure Creation [COMPLETE]

**Objective**: Create skill directory structure and core documentation

**Tasks**:
1. Create `.claude/skills/document-converter/` directory structure
2. Write SKILL.md with metadata and core instructions (<500 lines)
3. Create reference.md with detailed tool documentation
4. Create examples.md with usage patterns
5. Set up scripts/ directory with symlinks to existing lib/convert/ code
6. Create templates/batch-conversion.sh template

**Deliverables**:
- `.claude/skills/document-converter/SKILL.md`
- `.claude/skills/document-converter/reference.md`
- `.claude/skills/document-converter/examples.md`
- Symlinks in scripts/ directory
- templates/batch-conversion.sh

**Verification**:
- SKILL.md parses correctly (YAML frontmatter valid)
- Description is discoverable (test with fresh Claude instance)
- All symlinks resolve correctly
- Documentation follows project standards

**Dependencies**: None

---

### Phase 2: Command Integration Enhancement [COMPLETE]

**Objective**: Enhance `/convert-docs` command to leverage skill infrastructure

**Tasks**:
1. Add skill availability check to convert-docs.md
2. Implement skill delegation path (when skill available)
3. Maintain fallback to existing script/agent mode
4. Update execution directives following command authoring standards
5. Add verification checkpoint after skill delegation
6. Update command guide documentation

**Deliverables**:
- Updated `.claude/commands/convert-docs.md` with skill integration
- Updated `.claude/docs/guides/commands/convert-docs-command-guide.md`
- Backward compatibility maintained

**Verification**:
- Command works with skill present
- Command works with skill absent (fallback path)
- All execution directives present
- Verification checkpoints in place
- Tests pass (5 test files)

**Dependencies**: Phase 1 complete

---

### Phase 3: Agent Skill Auto-Loading [COMPLETE]

**Objective**: Enable doc-converter agent to auto-load document-converter skill

**Tasks**:
1. Update `.claude/agents/doc-converter.md` frontmatter with `skills: document-converter`
2. Simplify agent behavioral guidelines (skill handles core logic)
3. Update agent to delegate to skill for conversion operations
4. Test agent invocation with skill auto-loading
5. Update agent development documentation

**Deliverables**:
- Updated `.claude/agents/doc-converter.md`
- Simplified agent behavioral guidelines
- Agent leverages skill for core conversion logic

**Verification**:
- Agent successfully loads skill
- Agent delegates to skill for conversions
- No regression in agent mode conversion quality
- Agent mode tests pass

**Dependencies**: Phase 1, Phase 2 complete

---

### Phase 4: Testing and Validation [COMPLETE]

**Objective**: Comprehensive testing across all modes and scenarios

**Tasks**:
1. Run existing test suite (5 test files in `.claude/tests/`)
   - test_convert_docs_concurrency.sh
   - test_convert_docs_edge_cases.sh
   - test_convert_docs_filenames.sh
   - test_convert_docs_parallel.sh
   - test_convert_docs_validation.sh
2. Create skill-specific tests
3. Test skill auto-invocation in agent contexts
4. Test command skill delegation path
5. Test fallback paths (skill unavailable)
6. Performance benchmarking (ensure no regression)
7. Quality validation (conversion fidelity)

**Deliverables**:
- All existing tests passing
- New skill-specific tests in `.claude/tests/`
- Test results documentation
- Performance benchmark report
- Quality validation report

**Verification**:
- 100% test pass rate
- No performance regression (script mode <0.5s overhead maintained)
- No quality regression (75-95% fidelity maintained)
- Skill correctly auto-invokes in agent contexts

**Dependencies**: Phase 1, Phase 2, Phase 3 complete

---

### Phase 5: Documentation and Standards Compliance [COMPLETE]

**Objective**: Complete documentation and ensure full standards compliance

**Tasks**:
1. Create skill guide in `.claude/docs/guides/skills/`
2. Update command reference documentation
3. Add skill to README.md files (skills/, docs/)
4. Create architecture diagram showing skill integration
5. Document migration path for other commands to adopt skills pattern
6. Update CLAUDE.md with skills section (if needed)
7. Create troubleshooting guide for skill-related issues
8. Standards compliance audit

**Deliverables**:
- `.claude/docs/guides/skills/document-converter-skill-guide.md`
- Updated README.md files
- Architecture diagram
- Migration guide for other commands
- Troubleshooting guide
- Standards compliance checklist

**Verification**:
- All documentation follows project standards
- Links validated (no broken links)
- Architecture diagram accurate
- Migration guide actionable
- Standards audit passes

**Dependencies**: Phase 1-4 complete

---

## Risk Assessment

### High Risks

**1. Breaking Existing Workflows**
- **Impact**: Users unable to convert documents
- **Probability**: Medium
- **Mitigation**:
  - Maintain fallback to existing script/agent mode
  - Comprehensive test suite execution before release
  - Feature flag for skill delegation (can be disabled)

**2. Skill Auto-Invocation Failures**
- **Impact**: Skill not triggered when it should be
- **Probability**: Medium
- **Mitigation**:
  - Test description discoverability with fresh Claude instances
  - Iterate on description wording with team
  - Include comprehensive trigger keywords

**3. Performance Regression**
- **Impact**: Slower conversions
- **Probability**: Low
- **Mitigation**:
  - Benchmark before/after
  - Progressive disclosure minimizes token overhead
  - Script mode performance unaffected (bypasses skill)

### Medium Risks

**4. Documentation Drift**
- **Impact**: Outdated docs mislead users
- **Probability**: Medium
- **Mitigation**:
  - Update all docs in Phase 5
  - Link validation script execution
  - Documentation review checkpoint

**5. Test Coverage Gaps**
- **Impact**: Bugs slip through
- **Probability**: Low
- **Mitigation**:
  - Run full existing test suite
  - Create skill-specific tests
  - Test all integration points

### Low Risks

**6. Model Compatibility Issues**
- **Impact**: Skill works on Sonnet but not Haiku
- **Probability**: Low
- **Mitigation**:
  - Test on target models (Haiku 4.5 primary)
  - More explicit guidance for Haiku
  - Fallback model specified (Sonnet 4.5)

---

## Testing Strategy

### Test Categories

**1. Unit Tests**
- Skill YAML parsing
- Tool detection functions
- Conversion function correctness
- Error handling paths

**2. Integration Tests**
- Command → Skill delegation
- Agent → Skill auto-loading
- Skill → Conversion tools
- Fallback path execution

**3. End-to-End Tests**
- Full conversion workflows (all formats)
- Batch processing
- Error scenarios
- Quality validation

**4. Regression Tests**
- Existing test suite (5 files)
- Performance benchmarks
- Conversion quality metrics

**5. Discoverability Tests**
- Fresh Claude instance skill triggering
- Description effectiveness
- Keyword coverage

### Test Execution Plan

**Pre-Implementation**:
1. Run existing test suite to establish baseline
2. Document current pass rate and performance

**During Implementation**:
1. Run relevant tests after each phase
2. Fix failures before proceeding to next phase

**Post-Implementation**:
1. Full test suite execution
2. New skill-specific tests
3. Performance benchmarking
4. Quality validation
5. Discoverability testing

**Acceptance Criteria**:
- 100% test pass rate
- Zero performance regression
- Zero quality regression
- Skill correctly triggers in 90%+ of relevant scenarios

---

## Dependencies

### External Dependencies
- **Pandoc** (>=2.0): Primary conversion tool
- **Python** (>=3.8): For MarkItDown and PyMuPDF4LLM
- **MarkItDown**: Optional, recommended for best quality
- **PyMuPDF4LLM**: Optional, PDF fallback
- **Typst**: Optional, for Markdown→PDF
- **XeLaTeX**: Optional, PDF fallback

### Internal Dependencies
- Existing conversion libraries (`.claude/lib/convert/`)
- Command infrastructure (`.claude/commands/`)
- Agent infrastructure (`.claude/agents/`)
- Testing infrastructure (`.claude/tests/`)
- Documentation standards (`.claude/docs/`)

### Prerequisite Knowledge
- Claude Code skills architecture
- Command authoring patterns
- Agent behavioral injection pattern
- Progressive disclosure pattern
- Project standards (command-authoring, code-standards, output-formatting)

---

## Success Metrics

### Functional Metrics
- [ ] Skill correctly auto-invokes in agent contexts (90%+ success rate)
- [ ] Command skill delegation path works (100% when skill available)
- [ ] Fallback path works (100% when skill unavailable)
- [ ] All conversion formats supported (Markdown ↔ DOCX/PDF)
- [ ] All existing tests pass (5 test files)

### Performance Metrics
- [ ] Script mode overhead <0.5s (no regression)
- [ ] Agent mode overhead ~2-3s (no regression)
- [ ] Token efficiency improved via progressive disclosure
- [ ] Conversion time unchanged

### Quality Metrics
- [ ] DOCX→Markdown fidelity 75-80% (MarkItDown)
- [ ] PDF→Markdown quality maintained
- [ ] Markdown→DOCX quality 95%+ (Pandoc)
- [ ] No conversion quality regression

### Compliance Metrics
- [ ] All command authoring standards followed
- [ ] All code standards followed
- [ ] All output formatting standards followed
- [ ] Documentation standards compliance
- [ ] Zero broken links in documentation

### User Experience Metrics
- [ ] Backward compatibility maintained (existing workflows work)
- [ ] Error messages clear and actionable
- [ ] Documentation comprehensive and accurate
- [ ] Skill description discoverable

---

## Migration Notes

### For Other Commands

This refactor establishes a pattern for migrating other commands to skills:

**Candidates for Skills Migration**:
1. **Research workflows** → `research-specialist` skill
2. **Planning workflows** → `plan-generator` skill
3. **Documentation generation** → `doc-generator` skill
4. **Testing orchestration** → `test-orchestrator` skill

**Migration Template**:
1. Create `.claude/skills/{skill-name}/` structure
2. Write SKILL.md with discoverable description
3. Move/symlink logic to scripts/
4. Enhance command with skill delegation
5. Update agent with `skills:` field
6. Test and document

### Backward Compatibility

**Guarantees**:
- All existing `/convert-docs` invocations work unchanged
- Script mode performance unchanged
- Agent mode quality unchanged
- Fallback path always available

**Breaking Changes**: None (fully backward compatible)

---

## Next Steps After Completion

1. **Evaluate Skills Pattern**: Assess skill auto-invocation effectiveness
2. **Identify Next Candidates**: Choose next command for skills migration
3. **Document Lessons Learned**: Update migration guide with insights
4. **Team Training**: Share skills pattern with development team
5. **Monitor Usage**: Track skill invocation frequency and success rate

---

## References

### Project Documentation
- [Command Authoring Standards](.claude/docs/reference/standards/command-authoring.md)
- [Code Standards](.claude/docs/reference/standards/code-standards.md)
- [Output Formatting Standards](.claude/docs/reference/standards/output-formatting.md)
- [Directory Organization](.claude/docs/concepts/directory-organization.md)
- [Convert-Docs Command Guide](.claude/docs/guides/commands/convert-docs-command-guide.md)

### External Documentation
- [Claude Code Skills Guide](https://code.claude.com/docs/en/skills.md)
- [Skills Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)
- [MarkItDown Documentation](https://github.com/microsoft/markitdown)
- [Pandoc Manual](https://pandoc.org/MANUAL.html)

### Related Files
- `.claude/commands/convert-docs.md` (current implementation)
- `.claude/agents/doc-converter.md` (agent behavioral guidelines)
- `.claude/lib/convert/convert-core.sh` (core conversion logic)
- `.claude/tests/test_convert_docs_*.sh` (existing test suite)

---

## Plan Metadata

**Author**: Claude Code (Sonnet 4.5)
**Review Status**: Pending
**Approval Required**: Yes (significant architectural change)
**Estimated Effort**: 8-12 hours (across 5 phases)
**Priority**: Medium (enhancement, not urgent)
**Impact**: High (establishes pattern for future skills adoption)

---

## Appendix A: SKILL.md Outline

```markdown
---
name: document-converter
description: Convert between Markdown, DOCX, and PDF formats bidirectionally...
allowed-tools: Bash, Read, Glob, Write
dependencies: [pandoc>=2.0, python3>=3.8, markitdown, pymupdf4llm]
model: haiku-4.5
fallback-model: sonnet-4.5
---

# Document Converter Skill

## Core Capabilities
- Bidirectional conversion (Markdown ↔ DOCX/PDF)
- Automatic tool detection and selection
- Cascading fallback mechanisms
- Batch processing support

## Tool Priority Matrix
[Tool selection logic with fidelity metrics]

## Usage Patterns
[Common usage scenarios]

## Quality Considerations
[Fidelity metrics, limitations, edge cases]

## Progress Streaming Protocol
[PROGRESS markers and output format]

## Error Handling
[Error scenarios and recovery strategies]

## See Also
[Links to reference.md, examples.md, project docs]
```

---

## Appendix B: Command Enhancement Pseudocode

```markdown
## Task

**STEP 1**: Check skill availability and determine execution path.

```bash
SKILL_AVAILABLE=false
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/skills/document-converter/SKILL.md" ]; then
  SKILL_AVAILABLE=true
fi
```

**STEP 2**: Execute based on path.

If SKILL_AVAILABLE=true, delegate to skill via natural language:
"Use the document-converter skill to convert files from {input_dir} to {output_dir}"

Otherwise, execute existing script/agent mode logic per current implementation.

**STEP 3**: Verify output regardless of execution path.

[Existing verification checkpoints]
```

---

## Appendix C: Testing Checklist

**Pre-Implementation Baseline**:
- [ ] Run all 5 existing tests, document results
- [ ] Benchmark script mode performance
- [ ] Benchmark agent mode performance
- [ ] Measure conversion quality (sample documents)

**Phase 1 Tests**:
- [ ] SKILL.md YAML parses correctly
- [ ] Symlinks resolve
- [ ] Description discoverable (manual test)

**Phase 2 Tests**:
- [ ] Command works with skill present
- [ ] Command works with skill absent
- [ ] Fallback path executes correctly
- [ ] All execution directives present

**Phase 3 Tests**:
- [ ] Agent loads skill successfully
- [ ] Agent delegates to skill
- [ ] No regression in agent mode

**Phase 4 Tests**:
- [ ] test_convert_docs_concurrency.sh passes
- [ ] test_convert_docs_edge_cases.sh passes
- [ ] test_convert_docs_filenames.sh passes
- [ ] test_convert_docs_parallel.sh passes
- [ ] test_convert_docs_validation.sh passes
- [ ] Skill-specific tests pass
- [ ] Performance benchmarks (no regression)
- [ ] Quality validation (no regression)

**Phase 5 Tests**:
- [ ] Documentation link validation passes
- [ ] Standards compliance audit passes
- [ ] Troubleshooting guide validated

---

## Plan Approval

**Reviewed By**: [Pending]
**Approved By**: [Pending]
**Approval Date**: [Pending]

**Reviewer Comments**:
[Comments from technical review]

**Changes Requested**:
[List of requested changes before approval]

**Final Approval**: [Yes/No]
