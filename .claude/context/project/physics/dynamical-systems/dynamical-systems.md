# Dynamical Systems in LEAN 4

## Overview
Dynamical systems study the evolution of systems over time. While mathlib4's dynamical systems support is still developing, this file covers available formalizations and patterns for working with discrete and continuous dynamical systems.

## Core Definitions

### Discrete Dynamical System
A discrete dynamical system is defined by iterating a function.

```lean
import Mathlib.Dynamics.FixedPoints.Basic

-- Iteration of a function
def iterate {α : Type*} (f : α → α) : ℕ → α → α
  | 0, x => x
  | n + 1, x => f (iterate f n x)

-- Orbit of a point
def orbit {α : Type*} (f : α → α) (x : α) : Set α :=
  {y | ∃ n : ℕ, iterate f n x = y}

-- Forward orbit
def forwardOrbit {α : Type*} (f : α → α) (x : α) : ℕ → α :=
  fun n => iterate f n x
```

### Fixed Points
```lean
-- Fixed point
def IsFixedPt {α : Type*} (f : α → α) (x : α) : Prop :=
  f x = x

-- Periodic point
def IsPeriodicPt {α : Type*} (f : α → α) (n : ℕ) (x : α) : Prop :=
  n > 0 ∧ iterate f n x = x

-- Minimal period
def minimalPeriod {α : Type*} (f : α → α) (x : α) : ℕ :=
  Nat.find (exists_pos_iterate_eq x)
```

### Continuous Dynamical System (Flow)
```lean
import Mathlib.Topology.ContinuousFunction.Basic

-- Flow on a topological space
structure Flow (X : Type*) [TopologicalSpace X] where
  φ : ℝ → X → X
  φ_zero : ∀ x, φ 0 x = x
  φ_add : ∀ s t x, φ (s + t) x = φ t (φ s x)
  continuous_φ : Continuous (uncurry φ)

-- Trajectory
def trajectory {X : Type*} [TopologicalSpace X] 
    (flow : Flow X) (x : X) : ℝ → X :=
  fun t => flow.φ t x
```

## Key Theorems

### Fixed Point Theorems
```lean
-- Banach fixed point theorem (contraction mapping)
theorem banach_fixedPoint {X : Type*} [MetricSpace X] [CompleteSpace X]
    {f : X → X} (k : ℝ) (hk : 0 ≤ k ∧ k < 1)
    (hf : ∀ x y, dist (f x) (f y) ≤ k * dist x y) :
    ∃! x, f x = x

-- Brouwer fixed point theorem
theorem brouwer_fixedPoint {n : ℕ} 
    {f : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n)}
    (hf : Continuous f) :
    ∃ x ∈ Metric.closedBall 0 1, f x = x

-- Schauder fixed point theorem
theorem schauder_fixedPoint {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    {K : Set X} (hK : IsCompact K) (hK_conv : Convex ℝ K)
    {f : X → X} (hf : Continuous f) (hfK : MapsTo f K K) :
    ∃ x ∈ K, f x = x
```

### Orbit Properties
```lean
-- Orbit is invariant under f
theorem orbit_invariant {α : Type*} (f : α → α) (x : α) :
    ∀ y ∈ orbit f x, f y ∈ orbit f x

-- Periodic points have finite orbits
theorem periodicPt_finite_orbit {α : Type*} (f : α → α) (x : α) (n : ℕ)
    (h : IsPeriodicPt f n x) :
    (orbit f x).Finite

-- Fixed points are periodic with period 1
theorem fixedPt_is_periodicPt {α : Type*} (f : α → α) (x : α)
    (h : IsFixedPt f x) :
    IsPeriodicPt f 1 x
```

### Topological Dynamics
```lean
-- Continuous map preserves compactness
theorem continuous_preserves_compact {X Y : Type*} 
    [TopologicalSpace X] [TopologicalSpace Y]
    {f : X → Y} (hf : Continuous f) {K : Set X} (hK : IsCompact K) :
    IsCompact (f '' K)

-- Omega-limit set
def omegaLimit {X : Type*} [TopologicalSpace X] 
    (f : X → X) (x : X) : Set X :=
  {y | ∃ (n : ℕ → ℕ), StrictMono n ∧ Filter.Tendsto (fun k => iterate f (n k) x) Filter.atTop (𝓝 y)}

-- Omega-limit set is closed and invariant
theorem omegaLimit_closed {X : Type*} [TopologicalSpace X] [T2Space X]
    (f : X → X) (hf : Continuous f) (x : X) :
    IsClosed (omegaLimit f x)

theorem omegaLimit_invariant {X : Type*} [TopologicalSpace X]
    (f : X → X) (x : X) :
    f '' (omegaLimit f x) = omegaLimit f x
```

