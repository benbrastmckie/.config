# Compilation Guide

**Created**: 2026-01-28
**Purpose**: Typst compilation commands and workflow

---

## Overview

Typst uses single-pass compilation, which is simpler than LaTeX's multi-pass approach. No bibliography preprocessing or multiple runs are needed.

---

## Basic Commands

### Compile to PDF

```bash
typst compile document.typ
```

This produces `document.pdf` in the same directory.

### Specify Output Path

```bash
typst compile document.typ output.pdf
```

### Watch Mode

Automatically recompile on file changes:

```bash
typst watch document.typ
```

Press Ctrl+C to stop watching.

---

## Project Compilation

### Bimodal Reference Manual

```bash
cd Theories/Bimodal/typst
typst compile BimodalReference.typ
```

Output: `BimodalReference.pdf`

### With Watch Mode

```bash
cd Theories/Bimodal/typst
typst watch BimodalReference.typ
```

---

## Compilation Options

### Format Options

| Option | Description |
|--------|-------------|
| `--format pdf` | Output PDF (default) |
| `--format png` | Output PNG images |
| `--format svg` | Output SVG images |

### Other Options

| Option | Description |
|--------|-------------|
| `--root <dir>` | Set project root directory |
| `--font-path <path>` | Add font search path |
| `--open` | Open output after compilation |
| `--ppi <n>` | Set pixels per inch for images |

### Example with Options

```bash
typst compile --root . --open BimodalReference.typ
```

---

## Error Handling

### Viewing Errors

Typst prints errors to stderr with file, line, and column:

```
error: unknown variable: undefined_command
  ┌─ chapters/01-syntax.typ:15:3
  │
15 │   #undefined_command
  │    ^^^^^^^^^^^^^^^^^
```

### Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `unknown variable` | Undefined command/function | Check spelling, imports |
| `expected ...` | Syntax error | Check brackets, commas |
| `cannot import` | Missing package/file | Verify path, package name |
| `font not found` | Missing font | Install font or use fallback |

### Debugging Tips

1. **Check imports**: Verify all `#import` statements
2. **Simplify**: Comment out sections to isolate error
3. **Package version**: Ensure correct version in `@preview/pkg:X.Y.Z`

---

## Package Management

### Using Preview Packages

Packages are automatically downloaded on first use:

```typst
#import "@preview/thmbox:0.3.0" as thmbox
#import "@preview/cetz:0.3.4"
```

### Package Cache

Packages are cached in:
- Linux: `~/.cache/typst/packages/`
- macOS: `~/Library/Caches/typst/packages/`
- Windows: `%LOCALAPPDATA%\typst\packages\`

### Updating Packages

Change version number in import to update:

```typst
// Old
#import "@preview/thmbox:0.2.0" as thmbox
// New
#import "@preview/thmbox:0.3.0" as thmbox
```

---

## Font Setup

### Project Fonts

The project uses New Computer Modern:

```typst
#set text(font: "New Computer Modern", size: 11pt)
```

### Installing Fonts

**Linux**:
```bash
# System-wide
sudo apt install fonts-cmu

# User only
cp fonts/*.ttf ~/.local/share/fonts/
fc-cache -f
```

**macOS**:
```bash
brew install font-new-computer-modern
```

### Font Path

If fonts are in a non-standard location:

```bash
typst compile --font-path ./fonts document.typ
```

---

## Verification

### Successful Compilation

A successful compilation:
1. Produces the PDF file
2. Prints no errors to stderr
3. Returns exit code 0

### Verification Script

```bash
#!/bin/bash
# verify-typst.sh

cd Theories/Bimodal/typst

if typst compile BimodalReference.typ 2>&1; then
    echo "Compilation successful"
    ls -la BimodalReference.pdf
else
    echo "Compilation failed"
    exit 1
fi
```

---

## CI/CD Integration

### Basic CI Check

```yaml
# GitHub Actions example
- name: Compile Typst
  run: |
    typst compile Theories/Bimodal/typst/BimodalReference.typ
```

### With Artifact Upload

```yaml
- name: Compile Typst
  run: typst compile Theories/Bimodal/typst/BimodalReference.typ

- name: Upload PDF
  uses: actions/upload-artifact@v4
  with:
    name: bimodal-reference
    path: Theories/Bimodal/typst/BimodalReference.pdf
```

---

## Comparison with LaTeX

| Aspect | LaTeX | Typst |
|--------|-------|-------|
| Passes needed | 3+ (pdflatex, bibtex, etc.) | 1 |
| Bibliography | Separate bibtex/biber run | Built-in |
| Watch mode | latexmk -pvc | typst watch |
| Auxiliary files | .aux, .log, .toc, etc. | None |
| Cleanup needed | latexmk -c | Not needed |
| Error messages | Often cryptic | Clear with line numbers |

---

## Troubleshooting

### "Package not found"

```
error: package `@preview/thmbox:0.3.0` not found
```

**Fix**: Check internet connection; package downloads automatically.

### "File not found"

```
error: file not found (searched at chapters/01-syntax.typ)
```

**Fix**: Verify file exists at the specified path relative to main document.

### "Unknown font family"

```
warning: unknown font family: New Computer Modern
```

**Fix**: Install the font or use a fallback:
```typst
#set text(font: ("New Computer Modern", "Computer Modern", "Latin Modern Roman"))
```

---

## Best Practices

1. **Use watch mode during development**: Faster iteration
2. **Compile from project root**: Consistent relative paths
3. **Check output after changes**: Verify PDF looks correct
4. **Version pin packages**: Use specific versions like `@preview/thmbox:0.3.0`
5. **Keep Typst updated**: `typst --version` to check
