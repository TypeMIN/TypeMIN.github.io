import assert from 'node:assert/strict';
import { cp, mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

// Exercise the real content loader and static output without touching live content.
const root = fileURLToPath(new URL('../', import.meta.url));
const sandbox = await mkdtemp(join(tmpdir(), 'typemin-content-'));
const readOutput = (path) => readFile(join(sandbox, 'dist', path), 'utf8');
const build = () => spawnSync(process.execPath, [join(root, 'node_modules/astro/bin/astro.mjs'), 'build'], {
  cwd: sandbox,
  encoding: 'utf8',
  env: { ...process.env, ASTRO_TELEMETRY_DISABLED: '1' },
});
const assertBuild = () => {
  const result = build();
  assert.equal(result.status, 0, result.stdout + result.stderr);
};

const count = (html, className) => (html.match(new RegExp(`class="${className}"`, 'g')) ?? []).length;
const writeProject = (slug, content) => writeFile(join(sandbox, 'src/content/projects', `${slug}.md`), content);

try {
  for (const path of ['src', 'public', 'package.json', 'tsconfig.json', 'astro.config.mjs']) {
    await cp(join(root, path), join(sandbox, path), { recursive: true });
  }
  await symlink(join(root, 'node_modules'), join(sandbox, 'node_modules'), 'dir');
  await rm(join(sandbox, 'src/content/projects'), { recursive: true });
  await cp(join(root, 'src/content/projects/.gitkeep'), join(sandbox, 'src/content/projects/.gitkeep'));

  assertBuild();
  const emptyHome = await readOutput('index.html');
  assert.equal(count(emptyHome, 'project-placeholder'), 8);
  assert.equal(count(emptyHome, 'featured-project'), 0);
  assert.match(emptyHome, /href="\/webapp-projects\/"/);
  assert.match(emptyHome, /href="\/portfolio\/"/);
  assert.match(emptyHome, /href="\/about\/"/);
  assert.match(await readOutput('portfolio/index.html'), /00개 프로젝트/);
  assert.match(await readOutput('webapp-projects/index.html'), /웹앱 프로젝트를 준비하고 있습니다/);
  assert.match(await readOutput('about/index.html'), /안녕하세요, TypeMIN입니다/);
  assert.match(await readOutput('projects/index.html'), /url=\/portfolio\//);

  await writeProject('fixture-app', `---
title: "검증용 앱"
summary: "검증을 위한 프로젝트이며 공개되지 않습니다."
tags: [TypeScript, Astro]
featured: true
appUrl: "https://example.com/app"
repoUrl: "https://github.com/TypeMIN/example"
---

## 검증용 본문

Markdown 렌더링을 확인합니다.
`);
  await writeProject('fixture-unfeatured-app', `---
title: "대표가 아닌 앱"
summary: "전체 웹앱 목록에만 표시되어야 합니다."
appUrl: "https://example.com/another-app"
---
`);
  await writeProject('fixture-notes', `---
title: "검증용 기록"
summary: "외부 링크가 없는 대표 프로젝트입니다."
featured: true
---

내용을 준비하고 있습니다.
`);
  assertBuild();
  const home = await readOutput('index.html');
  const portfolio = await readOutput('portfolio/index.html');
  const apps = await readOutput('webapp-projects/index.html');
  const app = await readOutput('portfolio/fixture-app/index.html');
  const notes = await readOutput('portfolio/fixture-notes/index.html');
  assert.match(home, /검증용 앱/);
  assert.match(home, /검증용 기록/);
  assert.doesNotMatch(home, /대표가 아닌 앱/);
  assert.equal(count(home, 'featured-project'), 2);
  assert.equal(count(home, 'project-placeholder'), 6);
  assert.match(home, /class="featured-project" href="https:\/\/example.com\/app" target="_blank" rel="noopener noreferrer"/);
  assert.match(home, /class="featured-project" href="\/portfolio\/fixture-notes\/"/);
  assert.equal(count(apps, 'app-card'), 2);
  assert.match(apps, /대표가 아닌 앱/);
  assert.doesNotMatch(apps, /검증용 기록/);
  assert.match(apps, /href="https:\/\/example.com\/another-app"[^>]*target="_blank"/);
  assert.match(apps, /href="\/portfolio\/fixture-app\/"/);
  assert.match(portfolio, /03개 프로젝트/);
  assert.match(portfolio, /검증용 기록/);
  assert.match(portfolio, /대표가 아닌 앱/);
  assert.match(app, /<h2[^>]*>검증용 본문<\/h2>/);
  assert.match(app, /href="https:\/\/example.com\/app"[^>]*target="_blank"[^>]*rel="noopener noreferrer"/);
  assert.match(app, /href="https:\/\/github.com\/TypeMIN\/example"/);
  assert.match(app, /외부 사이트, 새 탭/);
  assert.match(app, /https:\/\/typemin.github.io\/portfolio\/fixture-app\//);
  assert.doesNotMatch(notes, /앱 실행|소스 코드/);
  assert.match(await readOutput('projects/fixture-app/index.html'), /url=\/portfolio\/fixture-app\//);
  const sitemap = await readOutput('sitemap-0.xml');
  for (const path of ['webapp-projects', 'portfolio', 'about']) {
    assert.ok(sitemap.includes(`https://typemin.github.io/${path}/`));
  }
  assert.ok(sitemap.includes('https://typemin.github.io/portfolio/fixture-app/'));
  assert.match(await readOutput('404.html'), /name="robots" content="noindex"/);

  for (let index = 1; index <= 9; index++) {
    await writeProject(`zz-extra-${index}`, `---
title: "추가 대표 프로젝트 ${index}"
summary: "홈의 8개 표시 제한 검증"
featured: true
---
`);
  }
  assertBuild();
  const fullHome = await readOutput('index.html');
  assert.equal(count(fullHome, 'featured-project'), 8);
  assert.equal(count(fullHome, 'project-placeholder'), 0);
  assert.doesNotMatch(fullHome, /추가 대표 프로젝트 7/);

  await writeProject('fixture-invalid', `---
title: "유효하지 않은 링크"
summary: "유효하지 않은 URL은 배포를 막아야 합니다."
appUrl: "javascript:alert(1)"
---
`);
  const invalid = build();
  assert.notEqual(invalid.status, 0, 'A non-web app URL must fail the build.');
  assert.match(invalid.stdout + invalid.stderr, /http 또는 https/);
  console.log('Content checks passed: eight-slot home, featured limit, webapp/portfolio separation, about, legacy redirects, optional links, Markdown, sitemap, and URL validation.');
} finally {
  await rm(sandbox, { recursive: true, force: true });
}
