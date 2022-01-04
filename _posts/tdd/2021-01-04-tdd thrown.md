---
layout: post
author: infoqoch
title: java junit 예외처리
categories: [tdd, java]
tags: [tdd, java]
---

## 예외처리
- 테스트 코드 중 발생하는 예외에 대해서도 테스트를 할 수 있다. 이때 `assertThatThrownBy`를 사용한다.
- assertThatThrownBy 의 경우 Consumer를 사용하며, 해당 컨슈머로 발생된 예외를 다음으로 이어가는 스트림인 `isInstanceOf` 메서드로 받는다.

```java
@Test
void 예외_연습(){
    assertThatThrownBy(() -> {throw new RuntimeException();})
            .isInstanceOf(RuntimeException.class);
}
```
