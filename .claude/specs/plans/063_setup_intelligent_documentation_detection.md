# /setup Command: Intelligent Documentation Detection and TDD Enforcement

## Metadata
- **Date**: 2025-10-17
- **Feature**: Enhanced /setup command with documentation discovery, TDD enforcement, and gap analysis
- **Scope**: Improve /setup to detect comprehensive project documentation, enforce TDD practices, and provide actionable recommendations
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Commands**: /setup, /validate-setup
- **Complexity**: High

## Problem Statement

The current `/setup` command has significant blind spots when analyzing projects:

### Current Issues (from nice_connectives analysis)

1. **Documentation Blindness**: Reports "no optimization needed" despite:
   - 11 comprehensive documentation files in `docs/` directory
   - TESTING.md with detailed test infrastructure
   - CONTRIBUTING.md with development guidelines
   - USAGE.md, INSTALLATION.md, DEFINABILITY.md, etc.
   - **None of these are referenced in CLAUDE.md**

2. **TDD Enforcement Gap**:
   - 338 tests exist with comprehensive test infrastructure
   - TESTING.md explicitly documents TDD approach (line 219-227)
   - CLAUDE.md Testing Protocols section has no TDD requirements
   - `/setup` detected pytest but missed TDD culture

3. **Shallow Analysis**:
   - Only validates CLAUDE.md structure (sections present, metadata format)
   - Doesn't detect documentation-CLAUDE.md integration gaps
   - Doesn't analyze documentation quality or coverage
   - Provides "everything is fine" feedback when critical gaps exist

### Real-World Impact

User ran `/setup` on nice_connectives and received:
> "Your CLAUDE.md is already in excellent shape... No changes needed"

But actual state:
- **11 documentation files** completely invisible to slash commands
- **TDD practices** documented but not enforced
- **Testing infrastructure** (markers, fixtures, patterns) not referenced
- **Contributing guidelines** not linked from CLAUDE.md
- **Usage documentation** not discoverable by commands

## Success Criteria

- [ ] `/setup --analyze` detects all documentation files in `docs/` directory
- [ ] Analysis identifies documentation-CLAUDE.md integration gaps
- [ ] TDD requirements detected from TESTING.md and enforced in Testing Protocols
- [ ] Gap report shows: missing links, undocumented TDD practices, missing cross-references
- [ ] Recommendations are actionable (specific file paths, section names, content suggestions)
- [ ] `/setup --apply-report` integrates documentation links into CLAUDE.md
- [ ] Updated CLAUDE.md provides comprehensive navigation to all project documentation
- [ ] Testing Protocols section enforces TDD when test infrastructure supports it

## Technical Design

### 1. Documentation Discovery System

#### Multi-Level Documentation Scanning

```yaml
discovery_algorithm:
  level_1_standard_locations:
    - docs/               # Primary documentation directory
    - documentation/
    - wiki/

  level_2_common_files:
    - README.md           # Project root and subdirectories
    - CONTRIBUTING.md
    - TESTING.md
    - ARCHITECTURE.md
    - API.md
    - USAGE.md
    - INSTALLATION.md

  level_3_technical_docs:
    - specs/              # Implementation plans and reports
    - examples/           # Usage examples
    - tutorials/          # Learning resources

  scanning_strategy:
    depth: 3              # Max directory depth
    ignore_patterns:
      - node_modules/
      - .git/
      - venv/
      - __pycache__/
      - dist/
      - build/
```

#### Documentation Classification

```python
class DocumentationType(Enum):
    TESTING = "testing"              # TESTING.md, test guides
    CONTRIBUTING = "contributing"    # CONTRIBUTING.md, dev guides
    USAGE = "usage"                  # USAGE.md, user guides
    ARCHITECTURE = "architecture"    # ARCHITECTURE.md, design docs
    API = "api"                      # API.md, reference docs
    INSTALLATION = "installation"    # INSTALLATION.md, setup guides
    EXAMPLES = "examples"            # Example code and tutorials
    SPECS = "specs"                  # Implementation plans and reports
    GENERAL = "general"              # Other documentation

# Classification logic
def classify_documentation(file_path: Path) -> DocumentationType:
    """
    Classify documentation by filename patterns and content analysis.

    Priority:
    1. Exact filename matches (TESTING.md → TESTING)
    2. Keyword patterns in filename (test_guide.md → TESTING)
    3. Content analysis (first 50 lines for keywords)
    """
    filename = file_path.name.lower()

    # Exact matches
    if filename == "testing.md":
        return DocumentationType.TESTING
    if filename == "contributing.md":
        return DocumentationType.CONTRIBUTING

    # Pattern matches
    if any(kw in filename for kw in ["test", "testing", "pytest", "tdd"]):
        return DocumentationType.TESTING
    if any(kw in filename for kw in ["contrib", "develop", "workflow"]):
        return DocumentationType.CONTRIBUTING

    # Content analysis (if needed)
    content = file_path.read_text()[:2000]  # First 2000 chars
    if "pytest" in content and "test" in content:
        return DocumentationType.TESTING

    return DocumentationType.GENERAL
```

#### Documentation Metadata Extraction

