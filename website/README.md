# GaitGuardAI Marketing Site

Premium health-tech landing page for [GaitGuardAI](https://github.com/aosmannn/GaitGuard).

## Stack

- Next.js (App Router) + TypeScript + Tailwind CSS v4
- Deploy target: Vercel (this directory as the project root)

## Develop

```bash
cd website
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Build

```bash
cd website
npm run build
npm start
```

## Deploy to Vercel

From this directory (preferred):

```bash
cd website
npx vercel login          # once
npx vercel link           # project name: gaitguardai (or gaitguard)
npx vercel --prod
```

Or from the repo root with a linked project whose **Root Directory** is `website`:

```bash
npx vercel --prod
```

Production: [https://gaitguardai.vercel.app](https://gaitguardai.vercel.app)  
Project: `pogamis-projects/gaitguardai` (linked from this directory).

Set `NEXT_PUBLIC_SITE_URL=https://gaitguardai.vercel.app` for correct Open Graph absolute links.

If the site shows a Vercel login wall, disable **Deployment Protection** for Production in the Vercel project settings.

## Notes

- No App Store URL yet — CTAs use “Coming soon” + GitHub.
- Safety disclaimer is visible in hero, safety section, CTA, and footer.
