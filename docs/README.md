# Documentation site

Built with Astro and Starlight. Requires Node.js 22.12 or later.

```sh
cd docs
npm ci
npm run dev
```

`npm run build` builds the site and its search index. `npm run preview` serves the build locally.

Edit pages in `src/content/docs/`. Add screenshots to `src/assets/` and reference them with relative Markdown image paths, with descriptive alt text. Use sample connection details and keep credentials out of screenshots.

GitHub Actions builds documentation changes on pull requests and deploys pushes to `main`. In the repository’s **Settings → Pages**, select **GitHub Actions** as the source and set the custom domain to `unlocalfs.luizkowalski.net`. Add a Cloudflare CNAME for `unlocalfs` pointing to `luizkowalski.github.io`, then enable **Enforce HTTPS** in GitHub Pages when the certificate is ready.

The site URL and `public/CNAME` already use the custom domain. No repository base path is needed.