```python
@dataclass
class DocumentationFile:
    """Represents a discovered documentation file."""
    path: Path
    type: DocumentationType
    title: str                    # Extracted from first h1
    summary: str                  # First paragraph or description
    sections: List[str]           # H2 headings
    word_count: int
    links_to: List[Path]          # Other docs referenced
    linked_from: List[Path]       # Docs that link here
    last_modified: datetime

    # Integration status
    referenced_in_claude_md: bool
    integration_quality: float    # 0.0-1.0 score

def extract_metadata(file_path: Path) -> DocumentationFile:
    """
    Extract comprehensive metadata from documentation file.

    Returns:
        DocumentationFile with all fields populated
    """
    content = file_path.read_text()

    # Extract title (first # heading)
    title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
    title = title_match.group(1) if title_match else file_path.stem

    # Extract summary (first paragraph after title)
    summary = extract_first_paragraph(content)

    # Extract sections (all ## headings)
    sections = re.findall(r'^##\s+(.+)$', content, re.MULTILINE)

    # Find links to other documentation
    links = extract_markdown_links(content)

    return DocumentationFile(
        path=file_path,
        type=classify_documentation(file_path),
        title=title,
        summary=summary,
        sections=sections,
        word_count=len(content.split()),
        links_to=links,
        linked_from=[],  # Populated in second pass
        last_modified=datetime.fromtimestamp(file_path.stat().st_mtime),
        referenced_in_claude_md=False,  # Checked later
        integration_quality=0.0  # Calculated later
    )
```

### 2. CLAUDE.md Integration Analysis

#### Gap Detection Algorithm

```python
class IntegrationGapType(Enum):
    MISSING_REFERENCE = "missing_reference"      # Doc exists, not linked
    WEAK_REFERENCE = "weak_reference"            # Linked but no description
    BROKEN_LINK = "broken_link"                  # Link points to non-existent file
    OUTDATED_CONTENT = "outdated_content"        # CLAUDE.md content contradicts doc
    MISSING_SECTION = "missing_section"          # Required section not in CLAUDE.md
    INCOMPLETE_SECTION = "incomplete_section"    # Section exists but missing key info

@dataclass
class IntegrationGap:
    """Represents a gap between documentation and CLAUDE.md."""
    type: IntegrationGapType
    priority: str                          # "critical", "high", "medium", "low"
    documentation_file: Optional[Path]     # Related doc (if applicable)
    claude_md_section: Optional[str]       # Affected CLAUDE.md section
    description: str                       # What's wrong
    recommendation: str                    # Specific fix
    example_fix: str                       # Code/markdown to add

def analyze_integration(
    docs: List[DocumentationFile],
    claude_md_path: Path
) -> List[IntegrationGap]:
    """
    Analyze integration between discovered documentation and CLAUDE.md.

    Returns:
        List of gaps with actionable recommendations
    """
    gaps = []
    claude_md_content = claude_md_path.read_text()

    # Check 1: Missing references to key documentation
    for doc in docs:
        if doc.type in [DocumentationType.TESTING, DocumentationType.CONTRIBUTING]:
            # These are critical and must be referenced
            if not is_referenced_in_claude(doc.path, claude_md_content):
                gaps.append(IntegrationGap(
                    type=IntegrationGapType.MISSING_REFERENCE,
                    priority="critical",
                    documentation_file=doc.path,
                    claude_md_section=infer_target_section(doc.type),
                    description=f"{doc.type.value.title()} documentation exists but not referenced in CLAUDE.md",
                    recommendation=f"Add link to {doc.path} in {infer_target_section(doc.type)} section",
                    example_fix=generate_integration_snippet(doc, claude_md_content)
                ))

    # Check 2: Testing protocols completeness
    testing_section = extract_section(claude_md_content, "Testing Protocols")
    if testing_section:
        gaps.extend(analyze_testing_protocols(testing_section, docs))

    # Check 3: Cross-reference validation
    gaps.extend(validate_cross_references(claude_md_content, docs))

    return sorted(gaps, key=lambda g: priority_score(g.priority))
```

#### Testing Infrastructure Analysis

```python
class TestingInfrastructure:
    """Detected testing infrastructure in project."""
    framework: str                      # "pytest", "jest", "vitest", etc.
    test_file_pattern: str              # "test_*.py", "*_spec.js"
    test_count: int                     # Total test files
    has_ci_cd: bool                     # CI/CD configuration exists
    has_coverage: bool                  # Coverage tools configured
    has_test_markers: bool              # Test categorization (pytest markers, jest tags)
    has_fixtures: bool                  # Shared test fixtures exist
    has_mocking: bool                   # Mocking infrastructure detected
    tdd_indicators: List[str]           # Evidence of TDD practices

    # From TESTING.md or test documentation
    documented_tdd: bool                # TDD explicitly documented
    documented_coverage_target: Optional[int]  # e.g., 80%
    documented_test_commands: List[str]  # Commands to run tests
    test_categories: List[str]          # "unit", "integration", "e2e", etc.

def detect_testing_infrastructure(project_dir: Path, docs: List[DocumentationFile]) -> TestingInfrastructure:
    """
    Comprehensive testing infrastructure detection.

    Goes beyond current detect-testing.sh to analyze:
    - Test documentation for TDD practices
    - Test organization and categorization
    - Coverage requirements and tooling
    - CI/CD integration
    """
    # Existing detection (from detect-testing.sh)
    score, frameworks = run_detect_testing_script(project_dir)

    # Enhanced detection from TESTING.md
    testing_doc = find_doc_by_type(docs, DocumentationType.TESTING)
    if testing_doc:
        tdd_info = extract_tdd_requirements(testing_doc)
        coverage_info = extract_coverage_requirements(testing_doc)
        test_commands = extract_test_commands(testing_doc)
    else:
        tdd_info = analyze_test_files_for_tdd(project_dir)
        coverage_info = None
        test_commands = []

    return TestingInfrastructure(
        framework=frameworks[0] if frameworks else "none",
        test_file_pattern=detect_test_pattern(project_dir),
        test_count=count_test_files(project_dir),
        has_ci_cd=detect_ci_cd(project_dir),
        has_coverage=detect_coverage_tools(project_dir),
        has_test_markers=detect_test_markers(project_dir),
        has_fixtures=detect_fixtures(project_dir),
        has_mocking=detect_mocking(project_dir),
        tdd_indicators=tdd_info.indicators,
        documented_tdd=tdd_info.documented,
        documented_coverage_target=coverage_info.target if coverage_info else None,
        documented_test_commands=test_commands,
        test_categories=detect_test_categories(project_dir)
    )
```

