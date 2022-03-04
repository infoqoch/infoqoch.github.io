---
layout: post
author: infoqoch
title: 이펙티브자바, 21-22 인터페이스의 default 메서드 주의점, 상수 인터페이스 지양
categories: [java]
tags: [java, effective]
---

## 21 인터페이스는 구현하는 쪽을 생각해 설계하라 : java 8, default method
- 자바 7까지는 interface는 구현된 메서드가 존재하지 않았다. 그러나 자바 8 부터 default 메서드가 생겼다. 
- default는 코드 품질이 높고 범용적이라 대부분의 상황에서 잘 작동한다. 하지만 모든 상황에서 불변식을 해치지 않는다고 보장할 수 없다.
- default를 고려하지 않은 어떤 구현체는, 자바 8 이후 새롭게 릴리즈 된 인터페이스의 default를 호출할 때, 런타임 에러가 발생하곤 한다. 
- default를 재정의하는 등, 보완책이 존재한다. 하지만 어떤 문제가 발생할지 모르기 때문에 default 메서드를 추가하여 릴리즈 하는 것은 신중해야 한다.
- 새롭게 인터페이스를 구현한다면 default는 구현체를 고려하여 잘 작성한다. 

## 22 인터페이스는 타입을 정의하는 용도로만 사용하라
- 인터페이스의 목적은 구현 클래스의 인스턴스가 참조할 수 있는 타입을 정하는 것에 있다. 
- 한편, 인터페이스를 상수로 정의하기 위하여 사용하는 경우가 있다. 이렇게 사용해서는 안된다. 
- 상수 인터페이스가 위험한 이유는, 상수로 정의한 데이터가 모든 하위 클래스에 영향을 미친다는 것에 있다. 

- 인터페이스

```java
public interface ConstInterface {
	static final Integer AGE = 10;
	static final String NAME = "kim";
}
```

- 구현체

```java
public class ConstInterfaceImpl implements ConstInterface {
	public static void main(String[] args) {
		int age = ConstInterfaceImpl.AGE; // 계속 영향이 생긴다.
		System.out.println(age);
	}
}
```

- 이러한 방식보다는 구현체에서 상수를 정의하거나, 열거 타입으로 나타내거나, 유틸리티 클래스에 담는다. 