# Bidirectional Conversion Support Implementation Plan

## Metadata
- **Date**: 2025-10-10
- **Feature**: Add bidirectional conversion support (Markdown ↔ PDF/DOCX)
- **Scope**: Extend doc-converter agent and /convert-docs command to support markdown → PDF/DOCX conversion
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Complexity**: Simple

## Overview

The doc-converter agent currently supports one-directional conversion (DOCX/PDF → Markdown). This plan adds bidirectional support, enabling markdown → PDF and markdown → DOCX conversion using Pandoc.

**Current State**:
- Agent converts DOCX/PDF → Markdown using Pandoc (DOCX) and marker_pdf (PDF)
- Command: `/convert-docs <input-dir> <output-dir>`
- No reverse conversion capability

**Target State**:
- Agent supports both directions: DOCX/PDF ↔ Markdown
- Auto-detection of conversion direction based on file extensions
- Optional output format specification
- Quality preservation in both directions

## Success Criteria
- [x] Markdown files convert to DOCX with excellent quality
- [x] Markdown files convert to PDF with PDF engine (Typst/LaTeX)
- [x] Existing DOCX/PDF → Markdown conversion unchanged
- [x] Direction auto-detected from file extensions
- [x] Batch processing works for both directions
- [x] Documentation updated with bidirectional examples
- [x] Agent validates PDF engine availability
- [x] All tests passing

## Technical Design

### Direction Detection Strategy

**Auto-detection from file extensions**:
```bash
Input: *.md files → Convert FROM markdown TO PDF/DOCX
Input: *.docx/*.pdf files → Convert TO markdown (existing)
```

**Detection logic**:
1. Scan input directory for file types
2. If .md files found: Reverse conversion mode (markdown → PDF/DOCX)
3. If .docx/.pdf files found: Forward conversion mode (existing)
4. If both found: Error or user confirmation required

### Tool Selection

**Markdown → DOCX**:
- Tool: Pandoc
- Command: `pandoc input.md -o output.docx`
- Options: `--reference-doc=template.docx` (optional styling)

**Markdown → PDF**:
- Tool: Pandoc with PDF engine
- Command: `pandoc input.md -o output.pdf --pdf-engine=typst`
- Fallback: `--pdf-engine=xelatex` if Typst unavailable
- Engine check: Validate PDF engine availability before batch processing

**DOCX/PDF → Markdown** (existing):
- No changes to existing implementation

### Output Format Specification

**Default behavior**:
- Single .md file → Convert to both PDF and DOCX
- Multiple .md files → Batch convert to both formats
- User can specify format with flag (future enhancement)

**Output structure**:
```
output_directory/
├── file1.pdf
├── file1.docx
├── file2.pdf
├── file2.docx
└── conversion.log
```

### Agent Modifications

**File location**: `.claude/agents/doc-converter.md`

**Changes needed**:
1. Add direction detection logic in discovery phase
2. Add markdown → DOCX conversion workflow
3. Add markdown → PDF conversion workflow
4. Add PDF engine availability check
5. Update progress markers for bidirectional flows
6. Update validation for reverse conversions

### Command Modifications

**File location**: `.claude/commands/convert-docs.md`

**Changes needed**:
1. Update usage examples for bidirectional conversion
2. Add direction detection logic
3. Update agent invocation prompt for bidirectional context
4. Add output format specification (optional parameter)

## Implementation Phases

### Phase 1: Add PDF Engine Detection [COMPLETED]
**Objective**: Validate PDF engine availability before attempting PDF conversions
**Complexity**: Low

Tasks:
- [x] Add PDF engine detection function to doc-converter.md (line ~390)
  - Check for `typst` command availability
  - Fallback to `xelatex` if Typst unavailable
  - Report engine status to user
- [x] Add engine validation to tool verification section
- [x] Update error messages for missing PDF engine

Testing:
```bash
# Verify engine detection
which typst || which xelatex
```

Expected: Agent reports which PDF engine is available or warns if none found

### Phase 2: Implement Markdown → DOCX Conversion [COMPLETED]
**Objective**: Add DOCX output capability from markdown files
**Complexity**: Low

Tasks:
- [x] Add markdown → DOCX conversion logic to doc-converter.md (line ~110)
  - Detection: Check for .md file extensions in input
  - Command: `pandoc "$file" -o "$output.docx"`
  - Image handling: Pandoc auto-embeds from relative paths