### 3. TDD Enforcement Mechanism

#### TDD Requirement Detection

```python
@dataclass
class TDDRequirements:
    """TDD practices that should be enforced."""
    requires_tdd: bool                     # Should TDD be enforced?
    confidence: float                      # 0.0-1.0 confidence in requirement
    evidence: List[str]                    # Why we think TDD is required

    # Specific requirements
    test_before_implementation: bool       # Write tests first
    minimum_coverage: Optional[int]        # e.g., 80%
    test_categories: List[str]             # Required test types
    pre_commit_tests: bool                 # Tests must pass before commit

    # From documentation
    documented_workflow: Optional[str]     # TDD workflow description
    documented_examples: List[str]         # TDD examples in docs

def detect_tdd_requirements(
    testing_infra: TestingInfrastructure,
    docs: List[DocumentationFile]
) -> TDDRequirements:
    """
    Determine if TDD should be enforced based on project evidence.

    Strong TDD indicators:
    - TESTING.md explicitly describes TDD workflow
    - High test count (>100 tests) with good organization
    - Test markers indicate systematic testing approach
    - CI/CD requires tests to pass
    - Coverage requirements documented

    Weak TDD indicators:
    - Some tests exist but no documentation
    - No coverage requirements
    - No test categorization
    """
    requires_tdd = False
    confidence = 0.0
    evidence = []

    # Check documentation
    testing_doc = find_doc_by_type(docs, DocumentationType.TESTING)
    if testing_doc:
        content = testing_doc.path.read_text()

        # Look for TDD keywords
        if re.search(r'test[- ]driven', content, re.IGNORECASE):
            requires_tdd = True
            confidence += 0.3
            evidence.append(f"TDD explicitly mentioned in {testing_doc.path.name}")

        # Look for "write tests first" guidance
        if re.search(r'write.*tests?\s+first', content, re.IGNORECASE):
            requires_tdd = True
            confidence += 0.3
            evidence.append(f"Test-first approach documented in {testing_doc.path.name}")

    # Check test infrastructure sophistication
    if testing_infra.test_count > 100:
        confidence += 0.2
        evidence.append(f"{testing_infra.test_count} tests indicate mature testing practice")

    if testing_infra.has_test_markers and testing_infra.has_fixtures:
        confidence += 0.2
        evidence.append("Sophisticated test infrastructure (markers + fixtures)")

    # Check CI/CD integration
    if testing_infra.has_ci_cd:
        confidence += 0.1
        evidence.append("CI/CD integration suggests test discipline")

    return TDDRequirements(
        requires_tdd=requires_tdd and confidence > 0.5,
        confidence=confidence,
        evidence=evidence,
        test_before_implementation=requires_tdd,
        minimum_coverage=testing_infra.documented_coverage_target,
        test_categories=testing_infra.test_categories,
        pre_commit_tests=testing_infra.has_ci_cd,
        documented_workflow=extract_tdd_workflow(testing_doc) if testing_doc else None,
        documented_examples=extract_tdd_examples(testing_doc) if testing_doc else []
    )
```

#### Testing Protocols Enhancement

```python
def generate_enhanced_testing_protocols(
    testing_infra: TestingInfrastructure,
    tdd_requirements: TDDRequirements,
    testing_doc: Optional[DocumentationFile]
) -> str:
    """
    Generate comprehensive Testing Protocols section for CLAUDE.md.

    Includes:
    - Test commands and patterns
    - TDD requirements (if detected)
    - Coverage requirements
    - Test categories and markers
    - Link to detailed TESTING.md
    """
    protocols = []

    # Header with metadata
    protocols.append("## Testing Protocols")
    protocols.append("[Used by: /test, /test-all, /implement]")
    protocols.append("")

    # Test discovery and commands
    protocols.append("### Test Discovery")
    protocols.append(f"- **Test Pattern**: `{testing_infra.test_file_pattern}`")
    protocols.append(f"- **Test Framework**: {testing_infra.framework}")
    protocols.append(f"- **Test Commands**: {', '.join(testing_infra.documented_test_commands)}")
    protocols.append("")

    # TDD requirements (if applicable)
    if tdd_requirements.requires_tdd:
        protocols.append("### Test-Driven Development (TDD)")
        protocols.append("")
        protocols.append("**This project follows TDD practices:**")
        protocols.append("")

        if tdd_requirements.test_before_implementation:
            protocols.append("- **Write tests first**: Implement tests before code")

        if tdd_requirements.minimum_coverage:
            protocols.append(f"- **Coverage requirement**: ≥{tdd_requirements.minimum_coverage}% for new code")

        if tdd_requirements.pre_commit_tests:
            protocols.append("- **Pre-commit validation**: All tests must pass before commit")

        if tdd_requirements.test_categories:
            protocols.append(f"- **Test categories**: {', '.join(tdd_requirements.test_categories)}")

        protocols.append("")
        protocols.append(f"**Evidence**: {'; '.join(tdd_requirements.evidence)}")
        protocols.append("")

    # Test categories and markers
    if testing_infra.has_test_markers:
        protocols.append("### Test Categories")
        protocols.append("")
        for category in testing_infra.test_categories:
            protocols.append(f"- **{category.title()}**: [Description from TESTING.md or inferred]")
        protocols.append("")

    # Coverage requirements
    if testing_infra.has_coverage:
        protocols.append("### Coverage Requirements")
        protocols.append("")
        if tdd_requirements.minimum_coverage:
            protocols.append(f"- Minimum coverage: {tdd_requirements.minimum_coverage}%")
        protocols.append(f"- Coverage command: `{infer_coverage_command(testing_infra.framework)}`")
        protocols.append("")

    # Link to comprehensive documentation
    if testing_doc:
        protocols.append("### Comprehensive Testing Guide")
        protocols.append("")
        protocols.append(f"See [{testing_doc.title}]({testing_doc.path.relative_to(project_dir)}) for:")
        for section in testing_doc.sections[:5]:  # First 5 sections
            protocols.append(f"- {section}")
        if len(testing_doc.sections) > 5:
            protocols.append(f"- ...and {len(testing_doc.sections) - 5} more sections")
        protocols.append("")

    return "\n".join(protocols)
```

