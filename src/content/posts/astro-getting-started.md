---
title: "Astro로 정적 사이트 만들기 — 처음 써본 후기"
description: "Next.js 대신 Astro를 선택한 이유, 설치부터 배포까지 정리"
pubDate: 2025-05-28
category: dev
tags: [Astro, 정적사이트, GitHub Pages]
draft: false
---

이 블로그 자체가 Astro로 만들어져 있어요. 처음 써보면서 느낀 점들을 기록합니다.

## 왜 Astro를 골랐나

블로그를 만들 때 선택지가 몇 가지 있었어요.

- **Next.js** — 너무 무겁다. 서버 렌더링까지 필요 없음
- **Gatsby** — 예전에 써봤는데 빌드 느리고 GraphQL이 과함
- **Hugo** — Go 템플릿 문법이 낯섦
- **Astro** — 배워보고 싶었던 것, Markdown 지원이 깔끔함

결국 Astro를 골랐습니다.

## 핵심 개념 — Islands Architecture

Astro의 가장 큰 특징은 **기본적으로 JavaScript를 하나도 안 보냄**이에요.

```astro
---
// 이 부분은 빌드 타임에만 실행됨
const posts = await getCollection('posts');
---

<ul>
  {posts.map(p => <li>{p.data.title}</li>)}
</ul>
```

위 코드는 빌드하면 순수 HTML로 변환돼요. React처럼 런타임에 JS가 실행되지 않습니다.

인터랙티브한 부분이 필요할 때만 `client:load` 같은 지시어로 명시적으로 수화(hydration)시킵니다. 이 개념을 "Islands Architecture"라고 부릅니다.

## Content Collections

Markdown 글들을 타입 안전하게 관리할 수 있어요.

```typescript
// src/content.config.ts
const posts = defineCollection({
  schema: z.object({
    title: z.string(),
    category: z.enum(['dev', 'photo', 'music', 'writing', 'essay']),
    pubDate: z.coerce.date(),
  }),
});
```

`getCollection('posts')`로 가져오면 모든 frontmatter가 TypeScript 타입으로 자동 추론됩니다.

## GitHub Pages 배포

`astro.config.mjs`에 site URL만 설정하면 GitHub Actions로 자동 배포가 됩니다.

```yaml
- name: Build
  run: npm run build

- name: Upload Pages artifact
  uses: actions/upload-pages-artifact@v3
  with:
    path: dist
```

`main`에 push하면 2~3분 안에 배포 완료예요.

## 느낀 점

Astro는 블로그처럼 콘텐츠 중심 사이트에 딱 맞습니다. 불필요한 복잡함 없이 Markdown 쓰고 배포하는 사이클이 깔끔해요.
