# Cross-References

**Created**: 2026-01-28
**Purpose**: Labels, references, and Lean cross-reference patterns

---

## Typst Label System

### Creating Labels

Add labels with angle brackets after any element:

```typst
= Syntax <ch-syntax>

== Formulas <sec-formulas>

#definition("Formula") <def-formula>

#theorem("Completeness") <thm-completeness>
```

### Label Naming Conventions

| Element Type | Prefix | Example |
|--------------|--------|---------|
| Chapter | `ch-` | `<ch-syntax>` |
| Section | `sec-` | `<sec-formulas>` |
| Definition | `def-` | `<def-formula>` |
| Theorem | `thm-` | `<thm-completeness>` |
| Lemma | `lem-` | `<lem-truth>` |
| Axiom | `ax-` | `<ax-k>` |
| Figure | `fig-` | `<fig-kripke>` |
| Table | `tab-` | `<tab-operators>` |
| Equation | `eq-` | `<eq-definition>` |

---

## Referencing

### Basic Reference

```typst
See @def-formula for the definition of formulas.

The proof of @thm-completeness uses @lem-truth.
```

### Reference with Context

```typst
As shown in @ch-syntax, formulas are defined inductively.

The operators in @sec-formulas include temporal modalities.
```

### Equation References

```typst
$ phi.alt arrow.r psi $ <eq-implication>

By @eq-implication, implication is primitive.
```

---

## Lean Cross-References

### Purpose

Link Typst documentation to Lean source code using raw text commands.

### Commands (from shared-notation.typ)

```typst
// Full module path reference
#let leansrc(module, name) = raw(module + "." + name)

// Simple name reference
#let leanref(name) = raw(name)
```

### Usage Patterns

#### Referencing a Definition

```typst
The formula type is implemented as #leansrc("Bimodal.Syntax", "Formula").
```

Output: `Bimodal.Syntax.Formula`

#### Referencing a Theorem

```typst
This result corresponds to #leanref("semantic_weak_completeness") in the formalization.
```

Output: `semantic_weak_completeness`

#### Inline Lean Code

```typst
The constructor `atom s` creates atomic formulas.
```

Use backticks for inline Lean identifiers that don't need the cross-reference commands.

### Lean Identifier Commands (from bimodal-notation.typ)

Pre-defined commands for frequently referenced identifiers:

```typst
#let leanTaskRel = raw("task_rel")
#let leanTimeShift = raw("time_shift")
#let leanRespTask = raw("respects_task")
// etc.
```

Usage:
```typst
The #leanTaskRel function defines the task relation.
```

---

## Table of Contents

### Basic Outline

```typst
#outline(title: "Contents", indent: auto)
```

### Styled TOC

```typst
// Bold chapter entries, normal sections
#show outline.entry.where(level: 1): it => {
  v(0.5em)
  strong(it)
}
#outline(title: "Contents", indent: auto)
```

---

## Figure References

### Creating Labeled Figures

```typst
#figure(
  table(
    columns: 4,
    // table content...
  ),
  caption: [Primitive operators of TM logic],
) <tab-primitives>
```

### Referencing Figures

```typst
@tab-primitives shows the primitive operators.
```

---

## Cross-Chapter References

### Pattern

Labels are global across all included files:

```typst
// In 01-syntax.typ
#definition("Formula") <def-formula>

// In 02-semantics.typ
The formulas from @def-formula are interpreted as follows...
```

### Best Practices

1. **Use unique labels**: Prefix with chapter context if needed
2. **Keep labels stable**: Don't rename labels once published
3. **Document key labels**: Note important cross-reference targets

---

## External Links

### Basic Links

```typst
#link("https://example.com")[Link Text]
```

### Styled Links

The project styles links with URLblue:

```typst
#let URLblue = rgb(0, 0, 150)
#show link: set text(fill: URLblue)

// Then links automatically use URLblue
See #link("https://github.com/...")[the repository].
```

### Project-Specific Link

```typst
// From shared-notation.typ
#let proofchecker = link("https://github.com/benbrastmckie/ProofChecker")[`ProofChecker`]

// Usage
This is documented in the #proofchecker project.
```

---

## Best Practices

1. **Label early**: Add labels when creating content, not later
2. **Use consistent prefixes**: Follow the naming conventions table
3. **Keep Lean refs current**: Update leansrc/leanref when Lean code changes
4. **Test cross-references**: Compile to verify all references resolve
5. **Avoid orphaned labels**: Remove labels for deleted content
