# Signed + Notarized Release Pipeline

This repository includes a GitHub Actions workflow that builds, signs, notarizes, staples, and publishes the macOS app.

Workflow file:
- `.github/workflows/release-macos.yml`

Scripts:
- `scripts/build-macos-app.sh`
- `scripts/sign-notarize-package.sh`

## Required GitHub Secrets

Set these in:
`Settings -> Secrets and variables -> Actions -> New repository secret`

1. `DEVELOPER_ID_APPLICATION_IDENTITY`
- Example format:
  `Developer ID Application: Your Name (TEAMID)`

2. `DEVELOPER_ID_APP_CERT_BASE64`
- Base64 of your Developer ID Application `.p12` certificate file.
- Create base64:
  `base64 -i developer_id_app.p12 | pbcopy`

3. `DEVELOPER_ID_APP_CERT_PASSWORD`
- Password used when exporting the `.p12`.

4. `APPLE_ID`
- Your Apple ID email used for notarization.

5. `APPLE_APP_SPECIFIC_PASSWORD`
- App-specific password from Apple ID account.

6. `APPLE_TEAM_ID`
- Your Apple Developer Team ID.

## How to Release

1. Push a semantic version tag:
- `git tag v1.0.0`
- `git push origin v1.0.0`

2. Workflow will:
- Build `Pirs5PDFCompressor.app`
- Sign with Developer ID
- Submit to Apple notarization and wait
- Staple notarization ticket
- Create `dist/Pirs5PDFCompressor-macos-arm64-app.zip`
- Attach it to the GitHub Release for that tag

You can also run it manually from the Actions tab using `workflow_dispatch`.