- [x] Add DOCX conversion to batch processing workflow (line ~450)
- [x] Update progress markers for markdown → DOCX flow
- [x] Add validation for DOCX output (file size, structure)

Testing:
```bash
# Test single file conversion
pandoc specs/tests/example.md -o specs/tests/example_converted.docx

# Verify output
ls -lh specs/tests/example_converted.docx
file specs/tests/example_converted.docx
```

Expected: Valid DOCX file created with content from markdown

### Phase 3: Implement Markdown → PDF Conversion [COMPLETED]
**Objective**: Add PDF output capability from markdown files
**Complexity**: Medium

Tasks:
- [x] Add markdown → PDF conversion logic to doc-converter.md (line ~115)
  - Detection: Check for .md file extensions
  - Engine selection: Use Typst if available, fallback to xelatex
  - Command: `pandoc "$file" -o "$output.pdf" --pdf-engine=typst`
  - Error handling: Graceful failure if no PDF engine available
- [x] Add PDF conversion to batch processing workflow (line ~500)
- [x] Update progress markers for markdown → PDF flow
- [x] Add validation for PDF output (file size, page count)
- [x] Handle Unicode and special characters (PDF engine compatibility)

Testing:
```bash
# Test with Typst engine
pandoc specs/tests/example.md -o specs/tests/example_typst.pdf --pdf-engine=typst

# Test with LaTeX engine (fallback)
pandoc specs/tests/example.md -o specs/tests/example_latex.pdf --pdf-engine=xelatex

# Verify output
ls -lh specs/tests/example*.pdf
file specs/tests/example*.pdf
```

Expected: Valid PDF files created with content from markdown

### Phase 4: Integrate Bidirectional Support and Update Documentation [COMPLETED]
**Objective**: Complete integration and update all documentation
**Complexity**: Low

Tasks:
- [x] Update convert-docs.md command with bidirectional examples
  - Add markdown → PDF example
  - Add markdown → DOCX example
  - Update parameter descriptions
- [x] Update doc-converter.md agent with complete bidirectional workflow
  - Update discovery phase to detect direction
  - Update conversion phase for both directions
  - Update example usage section
- [x] Update /home/benjamin/.config/.claude/docs/conversion-guide.md
  - Add "Converting FROM Markdown" section
  - Add markdown → PDF examples
  - Add markdown → DOCX examples
  - Add PDF engine installation instructions
  - Update quick start section
- [x] Add conversion direction to conversion.log output
- [x] Update doc-converter-usage.md with bidirectional workflows

Testing:
```bash
# Test bidirectional conversion with agent
# Create test markdown file
# Run /convert-docs on markdown directory
# Verify PDF and DOCX outputs created
# Check conversion.log for direction information
```

Expected: All documentation updated, bidirectional examples working, logs show direction

## Testing Strategy

### Unit Tests
- **Engine Detection**: Verify PDF engine availability check
- **Direction Detection**: Test file extension recognition logic
- **Format Selection**: Verify correct tool selection for each direction

### Integration Tests
- **Markdown → DOCX**: Convert sample markdown to DOCX, verify content
- **Markdown → PDF**: Convert sample markdown to PDF with both engines
- **Bidirectional Round-Trip**: Markdown → DOCX → Markdown (quality check)
- **Batch Processing**: Convert directory of markdown files to both formats
- **Mixed Input**: Test error handling when both .md and .docx files present

### Quality Tests
- **DOCX Quality**: Verify headings, lists, tables, images, links preserved
- **PDF Quality**: Check formatting, special characters, Unicode support
- **Image Embedding**: Ensure images embedded correctly in DOCX/PDF
- **Error Handling**: Test graceful failure when PDF engine unavailable

### Test Files
Use existing test file: `/home/benjamin/.config/specs/tests/example.md`
- Contains: headings, tables, code blocks, special characters, Unicode, emoji
- Good test case for quality preservation

## Documentation Requirements

### Agent Documentation
**File**: `.claude/agents/doc-converter.md`
- Update Core Capabilities section (line ~12)
- Add bidirectional conversion examples (line ~110)
- Update conversion strategies section (line ~97)
- Add PDF engine requirements (line ~390)

### Command Documentation
**File**: `.claude/commands/convert-docs.md`
- Update usage section with bidirectional syntax
- Add examples for markdown → PDF/DOCX
- Update what it does section

