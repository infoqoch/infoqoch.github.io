---
layout: post
author: infoqoch
title: 이펙티브자바, 23 태그 달린 클래스보다는 클래스 계층구조를 활용하라
categories: [java]
tags: [java, effective]
---

## 태그 주석으로 설명하지 말고 코드로 설명하라
- 하나의 클래스에 여러 개의 내용이 있고 복잡한 경우 주석을 통해 복잡하게 설명하는 경우가 있다. 

```java
public class FigureV1 {
	enum Shape {RECTANGLE, CIRCLE}

	// 현재 모양
	final Shape shape;

	// 사각형에서 사용
	double length;
	double width;

	// 원에서 사용
	double radius;

	// 원에 사용
	FigureV1(double radius) {
		shape = Shape.CIRCLE;
		this.radius = radius;
	}

	// 사각형에 사용
	public FigureV1(double length, double width) {
		shape = Shape.RECTANGLE;
		this.length = length;
		this.width = width;
	}

	// 스위치로 분기
	double area() {
		switch(shape) {
			case RECTANGLE:
				return length*width;
			case CIRCLE:
				return Math.PI*(radius*radius);
			default:
				throw new AssertionError(shape);
		}
	}
}
```

- 열거타입, swith, 주석 등 장황하고 복잡하다. 
- 이러한 방식을 클래스 계층구조를 통해 단순하고 쉽고 확장성 있게 구현 가능하다. 

## 클래스 계층 구조로 구현
- Figure를 추상클래스로 만들고, 공통 메서드 area를 하위 클래스에서 구현하도록 한다.
- 각 구현체마다 필요로 한 기능과 매서드를 삽입할 수 있고, 이러한 구현은 어떤 설명도 필요 없이 코드만으로 이해할 수 있다.
- Rectangle 에서 Square 로 확장 가능하다.

```java
public abstract class Figure {
	abstract double area();
}

public class Circle extends Figure{
	private final double radius;

	Circle(double radius) {
		this.radius = radius;
	}

	@Override
	double area() {
		return Math.PI*(radius*radius);
	}

}

public class Rectangle extends Figure{
	private final double length;
	private final double width;

	public Rectangle(double length, double width) {
		this.length = length;
		this.width = width;
	}

	@Override
	double area() {
		return length*width;
	}
}
public class Square extends Rectangle{

	public Square(double side) {
		super(side, side);
	}

}
```
