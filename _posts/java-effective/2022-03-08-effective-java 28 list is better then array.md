---
layout: post
author: infoqoch
title: 이펙티브자바, 28. 배열보다는 리스트를 사용하라
categories: [java]
tags: [java, effective]
---

## 배열과 리스트의 차이 
- 배열의 경우 Sub[] 이 Super[] 의 하위타입이 된다. 그러니까 Object[] 가 String[] 의 하위타입이 된다.
- 이러한 배열의 특성 때문에 문법 상 맞지 않는 코드가 컴파일 과정에서 승인된다. 그리고 런타임 과정에서 예외가 발생한다.
- 리스트, 정확히 제너릭 클래스와 인터페이스는, 컴파일 시점에서 타입이 맞지 않는 코드에 대하여 에러를 던진다. 
- 추가적으로 Object[] 타입으로 String[]이 초기화되는 것과 달리, 제네릭 클래스와 인터페이스는 상위/하위타입으로 타입변화가 허용되지 않는다. 
- 타입의 표현력과 안정성문제로 배열보다는 리스트가 선호된다. 

```java
@Test
void test() {
    Object[] objets = new Integer[10];
    objets[0] = 1;
    Assertions.assertThatThrownBy(()->{
        // String 을 삽입 할 수 있다.
        objets[1] = "hello!"; 
    }).isInstanceOf(ArrayStoreException.class);
}

@Test
void test2() {
    // 컴파일 에러 발생
    // List<Object> objects = new ArrayList<Integer>();

    // Integer로 타입이 고정된다.
    List<Integer> objects = new ArrayList<Integer>();
    objects.add(123);

    // 컴파일 에러 발생
    objects.add("kim");
}
```

## 제네릭으로의 적용의 다양한 방법들

### 제네릭 미적용
- 제네릭이 아닌 Object 배열을 사용한다.
- Object 배열을 사용할 경우 형변환의 문제가 발생한다. 

```java
public class Chooser1 {
	private final Object[] choiceArray;

	public Chooser1(Collection choices) {
		choiceArray = choices.toArray();
	}

	public Object choose() {
		Random rnd = ThreadLocalRandom.current();
		return choiceArray[rnd.nextInt(choiceArray.length)];
	}
}
```

### 제네렉 배열의 사용
- 제네릭을 배열로 한다. `T[]`
- 제네릭은 런타임 시점에서 타입을 잃어버린다. 그러므로 타입변환을 코드에서 명시해야 한다. `(T[]) choices.toArray();`
- 형변환을 하기 때문에 컴파일러는 형변환과 관련하여 확신을 할 수 없고 경고 메시지를 띄운다. 

```java
public class Chooser2<T> {
	private final T[] choiceArray;

	public Chooser2(Collection<T> choices) {
		choiceArray = (T[]) choices.toArray();
	}

	public Object choose() {
		Random rnd = ThreadLocalRandom.current();
		return choiceArray[rnd.nextInt(choiceArray.length)];
	}
}
```

### 리스트 제네릭 사용
- 형변환 문제과 관련한 고민이 사라진다. 컴파일 시점에서 코드의 문제가 드러난다. 성능 등 문제로 배열을 꼭 써야하는 상황이 아니면 리스트가 낫다. 

```java
public class Chooser3<T> {
	private final List<T> choiceArray;

	public Chooser3(Collection<T> choices) {
		choiceArray = new ArrayList<>(choices);
	}

	public Object choose() {
		Random rnd = ThreadLocalRandom.current();
		return choiceArray.get(rnd.nextInt(choiceArray.size()));
	}

}
```

## 제네릭의 특징
- 컴파일 시점에만 데이터 타입에 대한 정보를 제네릭은 가지고 있다. 런타임 시점에서 데이터 타입에 대한 정보가 사라지는 것을 소거(erasure)라 한다. 그리고 이러한 특징으로 제너릭을 실체화 불가 타입이라 한다.
- 이러한 방식으로 인하여 제너릭이 존재하지 않았던 레거시 코드와의 호환성을 가지게 되었다. 더 나아가 컴파일 시점에서 제너릭과 관련한 에러를 잡아낼 수 있게 되었다.
- 한편, 배열은 런타임에서도 데이터타입에 대한 정보를 가지고 있다. Integer[]는 런타임에서도 Integer 데이터 타입을 가지고 있다. 이러한 패러다임의 차이로 제너릭 배열이 허용되지 않는다.

## 교훈?
- 제네릭을 학습하며 캐스팅을 하지 않는 것이 얼마나 좋은지를 느끼게 한다. `Integer var = (Integer) result;` 라는 식의 형변환 자체는, 형변환의 대상의 데이터 타입 자체가 불완전함을 보여준다.
- 하지만 제네릭은 명확하게 `List<Integer> var = result`; 라는 형태를 가지기 때문에 코드가 명확하다. 캐스팅이 코드 작성과 유지보수 입장에서 어떤 문제를 가지는지를 이해하는 계기가 되었다. 이것 하나만으로도 큰 장점이 있어 보인다. 