# Documentation Accuracy Analyzer Agent Guide

Complete guide to using the docs-accuracy-analyzer agent for semantic documentation quality analysis.

**Related Files**:
- Behavioral: [.claude/agents/docs-accuracy-analyzer.md](../../agents/docs-accuracy-analyzer.md)
- Workflow: [/optimize-claude Command](../../../.claude/commands/optimize-claude.md)
- Library: [metadata-extraction.sh](../../lib/workflow/metadata-extraction.sh)

---

## 1. Architecture

### Purpose
The docs-accuracy-analyzer performs semantic documentation quality analysis using Opus 4.5, evaluating six quality dimensions to identify errors, gaps, and improvement opportunities.

### Model Selection
- **Primary**: Opus 4.5 (semantic understanding, nuanced quality assessment)
- **Fallback**: Sonnet 4.5
- **Justification**: High-quality semantic analysis required for accuracy detection, completeness evaluation, consistency analysis across conceptual boundaries

### Integration Points
```
/optimize-claude Workflow:
  Phase 1: Research (claude-md-analyzer, docs-structure-analyzer)
  Phase 2: Parallel Analysis
    ├─ docs-bloat-analyzer (bloat detection)
    └─ docs-accuracy-analyzer (quality evaluation) ← THIS AGENT
  Phase 3: Planning (cleanup-plan-architect receives both reports)
```

### Execution Model
6-step process with fail-fast checkpoints:
1. Receive and verify input paths (CLAUDE_MD_REPORT_PATH, DOCS_REPORT_PATH, ACCURACY_REPORT_PATH)
2. Ensure parent directory exists (lazy creation)
3. Create report file FIRST with template structure
4. Read research reports
5. Perform semantic accuracy analysis
6. Verify and signal completion

---

## 2. Quality Dimensions

### Dimension 1: Accuracy
**Definition**: Error-free technical content, verified implementation state

**Detection Methods**:
- Grep for technical claims in documentation
- Cross-reference claims with actual code (Read tool)
- Detect semantic mismatches (claim vs implementation)
- Flag outdated terminology and deprecated patterns

**Output**: Error inventory table
```markdown
| File Path | Line | Error | Correction |
|-----------|------|-------|------------|
| guide.md | 45 | References `old_func()` | Update to `new_func()` |
```

### Dimension 2: Completeness
**Definition**: Comprehensive coverage without gaps

