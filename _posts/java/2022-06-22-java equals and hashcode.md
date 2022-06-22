---
layout: post
author: infoqoch
title: equals와 hashcode의 사용과 재정의의 필요
categories: [java]
tags: [java]
---

# equals와 hashcode?
- 자바에서 두 데이터를 비교하는 방법은 크게 equals, hashcode, ==(동일성비교)가 있다.
- 개발을 하면서 equals와 hashcode를 재정의하는 경우가 존재하였으나 정확한 이해를 바탕으로 하지 않았다. 이번 기회에 정리하였다. 

# Object의 equals와 hashcode
- 모든 객체는 Object가 구현한 equals()와 hashCode()를 사용할 수 있다. 
- 다만 Object의 두 메서드는 매우 엄격하여 사실상 동일성 비교(==)이다. 주소가 같지 않은 이상 필드의 값이 아무리 같아도 false를 반환한다.

```java
public boolean equals(Object obj) {
    return (this == obj);
}
```

- 아래는 Object가 제공하는 equals()와 hashCode()를 통해 두 객체를 비교하였다. 

```java
@Test
@DisplayName("Object는 equals를 ==로서 동일성 비교를 한다. hashcode 역시 주소값을 기준으로 한다.")
void test1(){
    final Tester1 kim1 = new Tester1("kim");
    final Tester1 kim2 = new Tester1("kim");

    System.out.println("(kim1.equals(kim2)) = " + (kim1.equals(kim2))); // false
    System.out.println("(kim1.hashCode()==kim2.hashCode()) = " + (kim1.hashCode() == kim2.hashCode())); // false

    Set<Tester1> set = new HashSet<>();
    set.add(kim1);
    set.add(kim2);
    System.out.println("set.size() = " + set.size()); // 2
}

@RequiredArgsConstructor
static class Tester1{
    private final String name;
}
```

## HashMap, HashSet의 중복 판별 기준은?
- 참고로 위의 코드에서 HashSet 을 사용한 것을 확인할 수 있다. 
- HashMap, HashCode는 유일한 key를 보장하는 자료구조로 잘 알려져 있다. 두 자료구조는 어떤 기준으로 key의 유일함(혹은 중복)을 판별할까? 그것은 바로 해당 메서드의 equals와 hashCode를 통해 판별한다.

# equals와 hashcode의 재정의
- 만약 모든 필드에 동일한 데이터를 가지고 있고, 데이터 타입도 동일하다면, 두 객체가 같다고 정의하고 싶을 수 있다. 단순한 데이터 비교부터 자료구조의 중복 방지를 위한 기능까지 다방면으로 사용할 수 있다. 
- 이때 우리는 IDE의 힘을 빌려서 구현할 수 있다. IDE는 equals와 hashcode를 데이터 타입의 필드를 기준으로 재정의한다. 그러니까 해당 필드가 동일한 객체간에는 true를 반환하도록 재정의한다.

```java
@Test
@DisplayName("hashcode와 equals에 대하여 필드의 값이 같으면 같은 값을 출력하도록 오버라이드 한다. 동등성 비교를 한다.")
void test2(){
    final Tester2 kim1 = new Tester2("kim");
    final Tester2 kim2 = new Tester2("kim");

    System.out.println("(kim1.equals(kim2)) = " + (kim1.equals(kim2))); // true
    System.out.println("(kim1.hashCode()==kim2.hashCode()) = " + (kim1.hashCode() == kim2.hashCode())); // true

    Set<Tester2> set = new HashSet<>();
    set.add(kim1);
    set.add(kim2);
    System.out.println("set.size() = " + set.size()); // 1
}

@RequiredArgsConstructor
static class Tester2{
    private final String name;

    // 아래부터 IDE가 만들어준 내용 그대로 코드를 작성했다.
    // name을 기준으로 equals와 hashcode를 생산함을 확인할 수 있다.
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Tester2 tester2 = (Tester2) o;
        return Objects.equals(name, tester2.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name);
    }
}
```

# equals와 hashcode를 이상하게 정의하면?
- 만약 equals가 항상 true가 나오고 hashcode가 항상 1로 나오도록 이상하게 재정의하면 어떻게 될까? 

```java
@Test
@DisplayName("hashcode와 equals가 이상하게 구현되면 코드가 망가진다.")
void test3(){
    final Tester3 kim = new Tester3("kim");
    final Tester3 lee = new Tester3("lee");

    System.out.println("(kim.equals(lee)) = " + (kim.equals(lee))); // true
    System.out.println("(kim.hashCode()==lee.hashCode()) = " + (kim.hashCode() == lee.hashCode())); // ture

    Set<Tester3> set = new HashSet<>();
    set.add(kim);
    set.add(lee);
    System.out.println("set.size() = " + set.size()); //false
}

@RequiredArgsConstructor
static class Tester3{
    private final String name;

    // 어떤 값이 들어가든 true를 반환한다.
    @Override
    public boolean equals(Object o) {
        return true;
    }

    // 어떤 값이 들어가든 1을 반환한다.
    @Override
    public int hashCode() {
        return 1;
    }
}
```

- 위와 같이 코드를 작성할 경우 HashSet은 두 개의 객체가 동일하다고 본다. 

# hashcode와 equals에 대한 추가 정리
- 자바 기술서나 강의를 보면 hashcode와 equals를 IDE가 정의하는대로 작성하고 건들지 말라는 이야기를 자주 들었다. 그런데 왜 그렇게 해야하는지 알 수 있는 계기가 되었다. HashSet이나 HashMap을 사용할 경우, hashCode()와 equals()를 잘못 정의할 경우, 기대하지 않은 방향으로 데이터가 쌓일 수 있기 때문이다. 
- 추가적으로 hashcode는 int로 리턴한다. 이 말은 hashcode의 범위가 유한하다는 의미로서, 값이 명백히 다르더라도 hashcode는 같을 수 있다. 그러므로 hashcode로만 판별할 수 없고 equals도 항상 같이 비교한다.
- 한편, 값이 같은데 hashcode가 다른 경우를 상상할 수 있다. 그러나 `"abc".equals("abc")` 이 나오는데 hashcode가 달라서 HashSet에 중복으로 들어간다는 것은 상식적으로 이해가 가지 않는다. 그러므로 hashcode를 정의할 때, equals가 같으면, hashcode 역시 동일한 값이 나오도록 재정의해야 한다. 

# primitive type과 String의 동등성, 동일성 비교?
- primitive type과 String은 같은 데이터 타입일 경우 동일성 비교(==)를 할 때 true가 반환된다. 
- 그 이유는 primitive type과 String은 엄격하게 constant pool의 값을 참조하기 때문이다. 같은 주소값이 가지는 것과 동일하며, 그러므로 동일성 비교를 하면 true를 반환한다. 
- String도 마찬가지로 string constant pool을 참조한다. 하지만 `new String("abc");`로 정의할 경우 heap에 데이터를 저장하며 이로 인하여 동일성 비교가 더 이상 먹히지 않는다.

> 참조
>
> https://nesoy.github.io/articles/2018-06/Java-equals-hashcode
>
> https://brunch.co.kr/@mystoryg/133