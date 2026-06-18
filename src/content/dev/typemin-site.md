---
title: "typemin.github.io"
date: 2026-06-12
category: "web"
tags: ["Astro", "CSS", "TypeScript"]
description: "서브브랜드별로 다른 디자인 언어를 가진 개인 포털 사이트. carlinis(writing), kine.miles(photo), dev, music 네 개의 독립적인 비주얼 아이덴티티로 구성."
type: project
status: active
stack: ["Astro", "TypeScript", "CSS"]
repo: "https://github.com/TypeMIN/TypeMIN.github.io"
demo: "https://typemin.github.io"
draft: false
---

## 개요

개인 포털 사이트. 단일 도메인 아래 네 개의 독립적인 서브브랜드를 운영한다.

- **carlinis** — 원고지 질감의 writing 아카이브
- **kine.miles** — 디지털 카메라 뷰파인더 컨셉의 photo 아카이브
- **dev** — 개발 노트 + 프로젝트 쇼케이스
- **music** — 트랙리스트 형식의 음악 기록

## 기술 스택

- **Astro 6** — 정적 사이트 생성, Content Collections
- **CSS custom properties** — 브랜드별 테마 토큰 (`--brand-accent`, `--content-width` 등)
- **Leaflet.js** — photo 페이지의 촬영 위치 지도
- **GitHub Actions** — 자동 배포

## 설계 원칙

각 서브브랜드는 동일한 `BaseLayout`과 CSS 변수 시스템을 공유하되, 독립적인 시각 언어를 갖는다. 빌드 타임에 모든 페이지가 정적 HTML로 생성된다.
