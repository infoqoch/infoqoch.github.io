---
layout: post
author: infoqoch
title: 이펙티브 자바, 34. int 상수 대신 열거 타입을 사용하라
categories: [java]
tags: [java, effective]
---


## 열거타입과 기존 열거 패턴의 문제점
- 열거타입, enum은 일정 개수의 상수를 정의한 다음, 그 외의 값을 허용하지 않는 타입이다.
- 기존에는 아래와 같은 방식으로 정수 상수를 정의하였다.

```java
public class LegacyEnumPattern {
    public static final int SUCCESS = 0;
    public static final int ERROR = 1;

    public static final String HIS_NAME = "kim";
    public static final String HER_NAME = "choi";
}
```

- 정수 열거 타입(int enum pattern)은 많은 문제를 가진다. 
- 값으로 관리되기 때문에 깨지기 쉽다. 
- 로그나 통신 과정에서는 정수로 표현되기 때문에 직관적으로 그것이 무엇인지 파악하기 어렵다. 
- 상수의 갯수를 통제하기 어렵다.
- 컴파일러 과정에서 문제를 찾을 수 없다. 
- 문자열로 할 경우 문자열 비교를 해야하는 성능 상 문제가 발생한다. 
- 하드코딩을 하는 문제가 발생한다.

- enum이 있는 현대 자바에서는 기존의 열거패턴을 사용할 이유가 없다.

```java
public enum Enum {
    FUJI, PIPPIN, GRANNY_SMITH;
}
```

- 열거 타입 각각은 모두 클래스이다.
- 오류에 대해서 컴파일러 시점에서 찾아낼 수 있다. 클라이언트 오류 역시 컴파일러 시점에서 확인 가능하다. 
- 싱글턴을 객체를 보장한다. 각각의 열거타입은 public static final 필드의 객체로서 메모리에 적재되어 사용된다. 
- 클래스로서 다양한 기능과 메서드 등을 추가할 수 있다.
- enum의 갯수를 파악할 수 있다.(values())

## enum의 활용. 메서드와 필드
- enum은 아래와 같은 형태로 필드, 메서드, 생성자 등을 활용 가능하다. 기존의 클래스와 큰 차이를 가지지 않는다. 
- 상수 각각이 final 속성을 가지는 것처럼 필드 역시도 그러하다. 그러나 응집도를 위하여 필드는 public 으로 바로 공개하지 않는다.
- 상수를 추가하거나 삭제할 경우 클라이언트는 컴파일러 에러를 통해 문제를 확인할 수 있다. 
- values()를 통해 모든 상수에 접근할 수 있다.

```java
public enum Planet {
    // 아래의 인자는 임의로 막 작성했다ㅠ
	MERCURY(100000, 324),
	VENUS(2342, 334),
	EARTH(12343, 2342),
	MARS(345, 2342),
	JUPITER(34543, 234432),
	SATURN(3434, 343),

	// 상수 하나를 제거하더라도 전혀 문제가 없다.
	// 클라이언트에서 참조한다면 컴파일 에러를 발생한다.
	// URANUS(12343, 34),

	NEPTUNE(3245435, 2342);

	// 필드는 기본적으로 final 이다.
	private final double mass;
	private final double radius;
	private final double surfaceGravity;

	private static final double G = 6.213123213;

	// 생성자로 객체를 생성하여 사용한다.
	Planet(double mass, double radius){
		this.mass = mass;
		this.radius = radius;
		surfaceGravity = G*mass/(radius*radius); // 성능 최적화를 위하여 생성자 때 계산을 한다.
	}

	// 필드를 public으로 공개하지 않고, 메서드를 통해 값을 리턴한다.
	// 열거타입은 getMass 가 아닌 mass() 형태로 getter를 연다.
	public double mass() {
		return mass;
	}

	public double radius() {
		return radius;
	}

	public double surfaceGravity() {
		return surfaceGravity;
	}
}
```

```java
@Test
void test() {
    System.out.println("Planet.EARTH.mass() = "+ Planet.EARTH.mass());
    
    for(Planet p : Planet.values()) {
        System.out.println(p+" : "+p.surfaceGravity());
    }
}
```

