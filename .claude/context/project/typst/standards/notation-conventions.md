# Notation Conventions

**Created**: 2026-01-28
**Purpose**: Documentation of shared-notation.typ and theory-specific notation modules

---

## Notation Architecture

The project uses a two-tier notation system:

1. **shared-notation.typ** - Common notation across all theories
2. **{theory}-notation.typ** - Theory-specific extensions (e.g., bimodal-notation.typ)

### Import Pattern

Theory-specific modules import and re-export shared notation:

```typst
// In bimodal-notation.typ
#import "shared-notation.typ": *

// Add theory-specific notation...
```

Chapters import from the theory-specific module:

```typst
// In chapters/01-syntax.typ
#import "../template.typ": *
```

The template.typ imports notation, making it available to chapters.

---

## Shared Notation (shared-notation.typ)

### Modal Operators

| Symbol | Command | Description |
|--------|---------|-------------|
| `$square.stroked$` | `nec` | Necessity |
| `$diamond.stroked$` | `poss` | Possibility |

### Truth and Satisfaction

| Symbol | Command | Description |
|--------|---------|-------------|
| `$tack.r.double$` | `trueat` | Truth at / satisfaction |
| `$tack.r.double.not$` | `ntrueat` | Not true at |

### Proof Theory

| Symbol | Command | Description |
|--------|---------|-------------|
| `$tack.r$` | `proves` | Derivability |
| `$Gamma$` | `ctx` | Context |

### Meta-Variables

| Symbol | Command | Description |
|--------|---------|-------------|
| `$phi.alt$` | `metaphi` | Formula variable |
| `$psi$` | `metapsi` | Formula variable |
| `$chi$` | `metachi` | Formula variable |

### Model Notation

| Symbol | Command | Description |
|--------|---------|-------------|
| `$cal(M)$` | `model` | Model |
| `tuple(a, b, c)` | `tuple` | Angle-bracket tuple |
| `$:=$` | `define` | Definition |

### Propositional Connectives

| Symbol | Command | Description |
|--------|---------|-------------|
| `$arrow.r$` | `imp` | Implication |
| `$not$` | `lneg` | Negation |
| `$bot$` | `falsum` | Bottom/falsity |

### Lean Cross-References

| Command | Usage | Output |
|---------|-------|--------|
| `leansrc(module, name)` | `leansrc("Bimodal.Syntax", "Formula")` | `Bimodal.Syntax.Formula` |
| `leanref(name)` | `leanref("semantic_weak_completeness")` | `semantic_weak_completeness` |

### Project References

| Command | Description |
|---------|-------------|
| `proofchecker` | Link to GitHub repository |

---

## Bimodal Notation (bimodal-notation.typ)

### Temporal Operators

| Symbol | Command | Description |
|--------|---------|-------------|
| `$H$` | `allpast` | Always past (H) |
| `$G$` | `allfuture` | Always future (G) |
| `$P$` | `somepast` | Sometime past (P) |
| `$F$` | `somefuture` | Sometime future (F) |
| `$triangle.stroked.t$` | `always` | Always (all times) |
| `$triangle.stroked.b$` | `sometimes` | Sometimes (some time) |

### Temporal Swap

| Command | Description |
|---------|-------------|
| `swap` | Swap operation `$chevron.l S chevron.r$` |

### Frame Structure

| Symbol | Command | Description |
|--------|---------|-------------|
| `$cal(F)$` | `taskframe` | Frame |
| `$cal(D)$` | `Dur` | Duration set |
| `$W$` | `worldstate` | World-states |
| `$R$` | `taskrel` | Task relation |
| `taskto(x)` | N/A | Task transition arrow |

### Model Structure

| Symbol | Command | Description |
|--------|---------|-------------|
| `$V$` | `valuation` | Valuation function |
| `$tau$` | `history` | History |
| `$sigma$` | `althistory` | Alternative history |
| `$"dom"$` | `domain` | Domain function |
| `$H$` | `histories` | Set of histories |

### Truth Relations

| Command | Usage | Description |
|---------|-------|-------------|
| `satisfies` | N/A | Satisfaction symbol |
| `notsatisfies` | N/A | Non-satisfaction |
| `truthat(m, t, x, phi)` | Full truth statement | $M, tau, x \models phi$ |

### Proof Theory Extensions

| Command | Usage | Description |
|---------|-------|-------------|
| `derivable(gamma, phi)` | `derivable(ctx, metaphi)` | $\Gamma \vdash \phi$ |
| `valid(phi)` | `valid(metaphi)` | $\vdash \phi$ |
| `framevalid(f, phi)` | N/A | Frame validity |

### Metalanguage

| Command | Description |
|---------|-------------|
| `Iff` | Metalanguage biconditional (italic "iff") |
| `overset(base, top)` | Place text above symbol |
| `timeshift(sub, sup)` | Time-shift relation |

### Lean Identifiers

| Command | Description |
|---------|-------------|
| `leanTaskRel` | `task_rel` identifier |
| `leanTimeShift` | `time_shift` identifier |
| `leanRespTask` | `respects_task` identifier |
| `leanConvex` | `convex` identifier |
| `leanDomain` | `domain` identifier |
| `leanStates` | `states` identifier |
| `leanNullity` | `nullity` identifier |
| `leanCompositionality` | `compositionality` identifier |

---

## Creating New Theory Notation

When adding a new theory (e.g., `Logos`):

1. Create `notation/{theory}-notation.typ`
2. Import shared notation: `#import "shared-notation.typ": *`
3. Add theory-specific commands
4. Update template.typ to import theory notation
5. Document new commands in this file

### Example Structure

```typst
// logos-notation.typ
#import "shared-notation.typ": *

// Logos-specific operators
#let layerzero = $cal(L)_0$
#let layerone = $cal(L)_1$
// ... etc
```

---

## Best Practices

1. **Prefer semantic names** over cryptic abbreviations
2. **Document all commands** in this conventions file
3. **Re-export shared notation** to avoid double imports
4. **Use consistent naming** (command name matches concept)
5. **Group related commands** under clear section headers
