# Logos Laboratories Website Project

## Project Overview

This is the Logos Laboratories website project, built with Astro and Tailwind CSS v4, deployed to Cloudflare Pages. The site serves as the public-facing presence for Logos Laboratories, featuring static content pages, a blog/research section, and project showcases.

**Purpose**: Maintain a modern, performant, and accessible website for Logos Laboratories using static-first web architecture.

## Technology Stack

**Framework:** Astro (static-first, island architecture)
**Styling:** Tailwind CSS v4 (CSS-first configuration)
**Language:** TypeScript (strict mode)
**Deployment:** Cloudflare Pages
**Package Manager:** pnpm
**Build Output:** Static HTML/CSS/JS

## Project Structure

```
src/                          # Astro source code
├── pages/                   # Route-based pages (.astro)
│   ├── index.astro          # Homepage
│   ├── about.astro          # About page
│   └── blog/                # Blog routes
│       ├── index.astro      # Blog listing
│       └── [...slug].astro  # Dynamic blog posts
├── layouts/                 # Page layouts
│   └── BaseLayout.astro     # Base HTML layout
├── components/              # Reusable components
│   ├── Header.astro         # Site header/navigation
│   ├── Footer.astro         # Site footer
│   └── ...                  # Feature components
├── content/                 # Content collections
│   ├── config.ts            # Collection schemas
│   └── blog/                # Blog posts (Markdown/MDX)
├── styles/                  # Global styles
│   └── global.css           # Tailwind imports, @theme config
├── assets/                  # Optimized assets (images, fonts)
└── types/                   # TypeScript type definitions

public/                       # Static files (favicon, robots.txt)
astro.config.mjs              # Astro configuration
tsconfig.json                 # TypeScript configuration
package.json                  # Dependencies and scripts

specs/                        # Task management
├── TODO.md                  # Task list
├── state.json               # Task state
└── {NNN}_{SLUG}/              # Task artifacts
    ├── reports/
    ├── plans/
    └── summaries/

.opencode/                      # Claude Code configuration
├── CLAUDE.md                # Main reference
├── commands/                # Slash commands
├── skills/                  # Skill definitions
├── agents/                  # Agent definitions
├── rules/                  # Auto-applied rules
└── context/                 # Domain knowledge
```

## Web Architecture

### Astro Framework

The site uses Astro's static-first approach:
- Server-rendered HTML with zero JavaScript by default
- Island architecture for interactive components (`client:*` directives)
- Content collections for type-safe Markdown/MDX content
- File-based routing from `src/pages/`

### Tailwind CSS v4

Styling uses Tailwind CSS v4 with CSS-first configuration:
- `@import "tailwindcss"` in global CSS (no JavaScript config file)
- Theme customization via `@theme` directive
- Automatic content detection (no `content` array needed)
- Class ordering enforced by `prettier-plugin-tailwindcss`

### Cloudflare Pages Deployment

Deployment targets Cloudflare Pages:
- Git-triggered builds from main branch
- Edge-distributed static assets
- Automatic HTTPS and CDN
- Preview deployments for branches

## Development Workflow

### Standard Workflow

1. **Identify Need**: Page to create, component to build, content to add
2. **Research**: Review Astro docs, check existing patterns
3. **Implement**: Create/modify Astro components and pages
4. **Test**: Run dev server, verify in browser
5. **Build**: Run production build, check for errors
6. **Deploy**: Push to main branch

### AI-Assisted Workflow

1. **Research**: `/research` - Gather framework docs, patterns
2. **Planning**: `/plan` - Create implementation plan
3. **Implementation**: `/implement` - Execute the plan
4. **Review**: `/review` - Analyze code quality

## Common Tasks

### Creating a New Page

1. Create `.astro` file in `src/pages/`
2. Import and use a layout component
3. Define `interface Props` if the page accepts props
4. Add navigation links as needed

### Creating a Component

1. Create `.astro` file in `src/components/`
2. Define `interface Props` for component inputs
3. Use scoped `<style>` for component-specific styles
4. Add `client:*` directive only if interactivity is required

### Adding Blog Content

1. Create Markdown/MDX file in `src/content/blog/`
2. Include required frontmatter (title, date, description)
3. Content is type-checked against collection schema in `content/config.ts`

### Modifying Styles

1. Global theme changes go in `src/styles/global.css` via `@theme`
2. Component styles use scoped `<style>` blocks
3. Utility classes follow Tailwind's box-model ordering convention

## Verification Commands

```bash
# Start development server
pnpm dev

# Production build (catches type errors, broken references)
pnpm build

# TypeScript + Astro diagnostics
pnpm check

# Preview production build locally
pnpm preview

# Format code
pnpm format
```

## Related Documentation

- `.opencode/context/project/web/` - Web domain knowledge (Astro, Tailwind, TypeScript, Cloudflare)
- `.opencode/rules/web-astro.md` - Astro/Tailwind/TypeScript coding standards
- `.opencode/context/project/web/README.md` - Web context directory overview