**Detection Methods**:
- Build required documentation matrix:
  - commands/*.md → guides/*-command-guide.md
  - agents/*.md → reference/standards/agent-reference.md entries
  - concepts/patterns/*.md → README.md descriptions
- Calculate completeness percentage (actual/required)
- Identify missing high-priority documentation
- Prioritize gaps by architectural impact

**Output**: Gap analysis with completeness metrics
```markdown
| Category | Required | Actual | Completeness |
|----------|----------|--------|--------------|
| Command Guides | 20 | 18 | 90% |
```

### Dimension 3: Consistency
**Definition**: Uniform terminology, formatting, structure

**Detection Methods**:
- Extract domain concepts from all docs
- Identify semantic clusters (terminology variations)
- Flag inconsistencies (>3 variants for same concept)
- Check markdown structure (heading hierarchy, list formatting)
- Validate code fence language tags
- Verify cross-reference format (relative paths, anchors)

**Output**: Terminology variance table with standardization recommendations

### Dimension 4: Timeliness
**Definition**: Current information, no outdated content

**Detection Methods**:
- Grep for banned temporal patterns: "(New)", "(Old)", "previously", "recently", "now supports"
- Detect version references: "v1.0", "since version"
- Flag migration language: "migration from", "backward compatibility"
- Search for deprecated function references
- Identify obsolete architectural patterns

**Output**: Temporal violations with timeless rewrites
```markdown
| File | Line | Pattern | Timeless Rewrite |
|------|------|---------|------------------|
| setup.md | 23 | "recently added" | "provides feature X" |
```

### Dimension 5: Usability
**Definition**: Navigable, readable, accessible

**Detection Methods**:
- Scan for broken internal links
- Validate link targets exist
- Check for missing cross-references
- Identify orphaned files (not referenced anywhere)
- Validate navigation structure (README.md completeness)

**Output**: Broken links inventory, navigation improvements

### Dimension 6: Clarity
**Definition**: Concise writing, readable prose

**Detection Methods**:
- Analyze section complexity (task count, subsection depth)
- Estimate sentence length and paragraph density
- Note sections requiring simplification
- Flag overly complex or overly simple sections

**Output**: Clarity improvement recommendations

---

## 3. Evaluation Algorithm

### Accuracy Detection Process
```
For each documentation file:
  1. Extract technical claims and API references (Grep)
  2. Cross-reference with actual code (Read, Grep tools)
  3. Detect semantic mismatches using Opus understanding
  4. Flag outdated terminology (old function names)
  5. Verify file paths and line number references
  6. Generate correction recommendations
```

### Completeness Assessment Process
```
Build documentation matrix:
  commands/*.md → guides/*-command-guide.md
  agents/*.md → reference/standards/agent-reference.md
  patterns/*.md → README.md descriptions

For each category:
  1. Count required vs actual documentation
  2. Calculate completeness percentage
  3. Identify missing high-priority items
  4. Prioritize by architectural impact
```

### Consistency Evaluation Process
```
Terminology analysis (Opus semantic understanding):
  1. Extract domain concepts from all docs
  2. Identify semantic clusters (variations)
  3. Flag inconsistencies (>3 variants)
  4. Recommend canonical terms

Formatting validation (rule-based):
  1. Check markdown structure
  2. Validate code fence tags
  3. Verify cross-reference format
  4. Detect style violations
```

---

## 4. Report Structure

### Section 1: Metadata
- Date, analyzer name, model
- Input report paths (CLAUDE.md analysis, docs structure)
- References to bloat analysis report

### Section 2: Executive Summary
2-3 sentences with key statistics:
- Error count, gap count, violation count
- Overall completeness percentage
- Immediate action items

### Section 3: Current Accuracy State
- **Error Inventory**: file:line:error:correction table
- **Outdated Content**: deprecated patterns, old versions
- **Inconsistencies**: terminology variance

### Section 4: Completeness Analysis
- **Required Documentation Matrix**: category completeness percentages
- **Gap Analysis**: missing documentation identified
- **Missing High-Priority**: prioritized list

### Section 5: Consistency Evaluation
- **Terminology Variance**: concept variations table
- **Formatting Violations**: style guide violations
- **Structural Inconsistencies**: heading hierarchy issues

### Section 6: Timeliness Assessment
- **Temporal Pattern Violations**: banned phrases with rewrites
- **Deprecated Patterns**: old function/pattern references
- **Timeless Writing Recommendations**: specific fixes

### Section 7: Usability Analysis
- **Broken Links**: file:target inventory
- **Navigation Issues**: README gaps, missing cross-refs
- **Orphaned Files**: unreferenced files

### Section 8: Clarity Assessment
- **Readability Issues**: sections needing simplification
- **Section Complexity**: overly complex sections flagged

### Section 9: Quality Improvement Recommendations
Implementation-ready recommendations with:
- File paths and line numbers
- Specific corrections
- Priority levels (critical/important/nice-to-have)

### Section 10: Documentation Optimization Recommendations
Specific recommendations for revising/removing/combining documentation based on bloat analysis findings.

### Completion Signal
```
REPORT_CREATED: /absolute/path/to/accuracy_report.md
```

---

## 5. Integration Patterns

### Workflow Integration (/optimize-claude)

**Phase 1**: Path calculation
```bash
ACCURACY_REPORT_PATH="${REPORTS_DIR}/004_accuracy_analysis.md"
```

**Phase 4**: Parallel invocation (with bloat analyzer)
```bash
Task {
  subagent_type: "general-purpose"
  description: "Analyze documentation accuracy"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/docs-accuracy-analyzer.md

    INPUTS:
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - ACCURACY_REPORT_PATH: ${ACCURACY_REPORT_PATH}
  "
}
```

**Phase 5**: Verification checkpoint
```bash
if [ ! -f "$ACCURACY_REPORT_PATH" ]; then
  echo "ERROR: Accuracy analyzer failed"
  exit 1
fi
```

**Phase 6**: Metadata extraction
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/metadata-extraction.sh"
ACCURACY_METADATA=$(extract_accuracy_metadata "$ACCURACY_REPORT_PATH")
```

**Phase 7**: Planning integration
```bash
# cleanup-plan-architect receives ALL FOUR reports
Task {
  prompt: "
    INPUTS:
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - BLOAT_REPORT_PATH: ${BLOAT_REPORT_PATH}
    - ACCURACY_REPORT_PATH: ${ACCURACY_REPORT_PATH}

    Prioritize: Critical errors FIRST, bloat SECOND, enhancements THIRD
  "
}
```

### Metadata Extraction Pattern

**Function**: `extract_accuracy_metadata()`
**Location**: `.claude/lib/workflow/metadata-extraction.sh`
**Context Reduction**: 95%+ (400 bytes metadata vs 5000-10000+ bytes full report)

**Extracted Fields**:
- `title`: Report title
- `summary`: 50-word executive summary
- `error_count`: Number of critical accuracy errors
- `completeness_pct`: Documentation completeness percentage
- `key_findings[]`: Top 3-5 critical issues
- `path`: Report file path
- `size`: File size in bytes

**Usage**:
```bash
source .claude/lib/workflow/metadata-extraction.sh
METADATA=$(extract_accuracy_metadata "$ACCURACY_REPORT_PATH")
echo "$METADATA" | jq '.completeness_pct'  # 85
```

### Planning Coordination

The cleanup-plan-architect synthesizes findings from accuracy report:
1. Reads accuracy report Section 3-8
2. Extracts critical errors, gaps, violations
3. Integrates with bloat findings
4. Generates unified implementation plan
5. Prioritizes: **Critical accuracy errors FIRST**, bloat reduction SECOND, enhancements THIRD

---

## 6. Troubleshooting

### Issue: Report not created
**Symptoms**: Verification checkpoint fails, "File not found" error

**Diagnosis**:
```bash
# Check if agent was invoked
grep -A 5 "docs-accuracy-analyzer" /path/to/workflow/log

# Check parent directory exists
ls -la "${ACCURACY_REPORT_PATH%/*}"

# Verify input reports exist
test -f "$CLAUDE_MD_REPORT_PATH" && echo "✓ Input 1 exists"
test -f "$DOCS_REPORT_PATH" && echo "✓ Input 2 exists"
```

**Resolution**:
1. Verify `ACCURACY_REPORT_PATH` is absolute path (starts with `/`)
2. Ensure parent directory exists or agent has write permissions
3. Check agent invocation uses imperative pattern: "Read and follow ALL behavioral guidelines"
4. Review agent output for error messages

### Issue: Incomplete analysis (placeholders remain)
**Symptoms**: Report contains "TO BE ANALYZED IN STEP 4" text

**Diagnosis**:
```bash
# Check for placeholders
grep -c "TO BE ANALYZED" "$ACCURACY_REPORT_PATH"
# Expected: 0
```

**Resolution**:
1. Agent failed during STEP 4 (analysis phase)
2. Check input reports are complete and readable
3. Verify Opus 4.5 model availability
4. Review agent logs for error messages during analysis

### Issue: Low metadata extraction quality
**Symptoms**: Missing error_count or completeness_pct in metadata

**Diagnosis**:
```bash
METADATA=$(extract_accuracy_metadata "$ACCURACY_REPORT_PATH")
echo "$METADATA" | jq '.error_count'  # Should be >0
echo "$METADATA" | jq '.completeness_pct'  # Should be 0-100
```

**Resolution**:
1. Check report Section 3 contains error count patterns ("12 critical errors")
2. Check report Section 4 contains completeness percentage ("85%" or "102/120")
3. Verify executive summary includes key statistics
4. Report may be incomplete - re-run accuracy analyzer

### Issue: Standard 11 violation (agent not invoked)
**Symptoms**: Agent behavioral file not being followed

**Diagnosis**:
```bash
# Verify imperative invocation pattern
grep -B 2 -A 5 "docs-accuracy-analyzer" .claude/commands/optimize-claude.md | \
  grep -q "Read and follow ALL behavioral guidelines"
```

**Resolution**:
1. Update /optimize-claude invocation to use imperative pattern
2. Do NOT use documentation-only YAML blocks
3. Use Task tool with "Read and follow ALL behavioral guidelines from:" prompt
4. See [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)

---

## See Also

- [Agent Behavioral File](../../agents/docs-accuracy-analyzer.md) - Executable agent definition
- [Bloat Analyzer Guide](docs-bloat-analyzer-agent-guide.md) - Parallel bloat analysis agent
- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - Context reduction technique
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Agent invocation standard
- [Executable/Documentation Separation](../concepts/patterns/executable-documentation-separation.md) - File organization pattern