## Ergodic Theory

### Measure-Preserving Systems
```lean
import Mathlib.MeasureTheory.Measure.MeasureSpace

-- Measure-preserving transformation
def MeasurePreserving {X : Type*} [MeasurableSpace X] 
    (μ : Measure X) (f : X → X) : Prop :=
  Measurable f ∧ ∀ s, MeasurableSet s → μ (f ⁻¹' s) = μ s

-- Ergodic transformation
def Ergodic {X : Type*} [MeasurableSpace X] 
    (μ : Measure X) (f : X → X) : Prop :=
  MeasurePreserving μ f ∧ 
  ∀ s, MeasurableSet s → f ⁻¹' s = s → μ s = 0 ∨ μ sᶜ = 0
```

### Birkhoff Ergodic Theorem
```lean
-- Time average equals space average (simplified statement)
theorem birkhoff_ergodic {X : Type*} [MeasurableSpace X] 
    (μ : Measure X) [IsProbabilityMeasure μ]
    {f : X → X} (hf : MeasurePreserving μ f) (herg : Ergodic μ f)
    {φ : X → ℝ} (hφ : Integrable φ μ) :
    ∀ᵐ x ∂μ, Filter.Tendsto 
      (fun n => (1 / n : ℝ) * ∑ k in Finset.range n, φ (iterate f k x))
      Filter.atTop (𝓝 (∫ y, φ y ∂μ))
```

## Chaos Theory

### Lyapunov Exponents
```lean
-- Lyapunov exponent (simplified)
noncomputable def lyapunovExponent {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (f : X → X) (x : X) (v : X) : ℝ :=
  limsup (fun n : ℕ => (1 / n : ℝ) * Real.log ‖(iteratedDeriv f n x) v‖)

-- Positive Lyapunov exponent indicates chaos
def hasPositiveLyapunovExponent {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (f : X → X) (x : X) : Prop :=
  ∃ v : X, v ≠ 0 ∧ lyapunovExponent f x v > 0
```

### Sensitive Dependence on Initial Conditions
```lean
-- Sensitive dependence
def SensitiveDependence {X : Type*} [MetricSpace X] 
    (f : X → X) (δ : ℝ) : Prop :=
  δ > 0 ∧ ∀ x : X, ∀ ε > 0, ∃ y : X, ∃ n : ℕ, 
    dist x y < ε ∧ dist (iterate f n x) (iterate f n y) ≥ δ
```

## Common Patterns

### Defining Discrete Systems
```lean
-- Pattern: Define discrete dynamical system
def logisticMap (r : ℝ) : ℝ → ℝ :=
  fun x => r * x * (1 - x)

-- Study fixed points
example (r : ℝ) : IsFixedPt (logisticMap r) 0 := by
  unfold IsFixedPt logisticMap
  ring

example (r : ℝ) (hr : r ≠ 1) : 
    IsFixedPt (logisticMap r) ((r - 1) / r) := by
  unfold IsFixedPt logisticMap
  field_simp
  ring
```

### Analyzing Orbits
```lean
-- Pattern: Compute orbit
def computeOrbit {α : Type*} (f : α → α) (x : α) (n : ℕ) : List α :=
  List.range n |>.map (fun k => iterate f k x)

-- Check periodicity
def isPeriodic {α : Type*} [DecidableEq α] (f : α → α) (x : α) (n : ℕ) : Bool :=
  n > 0 && iterate f n x == x
```

### Working with Flows
```lean
-- Pattern: Define flow from ODE
-- dx/dt = f(x)
structure ODE (X : Type*) [NormedAddCommGroup X] [NormedSpace ℝ X] where
  f : X → X
  lipschitz : LipschitzWith K f  -- for some K

-- Solution exists and is unique (Picard-Lindelöf)
theorem ode_solution_exists {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    [CompleteSpace X] (ode : ODE X) (x₀ : X) :
    ∃! φ : ℝ → X, φ 0 = x₀ ∧ ∀ t, deriv φ t = ode.f (φ t)
```

## Mathlib Imports

### Basic Dynamics
```lean
import Mathlib.Dynamics.FixedPoints.Basic    -- Fixed points
import Mathlib.Dynamics.PeriodicPts          -- Periodic points
import Mathlib.Dynamics.Ergodic.MeasurePreserving -- Measure-preserving
```

