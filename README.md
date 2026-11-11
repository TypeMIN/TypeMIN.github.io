# TypeMIN

[typemin.github.io](https://typemin.github.io) — 프로젝트와 웹앱을 바로 여는 개인 허브.

Astro와 TypeScript로 만든 정적 사이트입니다. 소개와 프로젝트 설명은 GitHub Pages에서 제공하고, 개별 앱은 Vercel 등의 외부 배포 주소로 연결합니다.

홈에는 웹앱·포트폴리오·GitHub 바로가기와 앱 실행 목록을 배치했습니다. `appUrl`이 있는 모든 프로젝트는 대표 여부와 관계없이 허브에 표시되며, 앱 카드를 누르면 새 탭에서 실행됩니다. 프로젝트 소개와 소스 코드 링크는 별도로 제공합니다.

## 로컬 실행

Node.js 24.14.1 이상인 24 버전과 npm을 사용합니다.

```sh
nvm use
npm ci
npm run dev
```

터미널에 표시된 로컬 주소를 엽니다. 기본 주소는 `http://127.0.0.1:4321`입니다.

```sh
npm run check   # TypeScript와 Astro 콘텐츠 검사
npm test        # 임시 폴더에서 빈 상태·프로젝트 등록·잘못된 링크 검증
npm run build   # dist/에 정적 사이트 생성
npm run preview # 빌드 결과 확인
```

## 소개 수정

`src/config/site.ts`에서 이름, 첫 화면 문구, 소개와 GitHub 주소를 수정합니다. 경력이나 연락처가 준비되면 이 파일과 소개 섹션을 함께 확장하면 됩니다.

## 프로젝트 추가

`src/content/projects/`에 Markdown 파일을 추가합니다. 파일명은 영문 소문자·숫자·하이픈을 사용합니다. `my-app.md`를 추가하면 `/projects/my-app/` 페이지가 생성됩니다. 아래 내용은 등록 형식을 설명하는 예시이며 실제 프로젝트로 포함되어 있지 않습니다.

```md
---
title: "프로젝트 이름"
summary: "어떤 문제를 해결하는 프로젝트인지 한두 문장으로 설명합니다."
tags: [TypeScript, React]
featured: true
appUrl: "https://your-project.vercel.app"
repoUrl: "https://github.com/TypeMIN/your-project"
---

## 프로젝트 소개

작업의 배경과 주요 기능을 소개합니다.

## 만든 과정

내 역할, 기술 선택의 이유, 해결한 문제를 정리합니다.
```

- `title`과 `summary`는 필수입니다.
- `tags`는 생략하면 빈 목록, `featured`는 생략하면 `false`입니다.
- `featured: true`인 프로젝트는 홈의 프로젝트 노트에 최대 3개 표시합니다. 앱 실행 목록에는 `appUrl`이 있는 프로젝트가 모두 표시됩니다.
- 프로젝트는 파일명 순으로 정렬합니다. 파일명을 바꾸면 상세 주소도 변경됩니다.
- `appUrl`과 `repoUrl`은 선택 사항입니다. 준비되지 않았다면 해당 줄을 삭제합니다. 빈 문자열이나 예시 주소를 실제 공개 파일에 남기지 마세요.
- 앱과 저장소 주소는 `https://` 또는 `http://`로 시작하는 전체 URL을 사용합니다. 링크는 외부 사이트라는 안내와 함께 새 탭에서 열립니다.
- 중첩 폴더와 별도의 `slug` 필드는 사용하지 않습니다. 상세 주소는 파일명으로 결정합니다.
- 모든 Markdown 파일은 공개됩니다. 작성 중인 초안은 이 폴더 밖에서 관리합니다.

프로젝트가 없으면 준비 중 안내가 표시됩니다. 기본 공유 이미지는 `public/og-default.png`이며, 편집용 원본은 같은 폴더의 SVG입니다.

## Vercel 앱 연결

1. 개별 앱은 별도 저장소와 Vercel 프로젝트에서 배포합니다.
2. Vercel이 제공하는 고정 운영 주소를 해당 프로젝트의 `appUrl`에 넣습니다. 일회성 미리보기 주소는 사용하지 않습니다.
3. 이 저장소의 `main`에 변경 사항을 push합니다.

앱 코드, 로그인, 데이터 저장 기능은 이 저장소에 넣지 않습니다. GitHub Pages 사이트에는 Vercel 토큰이나 서버 환경 변수가 필요하지 않습니다.

## 배포

GitHub 저장소의 **Settings → Pages → Source**를 **GitHub Actions**로 설정합니다. 주소는 `https://typemin.github.io`이며 HTTPS를 사용합니다.

`main`에 push하면 워크플로가 의존성 설치, 검사, 콘텐츠 테스트, 빌드 후 GitHub Pages에 배포합니다. PR에서는 검사·테스트·빌드만 실행하며, Actions 탭에서 수동 배포도 가능합니다. 빌드 또는 검사 실패 시 배포하지 않고 기존 사이트를 유지합니다.

배포 뒤에는 Actions 성공 여부와 홈·프로젝트 목록·프로젝트 상세 링크를 확인합니다. 존재하지 않는 주소에서는 사용자 지정 404 페이지가 표시됩니다.

## 초기화 이력

기존 사이트 파일을 삭제한 커밋과 새 사이트를 작성한 커밋을 분리했습니다. 이전 사이트는 Git 이력에 보존되어 있습니다. 저장소 외부의 서비스와 데이터, 다른 브랜치·태그는 초기화하지 않았습니다.
