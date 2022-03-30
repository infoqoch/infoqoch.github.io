---
layout: post
author: infoqoch
title: 이펙티브자바 69-77 예외 Exception
categories: [java]
tags: [java]
---

## 69 예외는 진짜 예외 상황에만 사용하라
- 예외를 일종의 제어흐름으로 사용하면 안된다. 더 이상 수행이 불가능할 때, `catch(SomeException e)` 로 잡고, 다음 로직을 진행하는 경우가 있다. 

```java
try{
	while(true){
		// 로직 구현		
	}
}catch(SomeException e){ // 해당 로직이 더 이상 동작하지 않고 예외를 던질 때(예를 들면 NoSuchElementException이나 ArrayIndexOutOfBoundsException 등)
	
}
// 반복문을 종료하고 차기 로직을 수행한다.
```

- 이러한 방식으로 예외를 제어흐름으로 사용해서는 안된다. Iterator 처럼 hasNext() 등의 방식으로 값이 있음을 명시하거나, length 혹은 size를 제공하여, 코드를 명확하게 작성해야 한다.
- 실제 예외 상황에서만 사용한다. 그것이 더 분명하고, 빠르고, 효과적이다. 

## 70 복구할 수 있는 상황에는 검사 예외를, 프로그래밍 오류에는 런타임 예외를 사용하라
### 검사예외와 비검사예외?
- 검사예외와 비검사예외를 처음 들었을 때 단어의 의미가 다소 모호했다. 검사를 예외하는 것으로 처음에 이해해서, 검사를 하지 않는 예외라고 이해했다. 하지만 그렇지 않다. 원어로는 각각 checked exception과 unchecked exception이다. 검사되는 예외와 검사되지 않는 예외로 이해할 수 있다. 그러니까, 해당 예외를 처리하는 코드를 작성해야 컴파일 되는 것을 검사예외라고 하며 그렇지 않은 것은 비검사예외라 한다. 검사 예외란, 컴파일 시점이서 예외처리를 잘 했는지 "검사"한다는 뉘양스로 이해할 수 있다.
- 에러(Error)와 런타임 예외(Runtime Exception)가 unchecked 이며 예외(Exception)이 checked 이다.

### 복구할 수 있는 상황과 프로그래밍 오류?
- 복구할 수 있는 상황에서 검사예외를 하고, 프로그래밍 오류에 대해서는 비검사 예외를 하도록 제안한다. 이에 대한 내용을 명확하게 이해하진 못했지만, 나의 이해를 바탕으로 정리하면 아래와 같다. 
- 복구할 수 있는 상황이란, 해당 문제가 자주 발생할 수 있기 때문에, 이에 대한 조치를 취하기를 기대하는 상황이다.
	- IOException의 경우 파일이나 디렉토리의 입출력 과정에서 발생하는 예외로서, 검사 예외이다. 사용하고자 하는 파일이 없는 경우를 상상할 수 있기 때문에, 이에 대한 대비책이 매우 필요하다고 해당 API를 개발한 개발자가 판단할 수 있다. 이를 사용하는 클라이언트는 IOException에 대한 대비책을 세워야 한다. 
- 한편, 프로그래밍 오류에 대해서는 비검사 예외를 하도록 제안한다. 프로그래밍 오류란 코드 자체를 잘못 작성한 경우이다.
	- 예를 들면 null이 허용되지 않는 상황에서 null을 입력하도록 하는 것은 코드를 잘못 개발한 것으로 볼 수 있다. 그러니까 프로그래밍 오류이다. 
	- 만에 하나 null이 삽입된다고 한다. 이것이 허용 된다면 객체나 데이터의 불변이 깨질 수 있다. 이런 경우 검사 예외를 하여 어설프게 처리하도록 하는 것보다 메서드 동작 자체를 수행하지 않고 종료시키는 것이 최선일 수 있다. 그러니까 비검사예외로서 해당 예외에 대한 복구할 여지를 없앤다. 복구를 통한 득보다 실이 많은 경우 비검사 예외를 할 수 있다. 
	- error의 경우도 유사하다. error는 어플리케이션 자체의 치명적인 오류를 내포한다. 이 경우는 어플리케이션 동작 과정에서 수정하는 것이 아닌, 어플리케이션을 재작성해야 하는 치명적인 문제일 수 있다. 그러니까 복구할 수 없는 상태, 원래부터 잘못된 상태임을 내포한다.

## 71 필요 없는 검사 예외 사용은 피하라.
- API를 제작하는 입장에서 해당 API를 사용하는 클라이언트에게 검사예외를 강제하는 것은 좋은 방법일까?

```java
try {
	doAction(time);
}catch(SomeCheckedException e) {

}
```

- 예외 상황 여부를 미리 판별할 수 있는 메서드를 제공하고 비검사예외를 하는 것이 클라이언트의 사용성 입장에서는 낫다. 
- 클라이언트의 판단 하에 예외가 발생하면 그 예외를 전파하는게 낫다고 판단할 수 있다. 이 경우 해당 메서드를 try-catch 없이 작성하면 된다. 
- 이러한 측면으로 보면 검사 예외보다는, 검증 메서드 및 비검사 예외가 좀 더 유연함을 알 수 있다. 

```java
if(isOkayToDo(time)) { // 이 메서드를 통해 try-catch를 대신한다.
	doAction(time);
}

// 클라이언트가 해당 문제 발생 시 처리하지 않고 밖으로 예외를 던져야 한다고 판단할 수 있다. 이 경우 검증 메서드를 생략하여 유연하게 코드 작성 가능하다.
doAction(time); // 예외 상황을 내포하게 된다.
```

