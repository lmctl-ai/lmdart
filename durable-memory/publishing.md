# Publishing

## Current state

The application is public at https://github.com/lmctl-ai/lmdart and its CI is green. The website content is not published yet: https://www.lmctl.com/tools/lmdart/ returns 404. The website files and supporting raw-index checker changes are staged locally in the lmctl checkout, but they have not been committed or pushed to `lmctl-ai/lmctl/tools`.

The website remote advanced after the local lmdart work began. Synchronize that checkout before committing or pushing; do not force-push over the newer main branch.

## Generate the website tree

From the lmctl website checkout, run:

```sh
bash /path/to/lmdart/scripts/build.sh "$PWD/tools/lmdart"
```

This copies the raw root cover, eight chapters, `lmdart.js`, `boot.js`, CSS, favicon, and JSON data. The authored website `guide.html` and `skill.html` are documentation, not generator outputs.

The deployment inventory should contain 25 lmdart objects, including the `tools/lmdart` and `tools/lmdart/` aliases. There must be no `.map` or `.deps` files.

## Validate and review

Run the standard website checks from the website root:

```sh
npm run decorate:tools
npm run check:tools
npm run check:tools:selftest
```

The raw-index convention is shared website behavior:

- `index.html` with `body[data-page]` is an undecorated executable cover.
- `demo.html` and `demo-*.html` remain raw executable pages.
- External body scripts may be `teavm.js`, `lmdart.js`, or `boot.js`.
- Inline scripts, inline event handlers, and inline styles remain forbidden.

Independent review is required before pushing the website change. Review both the lmdart content and modifications to `scripts/tools/check.lms`, `decorate.lms`, and `run.sh`. Do not commit or deploy while the standard validation is incomplete.

## Commit and deploy

Commit `tools/lmdart/`, the generated tools catalog, the raw-index checker/decorator changes, and their documentation. Push to `lmctl-ai/lmctl` only after review and successful checks.

Publish with the scoped tools publisher:

```sh
AWS_PROFILE=lmctl-website-deploy bash scripts/deploy-tools.sh
```

Never run root-level S3 deletion. The publisher uploads only the tools prefix, writes directory-index aliases, and invalidates changed paths.

## Live verification

From the lmdart checkout, run the full production browser suite:

```sh
DEMO_URL=https://www.lmctl.com/tools/lmdart/ npm test
```

The test accepts the canonical redirect from www.lmctl.com to lmctl.com.

Use lmwebtest for an independent live smoke check. Install it from `github.com/lmctl-ai/lmwebtest`, run `npm ci` and `npx playwright install chromium`, then check the root and each chapter with `node src/cli.js test`. Examples:

```sh
node src/cli.js test https://www.lmctl.com/tools/lmdart/ \
  --title 'lmdart · Dart directly in the browser' \
  --selector '.chapter-grid'

node src/cli.js test https://www.lmctl.com/tools/lmdart/demo-hydration.html \
  --title 'HTML hydration · lmdart' \
  --selector '[data-hydrated="true"]'
```

Use `[data-bound="true"]` for the table, `#scene svg` for SVG, `#pie-chart svg path` for charts, `#tween-dot` for animation, and the visible canvas for Canvas, plot, and WebGL pages. Also check `guide.html` and `skill.html`. A passing report has HTTP 200, the exact title, visible selectors, no browser errors, no failed resources, and no broken images.

After deployment, update the current-state section above rather than leaving a stale 404 note.