### User Guide
**File**: `.claude/docs/conversion-guide.md`
- Add "Converting FROM Markdown" section (new)
- Add example patterns for reverse conversion
- Document PDF engine installation
- Update tool information section

### Usage Guide
**File**: `.claude/agents/doc-converter-usage.md`
- Add bidirectional workflow examples
- Update troubleshooting for PDF engine issues
- Add performance expectations for reverse conversion

## Dependencies

### System Requirements
- **Pandoc**: Already installed (required for existing DOCX conversion)
- **PDF Engine**: One of the following:
  - Typst (recommended, modern, fast)
  - XeLaTeX (from texlive-full, already installed based on configuration.nix:123)
  - Alternative: pdflatex, lualatex, wkhtmltopdf

### Installation Check
User's system already has texlive-full installed (configuration.nix), which includes xelatex.

Typst installation (optional, recommended):
```bash
# NixOS
nix-env -iA nixpkgs.typst
# or in configuration.nix
environment.systemPackages = [ pkgs.typst ];
```

### No New Agent Dependencies
- Uses existing Pandoc tool
- No changes to marker_pdf usage
- No new external libraries needed

## Risk Assessment

### Risks and Mitigations

**Risk 1: PDF Engine Not Available**
- **Impact**: Medium - Markdown → PDF conversion fails
- **Likelihood**: Low (user has texlive-full with xelatex)
- **Mitigation**: Graceful fallback from Typst → xelatex → error message
- **Mitigation**: Clear error message with installation instructions

**Risk 2: PDF Quality Issues with Special Characters**
- **Impact**: Medium - Unicode/emoji rendering issues in PDF
- **Likelihood**: Medium (LaTeX has known Unicode limitations)
- **Mitigation**: Use Typst engine (better Unicode support)
- **Mitigation**: Document known limitations in guide

**Risk 3: Confusion Between Conversion Directions**
- **Impact**: Low - User converts wrong direction
- **Likelihood**: Low (file extensions are clear indicators)
- **Mitigation**: Clear error messages when mixed file types detected
- **Mitigation**: Agent reports detected direction in progress markers

**Risk 4: Existing Functionality Regression**
- **Impact**: High - Breaking DOCX/PDF → Markdown conversion
- **Likelihood**: Very Low (additive changes only)
- **Mitigation**: No modifications to existing conversion logic
- **Mitigation**: Comprehensive testing of existing workflows

## Implementation Notes

### Code Organization
- Add bidirectional logic alongside existing conversion code
- Maintain separation between forward and reverse conversion
- Reuse validation and logging infrastructure

### Backward Compatibility
- All existing workflows continue to work unchanged
- No breaking changes to command interface
- Additive feature only

### Future Enhancements
Potential follow-up features (not in this plan):
- Explicit format flag: `--to-pdf`, `--to-docx`, `--to-markdown`
- Template support: `--reference-doc=template.docx`
- PDF styling: Custom CSS/templates for PDF output
- Selective conversion: Convert only to one format instead of both

## Git Commit Strategy

### Phase 1 Commit
```
feat(doc-converter): Add PDF engine detection

Add PDF engine availability check for markdown → PDF conversion.
Detect Typst or xelatex and report to user.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Phase 2 Commit
```
feat(doc-converter): Add markdown → DOCX conversion

Implement bidirectional DOCX conversion using Pandoc.
Auto-detect markdown input and convert to DOCX format.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Phase 3 Commit
```
feat(doc-converter): Add markdown → PDF conversion

Implement PDF output from markdown using Pandoc with Typst/LaTeX.
Includes PDF engine selection and Unicode handling.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Phase 4 Commit
```
docs(doc-converter): Update documentation for bidirectional conversion

Add markdown → PDF/DOCX examples to all documentation.
Update conversion guide with reverse conversion workflows.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Next Steps

After plan approval:
1. Execute with `/implement .claude/specs/plans/001_bidirectional_conversion_support.md`
2. The implement command will execute phases 1-4 sequentially
3. Each phase will be tested and committed before proceeding
4. Documentation will be updated in final phase

---

**Plan Status**: Ready for implementation
**Estimated Time**: 1-2 hours (all phases)
**Complexity**: Simple (leveraging existing Pandoc, additive changes only)
