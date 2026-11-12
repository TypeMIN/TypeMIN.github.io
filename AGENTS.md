# Project instructions

## Workspace

- Current local checkout: `/Users/typemin/Workspace/dev-typemin-github-io`.
- Remote: `https://github.com/TypeMIN/TypeMIN.github.io.git`.
- Use the actual checkout root and relative paths in scripts. The former checkout under `Documents/Projetcs` is historical and must not be used for commands.

## Site structure

- Keep the four menus distinct: Home, Webapp Projects, Portfolio, About.
- Home contains eight featured positions and a short introduction. Empty positions say 준비 중 and are not clickable.
- `featured` selects Home projects; `appUrl` independently selects the Webapp Projects listing. All projects appear in Portfolio.
- Content lives in `src/content/projects/*.md`; profile text lives in `src/config/site.ts`.
- The hub deploys to GitHub Pages. Individual apps have separate Vercel deployments.

## Validation

- For application or content changes, run `npm run check`, `npm test`, and `npm run build`. Check affected layouts and links when changing UI.
- Documentation-only changes need reference and whitespace checks. Do not add or publish invented biography or example projects.

## Notion project record

- Update the existing project page: `https://www.notion.so/4164ce1cf1d081bf9da0df72956d4b6f` (page ID `4164ce1c-f1d0-81bf-9da0-df72956d4b6f`). Do not create duplicate project pages.
- After meaningful completed project work, use the connected Notion tools to update relevant current-state sections and append a dated change note with the change, actual validation, relevant commit/deployment links, and remaining work.
- Keep the page's local path, purpose, GitHub link, project status, and next action accurate when those facts change. Preserve unrelated content and earlier decision history.
- Git is the source of truth for code. Notion records project context and progress; it is not a CMS for the published website or a background synchronization service.
- If Notion is unavailable, report which record remains unsaved instead of claiming synchronization succeeded.
