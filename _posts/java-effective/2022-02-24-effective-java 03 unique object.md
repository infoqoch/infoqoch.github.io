---
layout: post
author: infoqoch
title: 이펙티브 자바, private 생성자나 열거 타입으로 싱글턴임을 보장하라
categories: [java]
tags: [java, effective]
---

## 싱글턴?
- 싱글턴이란 인스턴스를 오직 하나만 생성할 수 있는 클래스를 말한다. 

## 필드 싱글턴
- static final로 유일함을 보장한다. 
- 필드에서 직접 객체를 가져온다. 

```java
public class SingletonV1 {
	// static final 이므로 메모리에서의 유일함을 보장한다. 쓰레드로부터 안전하다.
	public static final SingletonV1 Instance = new SingletonV1();

	// 리플렉션의 경우 싱글톤임에도 불구하고 객체 생성 가능하다. 아래의 에러를 통해 원천적으로 싱글톤의 재생성을 막는다.
	private SingletonV1() {
		throw new AssertionError();
	}
}
```

## 정적 팩터리 싱글턴
- getInstance()를 통해 객체를 가져온다. 매서드 명을 명시할 수 있고, 매개변수나 코드를 구현할 수 있어서 필드 싱글턴보다 훨씬 유연하다.

```java
public class SingletonV2Factory {
	private static final SingletonV2Factory INSTANCE = new SingletonV2Factory();

	// 팩토리 형태로 인스턴스를 전달한다.
	// 이전의 방식보다 유연하다. supplier 등 사용 가능하다. 여러 방식으로 조작 가능하다.
	public static SingletonV2Factory getInstance() {
		return INSTANCE;
	}

}
```

## 열거 타입
- 열거 타입은 enum 하나 마다 클래스를 생성하며, 이는 싱글턴을 보장한다.

```java
public enum SingletonV3Enum {
	INSTANCE
}
```

## 싱글턴과 스프링 빈 스코프 싱글턴? (_아래부터는 사실 사담이다_)
- 싱글턴은 유일한 객체를 보장하는 방식이다.
- 스프링이 IOC나 DI를 할 때, 마찬가지로 모든 빈에 대하여 유일함을 보장한다. 나는 이것이 일종의 싱글턴이라 이해했다. 그래서 싱글턴과 DI는 유사한 것으로 이해했다. 
- 하지만 돌이켜보면 스코프는 싱글턴이 기본값이지 프로토타입, 그러니까 주입할 때마다 계속 새로운 객체를 주입할 수도 있다. 그러므로 DI와 싱글턴은 연관이 있지만 완전하게 밀접한 개념이 아님을 알 수 있다. 
- DI는 사실, 유일한 빈을 보장함이 핵심적인 내용은 아니다. 그보다는 복잡한 의존성을  어너테이션이나 XML 명세서를 통해 외부에서 설정하고 쉽게 할 수 있다는 점에 있다. 
- 이 부분에 대해서는 좀 더 지식의 수준을 높혀서 차후 깊이를 더하겠다. 