## 상수에 따른 로직의 구현
- 열거타입에 공통의 기능을 부여하고, 각각의 상수마다 가지는 기능을 달리 할 수 있다. 이런 방식으로 유연한 코딩이 가능하며 그것의 예제는 아래와 같다. 

```java
public enum Operation {
	PLUS, MINUS, TIMES, DIVIDE;

	public double apply(double x, double y) {
		switch(this) {
			case PLUS: return x+y;
			case MINUS: return x-y;
			case TIMES: return x*y;
			case DIVIDE: return x/y;
		}
		throw new AssertionError();
	}

	public static void main(String[] args) {
		Double result = Operation.TIMES.apply(4, 10);
		System.out.println("result : "+result);
	}
}
```

- 위의 코드를 보면 switch를 통해 분기하여, 상수마다의 기능을 달리함을 확인할 수 있다. 
- 다만, 상수을 새롭게 정의할 경우 switch를 재정의해야 하는 등 깨지기 쉬운 메서드임은 분명하다. 

- 이보다 더 유연하게 코드를 작성하면 아래와 같다. 

```java
public enum Operation2 {
	PLUS{
		public double apply(double x, double y) {return x+y;}
	}, MINUS{
		public double apply(double x, double y) {return x-y;}
	}, TIMES{
		public double apply(double x, double y) {return x*y;}
	}, DIVIDE{
		public double apply(double x, double y) {return x/y;}
	};

	// switch의 분기는 깨지기 쉬운 메서드이다. 상수의 추가에 따라 변동이 심하다.
	// 각 객체마다의 매서드를 정의하여 더 좋은 코드를 구현한다.
	// abstract 을 통해 코드 구현을 강제한다.
	public abstract double apply(double x, double y);


	public static void main(String[] args) {
		Double result = Operation2.TIMES.apply(4, 10);
		System.out.println("result : "+result);
	}
}
```

- abstract 메서드를 추가하여 각 각의 상수마다 메서드 구현을 강제한다. 컴파일 시점에서 문제를 확인할 수 있다. 

- 열거타입은 문자열을 통해 상수에 접근할 수 있는 기능(valueOf())를 제공한다.
- 하지만 상수 그 자체의 이름보다 필드값으로 접근하고 싶을 수 있다. 이때는 아래와 같은 방식으로 코드를 작성한다.

```java
public enum Operation3 {
    // 각각의 상수마다 symbol을 정의한다. 더하기는 + 이다.
	PLUS("+"){ 
		public double apply(double x, double y) {return x+y;}
	}, MINUS("-"){
		public double apply(double x, double y) {return x-y;}
	}, TIMES("*"){
		public double apply(double x, double y) {return x*y;}
	}, DIVIDE("/"){
		public double apply(double x, double y) {return x/y;}
	};

	private final String symbol;

	Operation3(String symbol){
		this.symbol = symbol;
	}

	public String symbol() {
		return symbol;
	}

	public abstract double apply(double x, double y);

	// 아래의 정적타입필드는 열거타입 상수 생성 후이다. 그러므로 아래의 코드는 의도한대로 정상 동작한다.
    private static final Map<String, Operation3> stringToEnum =
    		Stream.of(values()).collect(Collectors.toMap(e -> e.symbol(), e -> e));

    public static Optional<Operation3> fromString(String symbol){
    	return Optional.ofNullable(stringToEnum.get(symbol));
    }
}
```

- 열거타입의 컴파일 방식은 각각의 상수를 객체(인스턴스)로 초기화 한 후, 각각의 객체를 필드값으로 가지는 형태이다.
- 정적타입필드는 상수의 초기화 후 동작한다. 그러므로 stringToEnum의 맵 컬렉션은 정상적으로 값이 들어간다. 
- fromString 메서드를 통해, 필드값으로 원하는 상수에 접근할 수 있다. 

