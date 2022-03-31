---
layout: post
author: infoqoch
title: 이펙티브자바, 57- 일반적인 프로그래밍 원칙
categories: [java]
tags: [java, effective]
---

## 57 지역변수의 범위를 최소화하라
- 지역변수에 대한 이해와 오남용을 방지하기 위하여, 지역변수의 사용은 최소화 한다.
- 만약 사용한다면 선언을 먼저하지 않는다. 가능한 초기화할 때 선언한다.
- 지역변수를 최소화 할 수 있는 방법을 활용한다. 반복문에서 지역변수를 최소화하기 위하여 while -> for -> 항상된 for문 순으로 사용을 우선한다.

## 58 전통적인 for 문보다는 for-each 문을 사용하라

```java
List<String> list = sampleList();

// while 보다는 for문이 낫다.
// for문을 사용할 경우 향상된 for문을 사용한다.
for(String s : list) {
	System.out.println(s); // 반복문 블록 안에 변수가 단 하나 s 밖에 없다.
}

// iterator를 사용할 경우 아래와 같이 사용한다. 다만 반복문 블록 안에 i.next()로 지역변수를 초기화함을 확인할 수 있다. 
// 그러므로, 가능하다면 아래의 코드 역시 향상된 for문을 사용할 수 있도록 한다.
for(Iterator<String> i = list.iterator(); i.hasNext();) {
	String s = i.next();
	System.out.println(s);
}

// n의 초기화를 반복문 초기화 때 수행한다.
for(int i = 0, n = expensiveComputation(); i < n; i++) {
	System.out.println("하이" + i);
}
```

## 59 라이브러리를 익히고 사용하라
- 만약 난수를 생성하려면 새롭게 난수 생성을 위한 기능을 구현해야 하는가? 그렇진 않다. 우리는 보통 자바가 제공하는 Random 라이브러리를 주로 사용한다. 
- 표준 라이브러리를 사용하는 것의 장점은 매우 많다.
- 전문가의 지식과 경험이 녹아든 기능을 매우 편리하게 사용할 수 있다.
- 부수적인 업무는 라이브러리로 대체하고, 중요한 업무에 더 집중할 수 있다.
- 버전이 올라갈 수록 성능과 기능이 자동으로 추가된다.
- 대부분의 자바 개발자가 공유하는 지식이기때문에 유지보수에 좋다.
- 다만, 현대 자바는 Random보다는 ThreadLocalRandom를 주로 사용한다. Random의 자체적인 결함, 성능, 편의기능, 동시성 문제 등 다양한 이유에 의해서이다. 
- 표준라이브러리를 사용하는 것과 더불어 새로운 기능에 대하여 학습해야 할 필요가 있다. 
- 자바 개발자라면 적어도 java.lang, java.util, java.io + java.util.concurrent 에는 익숙해지자.

## 60 정확한 답이 필요하다면 float와 double은 피하라
- 부동소수점 문제로 인하여, 금융 등 엄격한 숫자 계산이 필요할 경우, BigDecimal 을 사용해야 한다.

## 61 박싱된 기본타입보다는 기본타입을 사용하라
- 박싱된 기본타입과 기본타입은 분리해서 사용해야 한다. 그렇지 않으면 코드의 문제가 발생하거나 성능 상 문제가 발생한다.
- 특별하게 박싱된 기본타입이 필요하지 않으면 기본타입을 사용한다.
- 박싱타입으로 인하여 발생할 수 있는 문제를 아래에 나열했다. 

### 박싱된 기본타입을 비교할 경우
- Comparator를 구현과정에서, 0을 리턴할 때는 동일성을 비교하는 == 연산자를 사용했다. 
- 기본타입일 경우 정상적으로 동작한다. 하지만 객체인 Integer의 경우 각각 다른 메모리를 차지하는 객체로 생성하였기 때문에, ==이 false가 되어 영엉 0을 리턴하지 못한다.
- 이 경우 박싱된 타입을 강제로 꺼내야 한다.

```java
Comparator<Integer> compare = (i, j) -> (i > j) ? -1 : (i == j ? 0 : 1);

System.out.println("compare.compare(1, 2) = " + compare.compare(1, 2));
System.out.println("compare.compare(1, 1) = "+compare.compare(1, 1));
System.out.println("compare.compare(2, 1) = "+compare.compare(2, 1));


System.out.println("===========");
System.out.println("compare.compare(1, 2) = " + compare.compare(new Integer(1), new Integer(2)));
System.out.println("compare.compare(1, 1) = "+compare.compare(new Integer(1), new Integer(1))); // 객체간 비교(==)를 할 경우 다르다고 나온다.
System.out.println("compare.compare(2, 1) = "+compare.compare(new Integer(2), new Integer(1)));

Comparator<Integer> compare2 = (ii, jj) -> {
	int i = ii;
	int j = jj;
	return (i > j) ? -1 : (i == j ? 0 : 1);
};

System.out.println("compare2.compare(1, 2) = " + compare2.compare(new Integer(1), new Integer(2)));
System.out.println("compare2.compare(1, 1) = "+compare2.compare(new Integer(1), new Integer(1))); // int로 언박싱을 한 후 정상동작함을 확인할 수 있다.
System.out.println("compare2.compare(2, 1) = "+compare2.compare(new Integer(2), new Integer(1)));
```

### 초기화되지 않은 박싱타입을 꺼낼 때
- 만약 아래와 같이 초기화되지 않은 값을 꺼내려고 할 때 NullPointerException이 발생한다.
- 이 경우 선언을 Integer가 아닌 int로 하면 해결된다.

