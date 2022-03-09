---
layout: post
author: infoqoch
title: 이펙티브자바, 31. 한정적 와일드카드를 사용해 API 유연성을 높이라
categories: [java]
tags: [java, effective]
---

## 와일드카드와 extends, super
- 제네릭 <E>는 불공변이다. E의 매개변수가 Number이며 실제 삽입되는 인자가 그것의 하위 타입인 Interger라 하더라도, 형변환이 허용되지 않는다. 
- 와일드카드 <?>는 데이터에 대한 비교와 더불어 형변환을 위한 기능도 제공한다. 아래의 코드를 사용하여 하위타입에 대한 유연성을 높혀준다. 
    - <? extends E> 생산자
    - <? super E> 소비자 
- 전자는 매개변수가 생산자일 때 동작하며, 생산자란 데이터를 내보내는 경우를 의미한다.
- 후자는 매개변수가 소비자일 때 동작하며, 소비자란 데이터를 변경하는 경우를 의미한다. 기본 행태의 와일드 카드<?>로 받은 인자의 데이타를 변경할 수 없는 것과 대비하여, <? super E>는 그것의 인자의 데이터를 변경할 수 있다. 
- 해당 코드는 아래와 같다. Stack을 활용한다. 

```java
public class Stack<E> {
    private E[] elements;
    private int size = 0;
    private static final int DEFAULT_INITIAL_CAPACITY = 16;

    public Stack() {
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

    public void pushAll(Iterable<E> src){
        for (E e : src) {
            push(e);
        }
    }

    // 생산자, 데이터를 내보낸다.
    public void pushAll2(Iterable<? extends E> src){
        for (E e : src) {
            push(e);
        }
    }

    public void popAll(Collection<E>dst){
        while(!isEmpty())
            dst.add(pop());
    }

    // 그냥 와일드카드<?>와 달리 데이터를 넣어도 정상 동작한다.
    // 소비자, 데이터를 받는다.
    public void popAll2(Collection<? super E>dst){
        while(!isEmpty())
            dst.add(pop());
    }
}

```

- 위에는 pushAll과 popAll이 있다.
- pushAll을 테스트하면 아래와 같다.

```java
@Test
void test_pushAll(){
    Stack<Number> numberStack = new Stack<>();
    Iterable<Integer> integers = Arrays.asList(3, 1, 4, 1, 5, 9);
    
    // 제네릭은 상위 하위 타입 간 형변환이 불가능하다. 그러므로 컴파일 에러가 발생한다.
    // numberStack.pushAll(integers);

    // 생산자의 하위 타입을 허용하는 <? extends E>를 통해 Number의 하위 타입인 Integer를 인자로 허용한다. 
    numberStack.pushAll2(integers);
}
```


```java
@Test
void test_popAll(){
    //given
    Stack<Number> numberStack = new Stack<>();
    Iterable<Integer> integers = Arrays.asList(3, 1, 4, 1, 5, 9);
    numberStack.pushAll2(integers);

    // when
    Collection<Object> obj = new ArrayList<>();
    
    // 위와 같은 이유로 컴파일 에러가 발생한다. 
    // numberStack.popAll(obj);
    
    // 소비자의 하위 타입을 허용하는 <? super E>를 통해 하위타입의 인자를 허용한다. 
    numberStack.popAll2(obj);
    
    // then
    for (Object o : obj) {
        System.out.println("o = " + o);
    }
}
```


## 와일드카드와 제너릭의 조합
- 만약 super 혹은 extends 없이 모든 데이타타입에 대하여 허용하고자 하면 어떻게 해야하는가?
- 와일드카드는 앞서 말한 바와 같이 인자를 변경할 수 없다. 이로 인하여 컴파일 에러가 발생한다. 

```java
public class Swap {
    public static void swapOld(List<?> list, int i, int j) {
        list.set(i, list.set(j, list.get(i)));
    }

    @Test
    void test(){
        List<Integer> argList = Arrays.asList(3, 45, 6, 32, 234, 46);

        // 컴파일 에러가 발생한다. 
        swapOld(argList, 0, argList.size() - 1);
    }
}

```

- 방법은 매서드를 이중화 한다. 외부 API메서드는 와일드카드로 모든 인자를 받고, 내부 메서드는 이미 데이터 타입을 알기 때문에(`<E>` void) 제네릭으로 데이터를 변경할 수 있다.

```java
public class Swap {
    public static void swap(List<?> list, int i, int j) {
        swapHelper(list, i, j);
    }

    private static <E> void swapHelper(List<E> list, int i, int j) {
        list.set(i, list.set(j, list.get(i)));
    }

    @Test
    void test(){
        List<Integer> argList = Arrays.asList(3, 45, 6, 32, 234, 46);

        swap(argList, 0, argList.size() - 1);

        System.out.println(argList);
    }
}
```