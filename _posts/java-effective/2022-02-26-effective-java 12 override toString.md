---
layout: post
author: infoqoch
title: 이펙티브자바, toString을 항상 재정의하라
categories: [java]
tags: [java, effective]
---

## toString
- toString은 Object의 메서드 중 하나이다. 
- 모든 객체는 toString을 재정의 할 수 있다. 
- 아래는 재정의하지 않은 toString을 호출한다.

```java
@AllArgsConstructor
@Builder
public class OverrideToString {
    private String name;
    private int age;
    private String school;
}
```

```java
@Test
void test(){
    final OverrideToString kim = OverrideToString
            .builder()
            .name("kim")
            .age(14)
            .school("kimho high-school")
            .build();

    System.out.println("kim = " + kim.toString());
}
```

```log
kim = effective.c12.OverrideToString@47eaca72
```

- 위의 내용은 클래스의 내용과 해쉬값을 가지고 있지만 사용자 입장에서는 특별한 내용을 가지고 있지 않다.
- toString을 의미가 있는 내용으로 변경한다.

```java
// 해당 객체가 자신을 소개하는 형태로 재정의 하였다. 
@Override
public String toString() {
    return "안녕하세요, 저는 "+name+"입니다. 나이는 "+age+"이며, 현재 다니는 학교는 "+school+"입니다.";
}
```

```log
kim = 안녕하세요, 저는 kim입니다. 나이는 14이며, 현재 다니는 학교는 kimho high-school입니다.
```

## toString의 구현에 대하여
- 로깅, 디버깅을 위하여 toString을 의미있는 형태로 구현하는 것은 대체로 좋다. 해시나 클래스 명은 디버깅 입장에서 큰 의미를 가지기 어렵다. 
- lombok이나 IDE는 모든 필드에 대하여 깔끔하게 구현해주기도 한다. 하지만 이는 해당 객체에 맞는 적절한 구현을 하지 못한다. 그런 경우 개발자가 직접 toString을 재정의 할 수 있다. 
- toString을 재정의 할 때, 가능하면 해당 객체가 가진 주요 정보 모두를 반환하는 것이 좋다. 또한 그것의 의도와 이유를 주석으로 잘 작성한다. 
- List, Map 등 컬렉션의 경우 기본적으로 toString을 잘 구현하였다. 이에 대해서는 특별하게 재정의할 이유가 없다. 