### Topology and Analysis
```lean
import Mathlib.Topology.MetricSpace.Basic    -- Metric spaces
import Mathlib.Analysis.Calculus.Deriv.Basic -- Derivatives
import Mathlib.MeasureTheory.Measure.MeasureSpace -- Measures
```

### Advanced Topics
```lean
import Mathlib.Analysis.ODE.PicardLindelof   -- ODE solutions
import Mathlib.MeasureTheory.Integral.Bochner -- Integration
```

## Common Tactics

### For Dynamics Proofs
- `unfold iterate` - Expand iteration definition
- `induction n` - Prove by induction on iteration count
- `simp [IsFixedPt]` - Simplify fixed point conditions
- `continuity` - Prove continuity of compositions

### Examples
```lean
-- Prove iteration property
example {α : Type*} (f : α → α) (n m : ℕ) (x : α) :
    iterate f (n + m) x = iterate f n (iterate f m x) := by
  induction n with
  | zero => rfl
  | succ n ih => simp [iterate, ih]

-- Prove orbit contains starting point
example {α : Type*} (f : α → α) (x : α) : x ∈ orbit f x := by
  use 0
  rfl
```

## Standard Examples

### Logistic Map
```lean
def logisticMap (r : ℝ) (x : ℝ) : ℝ := r * x * (1 - x)

-- Bifurcation diagram shows period-doubling route to chaos
-- r < 1: fixed point at 0 is stable
-- 1 < r < 3: fixed point at (r-1)/r is stable
-- r > 3: period-doubling cascade
-- r ≈ 3.57: onset of chaos
```

### Tent Map
```lean
def tentMap (x : ℝ) : ℝ :=
  if x ≤ 1/2 then 2*x else 2*(1-x)

-- Chaotic for almost all initial conditions
```

### Circle Rotation
```lean
def circleRotation (α : ℝ) : ℝ → ℝ :=
  fun x => (x + α) % 1

-- Ergodic if α is irrational
-- Periodic if α is rational
```

### Henon Map
```lean
def henonMap (a b : ℝ) : ℝ × ℝ → ℝ × ℝ :=
  fun (x, y) => (1 - a*x^2 + y, b*x)

-- Strange attractor for a = 1.4, b = 0.3
```

## Applications

### Physics
- Hamiltonian systems
- Conservative systems
- Dissipative systems
- Celestial mechanics

### Biology
- Population dynamics
- Predator-prey models
- Epidemic models

### Economics
- Market dynamics
- Economic cycles
- Game theory

### Engineering
- Control systems
- Signal processing
- Robotics

## Business Rules

1. **Check continuity**: Many results require continuous maps
2. **Verify compactness**: Fixed point theorems often need compact spaces
3. **Use measure theory**: For ergodic theory and statistical properties
4. **Import ODE theory**: For continuous-time systems
5. **Consider numerical methods**: For systems without closed-form solutions

## Common Pitfalls

1. **Assuming ergodicity**: Not all measure-preserving systems are ergodic
2. **Forgetting completeness**: Banach fixed point needs complete spaces
3. **Ignoring topology**: Many results require specific topological properties
4. **Not checking Lipschitz**: ODE uniqueness requires Lipschitz continuity
5. **Missing measure theory**: Ergodic results need measure-theoretic setup

## Advanced Topics

### Symbolic Dynamics
- Shift spaces
- Subshifts of finite type
- Topological entropy

### Hyperbolic Dynamics
- Anosov diffeomorphisms
- Axiom A systems
- Stable/unstable manifolds

### KAM Theory
- Kolmogorov-Arnold-Moser theorem
- Persistence of invariant tori
- Nearly integrable systems

### Bifurcation Theory
- Saddle-node bifurcation
- Period-doubling bifurcation
- Hopf bifurcation

## Relationships

- **Uses**: Topology, analysis, measure theory
- **Related**: Differential equations, ergodic theory, chaos theory
- **Applications**: Physics, biology, economics, engineering

## References

- Mathlib docs: `Mathlib.Dynamics`
- Dynamical systems textbooks (Devaney, Strogatz, Wiggins)
- Ergodic theory references (Walters, Petersen)
- Chaos theory (Alligood, Sauer, Yorke)

## Future Directions

Mathlib4's dynamical systems library is still developing. Potential additions:
- More ergodic theory results
- Symbolic dynamics
- Hyperbolic dynamics
- Bifurcation theory
- Numerical methods for dynamics