```java
Integer i; // int i;

@Test
void nullPoint() {
	if(i>100)
		System.out.println(i+"는 100보다 크다");
}
```

### 박싱타입으로 연산할 때
- 자바는 연산을 할 때 박싱타입이 아닌 기본타입으로 한다. 박싱타입을 연상할 때, 해당 객체를 언박싱한 후, 연산한 후, 다시 박싱한다. 많은 오버헤드가 발생한다. 
- 실제로 아래의 테스트를 한 결과 약 24배의 차이가 발생했다.

```java
Long boxedLong = 0l;
long primitiveLong = 0l;


long start1 = System.currentTimeMillis();
for(int i=0; i<Integer.MAX_VALUE; i++) {
	boxedLong += i;
}
System.out.println("첫 번째 시간 : "+(start1-System.currentTimeMillis()));

long start2 = System.currentTimeMillis();
for(int i=0; i<Integer.MAX_VALUE; i++) {
	primitiveLong += i;
}
System.out.println("두 번째 시간 : "+(start2-System.currentTimeMillis()));
```

## 62 다른 타입이 적절하다면 문자열 사용을 피하라
- 숫자, enum 등 문자열보다 나은 대안이 있으면, 문자열은 사용하지 않는다.

## 63 문자열 연결은 느리니 주의하라
- String 보다 StringBuilder를 사용한다.

## 64 객체는 인터페이스를 사용해 참조하라
- 객체를 선언할 때 인터페이스를 데이터 타입한다. 불가피하게 인터페이스로 선언할 수 없으면, 클래스 계층 구조 중 가장 덜 구체적인(상위) 클래스를 사용한다.
- 인터페이스로 선언할 때, 필요에 따라 구현 클래스를 변경하여, 유연한 코드를 작성할 수 있다.

```java
Set<String> set1 = new HashSet<>(); // 좋은 예
HashSet<String> set2 = new HashSet<>(); // 나쁜 예
```

## 65 리플렉션보다는 인터페이스를 사용하라
- 리플렉션은 강력한 기능을 제공하지만 몇 가지 단점이 존재한다.
    - 컴파일 시점에서 오류를 잡을 수 없다. 타입 검사 등의 이점을 누릴 수 없다. 오류가 런타임 때로 미뤄진다.
    - 코드가 복잡하고 장황하다.
    - 성능이 떨어진다. 
- 그러므로 리플렉션은 제한된 상황에서 사용한다. 리플렉션은 인스턴스 생성에만 쓰고, 인터페이스 등 상위 클래스로 형변환해 사용한다.
- 사견인데, 리플렉션이 인스턴스를 생성하는 시점을 스프링 빈으로 등록하여 어플리케이션 로딩 시점으로 만들 수 있다. 이 경우, 빈 등록 과정에서 에러를 인지할 수 있다. 그리고 로딩은 느려지지만 그 시점에서 빈을 등록하기 때문에 성능 상 여러 문제가 해소된다고 알고 있다. 컴파일 - 런타임 가운데 어플리케이션 로딩 시점을 우리는 둘 수 있다. 

## 66 네이티브 메서드는 신중히 사용하라

## 67 최적화는 신중히 하라

>최적화를 할 때는 다음 두 규칙을 따르라.
첫 번째, 하지마라.
두 번째, (전문가 한정) 아직 하지 마라. 다시 말해, 완전히 명백하고 최적화되지 않은 해법을 찾을 때까지는 하지 마라.
M.A 잭슨 (Jackson75)

- 처음에 위 경구를 봤을 때 엄청 웃었다. 누구나 최적화를 이야기하는데 최적화를 하지 말라고 하다니!
- (사실) 이펙티브자바를 읽는 이유는 좋은 프로그램을 만들기 위해서다. 저자는 빠른 프로그램보다는 좋은 프로그램을 작성하기를 제안한다.
- 다만, 성능에 영향을 줄 수 있는 설계를 피해야 한다. API, 네트워크 프로토콜, 영구 저장용 데이터 포맷 등은 한 번 결정되면 이후 수정하기 어렵다. 
- 특히 외부에 노출되는 public API는 설계에 있어서 신중해야 한다. 내부의 설계는 숨기면 숨길수록, 차후 최적화의 가능성이 높다.
- 최적화를 하기 전후로 프로파일링 도구를 활용하여 최적화를 어디에 할지 판단해야 한다. 자바는 코드와 cpu의 동작 사이에 추상화 격차가 큰 언어이다. 자바는 버전이 올라갈 수록 내부 구조가 더 복잡해진다. 그렇기 때문에 단순하게 코드를 읽고 최적화의 여부를 판단하기 어렵다. 최적화가 필요로 한 부분을 판단하고, 최적화 전후의 성능을 비교해야 한다.

## 68 일반적으로 통용되는 명명 규칙을 따르라.
- 패키지는 8자 이하로 한다.
- boolean 을 반환하는 메서드는 is 혹은 has로 시작한다.
- boolean 이 아닌 값을 반환하는 경우, get으로 보통 시작하나, 필요에 따라 변경할 수 있다.
- 객체의 타입을 변경할 경우 toType 형태를 가진다. (toString, toArray)
- 객체를 다른 뷰로 보여줄 경우 asType 형태를 가진다. (asList)
- 객체의 값을 기본타입값으로 반환하는 경우 typeValue 형태를 가진다. (intValue)
- 정적 팩터리의 이름은 from, of, valueOf, instance, getInstance, newInstance, getType, newType 등을 사용한다. 