## 72 표준 예외를 사용하라
- 자바가 제공하는 표준 예외는 일종의 규약이다. 재사용 및 협업, API로의 공개 시 사용자 예외 클래스보다 더 나은 사용성을 제공한다. 
- 표준 예외 중 주로 사용되는 것은 아래와 같다.

|예외|주요 쓰임|
|----|---------|
|IllegalArgumentException|허용하지 않는 값이 인수로 건네졌을 때 (주의* null은 따로 NullPointerException으로 처리)|
|IllegalStateException|객체가 메서드를 수행하기에 적절하지 않은 상태일 때|
|NullPointerException|null을 허용하지 않는 메서드에 null을 건넸을 때|
|IndexOutOfBoundsException|인덱스가 범위를 넘어섰을 때|
|ConcurrentModificationException|허용하지 않는 동시 수정이 발견됐을 때|
|UnsupportedOperationException|호출한 메서드를 지원하지 않을 때|

- 대체로 IllegalArgumentException과 IllegalStateException을 주로 사용한다.
- 전자는 값에 따라 동작의 여부를 결정하는 경우이며, 후자는 값과 관계 없이 발생하는 경우이다. 그러니까 객체가 제대로 생성이 안되었을 경우 후자의 예외를 던져야 한다.

## 73 추상화 수준에 맞는 예외를 던지라
- 만약 아래의 코드가 있다고 상상한다.

```java
GogodanResult gogodan(File file) throws FileNotFoundException {
	String raw =  fileToString(file); // 검사 예외 FileNotFoundException 가 발생한다.
	return gogodanProcess(raw);
}

@Test
void test1() {
	// 클라이언트는 FileNotFoundException를 해결해야한다. 
	// 현재 상태를 유지할 경우 컴파일 오류가 발생한다. 
	GogodanResult result = gogodan(new File("C:\\file.txt")); 
	result.prettyPrint();
}
```

- 클라이언트 입장에서는 gogodan() 메서드를 사용함에 있어 FileNotFoundException의 저수준의 예외를 맞닥뜨린다.
- 이러한 저수준의 예외를 클라이언트가 확인하도록 만드는 것 보다,
	- 1) 고수준의 예외로 치환하거나
	- 2) 처음부터 그러한 예외를 던지지 않도록 개발하는 것이 낫다.
	- 3) 예외를 던질 필요가 없다면 로그를 잘 남긴다.
- 아래는 첫 번째 상황에서의 예제 코드이다.

```java
void test2() {
	GogodanResult result = gogodanV2(new File("C:\\file.txt"));
	result.prettyPrint();
}


GogodanResult gogodanV2(File file) {
	String raw;
	try {
		raw = fileToString(file);
	} catch (FileNotFoundException e) {
		throw new IllegalStateException("정상적인 파일을 삽입해주세요.");
	}
	return gogodanProcess(raw);
}
```

## 74. 메서드가 던지는 모든 예외를 문서화하라
- 어떤 예외든 예외가 발생할 수 있으면 해당 예외를 문서화하라.

## 75. 예외의 상세 메시지에 실패 관련 정보를 담으라
- 예외를 사용할 때 예를 들면 해당 message를 파싱하는 경우가 있다. 
- 효과적이지 않다. 자바의 버전이나 개발자의 유지보수에 따라 해당 파싱이 정상동작하지 않을 수 있다. 
- 사용자 예외를 통해 적절한 메서드와 생성자를 마련해야 한다. 

- 이펙티브자바의 예제는 아래와 같다. 

```java
// https://github.com/WegraLee/effective-java-3e-source-code/blob/master/src/effectivejava/chapter10/item74/IndexOutOfBoundsException.java

// 실패 상황을 온전히 포착하도록 수정해본 IndexOutOfBoundsException (405쪽)
public class IndexOutOfBoundsException extends RuntimeException {
    private final int lowerBound;
    private final int upperBound;
    private final int index;

    /**
     * IndexOutOfBoundsException을 생성한다.
     *
     * @param lowerBound 인덱스의 최솟값
     * @param upperBound 인덱스의 최댓값 + 1
     * @param index      인덱스의 실젯값
     */
    public IndexOutOfBoundsException(int lowerBound, int upperBound,
                                     int index) {
        // 실패를 포착하는 상세 메시지를 생성한다.
        super(String.format(
                "최솟값: %d, 최댓값: %d, 인덱스: %d",
                lowerBound, upperBound, index));

        // 프로그램에서 이용할 수 있도록 실패 정보를 저장해둔다.
        this.lowerBound = lowerBound;
        this.upperBound = upperBound;
        this.index = index;
    }
}
```

## 76. 가능 한 실패 원자적으로 만들라
- 호출된 메서드가 실패하더라도 해당 객체는 메서드 호출 전 상태를 유지해야 한다. 이에 대한 방법으로
	- 메서드 호출 전, 매개변수에 대하여 유효성을 검사한다. 이를 통해 객체가 변경되기 전에 실패한다.
	- 변경하려는 객체를 복사하고, 그것이 성공하면, 원래 객체와 교환한다.
- 상황에 따라 실패 원자적인 방식을 선택하지 않을 수 있다. 혹은 불가피하게 실패 원자적으로 구현할 수 없을 수 있다. 이런 경우 분명하게 명시해야 한다. 
- 아래의 코드는 객체 변경 전 유효성 검사를 하는 방식이다. 

```java
public void addAge(int i) {
	if(i<0)
		throw new IllegalArgumentException("1 이상의 정수만 입력 가능합니다.");
	
	// 로직
}
```

## 77. 예외를 무시하자 마라.
- catch 블록을 작성하였지만 어떤 코드도 없다면 예외의 존재 이유가 없다. 
- 만약 무시한다면 왜 무시하는지에 대하여 명확하게 표현한다. 