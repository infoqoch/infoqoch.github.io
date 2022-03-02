---
layout: post
author: infoqoch
title: 이펙티브자바, 18 상속보다는 컴포지션을 사용하라
categories: [java]
tags: [java, effective]
---

## 상속의 위험성
- 클래스가 다른 클래스를 상속하는 구현 상속은 오류를 내기 쉬운 소프트웨어를 만든다.
- 상속은 캡슐화를 깨뜨린다. 상위 클래스의 내부 구현에 하위 클래스가 종속되고 오작동의 가능성을 내포한다. 

## 예제 
- 아래는 HashSet을 구현하였다. 
- add를 할 때 몇 개를 하였는지 갯수를 세는 기능을 추가하기 위하여 구현하였다.
- extends를 통해 하였고, add와 addAll을 오버라이드 하였다. 

```java
public class InstrumentedHashSet<E> extends HashSet<E> {
    private int addCount = 0;

    public InstrumentedHashSet() {
    }

    public InstrumentedHashSet(int initialCapacity, float loadFactor) {
        super(initialCapacity, loadFactor);
    }

    @Override
    public boolean add(E e) {
        System.out.println("add called");
        addCount++;
        return super.add(e);
    }

    @Override
    public boolean addAll(Collection<? extends E> c) {
        System.out.println("addAll called");
        addCount+=c.size();
        return super.addAll(c);
    }

    public int getAddCount() {
        return addCount;
    }
}

```

- 테스트는 아래와 같이 한다. 

```java

@Test
void test(){
    final InstrumentedHashSet<String> insSet = new InstrumentedHashSet<>();
    System.out.println("test 매서드에서 add 1개 시작");
    insSet.add("kim");

    System.out.println("test 매서드에서 addAll 2개 시작");
    insSet.addAll(List.of("lee", "choi"));

    System.out.println("insSet = " + insSet);
    System.out.println("insSet.getAddCount() = " + insSet.getAddCount());
}

```
- 테스트의 결과는 아래와 같다. 

```log
test 매서드에서 add 1개 시작 
add called
test 매서드에서 addAll 2개 시작
addAll called
add called
add called
insSet = [choi, lee, kim]
insSet.getAddCount() = 5
```

- 의도와 달리 insSet.getAddCount() 의 결과는 5이다. 왜냐하면 addAll은 add를 활용하기 때문이다. addAll로 갯수를 센 다음, add를 통해 중복하여 한 번 더 갯수를 센다. 
- 상속을 통해 메서드를 오버라이딩 하는 것은 이처럼 내부 구현에 대한 이해를 전제하게 된다. 이 경우 상위 클래스를 구현하는 사람은 상속을 전제하여 복잡한 설명을 요구받게 되며, 하위 클래스를 구현하는 사람은 해당 클래스에 대한 복잡한 이해를 전제하게 된다. 컴퍼넌트가 외부에 노출된 API만을 가지고 사용한다는 규칙으로부터 멀리 떨어지게 된다.
- 그 외 상위 클래스의 내부 로직의 변경, 메서드의 생성 등 다양한 변경 과정에서, 하위 클래스에 안정성을 보장할 수 없다. 
- 그러므로 결과적으로 extends를 통한 상속은 최소한으로 해야한다. 만약 상속을 사용한다면 isA의 원칙을 지켜야 한다. 
- 그 보다는 컴포지션을 사용한다.

### 컴포지션 예제
- 인터페이스를 구현하는 FowardingSet을 만든다.
- Set 구현 클래스의 인스턴스를 필드값으로 가진다. 새로운 클래스의 구성요소로 쓰인다는 뜻으로 컴포지션Composition 이라 한다.
- 해당 구현 클래스의 메서드를 자신의 구현 메서드로 한다. 이 방식을 전달Forwarding이라 하며 전달 메서드Forwarding Method라 한다. 
- 노출된 API만을 활용하여, 상위 클래스의 내부 구현에 대한 어떤 고민도 필요하지 않게 된다. 메서드의 오버라이딩에 대한 부담감을 없애고 필요로한 내용을 구현할 수 있다. 
- 제너릭을 유지할 수 있다. 데이타 타입에 대하여 유연하다. 

```java
public class ForwardingSet<T> implements Set<T> {
    private final Set<T> s;

    public ForwardingSet(Set<T> s) {
        this.s = s;
    }

    @Override
    public int size() {
        return s.size();
    }

    @Override
    public boolean isEmpty() {
        return s.isEmpty();
    }

    @Override
    public boolean contains(Object o) {
        return s.contains(o);
    }

    @Override
    public Iterator<T> iterator() {
        return s.iterator();
    }

    @Override
    public Object[] toArray() {
        return s.toArray();
    }

    @Override
    public <T1> T1[] toArray(T1[] a) {
        return s.toArray(a);
    }

    @Override
    public boolean add(T t) {
        return s.add(t);
    }

    @Override
    public boolean remove(Object o) {
        return s.remove(o);
    }

    @Override
    public boolean containsAll(Collection<?> c) {
        return s.containsAll(c);
    }

    @Override
    public boolean addAll(Collection<? extends T> c) {
        return s.addAll(c);
    }

    @Override
    public boolean retainAll(Collection<?> c) {
        return s.retainAll(c);
    }

    @Override
    public boolean removeAll(Collection<?> c) {
        return s.removeAll(c);
    }

    @Override
    public void clear() {
        s.clear();
    }
}
```

```java
public class InstrumentedHashSet<E> extends ForwardingSet<E> {
    private int addCount = 0;

    public InstrumentedHashSet(Set<E> s) {
        super(s);
    }

    @Override
    public boolean add(E e) {
        System.out.println("add called");
        addCount++;
        return super.add(e);
    }

    @Override
    public boolean addAll(Collection<? extends E> c) {
        System.out.println("addAll called");
        addCount+=c.size();
        return super.addAll(c);
    }

    public int getAddCount() {
        return addCount;
    }
}
```

```java
    @Test
    void test(){
        final InstrumentedHashSet<String> insSet = new InstrumentedHashSet<>(new HashSet<>());

        insSet.add("kim");
        insSet.addAll(List.of("lee", "choi"));

        System.out.println("insSet = " + insSet.toString());
        System.out.println("insSet.getAddCount() = " + insSet.getAddCount());
    }
```

```log
add called
addAll called
insSet = effective.c18.composition.InstrumentedHashSet@447988a1
insSet.getAddCount() = 3
```

## 정리
- Set 인스턴스를 감싸고 있다는 뜻에서 래퍼 클래스라고 하여 이러한 패턴을 데코레이션 패턴이라 한다.
- 래퍼 클래스의 단점은 거의 없다. 전달 메서드를 작성하는 것이 지루하고, 콜백 관련한 SELF 문제가 있으나, 이것 이외에는 모두 장점이다. 
