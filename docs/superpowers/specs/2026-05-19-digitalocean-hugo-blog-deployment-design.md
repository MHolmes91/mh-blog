# DigitalOcean Hugo Blog Deployment Design

## Goal

Create a separate production blog repository at `MHolmes91/mh-blog` that uses this repository only as its Hugo theme, then deploy that blog to DigitalOcean App Platform as a static site.

## Context

This repository is a Hugo theme named `mh-blog-theme`. Its `theme.toml` requires Hugo `0.146.0` or newer with the extended build. The current `exampleSite/hugo.yaml` provides the reference site configuration, content structure, taxonomies, home JSON search output, related-post settings, and theme parameters.

DigitalOcean App Platform supports static-site components. Its app spec supports `static_sites`, `environment_slug: hugo`, `build_command`, `source_dir`, and `output_dir`. Static sites are served from built assets on DigitalOcean's CDN. The built asset directory should be `public` for Hugo.

## Chosen Approach

Use a new Hugo site repository, `MHolmes91/mh-blog`, with this theme consumed as a Hugo Module dependency.

The blog repository will contain production blog content and site-specific configuration only. The theme repository remains separately maintained and versioned. This keeps theme development isolated from content publishing while allowing the blog to receive theme updates intentionally.

## Alternatives Considered

1. Hugo Module dependency
   Best long-term fit. Keeps the blog repo clean, avoids vendoring the theme, and supports explicit dependency updates.

2. Git submodule under `themes/mh-blog-theme`
   Familiar Hugo layout, but submodules add deployment friction and are easy to forget during local or CI checkouts.

3. Copy the theme into the blog repo
   Fast initial setup, but creates a forked copy of the theme and makes future theme updates manual and error-prone.

## Blog Repository Structure

The new repository should use a standard Hugo site layout:

```text
mh-blog/
  content/
    _index.md
    archives/_index.md
    posts/
  static/
    images/
  hugo.yaml
  go.mod
  .do/app.yaml
  .gitignore
```

The `hugo.yaml` file should copy the reusable pieces from `exampleSite/hugo.yaml`, then replace demo values with production values:

- `baseURL`: the eventual production domain or DigitalOcean preview URL during first deployment.
- `title`: the real blog title.
- `module.imports`: import this theme repository.
- `outputs.home`: include `html`, `rss`, and `json` so the theme's search index continues to work.
- `taxonomies`: keep `tags` and `series` unless the real blog intentionally removes series.
- `related`: keep the same related-post configuration as the example site.
- `params`: configure description, intro text, site icon, and social links for the real blog.

## Theme Dependency

The production blog should use Hugo Modules instead of a copied `themes/` directory. The module import path should be `github.com/MHolmes91/mh-blog-theme`, matching this repository's GitHub remote.

The blog repository should include `go.mod` so Hugo can resolve the theme dependency consistently in local builds and on DigitalOcean App Platform.

## DigitalOcean App Platform Configuration

Deploy `MHolmes91/mh-blog` as a DigitalOcean App Platform static site with a checked-in app spec at `.do/app.yaml`.

The static site component should use:

- `environment_slug: hugo`
- GitHub source `MHolmes91/mh-blog`
- branch `main`
- deploy-on-push enabled
- `source_dir: /`
- `build_command: hugo --gc --minify`
- `output_dir: public`
- ingress route `/`

The app should not define a web service, worker, or database. The site is fully static.

## Build Requirements

The local and App Platform builds must use Hugo extended `0.146.0` or newer because the theme declares that minimum. The deployment should fail fast if DigitalOcean uses an older Hugo version. If App Platform's Hugo buildpack does not provide a sufficiently new version, the fallback is to use a custom build command or Dockerfile only for the build phase, while still deploying the generated `public` directory as a static site.

## Validation

Before creating the DigitalOcean app, validate locally from the new blog repo:

```sh
hugo mod get
hugo --gc --minify
```

Expected result: Hugo generates the site into `public` without template, asset, or module resolution errors.

After deployment, verify:

- Homepage loads from the App Platform URL.
- Post pages render with the theme's header, typography, taxonomy, table of contents, and post chrome.
- `/index.json` exists for search.
- `/tags/`, `/series/`, `/archives/`, RSS, sitemap, CSS, and JS assets load correctly.
- A custom domain can be attached after the first successful deployment.

## Error Handling

If the deployment fails due to module access, confirm that the theme repository is accessible from App Platform and that the module import path matches the actual GitHub remote.

If the deployment fails due to Hugo version support, confirm the App Platform build logs and switch to an explicit build environment that installs the required Hugo extended version.

If assets or search fail after deployment, compare the production `hugo.yaml` against `exampleSite/hugo.yaml`, focusing on `outputs.home`, `params`, and taxonomy settings.

## Implementation Readiness

The core deployment decisions are resolved. Implementation can proceed by creating `MHolmes91/mh-blog`, scaffolding the Hugo site, adding the Hugo Module dependency on `github.com/MHolmes91/mh-blog-theme`, validating the local build, then creating the DigitalOcean App Platform static-site app.
