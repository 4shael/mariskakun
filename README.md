# mariskakun

Lightweight Astro site for Mari Skakun's portfolio and catalog.

## Quick start

```bash
npm install
npm run import:wp
npm run dev
```

## Content workflow

- Pages live in `src/content/pages`.
- Paintings live in `src/content/paintings`.
- Run `npm run import:wp` to pull content from the WordPress API.
- Edit or add Markdown files directly to update the site.
- Override the source with `WP_BASE_URL=https://example.com npm run import:wp`.

## Configuration

- Site metadata and navigation live in `src/data/site.json`.
- Update this file when adding new pages to the nav.

## Deploy

Cloudflare Pages works best for global delivery and a free tier. Build command: `npm run build`.
