# Typst Context

**Created**: 2026-01-28
**Purpose**: Context files for Typst document implementation tasks

---

## Overview

Typst is a modern typesetting system used in this project for technical documentation, primarily for the Bimodal logic reference manual at `Theories/Bimodal/typst/`.

### Key Characteristics

- **Single-pass compilation** via `typst compile` (no multi-pass like LaTeX)
- **Package management** via `@preview/` imports (e.g., thmbox, cetz)
- **Modular structure** with `#import` and `#include` statements
- **LaTeX-like typography** via New Computer Modern font

### Project Usage

Primary document: `Theories/Bimodal/typst/BimodalReference.typ`

Structure:
```
Theories/Bimodal/typst/
├── BimodalReference.typ      # Main document
├── template.typ              # Theorem environments (thmbox)
├── notation/
│   ├── shared-notation.typ   # Common notation across theories
│   └── bimodal-notation.typ  # Bimodal-specific notation
└── chapters/
    ├── 00-introduction.typ
    ├── 01-syntax.typ
    ├── 02-semantics.typ
    └── ...
```

---

## Context Files

### Standards
- **typst-style-guide.md** - Document setup, typography, show rules
- **notation-conventions.md** - shared-notation.typ and theory-specific modules
- **document-structure.md** - Main document and chapter organization

### Patterns
- **theorem-environments.md** - thmbox setup and usage
- **cross-references.md** - Labels, refs, Lean cross-references

### Templates
- **chapter-template.md** - Boilerplate for new chapters

### Tools
- **compilation-guide.md** - `typst compile` and `typst watch` usage

---

## Loading Strategy

For Typst implementation tasks, load:
1. This README.md (overview)
2. Relevant standards/patterns based on task
3. Chapter template if creating new content
4. Compilation guide for verification

---

## Differences from LaTeX

| Aspect | LaTeX | Typst |
|--------|-------|-------|
| Compilation | Multi-pass (pdflatex x3) | Single-pass |
| Bibliography | bibtex/biber separate | Built-in |
| Packages | `\usepackage{}` | `#import "@preview/"` |
| Syntax | Commands `\cmd{}` | Functions `#cmd()` |
| Math mode | `$...$` or `\[...\]` | `$...$` |
| Show rules | N/A | `#show: rule` |