### 4. Gap Report Generation

#### Comprehensive Gap Analysis Report

```markdown
# Standards Analysis Report: [Project Name]

## Metadata
- **Date**: [YYYY-MM-DD]
- **Project Directory**: [path]
- **CLAUDE.md Status**: [lines, sections present]
- **Documentation Files**: [count discovered]
- **Analysis Type**: Documentation Integration + TDD Enforcement

## Executive Summary

### Key Findings
- Discovered **[N] documentation files** in project
- **[M] critical gaps** between documentation and CLAUDE.md
- TDD practices **[detected/not detected]** (confidence: [X]%)
- Integration quality: **[score]/100**

### Priority Issues
1. [Critical issue 1]
2. [Critical issue 2]
3. [High priority issue 1]

## Documentation Discovery

### Found Documentation Files

| File | Type | Word Count | Sections | Referenced in CLAUDE.md |
|------|------|-----------|----------|------------------------|
| docs/TESTING.md | Testing | 5,800 | 12 | ❌ No |
| docs/CONTRIBUTING.md | Contributing | 3,200 | 8 | ❌ No |
| docs/USAGE.md | Usage | 4,500 | 10 | ❌ No |
| ... | ... | ... | ... | ... |

**Total**: [N] files, [M] words of documentation not integrated

### Documentation Map

```
docs/
├── TESTING.md          [Testing infrastructure, TDD workflow]
│   └── Sections: Overview, Test Organization, Running Tests, TDD Practices, ...
├── CONTRIBUTING.md     [Development workflow, PR guidelines]
│   └── Sections: Getting Started, Code Standards, Review Process, ...
├── USAGE.md            [User guide, CLI reference]
│   └── Sections: Installation, Commands, Examples, ...
└── ... (8 more files)
```

## Integration Gap Analysis

### Critical Gaps

#### Gap 1: Missing TESTING.md Reference
- **Type**: Missing Reference
- **Priority**: Critical
- **Impact**: Commands cannot discover comprehensive testing documentation
- **Current State**: CLAUDE.md has minimal Testing Protocols section (22 lines)
- **Documentation State**: TESTING.md has comprehensive guide (675 lines, 12 sections)
- **Evidence**:
  - TESTING.md documents TDD workflow (line 219-227)
  - Test markers and categories explained (line 166-214)
  - Pre-PR checklist with coverage requirements (line 410-449)
  - Mock patching guidelines (line 324-408)
  - None of this integrated into CLAUDE.md

**Recommendation**: Add comprehensive link in Testing Protocols section

**Example Fix**:
```markdown
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Quick Reference
- **Test Pattern**: `test_*.py`, `*_test.py`
- **Test Framework**: pytest
- **Quick Test**: `pytest tests/ -m "not slow"` (~60 seconds)
- **Full Suite**: `pytest tests/` (~8-10 minutes, required for PRs)

### Comprehensive Testing Guide

See [Testing Guide](docs/TESTING.md) for complete documentation:
- Test organization and infrastructure
- TDD workflow and best practices
- Test markers (slow, integration, notebook)
- Mock patching guidelines
- Pre-PR checklist
- Coverage requirements
- Troubleshooting

**Key Requirements**:
- All tests must pass before PR
- New features require tests (≥80% coverage)
- Use test markers for slow tests (>1s)
```

#### Gap 2: TDD Practices Not Enforced
- **Type**: Incomplete Section
- **Priority**: Critical
- **Impact**: /implement command doesn't enforce TDD practices
- **Current State**: No TDD requirements in Testing Protocols
- **Documentation State**: TESTING.md explicitly documents TDD approach
- **Evidence**:
  - "Write Tests First (TDD Recommended)" - line 219
  - Step-by-step TDD process documented
  - 338 tests demonstrate TDD culture
  - Pre-commit checklist requires test coverage

**Recommendation**: Add TDD requirements to Testing Protocols

**Example Fix**:
```markdown
### Test-Driven Development (TDD)

**This project follows TDD practices:**

