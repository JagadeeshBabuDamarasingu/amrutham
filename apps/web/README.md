# @amrutham/web

Landing page and privacy page for Amrutham. Next.js (App Router), run with Turbopack.

Run these from Git Bash on Windows (the Windows-native Node/pnpm), not from WSL.

```sh
pnpm install          # once, from the repo root
pnpm dev:web          # http://localhost:3000, Turbopack
pnpm build:web
pnpm check            # typecheck + lint + format check
```

Copy `.env.example` to `.env.local` and set the Play Store link and site URL.
The screenshots in `public/screens` are Doop design previews with sample data;
replace them with real app screenshots when the app is published.
