# Logos Laboratories Project Context

**Project**: Logos Laboratories Website
**Tech Stack**: Astro 5.x, Tailwind CSS v4, TypeScript, Cloudflare Pages

## Coding Standards

### Astro Components

All components should:

- Use TypeScript with strict mode
- Export named component
- Include JSDoc comments for complex props
- Define `interface Props`

```astro
---
interface Props {
  title: string;
  description?: string;
  class?: string;
}

const { title, description, class: className } = Astro.props;
---

<section class={className}>
  <h2>{title}</h2>
  {description && <p>{description}</p>}
  <slot />
</section>
```

### Tailwind Classes

Follow box-model ordering convention:

1. Layout (flex, grid, position)
2. Sizing (w, h)
3. Spacing (p, m, gap)
4. Typography (text, font)
5. Visual (bg, border, shadow)
6. Interactive (hover, focus)
7. Responsive (md:, lg:)

### TypeScript

- Use strict mode
- Define interfaces for all props
- No `any` type (use `unknown` with guards)
- Explicit return types on exported functions

### File Naming

- Components: `PascalCase.astro`
- Pages: `lowercase.astro` or `index.astro`
- Utilities: `camelCase.ts`
- Types: `PascalCase.ts`

### Build Verification

Always run before completing:

```bash
pnpm check    # TypeScript diagnostics
pnpm build    # Production build
```

### Git Commits

Format: `task {N}: {action}`

Examples:

- `task 1: create about page`
- `task 2: complete research`
- `task 3: phase 1: add navigation component`

### Task Management

- Update TODO.md before starting work
- Update state.json for machine state
- Create research reports in `specs/{NNN}_{slug}/reports/`
- Create implementation plans in `specs/{NNN}_{slug}/plans/`
- Create summaries in `specs/{NNN}_{slug}/summaries/`

## Language Routing

| Language | Research Agent   | Implementation Agent  |
| -------- | ---------------- | --------------------- |
| web      | web-research     | web-implementation    |
| neovim   | neovim-research  | neovim-implementation |
| general  | general-research | build                 |