- **Write tests first**: Implement tests before code (see TESTING.md line 219-227)
- **Coverage requirement**: ≥80% for new code, ≥60% baseline
- **Pre-commit validation**: All tests must pass before commit
- **Test categories**: Unit, integration, slow, notebook

**Evidence**: 338 tests, sophisticated test infrastructure (markers + fixtures), CI/CD integration, explicit TDD documentation

See [Testing Guide](docs/TESTING.md#testing-new-features) for TDD workflow details.
```

#### Gap 3: Missing CONTRIBUTING.md Reference
- **Type**: Missing Reference
- **Priority**: High
- **Impact**: Development workflow not discoverable by commands
- **Current State**: No reference to contributing guidelines
- **Documentation State**: CONTRIBUTING.md exists with comprehensive dev workflow

**Recommendation**: Add link in appropriate section (create "Development Workflow" if needed)

**Example Fix**:
```markdown
## Development Workflow
[Used by: /implement, /plan]

See [Contributing Guide](docs/CONTRIBUTING.md) for:
- Development setup and environment
- Code review process
- Pull request guidelines
- Release workflow
```

### High Priority Gaps

[Continue with remaining gaps...]

## TDD Enforcement Analysis

### Detected TDD Requirements

**TDD Required**: Yes
**Confidence**: 85%

**Evidence**:
1. TDD explicitly mentioned in docs/TESTING.md (line 219)
2. Test-first approach documented (line 220-227)
3. 338 tests indicate mature testing practice
4. Sophisticated test infrastructure (markers + fixtures)
5. CI/CD integration suggests test discipline

### Recommended TDD Enforcement

Add to Testing Protocols section in CLAUDE.md:

```markdown
### Test-Driven Development (TDD)

**This project follows TDD practices:**

- **Write tests first**: Implement tests before code
- **Coverage requirement**: ≥80% for new code
- **Pre-commit validation**: All tests must pass before commit
- **Test categories**: unit, integration, slow, notebook

**Evidence**: [list evidence from above]
```

## Interactive Gap Filling

[For each gap, provide [FILL IN: ...] section with context, recommendation, decision field, rationale field]

### Gap 1: TESTING.md Integration

**Context**:
- Current: CLAUDE.md has minimal 22-line Testing Protocols section
- Discovered: docs/TESTING.md with 675 lines of comprehensive testing documentation
- Impact: Commands cannot discover detailed testing practices

**Recommendation**: Add comprehensive link in Testing Protocols section (see example above)

**Decision**:
[FILL IN: Accept recommendation, modify, or skip]
_______________________________________________

**Rationale**:
[FILL IN: Why this decision was made]
_______________________________________________

### Gap 2: TDD Enforcement

[Continue pattern for each gap...]

## Recommendations

### Immediate Actions (Critical)
1. Add TESTING.md link to Testing Protocols section
2. Add TDD requirements to Testing Protocols
3. Add CONTRIBUTING.md link to CLAUDE.md

### Short-Term Actions (High Priority)
4. Add links to all docs/* files in appropriate CLAUDE.md sections
5. Create cross-reference navigation in documentation
6. Update Documentation Policy to reference comprehensive docs

### Medium-Term Actions (Enhancement)
7. Create Documentation Index section in CLAUDE.md
8. Add documentation coverage metrics to /validate-setup
9. Consider extracting detailed CLAUDE.md sections to docs/ (if CLAUDE.md grows)

## Implementation

### Option 1: Manual Editing
Edit CLAUDE.md directly following example fixes above.

### Option 2: Automated Application
Fill [FILL IN: ...] sections in this report, then run:
```bash
/setup --apply-report specs/reports/[this-report].md
```

## Next Steps

1. Review this report
2. Fill interactive gap sections with decisions
3. Run `/setup --apply-report` or edit CLAUDE.md manually
4. Run `/validate-setup` to verify changes
5. Test that commands can now discover documentation
```

### 5. Report Application Logic

```python
def apply_gap_report(
    report_path: Path,
    claude_md_path: Path,
    backup: bool = True
) -> ApplicationResult:
    """
    Parse completed gap report and apply decisions to CLAUDE.md.

    Process:
    1. Parse report for filled [FILL IN: ...] sections
    2. For each accepted recommendation:
       - Locate target section in CLAUDE.md
       - Apply fix (add link, update content, create section)
    3. Validate updated CLAUDE.md structure
    4. Return summary of changes
    """
    # Backup original
    if backup:
        backup_path = create_backup(claude_md_path)

    # Parse report
    decisions = parse_gap_decisions(report_path)

    # Apply each decision
    changes = []
    for decision in decisions:
        if decision.action == "accept":
            change = apply_fix(claude_md_path, decision.gap, decision.fix)
            changes.append(change)
        elif decision.action == "modify":
            change = apply_custom_fix(claude_md_path, decision.gap, decision.custom_fix)
            changes.append(change)
        # Skip if action == "skip"

    # Validate result
    validation = validate_claude_md(claude_md_path)
    if not validation.success:
        # Rollback and report errors
        restore_backup(backup_path, claude_md_path)
        return ApplicationResult(success=False, errors=validation.errors)

    return ApplicationResult(
        success=True,
        changes_applied=len(changes),
        changes=changes,
        backup_path=backup_path
    )
```

### 6. Enhanced /setup Workflow

```python
def setup_with_documentation_analysis(project_dir: Path, mode: SetupMode):
    """
    Enhanced /setup workflow with documentation discovery.

    Modes:
    - standard: Generate/update CLAUDE.md (existing behavior)
    - analyze: Generate comprehensive gap report (NEW)
    - apply-report: Apply gap report decisions (ENHANCED)
    """

    if mode == SetupMode.ANALYZE:
        # NEW: Comprehensive analysis

        # 1. Discover all documentation
        docs = discover_documentation(project_dir)
        print(f"Discovered {len(docs)} documentation files")

        # 2. Analyze testing infrastructure
        testing_infra = detect_testing_infrastructure(project_dir, docs)
        print(f"Testing framework: {testing_infra.framework}, {testing_infra.test_count} tests")

        # 3. Detect TDD requirements
        tdd_requirements = detect_tdd_requirements(testing_infra, docs)
        if tdd_requirements.requires_tdd:
            print(f"TDD practices detected (confidence: {tdd_requirements.confidence:.0%})")

        # 4. Analyze CLAUDE.md integration
        claude_md = project_dir / "CLAUDE.md"
        if claude_md.exists():
            gaps = analyze_integration(docs, claude_md)
            print(f"Found {len(gaps)} integration gaps")
        else:
            gaps = []  # Will recommend creating CLAUDE.md

        # 5. Generate comprehensive report
        report = generate_gap_report(
            docs=docs,
            gaps=gaps,
            testing_infra=testing_infra,
            tdd_requirements=tdd_requirements,
            project_dir=project_dir
        )

        # 6. Save report
        report_path = save_report(report, project_dir)
        print(f"\nAnalysis complete: {report_path}")
        print(f"\nNext steps:")
        print(f"1. Review {report_path}")
        print(f"2. Fill [FILL IN: ...] sections with decisions")
        print(f"3. Run: /setup --apply-report {report_path}")

    elif mode == SetupMode.APPLY_REPORT:
        # ENHANCED: Apply with documentation integration
        result = apply_gap_report(
            report_path=mode.report_path,
            claude_md_path=project_dir / "CLAUDE.md",
            backup=True
        )

        if result.success:
            print(f"✓ Applied {result.changes_applied} changes to CLAUDE.md")
            print(f"  Backup: {result.backup_path}")
            print(f"\nChanges:")
            for change in result.changes:
                print(f"  - {change.description}")
            print(f"\nRun /validate-setup to verify structure")
        else:
            print(f"✗ Failed to apply report")
            print(f"Errors: {result.errors}")

    elif mode == SetupMode.STANDARD:
        # ENHANCED: Standard mode with documentation check

        # Check if comprehensive documentation exists
        docs = discover_documentation(project_dir)
        docs_count = len([d for d in docs if d.type != DocumentationType.GENERAL])

        if docs_count >= 3:  # 3+ specialized docs
            print(f"\n⚠ Found {docs_count} documentation files")
            print(f"  Run /setup --analyze to check integration with CLAUDE.md")
            print()

        # Continue with standard CLAUDE.md generation
        # [existing standard mode logic]
```

## Implementation Phases

### Phase 1: Documentation Discovery System
**Objective**: Build comprehensive documentation scanning and classification
**Complexity**: Medium

Tasks:
- [ ] Create `DocumentationType` enum with all document categories
- [ ] Implement `discover_documentation()` function with multi-level scanning
- [ ] Implement `classify_documentation()` with filename + content analysis
- [ ] Implement `extract_metadata()` for comprehensive file analysis
- [ ] Create `DocumentationFile` dataclass with all metadata fields
- [ ] Add tests for discovery on sample project structures
- [ ] Add tests for classification accuracy
- [ ] Add tests for metadata extraction

Testing:
```bash
# Test on nice_connectives repo
python -c "
from setup_enhanced import discover_documentation
docs = discover_documentation('/path/to/nice_connectives')
print(f'Found {len(docs)} files')
for doc in docs:
    print(f'  {doc.type.value}: {doc.path.name}')
"

# Expected: 11+ documentation files discovered and classified
```

Files to create/modify:
- `.claude/lib/documentation-discovery.py` (new, ~300 lines)
- `.claude/lib/setup-enhanced.py` (new, integrates all new functionality)
- `.claude/tests/test_documentation_discovery.py` (new, ~150 lines)

### Phase 2: Testing Infrastructure Analysis
**Objective**: Enhanced testing detection with TDD requirement inference
**Complexity**: Medium

Tasks:
- [ ] Create `TestingInfrastructure` dataclass with all fields
- [ ] Implement `detect_testing_infrastructure()` extending detect-testing.sh
- [ ] Implement test marker detection (pytest.mark, jest describe tags)
- [ ] Implement fixture detection (conftest.py, test utilities)
- [ ] Implement mocking detection (unittest.mock, jest.mock usage)
- [ ] Create `TDDRequirements` dataclass
- [ ] Implement `detect_tdd_requirements()` with confidence scoring
- [ ] Implement `extract_tdd_workflow()` from TESTING.md
- [ ] Add tests for infrastructure detection
- [ ] Add tests for TDD requirement detection with various confidence levels

Testing:
```bash
# Test on nice_connectives repo
python -c "
from setup_enhanced import detect_testing_infrastructure, detect_tdd_requirements
docs = discover_documentation('/path/to/nice_connectives')
infra = detect_testing_infrastructure('/path/to/nice_connectives', docs)
tdd = detect_tdd_requirements(infra, docs)

print(f'Framework: {infra.framework}')
print(f'Tests: {infra.test_count}')
print(f'TDD Required: {tdd.requires_tdd} (confidence: {tdd.confidence:.0%})')
print(f'Evidence: {tdd.evidence}')
"

# Expected:
# Framework: pytest
# Tests: 338
# TDD Required: True (confidence: 85%)
# Evidence: [list of 5 indicators]
```

Files to create/modify:
- `.claude/lib/testing-analysis.py` (new, ~400 lines)
- `.claude/tests/test_testing_analysis.py` (new, ~200 lines)

### Phase 3: Integration Gap Detection
**Objective**: Analyze CLAUDE.md vs documentation and identify gaps
**Complexity**: High

Tasks:
- [ ] Create `IntegrationGapType` enum with all gap types
- [ ] Create `IntegrationGap` dataclass with all fields
- [ ] Implement `analyze_integration()` main analysis function
- [ ] Implement `is_referenced_in_claude()` for link detection
- [ ] Implement `analyze_testing_protocols()` for testing section analysis
- [ ] Implement `validate_cross_references()` for broken link detection
- [ ] Implement `generate_integration_snippet()` for example fixes
- [ ] Implement priority scoring for gap ordering
- [ ] Add tests for each gap type detection
- [ ] Add tests for false positive prevention
- [ ] Add tests for priority scoring

Testing:
```bash
# Test on nice_connectives repo (before fixes)
python -c "
from setup_enhanced import analyze_integration, discover_documentation
docs = discover_documentation('/path/to/nice_connectives')
gaps = analyze_integration(docs, '/path/to/nice_connectives/CLAUDE.md')

print(f'Found {len(gaps)} gaps:')
for gap in gaps[:5]:  # First 5
    print(f'  [{gap.priority}] {gap.type.value}: {gap.description}')
"

# Expected output:
# Found 13 gaps:
#   [critical] missing_reference: Testing documentation exists but not referenced
#   [critical] incomplete_section: Testing Protocols missing TDD requirements
#   [high] missing_reference: Contributing documentation not linked
#   ...
```

Files to create/modify:
- `.claude/lib/integration-analysis.py` (new, ~500 lines)
- `.claude/tests/test_integration_analysis.py` (new, ~250 lines)

### Phase 4: Enhanced Testing Protocols Generation
**Objective**: Generate comprehensive Testing Protocols section with TDD enforcement
**Complexity**: Medium

Tasks:
- [ ] Implement `generate_enhanced_testing_protocols()` main function
- [ ] Implement test command extraction and formatting
- [ ] Implement TDD requirement formatting with evidence
- [ ] Implement test category documentation
- [ ] Implement coverage requirement documentation
- [ ] Implement TESTING.md link with section list
- [ ] Add tests for protocol generation with various configurations
- [ ] Add tests for TDD section inclusion/exclusion
- [ ] Add tests for output format validation

Testing:
```bash
# Test protocol generation
python -c "
from setup_enhanced import generate_enhanced_testing_protocols
# [setup infra and tdd objects]
protocols = generate_enhanced_testing_protocols(infra, tdd, testing_doc)
print(protocols)
"

# Expected: Well-formatted Testing Protocols section with:
# - Test commands
# - TDD requirements (if applicable)
# - Test categories
# - Coverage requirements
# - Link to TESTING.md with section list
```

Files to create/modify:
- `.claude/lib/protocol-generator.py` (new, ~300 lines)
- `.claude/tests/test_protocol_generator.py` (new, ~150 lines)

### Phase 5: Gap Report Generation and Application
**Objective**: Generate comprehensive reports and apply user decisions
**Complexity**: High

Tasks:
- [ ] Implement `generate_gap_report()` main report generator
- [ ] Implement documentation discovery summary table
- [ ] Implement gap analysis sections with examples
- [ ] Implement TDD enforcement analysis section
- [ ] Implement interactive gap filling sections with [FILL IN: ...]
- [ ] Implement recommendations prioritization
- [ ] Implement `parse_gap_decisions()` for report parsing
- [ ] Implement `apply_fix()` for automated fix application
- [ ] Implement `apply_custom_fix()` for user-modified fixes
- [ ] Implement backup and rollback mechanism
- [ ] Add tests for report generation
- [ ] Add tests for decision parsing
- [ ] Add tests for fix application
- [ ] Add tests for rollback on validation failure

Testing:
```bash
# Generate report
/setup --analyze /path/to/nice_connectives

# Expected: specs/reports/NNN_standards_analysis_report.md created
# with all sections, gaps, and [FILL IN: ...] markers

# Test application (after filling report)
/setup --apply-report specs/reports/NNN_*.md

# Expected:
# - Backup created
# - CLAUDE.md updated with links and TDD requirements
# - Validation passes
# - Changes summarized
```

Files to create/modify:
- `.claude/lib/report-generator.py` (new, ~600 lines)
- `.claude/lib/report-parser.py` (new, ~300 lines)
- `.claude/tests/test_report_generation.py` (new, ~200 lines)
- `.claude/tests/test_report_application.py` (new, ~250 lines)

### Phase 6: Integration with /setup Command
**Objective**: Integrate all new functionality into /setup command
**Complexity**: Medium

Tasks:
- [ ] Modify `.claude/commands/setup.md` with new documentation
- [ ] Update argument parsing for --analyze mode
- [ ] Update argument parsing for --apply-report mode
- [ ] Implement `setup_with_documentation_analysis()` workflow
- [ ] Add documentation discovery check to standard mode
- [ ] Add warning in standard mode if docs found but not integrated
- [ ] Update help text and usage examples
- [ ] Update error messages with helpful guidance
- [ ] Add integration tests for all modes
- [ ] Add end-to-end tests on sample projects
- [ ] Test on nice_connectives repository
- [ ] Test on .config repository (self-test)

Testing:
```bash
# Test standard mode with warning
/setup /path/to/nice_connectives

# Expected output:
# [standard setup output]
#
# ⚠ Found 11 documentation files
#   Run /setup --analyze to check integration with CLAUDE.md

# Test analyze mode
/setup --analyze /path/to/nice_connectives

# Expected: Comprehensive report generated with all gaps identified

# Test apply mode (after filling report)
/setup --apply-report /path/to/nice_connectives/specs/reports/NNN_*.md

# Expected: CLAUDE.md updated with documentation links and TDD requirements

# Verify result
/validate-setup /path/to/nice_connectives

# Expected: Validation passes, documentation references verified
```

Files to modify:
- `.claude/commands/setup.md` (~300 lines of additions)
- `.claude/lib/setup-enhanced.py` (modifications for integration)
- `.claude/tests/test_setup_integration.py` (new, ~300 lines)

## Testing Strategy

### Unit Tests
- Documentation discovery and classification
- Metadata extraction accuracy
- Testing infrastructure detection
- TDD requirement inference
- Gap detection for each type
- Protocol generation with various inputs
- Report parsing and decision extraction

### Integration Tests
- End-to-end analyze mode on sample projects
- End-to-end apply mode with various report states
- Standard mode with documentation warning
- Cross-validation with /validate-setup

### Test Projects
1. **nice_connectives**: Real-world project with comprehensive docs, good TDD test case
2. **Minimal project**: No docs, basic tests, should not trigger TDD requirements
3. **Medium project**: Some docs, some tests, partial TDD indicators
4. **.config repository**: Self-test on own codebase

### Coverage Requirements
- ≥80% coverage for all new code
- All gap types must have test cases
- All TDD confidence levels must have test cases
- All report application scenarios must have test cases

## Documentation Requirements

### Command Documentation
- Update `.claude/commands/setup.md` with new modes and examples
- Add troubleshooting section for common issues
- Add detailed examples for each mode

### Utility Documentation
- Add docstrings to all new functions and classes
- Add inline comments for complex algorithms
- Create `.claude/lib/README.md` documenting new utilities

### User Guide
- Update `.claude/docs/setup-command-guide.md` with new functionality
- Add examples of gap reports
- Add examples of before/after CLAUDE.md

## Dependencies

### New Utilities
- `.claude/lib/documentation-discovery.py`
- `.claude/lib/testing-analysis.py`
- `.claude/lib/integration-analysis.py`
- `.claude/lib/protocol-generator.py`
- `.claude/lib/report-generator.py`
- `.claude/lib/report-parser.py`

### Existing Dependencies
- `.claude/lib/detect-testing.sh` (extended, not replaced)
- `.claude/lib/generate-testing-protocols.sh` (may be deprecated in favor of Python)
- `.claude/commands/setup.md` (significantly enhanced)

### External Dependencies
- Python 3.8+ (for dataclasses, pathlib, type hints)
- Standard library only (no new external dependencies)

## Migration Plan

### Backward Compatibility
- Existing `/setup` behavior preserved (standard mode)
- Existing utilities continue to work
- New modes are opt-in (--analyze, --apply-report)

### Deprecation Strategy
- `.claude/lib/generate-testing-protocols.sh` may be deprecated in favor of Python implementation
- If deprecated, add warning message pointing to new implementation
- Keep for at least 2 releases before removal

## Success Metrics

### Quantitative
- [ ] Discovers 100% of documentation files in standard locations
- [ ] Correctly classifies ≥90% of documentation by type
- [ ] Detects TDD requirements with ≥80% accuracy (measured against manual review)
- [ ] Identifies all critical integration gaps in test cases
- [ ] Generates actionable recommendations for ≥95% of gaps

### Qualitative
- [ ] Users find gap reports actionable and helpful
- [ ] Users understand how to fill [FILL IN: ...] sections
- [ ] Users successfully apply reports with --apply-report
- [ ] CLAUDE.md integration improves command discoverability
- [ ] TDD enforcement helps maintain test discipline

### User Feedback
- Test on nice_connectives repository (original issue)
- Test on other real-world projects
- Gather feedback on report clarity and usefulness
- Iterate on recommendation formatting based on feedback

## Notes

### Design Decisions

#### Why Python for New Utilities?
- Complex data structures (dataclasses) better suited to Python
- Easier testing with pytest
- Better maintainability for complex logic
- Existing bash utilities remain for simple tasks

#### Why Not Fully Automated Integration?
- User judgment required for some decisions (e.g., where to place links)
- Interactive gap filling allows customization
- Automatic application is opt-in via --apply-report
- Balances automation with control

#### Why Confidence Scoring for TDD?
- TDD is a cultural practice, not just tooling
- Some projects have tests but don't follow TDD
- Confidence score helps users make informed decisions
- Prevents false positives in test-light projects

### Future Enhancements

#### Phase 7 (Future): Advanced Features
- **Documentation health metrics**: Staleness detection, broken links, incomplete sections
- **Cross-project standards**: Detect organization-wide standards from multiple CLAUDEs
- **Documentation templates**: Generate missing docs (TESTING.md, CONTRIBUTING.md) from templates
- **CI/CD integration**: Validate documentation coverage in CI pipeline
- **Documentation coverage visualization**: Generate graphs of doc coverage over time

#### Potential Improvements
- Machine learning for better TDD requirement detection
- Natural language processing for better content analysis
- Automatic section summarization for large docs
- Documentation diff tracking (what changed since last analysis)
