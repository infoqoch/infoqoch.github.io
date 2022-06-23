---
layout: post
author: infoqoch
title: junit5 필드 값으로 객체 비교하기 (동등성 비교)
categories: [tdd]
tags: [tdd, junit]
---

## 들어가며
- 객체를 비교할 때 동등성, 동일성으로 비교 가능하다. 
- 동일성은 동일한 주소를 가리키냐의 문제이며 동등성은 내부 데이터의 값이 동일함을 의미한다.
- 동등성 비교를 할 때, 우리는 두 가지 상황을 상상할 수 있다. 
  - 주소만 다르고 값은 완전 일치
  - 필드 일부분(수정일 등)만 차리를 가지며 나머지는 동일
- 이러한 상황에서 사용하는 junit 메서드가 `usingRecursiveComparison()` 이다.

```java
import lombok.RequiredArgsConstructor;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

public class RecursiveTest {

    @Test
    void same_fields(){
        final Tester kim1 = new Tester("kim", 10);
        final Tester kim2 = new Tester("kim", 10);

        assertThat(kim1).isNotEqualTo(kim2); // 필드의 값이 같더라도 isEquals()에 대하여 false 를 반환한다.
        assertThat(kim1).usingRecursiveComparison().isEqualTo(kim2);
    }

    @Test
    void a_little_diff_fields() {
        final Tester kim1 = new Tester("kim", 10);
        final Tester kim2 = new Tester("kim", 11);

        assertThat(kim1).isNotEqualTo(kim2);
        assertThat(kim1).usingRecursiveComparison().isNotEqualTo(kim2);
        assertThat(kim1).usingRecursiveComparison().ignoringFields("name").isNotEqualTo(kim2);
        assertThat(kim1).usingRecursiveComparison().ignoringFields("age").isEqualTo(kim2);
    }

    @RequiredArgsConstructor
    static class Tester{
        private final String name;
        private final int age;
    }
}
```

## 참고
- junit의 경우 메서드 명에서 어떤 기능일지 상상할 수 있도록 잘 만들어졌다. 나도 메서드명을 이렇게 멋지게 만들고 싶다. 아래의 메뉴얼을 훑어 보다가 해당 기능을 찾을 수 있었다. 참고 바란다.

> https://javadoc.io/doc/org.assertj/assertj-core/latest/org/assertj/core/api/AbstractObjectAssert.html#usingComparatorForFields(java.util.Comparator,java.lang.String...)