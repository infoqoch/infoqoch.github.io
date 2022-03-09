---
layout: post
author: infoqoch
title: 이펙티브자바, 30. 이왕이면 제네릭 메서드로 만들라
categories: [java]
tags: [java, effective]
---

## 이왕이면 제네릭 메서드
- 제네릭 타입으로 클래스를 작성하듯, 이왕이면 제네릭 메서드를 작성한다. 
- 첫 번째는 제네릭이 없고 두 번째는 제네릭이 있다. 

```java
public static Set union1(Set s1, Set s2){
    Set result = new HashSet(s1);
    result.addAll(s2);
    return result;
}

@Test
void testV1(){
    // given
    Set s1 = new HashSet();
    s1.add(1234);
    s1.add("kim");

    Set s2 = new HashSet();
    s2.add(4567);
    s2.add("lee");

    // when
    final Set result = union1(s1, s2);

    // then
    for (Object o : result) {
        System.out.println("o = " + o);
        System.out.println("o.getClass() = " + o.getClass());
    }
}
```

- 아래는 제네릭 메서드이다.
- 기존의 코드가 정상 동작함을 첫 번째 테스트에서 확인할 수 있다.
- 두 번째 테스트는 제네릭으로 한정한 객체이며 이 경우 컴파일 시점에서 오류를 확인할 수 있다.

```java
public static <E> Set<E> union2(Set<E> s1, Set<E> s2){
    Set<E> result = new HashSet<>(s1);
    result.addAll(s2);
    return result;
}

@Test
void testV2_legacy(){
    // given
    Set s1 = new HashSet(); // 제네릭 메서드로 변경하더라도 제네릭을 선언하지 않은 기존의 코드가 정상적으로 동작한다.
    s1.add(1234);
    s1.add("kim");

    Set s2 = new HashSet();
    s2.add(4567);
    s2.add("lee");

    // when
    final Set result = union2(s1, s2);

    // then
    for (Object o : result) {
        System.out.println("o = " + o);
        System.out.println("o.getClass() = " + o.getClass());
    }
}

@Test
void testV2_type(){
    // given
    Set<Integer> s1 = new HashSet<>();
    s1.add(1234);
    // 컴파일 에러가 발생한다.
    // s1.add("kim");

    Set<Integer> s2 = new HashSet<>();
    s2.add(4567);
    // s2.add("lee");

    // when
    final Set<Integer> result = union2(s1, s2);

    // then
    for (Object o : result) {
        System.out.println("o = " + o);
        System.out.println("o.getClass() = " + o.getClass());
    }
}
```