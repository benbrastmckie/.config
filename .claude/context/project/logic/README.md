# Logic Context README

## Purpose
Canonical proof principles, notation, and strategies for Logos logic (modal + temporal). Lean-specific overlays live in `project/lean4/`; this directory is the authoritative source for proof conventions and notation.

## Terminology Conventions

### Sentence Letters (Preferred Term)

In all logic documentation, use **"sentence letter"** instead of "propositional atom" or "propositional variable":

| Preferred Term | Avoid | Usage |
|----------------|-------|-------|
| sentence letter | propositional atom | Documentation, comments, descriptions |
| sentence letters | propositional variables | Plural references |
| sentence letter | atomic proposition | When referring to syntax |

**Rationale**: "Sentence letter" is the standard term in philosophical logic and modal logic literature. It clearly indicates a syntactic placeholder for a declarative sentence.

**In Languages with Predicates**: A sentence letter is equivalent to a zero-place predicate (a predicate with no arguments). This connection is important when extending to first-order modal logic.

**Note on Lean Code**: Lean type names like `PropVar` and constructor names like `atom` remain unchanged. The terminology preference applies to documentation and prose, not code identifiers.

## Canonical Files
- Standards: `standards/proof-conventions.md`, `standards/notation-standards.md`, `standards/naming-conventions.md`
- Processes: `processes/modal-proof-strategies.md`, `processes/temporal-proof-strategies.md`, `processes/proof-construction.md`, `processes/verification-workflow.md`
- Domain: `domain/kripke-semantics-overview.md`, `domain/metalogic-concepts.md`, `domain/proof-theory-concepts.md`, `domain/task-semantics.md`

## Lean Overlay Boundaries
- Use this directory for logic principles and notation.
- Use `project/lean4/standards/proof-conventions-lean.md` for Lean syntax/tooling/readability.
- Lean tactics/patterns: `project/lean4/patterns/tactic-patterns.md`.

## Usage Guidance
- Agents should load logic standards for any proof principles; add Lean overlays only when executing Lean code.
- Keep references updated to `project/logic/...` paths (avoid legacy `context/logic` or `lean4` roots).
