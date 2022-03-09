---
layout: post
author: infoqoch
title: 이펙티브자바, 29. 이왕이면 제네릭 타입으로 만들라
categories: [java]
tags: [java, effective]
---

## 기왕이면 제네릭으로
- 스택 등 자료구조의 경우 배열의 요소를 특정 객체에 의존하거나 Object로 호환성을 높히는 경우가 있다.
- 전자의 경우 범용성이 떨어진다.
- 후자의 경우 해당 자료구조 밖에서 형변환을 해야하는 문제가 발생한다. 형변환의 잘못으로 인한 예외를 런타임에서 부담해야 한다.

## 제네릭 자료구조와 형변환 문제
- 제네릭 클래스나 인터페이스가 형변환 문제에서 가장 안전하다.
- 하지만 성능 등 최적화의 문제로 인해, 배열을 사용하는 경우가 있다. 이 경우 클래스에는 `<E>`로 제네릭을 선언하고 자료구조에는 `E[]`의 형태를 부여하면 된다.
- 한편, 제네릭은 실체화 불가 타입이다. 그러므로 형변환을 해야 한다. 두 가지 방법이 있다. 첫 번째는 자료구조를 초기화 할 때, 두 번째는 자료구조를 Object[]로 하고 값을 꺼낼 때, 할 수 있다. 그리고 이 경우 컴파일 시점에서 형변환과 관련한 경고가 발생한다. 
- 전자는 코드가 단순하고 형변환을 한 번만 하기 때문에 대체로 선호된다. 하지만 런타임과 컴파일 시점의 타입이 달라 힙 오염의 위험이 있다. 힙 오염때문에 후자를 선호하기도 한다. 
- 이에 대한 구현은 각각 V2와 V3이며, V1은 제네릭을 사용하지 않은 Object이다. 


```java
public class StackV1 {
    private Object[] elements;
    private int size = 0;
    private static final int DEFAULT_INITIAL_CAPACITY = 16;

    public StackV1() {
        elements = new Object[DEFAULT_INITIAL_CAPACITY];
    }

    public void push(Object e) {
        ensureCapacity();
        elements[size++] = e;
    }

    public Object pop(){
        if(size == 0)
            throw new EmptyStackException();
        final Object result = elements[--size];
        elements[size] = null;
        return result;
    }

    public boolean isEmpty(){
        return size == 0;
    }

    private void ensureCapacity() {
        if (elements.length == size)
            elements = Arrays.copyOf(elements, 2 * size + 1);
    }
}


public class StackV2<E> {
    private E[] elements;
    private int size = 0;
    private static final int DEFAULT_INITIAL_CAPACITY = 16;

    public StackV2() {
        // 제네릭은 실체화 불가 타입이다.
        // 이번 구현은 return 마다 형변환을 하지 않고, 배열 자체를 초기화할 때 형변환을 한다.
        elements = (E[]) new Object[DEFAULT_INITIAL_CAPACITY];
    }

    public void push(E e) {
        ensureCapacity();
        elements[size++] = e;
    }

    public E pop(){
        if(size == 0)
            throw new EmptyStackException();
        final E result = elements[--size];
        elements[size] = null;
        return result;
    }

    public boolean isEmpty(){
        return size == 0;
    }

    private void ensureCapacity() {
        if (elements.length == size)
            elements = Arrays.copyOf(elements, 2 * size + 1);
    }
}

public class StackV3<E> {
    private Object[] elements;
    private int size = 0;
    private static final int DEFAULT_INITIAL_CAPACITY = 16;

    public StackV3() {
        elements = new Object[DEFAULT_INITIAL_CAPACITY];
    }

    public void push(E e) {
        ensureCapacity();
        elements[size++] = e;
    }

    public E pop(){
        if(size == 0)
            throw new EmptyStackException();
        // 배열은 Object로 한다. 리턴할 때 형변환을 한다.
        @SuppressWarnings(value = "unchecked")
        final E result = (E) elements[--size];
        elements[size] = null;
        return result;
    }

    public boolean isEmpty(){
        return size == 0;
    }

    private void ensureCapacity() {
        if (elements.length == size)
            elements = Arrays.copyOf(elements, 2 * size + 1);
    }
}

```

