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

try {
  for (const path of ['src', 'public', 'package.json', 'tsconfig.json', 'astro.config.mjs']) {
    await cp(join(root, path), join(sandbox, path), { recursive: true });
  }
  await symlink(join(root, 'node_modules'), join(sandbox, 'node_modules'), 'dir');
  // Keep the test independent of the owner's published projects.
  await rm(join(sandbox, 'src/content/projects'), { recursive: true });
  await cp(join(root, 'src/content/projects/.gitkeep'), join(sandbox, 'src/content/projects/.gitkeep'));

  assertBuild();
  assert.match(await readOutput('index.html'), /아직 공개된 웹앱이 없습니다/);
  assert.match(await readOutput('projects/index.html'), /00개 프로젝트/);
  assert.doesNotMatch(await readOutput('projects/index.html'), /class="project-card"/);

  await writeFile(join(sandbox, 'src/content/projects/fixture-app.md'), `---
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
  await writeFile(join(sandbox, 'src/content/projects/fixture-unfeatured-app.md'), `---
title: "대표가 아닌 앱"
summary: "대표 프로젝트 여부와 관계없이 허브에서 실행할 수 있어야 합니다."
appUrl: "https://example.com/another-app"
---
`);
  await writeFile(join(sandbox, 'src/content/projects/fixture-notes.md'), `---
title: "검증용 기록"
summary: "외부 링크가 없는 프로젝트입니다."
---

내용을 준비하고 있습니다.
`);
  assertBuild();
  const home = await readOutput('index.html');
  const list = await readOutput('projects/index.html');
  const app = await readOutput('projects/fixture-app/index.html');
  const notes = await readOutput('projects/fixture-notes/index.html');
  assert.match(home, /검증용 앱/);
  assert.doesNotMatch(home, /검증용 기록/);
  assert.doesNotMatch(home, /아직 공개된 웹앱이 없습니다/);
  assert.match(home, /대표가 아닌 앱/);
  assert.match(home, /href="https:\/\/example.com\/another-app"[^>]*target="_blank"/);
  assert.match(home, /href="https:\/\/example.com\/app"[^>]*class="app-launch"[^>]*target="_blank"[^>]*rel="noopener noreferrer"/);
  assert.match(home, /href="\/projects\/fixture-app\/"/);
  assert.equal((home.match(/class="app-card"/g) ?? []).length, 2);
  assert.match(list, /03개 프로젝트/);
  assert.match(list, /검증용 기록/);
  assert.match(list, /href="\/projects\/fixture-app\/"/);
  assert.match(list, /href="https:\/\/example.com\/app"/);
  assert.match(app, /<h2[^>]*>검증용 본문<\/h2>/);
  assert.match(app, /TypeScript/);
  assert.match(app, /href="https:\/\/example.com\/app"[^>]*target="_blank"[^>]*rel="noopener noreferrer"/);
  assert.match(app, /href="https:\/\/github.com\/TypeMIN\/example"/);
  assert.match(app, /외부 사이트, 새 탭/);
  assert.match(app, /https:\/\/typemin.github.io\/projects\/fixture-app\//);
  assert.doesNotMatch(notes, /앱 실행|소스 코드/);
  assert.match(await readOutput('sitemap-0.xml'), /https:\/\/typemin.github.io\/projects\/fixture-app\//);
  assert.match(await readOutput('404.html'), /name="robots" content="noindex"/);

  await writeFile(join(sandbox, 'src/content/projects/fixture-invalid.md'), `---
title: "유효하지 않은 링크"
summary: "유효하지 않은 URL은 배포를 막아야 합니다."
appUrl: "javascript:alert(1)"
---
`);
  const invalid = build();
  assert.notEqual(invalid.status, 0, 'A non-web app URL must fail the build.');
  assert.match(invalid.stdout + invalid.stderr, /http 또는 https/);
  console.log('Content checks passed: empty state, featured selection, Markdown routes, optional links, metadata, sitemap, and invalid URLs.');
} finally {
  await rm(sandbox, { recursive: true, force: true });
}
