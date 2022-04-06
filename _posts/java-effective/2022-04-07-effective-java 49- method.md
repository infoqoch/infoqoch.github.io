---
layout: post
author: infoqoch
title: 이펙티브자바, 49- 메서드
categories: [java]
tags: [java, effective]
---

## 49 매개변수가 유효한지 검사하라
- 매개변수의 유효성은 메서드 몸체가 시작하기 전에 검사해야 한다. 오류는 가능한 빨리 잡아야 한다.
- 만약 그렇지 않으면 오류가 예상치 못한 곳에 발생하여 유지보수를 어렵게 할 수 있다. 객체가 변경되어 실패 원자성을 어기는 결과를 낳을 수 있다.
- 노출된 API에 대해서는 매개변수에 일반적으로 사용되는 예외(IllegalArgumentException, IndexOutOfBoundsException, NullPointerException)만 제공하더라도 클라이언트가 제약을 지키도록 유도할 수 있다. 물론 이에 대한 문서화를 해야 한다.

- 자바에서는 버전이 올라가며 유효성 검사를 위한 좋은 기능을 마련했다. 
- assert, Object.requireNonNull 등이 그것이며 내용은 아래와 같다. 

### Objects 를 통한 널 검사

```java
@Test
void test1() {
	Object obj = null;
	Assertions.assertThatThrownBy(()->{
		Objects.requireNonNull(obj, "널이잖여!!");
	}).isInstanceOf(NullPointerException.class)
	.message().isEqualTo("널이잖여!!");

	int[] ints = new int[] {1,3,4};
	Assertions.assertThatThrownBy(()->{
		Objects.checkIndex(10, ints.length);
	}).isInstanceOf(IndexOutOfBoundsException.class);
}
```

### assert 를 통한 boolean 검사
- AssertionError는 검증을 위한 에러 클래스이다.
- true 와 false를 통해 해당 소스코드의 정상 유무를 판단한다.
- assert 절은 런타임 시점에서 모두 무시된다. assert는 개발자가 소스코드를 작성하고 테스트하는 개발 과정에서 사용한다. 테스트 시점에서는 엄격하게 설계하기 위해 작성하지만, 성능이나 암묵적인 승인 등 다양한 이유로 인해 런타임 시점에서 적용하고 싶지 않은 경우 사용한다. 
- 만약 런타임 시점에서 사용하고 싶으면, -ea 등 옵션을 사용한다.

```java
@Test
void test2() {
	int a = 0, b = 50;
	
    assert a<20; // 문제없이 동작한다.

	Assertions.assertThatThrownBy(()->{
		assert b<20; // 예외가 발생한다.
	}).isInstanceOf(AssertionError.class);
}
```

### 정리
- 매개변수의 유효성 검사는 실패원자성을 위하여 매우 중요하다.
- 성능이 우선되야 하거나, 설계가 좋아서 유효성 검사가 필요 없을 수 있다. 이런 경우 생략할 수 있으나 언제나 실패원자성을 최우선으로 고려해야 한다.
- 매개변수의 검사로 인해 발생한 예외는 적절한 고수준의 예외로 처리해야 한다. (catch IOException -> throw IllegalArgumentException)

## 50 적시에 방어적 복사본을 만들라
- 악의적인 의도를 가지고 보안을 뚫기 위하여 객체 내부에 침입, 수정 할 수 있다. 클라이언트가 의도치 않게 가변적인 객체의 데이터를 수정하고 이로 인한 문제가 발생할 수 있다. 단순하게 private final로 선언한다고 하여 이것이 불변임을 보장하지 못한다. 변경 가능성을 최소화하기 위해서 가변적인 객체를 인자로 하는 매개변수와 리턴에 대하여 방어적 복사본을 사용해야 한다. 

### 불변객체가 아니다.
- 아래는 private final인 Date 객체를 필드로 가지는 객체이다. 불변 객체가 아니다.

```java
import java.util.Date;

public class Period {
	// private final 을 통해 불변을 기대하였으나 의도대로 동작하지 않는다.
	private final Date start;
	private final Date end;

	public Period(Date start, Date end) {
		this.start = start;
		this.end = end;
	}

	public Date start() {
		return start;
	}

	public Date end() {
		return end;
	}

	public static void main(String[] args) {
		Date start = new Date();
		Date end = new Date();
		Period p = new Period(start, end);
		Period p2 = new Period(start, end);
		p.end().setYear(1522); // 데이터가 조작된다.
		System.out.println(p.end());

		System.out.println(p2.end()); // 다른 Period 객체에 영향을 미친다.
	}
}
```

### 불변객체
- 필드를 초기화 할 때 new Date(arg)를 통해 초기화한다. 값을 리턴할 때 return new Date(start); 를 통해 데이터를 전달한다. 이를 통하여 클라이언트는 초기화된 Period 객체의 Date 객체에 절대로 접근할 수 없다.
- clone을 사용하지 않는다. Date 객체를 상속하고 clone을 부정적인 방식으로 오버라이딩 한 후, 해당 객체를 인자로 삽입할 경우, 문제가 발생할 수 있기 때문이다. 
- 방어적 복사를 할 때는, 초기화를 한 후 유효성 검사를 해야 한다. 멀티 스레드 환경에서 찰나의 순간에 데이터가 바뀔 수 있기 때문이다.

```java
import java.util.Date;

public class Period2 {
	// private final 을 통해 불변을 목표하였다.
	private final Date start;
	private final Date end;

	public Period2(Date start, Date end) {
		// Date 객체를 새로 생성하여, 해당 객체가 다른 Period 객체간 복사되지 않도록 한다.
		this.start = new Date(start.getTime());
		this.end = new Date(end.getTime());

		// 유효성 검사는 객체를 생성한 후 진행한다.
		// 찰나의 순간에 다른 스레드가 원본 객체를 수정할 위험이 있기 때문이다. (TOCTOU 공격)
		// clone을 사용하지 않는다. 매개변수가 된 객체의 clone이 어떻게 정의되어 있는지 알 수 없기 때문이다.
		if(this.start.compareTo(this.end)>0)
			throw new IllegalArgumentException();
	}

	// 값을 리턴할 때도 새로운 객체를 생성하여 전달한다.
	public Date start() {
		return new Date(start.getTime());
	}

	public Date end() {
		return new Date(end.getTime());
	}

	public static void main(String[] args) {
		Date start = new Date();
		Date end = new Date(System.currentTimeMillis() + 100);
		Period2 p = new Period2(start, end);
		Period2 p2 = new Period2(start, end);
		p.end().setYear(1522); // 데이터가 조작된다.
		System.out.println(p.end()); // 하지만 원래의 값을 전달한다. 왜냐하면 Period 객체 내부의 Date는 외부에서 더는 변경되지 않기 때문이다.

		System.out.println(p2.end()); // 더 이상 다른 Period 객체에 영향을 주지 않는다.
	}
}
```

### 정리
- 불변 객체를 구현하기 위해서는 방어적 복사가 필요할 수 있다.
- 방어적 복사를 하지 않고 가변 객체를 공개할 수 있다. 객체에 대한 통제권을 클라이언트에게 넘길 수 있다. 이런 식으로 의도한 상황이라면 클라이언트에게 해당 내용을 알리기 위하여 명확하게 문서화한다.
- 통제권을 넘기더라도, 클라이언트의 조작으로 인한 문제는 클라이언트에 한정하도록 코드를 작성해야 한다.




