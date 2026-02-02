# Theorem Environments

**Created**: 2026-01-28
**Purpose**: thmbox package setup and theorem environment usage patterns

---

## Overview

The project uses the `thmbox` package from the Typst preview registry for theorem-like environments. The setup follows AMS journal aesthetics: austere styling with no background colors.

---

## Package Setup

### Import in Main Document

```typst
#import "@preview/thmbox:0.3.0" as thmbox
```

### Initialize in template.typ

```typst
// thmbox initialization function
#let thmbox-show = thmbox.thmbox-init()
```

### Enable in Main Document

```typst
#show: thmbox-show
```

### Allow Page Breaks

```typst
#show figure.where(kind: "thmbox"): set block(breakable: true)
```

---

## Available Environments

The project defines these theorem environments in `template.typ`:

| Environment | Style | Body Text | Usage |
|-------------|-------|-----------|-------|
| `definition` | definition-style | Upright | Definitions of concepts |
| `theorem` | theorem-style | Italic | Major results |
| `lemma` | theorem-style | Italic | Supporting results |
| `axiom` | axiom-style | Italic | Axiomatic rules |
| `remark` | remark-style | Upright | Observations, notes |
| `proof` | (default) | Upright | Proof content |

---

## Style Definitions

### AMS Aesthetic

The project uses a clean, professional style without colored backgrounds:

```typst
#let theorem-style = (
  fill: none,
  stroke: none,
  bodyfmt: it => emph(it),  // Italic body per AMS plain style
)

#let definition-style = (
  fill: none,
  stroke: none,
  // Upright body (thmbox default) per AMS definition style
)

#let axiom-style = (
  fill: none,
  stroke: none,
  bodyfmt: it => emph(it),  // Italic body like theorems
)

#let remark-style = (
  fill: none,
  stroke: none,
  // Upright body (thmbox default)
)
```

### Applying Styles

```typst
#let definition = thmbox.definition.with(..definition-style)
#let theorem = thmbox.theorem.with(..theorem-style)
#let lemma = thmbox.lemma.with(..theorem-style)
#let axiom = thmbox.axiom.with(..axiom-style)
#let remark = thmbox.remark.with(..remark-style)
#let proof = thmbox.proof
```

---

## Usage Patterns

### Basic Definition

```typst
#definition("Formula")[
  The type `Formula` is defined by:
  $ phi.alt, psi ::= p | bot | phi.alt arrow.r psi | square.stroked phi.alt $
]
```

### Named Theorem

```typst
#theorem("Involution")[
  $chevron.l S chevron.r chevron.l S chevron.r phi.alt = phi.alt$
]
```

### Theorem with Proof

```typst
#theorem("Soundness")[
  If $Gamma proves phi.alt$, then $Gamma models phi.alt$.
]

#proof[
  By induction on the derivation of $Gamma proves phi.alt$.
  // ...proof content...
]
```

### Lemma

```typst
#lemma("Truth Lemma")[
  For all formulas $phi.alt$ and worlds $w$ in the canonical model:
  $w satisfies phi.alt$ iff $phi.alt in w$.
]
```

### Axiom

```typst
#axiom("K")[
  $proves square.stroked (phi.alt arrow.r psi) arrow.r (square.stroked phi.alt arrow.r square.stroked psi)$
]
```

### Remark

```typst
#remark[
  This result generalizes to arbitrary modal logics with the finite model property.
]
```

---

## Labeling and References

### Adding Labels

```typst
#definition("Formula") <def-formula>

#theorem("Completeness") <thm-completeness>
```

### Referencing

```typst
By @def-formula, formulas are inductively defined.

The proof of @thm-completeness uses the canonical model construction.
```

---

## Common Patterns

### Definition with Table

```typst
#definition("Propositional")[
  $
    not phi.alt &:= phi.alt arrow.r bot \
    phi.alt and psi &:= not (phi.alt arrow.r not psi) \
    phi.alt or psi &:= not phi.alt arrow.r psi
  $
]

#figure(
  table(
    columns: 4,
    stroke: none,
    table.hline(),
    table.header([*Symbol*], [*Name*], [*Lean*], [*Reading*]),
    table.hline(),
    [$not phi.alt$], [Negation], [`neg`], ["it is not the case that..."],
    // more rows...
    table.hline(),
  ),
  caption: none,
)
```

### Multi-Part Definition

```typst
#definition("Temporal")[
  $
    P phi.alt &:= not H not phi.alt \
    F phi.alt &:= not G not phi.alt \
    triangle.stroked.t phi.alt &:= H phi.alt and phi.alt and G phi.alt \
    triangle.stroked.b phi.alt &:= P phi.alt or phi.alt or F phi.alt
  $
]
```

### Theorem with Conditions

```typst
#theorem("Weak Completeness")[
  For any formula $phi.alt$:
  $models phi.alt$ implies $proves phi.alt$.
]
```

---

## Customization

### Adding New Environments

To add a new environment type:

```typst
// In template.typ
#let corollary-style = (
  fill: none,
  stroke: none,
  bodyfmt: it => emph(it),
)

#let corollary = thmbox.corollary.with(..corollary-style)
```

Then export in the template and use in chapters.

### Custom Numbering

The thmbox package handles numbering automatically. To customize:

```typst
// Reset numbering per chapter
#let theorem = thmbox.theorem.with(
  ..theorem-style,
  base: "heading",  // Number relative to headings
)
```

---

## Best Practices

1. **Use semantic environments**: Match environment type to content (definitions for definitions, theorems for results)
2. **Add labels to key results**: Enable cross-referencing with `<label-name>`
3. **Keep proofs with theorems**: Place proof immediately after theorem
4. **Name important results**: Use descriptive names for findability
5. **Consistent styling**: Don't override styles in chapters