```java
@Test
void test2() {
    // valueOf로 객체를 꺼낼 수 있지만
    System.out.println("Operation3.valueOf(\"MINUS\"); = "+Operation3.valueOf("MINUS"));

    // fromString이란 메서드로 구현할 수 있다.
    System.out.println("Operation3.fromString(\"-\") = "+ Operation3.fromString("-"));
    System.out.println("Operation3.fromString(\"+\") = "+ Operation3.fromString("+"));
    System.out.println("Operation3.fromString(\"&\") = "+ Operation3.fromString("&"));
}
```

## 공유 로직과 개별 로직의 구현, 전략 열거 타입 패턴
- 앞서의 예제는 apply() 라는 공통의 로직을 각각의 상수에서 구현하였다.
- 공통의 로직과 상수 마다의 로직을 분리할 수는 없을까?

- 아래의 예제는 근무시간에 따른 임금을 계산하는 상수 타입이다.
- 주말에 대해서는 switch로 분기하여 오버타임에 대한 추가 수당을 구현하였다. 

```java
public enum PayrollDay {
	MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY;
	
	private static final int MINS_PER_SHIFT = 8*60;

	int pay(int minutesWorked, int payRate) {
		int basePay = minutesWorked * payRate;

		int overtimePay;
		switch(this) {
		case SATURDAY: case SUNDAY:
			overtimePay = basePay / 2;
			break;
		default:
			overtimePay = minutesWorked <= MINS_PER_SHIFT?
					0:(minutesWorked-MINS_PER_SHIFT)*payRate/2;
		}

		return basePay + overtimePay;
	}
}
```

- 열거타입에 대한 열거타입을 구현하여 좀 더 유연한 코드를 작성할 수 있다. 
- 이러한 방식을 전략 열거 타입 패턴이라 하며 그 코드는 아래와 같다. 

```java
public enum PayrollDay2 {
	MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY
	,SATURDAY(WEEKEND),SUNDAY(WEEKEND);

    private final PayType payType;

	PayrollDay2(){
		this.payType = WEEKDAY;
	}

	PayrollDay2(PayType payType){
		this.payType = payType;
	}

	int pay(int minutesWorked, int payRate) {
        return payType.pay(minutesWorked, payRate);
    }

	// 전략 열거 타입 패턴
	// 열거 타입의 열거 타입을 정의하고, 해당 열거 타입에 대한 매서드를 구현한다.
	enum PayType{

		// switch를 사용하지 않아 안전하고 유연하다.
		WEEKDAY {
			int overtimePay(int minutesWorked, int payRate) {
                return minutesWorked <= MINS_PER_SHIFT ? 0 :
                    (minutesWorked - MINS_PER_SHIFT) * payRate / 2;
			}
		}, WEEKEND{
			int overtimePay(int minutesWorked, int payRate) {
                return minutesWorked * payRate / 2;
			}
		};

		// 차이를 가지는 오버타임에 대해서만 구현 객체로 만든다.
		abstract int overtimePay(int minutesWorked, int payRate);

		private static final int MINS_PER_SHIFT = 8*60;

		int pay(int minutesWorked, int payRate) {
			int basePay = minutesWorked * payRate;
			return basePay + overtimePay(minutesWorked, payRate);
		}

	}    
}
```

- 결과가 동일하게 나오는 것을 확인할 수 있다. 

```java
@Test
void test_v1() {
    System.out.println("PayrollDay.FRIDAY.pay(60*7, 10) = "+PayrollDay.FRIDAY.pay(60*10, 10));
    System.out.println("PayrollDay.SUNDAY.pay(60*7, 10) = "+PayrollDay.SUNDAY.pay(60*10, 10));
}

@Test
void test_v2() {
    System.out.println("PayrollDay.FRIDAY.pay(60*7, 10) = "+ PayrollDay2.FRIDAY.pay(60*10, 10));
    System.out.println("PayrollDay.SUNDAY.pay(60*7, 10) = "+PayrollDay2.SUNDAY.pay(60*10, 10));
}
```

## 정리
- 필요한 원소를 컴파일 타임에 다 알 수 있는 상수집합이라면 항상 열거 타입을 사용한다.