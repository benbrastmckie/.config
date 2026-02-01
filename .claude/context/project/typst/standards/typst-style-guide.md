# Typst Style Guide

**Created**: 2026-01-28
**Purpose**: Document setup, typography conventions, and show rules for Typst documents

---

## Document Setup

### Package Imports

Place package imports at the top of the main document:

```typst
// External packages from preview registry
#import "@preview/cetz:0.3.4"
#import "@preview/thmbox:0.3.0" as thmbox

// Local notation and template
#import "notation/bimodal-notation.typ": *
#import "template.typ": thmbox-show, definition, theorem, lemma, axiom, remark, proof
```

### Document Metadata

Set document metadata early:

```typst
#set document(
  title: "Document Title",
  author: "Author Name",
)
```

---

## Typography Settings

### Font Configuration

Use New Computer Modern for LaTeX-like appearance:

```typst
#set text(font: "New Computer Modern", size: 11pt)
```

### Paragraph Settings

Match LaTeX paragraph behavior:

```typst
#set par(
  justify: true,
  leading: 0.55em,           // Line spacing
  spacing: 0.55em,           // Paragraph spacing
  first-line-indent: 1.8em,  // First-line indent
)
```

### Page Layout

Professional margins:

```typst
#set page(
  numbering: "1",
  number-align: center,
  margin: (x: 1.5in, y: 1.25in),
)
```

### Heading Configuration

```typst
#set heading(numbering: "1.1")
#show heading: set block(above: 1.4em, below: 1em)
```

---

## Show Rules

### Global Text Substitutions

Automatically style specific text:

```typst
// Bold "TM" throughout document
#show "TM": strong
```

### Link Styling

Style hyperlinks with a consistent color:

```typst
#let URLblue = rgb(0, 0, 150)
#show link: set text(fill: URLblue)
```

### URL Text Formatting

Use `raw()` for monospace URL display (equivalent to LaTeX `\texttt{}`):

```typst
// URL with monospace text display
#link("https://www.example.com")[#raw("www.example.com")]

// Citation links
See #link("https://arxiv.org/abs/2401.12345")[#raw("arxiv.org/abs/2401.12345")]
```

This matches the LaTeX convention:
```latex
\href{https://www.example.com}{\texttt{www.example.com}}
```

### Theorem Environment Initialization

Enable thmbox theorem environments:

```typst
#show: thmbox-show
```

### Breakable Figures

Allow theorem boxes to break across pages:

```typst
#show figure.where(kind: "thmbox"): set block(breakable: true)
```

---

## Code Conventions

### File Organization

1. Package imports (external, then local)
2. Document metadata
3. Typography settings (`#set` rules)
4. Page layout
5. Show rules
6. Custom commands/functions
7. Content (title page, abstract, chapters)

### Naming Conventions

- **Files**: lowercase with hyphens (`shared-notation.typ`)
- **Functions**: snake_case for internal, camelCase avoided
- **Let bindings**: lowercase with descriptive names

### Comments

Use `//` for single-line comments:

```typst
// ============================================================================
// Section Header
// ============================================================================
```

---

## Math Mode

### Inline Math

```typst
The formula $phi.alt arrow.r psi$ represents implication.
```

### Display Math

```typst
$
  phi.alt, psi ::= p | bot | phi.alt arrow.r psi | square.stroked phi.alt
$
```

### Math Symbols

Use Typst symbol names (similar to Unicode names):
- `square.stroked` for box
- `diamond.stroked` for diamond
- `arrow.r` for right arrow
- `phi.alt` for Greek letters

---

## Tables

### Standard Table Format

```typst
#figure(
  table(
    columns: 4,
    stroke: none,
    table.hline(),
    table.header(
      [*Symbol*], [*Name*], [*Lean*], [*Reading*],
    ),
    table.hline(),
    [$p$], [Atom], [`atom s`], [sentence letter],
    // ... more rows
    table.hline(),
  ),
  caption: none,
)
```

---

## Custom Commands

### Horizontal Rule

```typst
#let HRule = line(length: 100%, stroke: 0.5pt)
```

### Semantic Functions

```typst
#let tuple(..args) = $lr(angle.l #args.pos().join(", ") angle.r)$
#let overset(base, top) = $limits(#base)^#top$
```

---

## Anti-Patterns

**Avoid**:
- Using `#show` rules in chapter files (keep in main document)
- Redefining standard functions without clear purpose
- Hardcoding colors (use named constants like `URLblue`)
- Mixing content with configuration in the same section
