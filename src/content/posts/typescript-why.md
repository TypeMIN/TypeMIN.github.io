---
title: "TypeScript를 쓰는 이유 — 귀찮음보다 편함이 크다"
description: "JavaScript만 쓰다가 TypeScript로 넘어오면서 달라진 것들"
pubDate: 2025-05-05
category: dev
tags: [TypeScript, JavaScript, 개발]
draft: false
---

TypeScript를 처음 봤을 때는 "왜 이렇게 복잡하게 써야 하지?" 싶었어요.

```typescript
// 이걸 굳이?
function greet(name: string): string {
  return `Hello, ${name}`;
}
```

그냥 `function greet(name)` 쓰면 되는 거 아닌가 했습니다.

## 생각이 바뀐 계기

프로젝트가 조금만 커지면 JavaScript만으로는 힘들어지더라고요.

```javascript
// 이 함수가 뭘 반환하는지 바로 알 수 있나요?
function processUser(user) {
  return {
    ...user,
    displayName: user.firstName + ' ' + user.lastName,
    age: calculateAge(user.birthDate),
  };
}
```

`user`에 어떤 필드가 있어야 하는지, `processUser`가 뭘 반환하는지 — 파일을 열어서 코드를 처음부터 읽어야 알 수 있어요.

TypeScript는 이걸 타입으로 명시합니다.

```typescript
interface User {
  firstName: string;
  lastName: string;
  birthDate: Date;
  email: string;
}

interface ProcessedUser extends User {
  displayName: string;
  age: number;
}

function processUser(user: User): ProcessedUser {
  return {
    ...user,
    displayName: `${user.firstName} ${user.lastName}`,
    age: calculateAge(user.birthDate),
  };
}
```

코드 자체가 문서가 됩니다.

## 실제로 도움됐던 순간들

**1. 오타를 빌드 전에 잡아줌**

```typescript
const user = { name: 'TypeMIN', role: 'admin' };
console.log(user.naem); // ❌ Property 'naem' does not exist
```

런타임에서 `undefined`가 되어서 나중에 발견되는 버그를 미리 잡아줍니다.

**2. 자동완성이 정확해짐**

IDE가 타입 정보를 알기 때문에 정확한 자동완성을 제안해요. 객체의 어떤 필드가 있는지 외울 필요가 없습니다.

**3. 리팩토링이 안전해짐**

함수 시그니처를 바꾸면 그걸 쓰는 모든 곳에서 에러가 표시됩니다. 일일이 찾아다닐 필요 없이.

## 귀찮은 것도 있다

솔직히 말하면 타입 정의가 귀찮을 때 있어요. 특히 외부 라이브러리 타입이 복잡할 때.

그래도 결론적으로는 **쓰는 게 낫다**는 생각이에요. 초반에 타입 정의하는 수고가 나중의 디버깅 시간보다 훨씬 작습니다.
