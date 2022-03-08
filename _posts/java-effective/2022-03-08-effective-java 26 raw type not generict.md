---
layout: post
author: infoqoch
title: 이펙티브자바, 26. 로 타입은 사용하지 마라
categories: [java]
tags: [java, effective]
---

## 제네릭 타입과 제네릭 매개변수의 정의
- 클래스와 인터페이스를 선언할 때 타입 매개변수가 쓰이면, 이를 제네릭 클래스 혹은 제네릭 인터페이스라 한다. 이를 통틀어서 제네릭 타입이라 한다.
- 제네릭 타입은 매개변수화 타입(parameterized type)을 정의한다.

```java
List list = new ArrayList(); // 제네릭 이전의 방식. 타입이 정해져 있지 않다. 제네릭을 쓸 수 있는 인터페이스, 클래스이다.
List<String> list = new ArrayList<>(); // 제네릭을 명시하였다.  매개변수화 타입을 String으로 정의하였다. 
```

- 제네릭 타입은 제네릭이 없었던 이전의 코드와의 호환성을 위하여 타입 없이 선언될 수 있다. 이로 인하여 제네릭이 널리 쓰일 수 있었다. 더 구체적으로 말하자면, 런타임 시점에서 이전의 코드와 동일한 동작을 위하여, 제네릭은 아래와 같은 두 가지 특징을 지니게 된다. 
    - 첫 번째는 컴파일 시점에서 제네릭의 유효성을 검사한다.
    - 두 번째는 컴파일 이후 런타임 시점에서 제네릭에 관련한 데이터는 소거된다. 
- 제네릭이 보편화된 현 시점에서, raw 타입을 절대로 사용하지 않는다. 그 이유는 제네릭의 안정성과 표현력을 지키기 위해서이다.

```java
@Test
// 확실하게 문제가 없을 경우만 사용해야 한다. 
// 제네릭 없이 선언한 것(List list}에 대한 경고를 없애기 위하여 사용했다.
@SuppressWarnings("unchecked") 
void raw_generic_typeconvert_exception() {
    // given
    List list = new ArrayList<>();

    // when
    list.add("hello");
    list.add(1234);
    list.forEach(obj -> System.out.printf("obj value : %s obj class : %s\n", obj, obj.getClass()));

    // then
    Assertions.assertThatThrownBy(()->{
        list.forEach(obj -> {
            String converted = (String) obj; // 1234를 캐스팅하는 과정에서 런타임 예외 발생
        });
    }).isInstanceOf(ClassCastException.class);
}
```

```log
obj value : hello obj class : class java.lang.String
obj value : 1234 obj class : class java.lang.Integer
```

- 제네릭으로 타입을 명시하지 않으면 어떤 데이타가 들어와있을지 알 수 없다. 명시적인 표현력을 잃어버린다.
- 데이타에 대한 한정을 하지 않기 때문에 어떤 요소든 삽입될 수 있다. 이후 이를 꺼내서 사용할 때 타입 컨버팅의 문제가 발생한다.
- 제네릭으로 구현하면 아래와 같다. 

```java
@Test
void compile_error() {
    // given
    List<String> list = new ArrayList<>();

    // when
    list.add("kim");

    // then 
    // 컴파일 에러 발생 
    // java.lang.Error: Unresolved compilation problem. The method add(int, String) in the type List<String> is not applicable for the arguments (int)
    list.add(1234); 
}
```

- 제네릭으로 할 경우 컴파일 시점에서 문제를 잡아낸다. 
- 캐스팅을 할 필요가 없이 바로 꺼내 쓸 수 있다. 자바에서 타입컨버터를 제공해준다. 
- 컴파일 시점에서 에러를 잡고, 타입 컨버터를 지원하는 등 제너릭의 장점은 매우 많다. 제너릭의 안정성과 표현력을 위하여 반드시 raw 타입을 사용하지 않는다!!

## raw 타입, List<Object>의 차이
- List와 List<Object>는 제네릭의 존재에 따른 차이를 가진다. 그러니까 로타입은 제너릭을 아예 사용하지 않고, 후자는 모든 타입을 허용한다는 의미이다.
- 하지만, Object[] 매개변수에 String[] 을 대신할 수 있는 것과 달리, List<Object>는 List<String>으로 대체할 수 없다. 그러니까 Object는 모든 객체의 상위 클래스이지만, 제네릭으로 선언된 순간 상위-하위 클래스로의 다형성이 불가능하다.

```java
@Test
void raw타입을_매개변수로() {
    List<String> list = new ArrayList<>();
    unsafeAdd(list, "hi");
    unsafeAdd(list, 123);

    // 런타임 시점에서 에러가 발생한다.
    Assertions.assertThatThrownBy(()->{
        list.forEach(obj -> {
            String converted = (String) obj;
        });
    }).isInstanceOf(ClassCastException.class);
}

void unsafeAdd(List list, Object o) {
    list.add(o);
}


@Test
void generic_object를_매개변수로() {
    List<String> list = new ArrayList<>();

    // 컴파일 시점에서 에러가 발생한다.
    // Integer와 String은 Object의 하위 클래스이지만 제네릭에서는 허용되지 않는다.
    safeAdd(list, "hi"); 
    safeAdd(list, 123);
}

void safeAdd(List<Object> list, Object o) {
    list.add(o);
}
```

- 첫 번재 예제는 raw 타입으로 unsafeAdd 메서드의 매개변수를 받음을 알 수 있다.
- 이 경우 에러는 컴파일 시점이 아닌 런타임 시점에서 발생한다.
- 두 번째 예제는 List<Object> 매개변수에 List<String>을 넣으려고 하였다.
- 하지만 컴파일 시점에서 예외가 발생한다. 제네릭은 상위-하위 클래스 간 형변환을 허용하지 않는다. 

## 데이터의 비교, 로타입과 와일드카드
- 다양한 데이터 타입을 받고, 동시에 데이타간 비교를 할 수 없을까? Object를 제네릭으로 하더라도 Object를 제네릭으로 하는 클래스만 허용됨을 확인할 수 있었다. 이런 순간을 위하여 와일드타입<?>이 존재한다. 
- 일단, 아래는 로 타입으로 데이터를 비교한다. 

```java
@Test
void testSet() {
    Set<String> s1 = new HashSet<>();
    s1.add("lee");
    s1.add("choi");

    Set<String> s2 = new HashSet<>();
    s2.add("lee");
    s2.add("kim");

    int result = numElementsInCommon(s1, s2);
    System.out.println("result : " + result);
}

int numElementsInCommon(Set s1, Set s2) {
    int result = 0;
    for(Object o1 : s1) {
        if(s2.contains(o1))
            result++;
    }
    s1.add("park");
    return result;
}
```

- 위의 코드의 문제는 `s1.add("park");` 이다. 이는 데이터의 불변성을 해친다. 
- 이러한 불변성을 방지하며 단순한 비교를 하기 위해서는 와일드카드를 사용한다. 

```java
@Test
void testWildCard() {
    Set<String> s1 = new HashSet<>();
    s1.add("lee");
    s1.add("choi");

    Set<String> s2 = new HashSet<>();
    s2.add("lee");
    s2.add("kim");

    int result = numElementsInCommonWild(s1, s2);
    System.out.println("result : " + result);

}

int numElementsInCommonWild(Set<?> s1, Set<?> s2) {
    int result = 0;
    for(Object o1 : s1) {
        if(s2.contains(o1))
            result++;
    }
    // 컴파일 에러가 발생한다.
    // s1.add("park");
    return result;
}
```