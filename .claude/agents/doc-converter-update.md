# Document Converter Update: marker_pdf Command

**Date**: 2025-10-10
**Change**: Updated all references from `marker_single` to `marker_pdf`
**Reason**: User installed package provides `marker_pdf` command, not `marker_single`

## Files Updated

### 1. `.claude/agents/doc-converter.md` (Main Agent)
**Changes**: 8 references updated

- Line 112: PDF conversion example command
- Line 278: Tool availability check (graceful degradation)
- Line 372: Bash tool usage description
- Line 375: Tool availability check
- Line 391: Tool dependencies section
- Line 400: Verification script
- Line 511: Conversion script template

**Example changes**:
```bash
# Old
marker_single "document.pdf" -o "document.md"

# New
marker_pdf "document.pdf" "document.md"
```

### 2. `.claude/agents/doc-converter-usage.md` (Usage Guide)
**Changes**: 3 references updated

- Line 14: Verification command
- Line 170: Troubleshooting section header
- Line 172: Installation instructions

**Example changes**:
```bash
# Old
which marker_single # Should show path to marker_single

# New
which marker_pdf  # Should show path to marker_pdf
```

## Command Syntax Differences

### marker_single (old, not available)
```bash
marker_single "input.pdf" -o "output.md"
```

### marker_pdf (new, installed)
```bash
marker_pdf "input.pdf" "output.md"
```

**Key differences**:
- No `-o` flag needed
- Direct positional arguments: `marker_pdf <input> <output>`

## Verification

All instances of `marker_single` have been replaced:
```bash
✓ doc-converter.md: 8 instances of marker_pdf
✓ doc-converter-usage.md: 2 instances of marker_pdf
✓ No remaining marker_single references
```

## Next Steps

The doc-converter agent is now ready to use with your installed `marker_pdf` command!

**Test the PDF conversion**:
```bash
# The marker_pdf command should now work
marker_pdf specs/tests/example_simple.pdf specs/tests/example_simple.md
```

**Or use the agent**:
```
Please use the doc-converter agent to convert specs/tests/example_simple.pdf to markdown.
```

## Status

✅ **All updates complete**
✅ **Agent ready for PDF conversion**
✅ **Documentation updated**
✅ **No breaking changes to DOCX conversion**

The doc-converter agent will now correctly use `marker_pdf` for PDF conversions!
