# EC2 Mac AMI Scan Documentation

Static documentation for [Veertu AWS EC2 Mac AMI Scan](https://github.com/veertuinc/ec2-mac-ami-scan), built with [Docusaurus](https://docusaurus.io/docs).

## Requirements

- Node.js 20+

## Local development

```bash
npm install
npm start
```

The site uses [docs-only mode](https://docusaurus.io/docs/docs-introduction#docs-only-mode) with `baseUrl` `/ec2-mac-ami-scan/`. Open the URL shown in the terminal (for example `http://localhost:3000/ec2-mac-ami-scan/`).

## Production build

```bash
npm run public-build
npx docusaurus serve
```

## CI / deploy

- `npm run staging-build` / `npm run public-build` — production bundles with the correct `url` for metadata (override with `DOCUSAURUS_URL`).
- `npm run staging-deploy` / `npm run public-deploy` — sync `build/` to S3 and (for production) invalidate CloudFront. Requires AWS CLI credentials (as in Jenkins `withAWS`).

## Content

- Main guide: `docs/intro.mdx`
- Third-party licenses: `docs/third-party-license-acknowledgements.md` (uses `mdx.format: md` in front matter so plain-license text is not parsed as MDX)

