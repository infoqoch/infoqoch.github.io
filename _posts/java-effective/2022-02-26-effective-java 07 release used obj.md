---
layout: post
author: infoqoch
title: 이펙티브 자바, 다 쓴 객체 참조를 해제하라
categories: [java]
tags: [java, effective]
---

## GC와 메모리 해제
- 자바는 가비지 컬렉터로 인하여 메모리를 해제할 필요가 없다.
- 하지만 모든 메모리에 대해서는 아니다. 개발자는 쓸모 없는 객체로 판단했더라도 GC 입장에서는 정상적으로 참조되는 메모리가 존재할 수 있다.
- 그 중 예는 Stack의 포인터를 움직일 때 발생한다.

## Stack 의 구현

```java
public class SampleStack {
	private int size;
	private Object[] repository;
	private static int LIMIT_SIZE = 10;

	public SampleStack() {
		repository = new Object[LIMIT_SIZE];
	}

	public void push(Object val) {
		if(size> LIMIT_SIZE)
			throw new IllegalArgumentException("용량을 초과하였습니다.");
		repository[size++] = val;
	}

	public Object pop() {
		if(size-1<0)
			throw new IllegalArgumentException("비어 있습니다.");
		return repository[--size];
	}

	public Object popV2() {
		if(size-1<0)
			throw new IllegalArgumentException("비어 있습니다.");
		Object result = repository[--size];
		repository[size] = null;
		return result;
	}

	public void print() {
		System.out.println("repository.length : " + repository.length);
		for(int i=0; i<repository.length; i++) {
			System.out.println("["+i+"]"+repository[i]);
		}
	}
}

```

- stack을 구현 할 때, pointer(여기서는 int size;)를 이용하여 할당된 스택 메모리 전체(Object[] repository;)에서 사용되는 위치를 가리킨다. 
- pop을 하고 포인터가 이동할 때, 두 가지 매서드로 구현되어 있다. pop()과 popV2()이다. 전자의 경우 pop을 통해 사용한 메모리에 대해서는 제거하지 않고, 후자의 경우 `=null`을 통해 메모리를 제거한다.
- 이로 인하여 발생하는 결과는 아래와 같다. 

```java
@Test
void test() {
    SampleStack stack = new SampleStack();

    for(int i=0; i<10; i++) {
        stack.push(LocalDateTime.now().plusDays(i)); // 푸쉬를 한다. 
    }

    stack.print(); // 푸쉬한 결과를 출력한다. 

    for(int i=0; i<10; i++) {
        stack.pop(); // pop을 한다. 포인트가 이동하지만 해당 객체를 해제하지 않는다.
    }

    stack.print(); // pop이 되었으나 해당 객체는 살아있다.
}
```

```log
repository.length : 10
[0]2022-02-26T18:28:00.454089700
[1]2022-02-27T18:28:00.454089700
[2]2022-02-28T18:28:00.454089700
[3]2022-03-01T18:28:00.454089700
[4]2022-03-02T18:28:00.455091500
[5]2022-03-03T18:28:00.455091500
[6]2022-03-04T18:28:00.455091500
[7]2022-03-05T18:28:00.455091500
[8]2022-03-06T18:28:00.455091500
[9]2022-03-07T18:28:00.455091500

// pop을 하였지만 데이타가 남아있음을 확인할 수 있다. 
repository.length : 10
[0]2022-02-26T18:28:00.454089700
[1]2022-02-27T18:28:00.454089700
[2]2022-02-28T18:28:00.454089700
[3]2022-03-01T18:28:00.454089700
[4]2022-03-02T18:28:00.455091500
[5]2022-03-03T18:28:00.455091500
[6]2022-03-04T18:28:00.455091500
[7]2022-03-05T18:28:00.455091500
[8]2022-03-06T18:28:00.455091500
[9]2022-03-07T18:28:00.455091500
```

```java
@Test
void test2() {
    SampleStack stack = new SampleStack();

    for(int i=0; i<10; i++) {
        stack.push(LocalDateTime.now().plusDays(i));
    }

    stack.print();

    for(int i=0; i<10; i++) {
        stack.popV2(); // 포인터가 지나간 위치에 대해서는 =null을 하여 해제한다.
    }

    stack.print(); // 더 이상 객체가 살아있지 않고 제거된다.
}
```

```log
repository.length : 10
[0]2022-02-26T18:28:00.562091800
[1]2022-02-27T18:28:00.562091800
[2]2022-02-28T18:28:00.562091800
[3]2022-03-01T18:28:00.562091800
[4]2022-03-02T18:28:00.562091800
[5]2022-03-03T18:28:00.562091800
[6]2022-03-04T18:28:00.562091800
[7]2022-03-05T18:28:00.562091800
[8]2022-03-06T18:28:00.562091800
[9]2022-03-07T18:28:00.562091800

// 정상적으로 null 처리가 됨을 확인할 수 있다.
repository.length : 10
[0]null
[1]null
[2]null
[3]null
[4]null
[5]null
[6]null
[7]null
[8]null
[9]null
```

- pop()의 경우, 포인터는 앞으로 이동하여 더 이상 사용하지 않지만, 자료구조 자체는 살아 있다. 
- 필요없는 객체가 살아있고, 또한 그것은 무거운 객체이며 그 객체가 다른 객체와 연결되어 있을 경우, 이에 딸린 많은 메모리가 계속 살아 있게 된다.
- 한편, 해당 객체와 그것의 필드값인 repository가 사용되는 이상, GC 입장에서는 repository의 모든 값들은 정상으로 받아드린다. 그러므로 이러한 부분은 개발자가 직접 메모리를 해제해야 한다. 
