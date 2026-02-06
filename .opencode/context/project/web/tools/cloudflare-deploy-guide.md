# Cloudflare Pages Deployment Guide

Deployment reference for the Logos website on Cloudflare Pages.

## Wrangler CLI Setup

### Installation

```bash
# Add as dev dependency
pnpm add -D wrangler

# Login to Cloudflare
pnpm exec wrangler login

# Verify authentication
pnpm exec wrangler whoami
```

### Configuration

Create `wrangler.jsonc` in the project root:

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "logos-website",
  "pages_build_output_dir": "./dist",
  "compatibility_date": "2026-02-01"
}
```

## Manual Deployment

### Build and Deploy

```bash
# Build the site
pnpm build

# Deploy to Cloudflare Pages
pnpm exec wrangler pages deploy dist/

# Deploy with explicit project name
pnpm exec wrangler pages deploy dist/ --project-name=logos-website
```

### First Deployment

The first `wrangler pages deploy` creates the project automatically. Subsequent deploys update it.

```bash
# First deploy creates project "logos-website"
pnpm exec wrangler pages deploy dist/ --project-name=logos-website

# Output:
# Uploading... (42 files)
# Deployment complete!
# https://abc123.logos-website.pages.dev
```

## Git-Connected Deployment

### Setup (Cloudflare Dashboard)

1. Go to **Workers & Pages** > **Create application** > **Pages**
2. Select **Connect to Git**
3. Authorize and select the repository
4. Configure build settings:

| Setting | Value |
|---------|-------|
| Production branch | `main` |
| Build command | `pnpm build` |
| Build output directory | `dist` |
| Root directory | `/` (or subdirectory if monorepo) |

### Automatic Deployments

Once connected:
- Push to `main` triggers production deployment
- Push to any other branch triggers preview deployment
- Pull requests get automatic preview URLs

## Preview Deployments

### URL Format

| Type | URL Pattern |
|------|-------------|
| Production | `logos-website.pages.dev` |
| Branch preview | `<branch>.logos-website.pages.dev` |
| Commit preview | `<commit-hash>.logos-website.pages.dev` |
| Custom domain | `logos-laboratories.com` |

### Viewing Previews

```bash
# List recent deployments
pnpm exec wrangler pages deployment list --project-name=logos-website

# Tail deployment logs
pnpm exec wrangler pages deployment tail --project-name=logos-website
```

## Environment Variables

### Setting Variables

```bash
# Set production variable
pnpm exec wrangler pages secret put API_KEY --project-name=logos-website

# Variables are entered interactively (not visible in terminal)
```

### Dashboard Method

1. Go to project **Settings** > **Environment Variables**
2. Add variables for Production and/or Preview environments

### Accessing in Code

Environment variables are available in server-side code:

```typescript
// In SSR routes or API endpoints
export function GET({ locals }: APIContext) {
  const apiKey = locals.runtime.env.API_KEY;
  // ...
}
```

For static builds, use `import.meta.env`:

```astro
---
// Public variables (prefixed with PUBLIC_)
const siteUrl = import.meta.env.PUBLIC_SITE_URL;

// Secret variables (server-side only, not in client JS)
const apiKey = import.meta.env.API_KEY;
---
```

### Variable Naming

| Prefix | Visibility |
|--------|-----------|
| `PUBLIC_` | Exposed to client-side code |
| (none) | Server-side only |

## Custom Domains

### Adding a Custom Domain

1. Go to project **Custom domains** > **Set up a custom domain**
2. Enter domain: `logos-laboratories.com`
3. Cloudflare auto-configures DNS if domain is on Cloudflare

### DNS Configuration (External DNS)

If the domain is not on Cloudflare DNS:

| Record Type | Name | Value |
|-------------|------|-------|
| CNAME | `@` | `logos-website.pages.dev` |
| CNAME | `www` | `logos-website.pages.dev` |

SSL is provisioned automatically.

## Rollback

### Via Wrangler

```bash
# List deployments to find ID
pnpm exec wrangler pages deployment list --project-name=logos-website

# Rollback to specific deployment
pnpm exec wrangler pages deployment rollback <deployment-id> --project-name=logos-website
```

### Via Dashboard

1. Go to project **Deployments**
2. Find the target deployment
3. Click the three-dot menu > **Rollback to this deployment**

## Build Configuration

### Headers

Create `public/_headers` for custom HTTP headers:

```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin

/fonts/*
  Cache-Control: public, max-age=31536000, immutable

/_astro/*
  Cache-Control: public, max-age=31536000, immutable
```

### Redirects

Create `public/_redirects` for URL redirects:

```
# Redirect old paths
/old-page  /new-page  301
/blog/old-slug  /blog/new-slug  301

# SPA fallback (if using SSR)
/*  /index.html  200
```

## Deployment Script

Add to `package.json`:

```json
{
  "scripts": {
    "deploy": "astro check && astro build && wrangler pages deploy dist/",
    "deploy:preview": "astro build && wrangler pages deploy dist/ --branch=preview"
  }
}
```

## Free Tier Limits

| Resource | Limit |
|----------|-------|
| Bandwidth | Unlimited |
| Requests | Unlimited |
| Builds per month | 500 |
| Concurrent builds | 1 |
| Max file size | 25 MB |
| Max files per deployment | 20,000 |
| Max project size | 25 MB (total asset size) |
| Custom domains | Unlimited |
