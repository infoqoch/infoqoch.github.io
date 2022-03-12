---
layout: post
author: infoqoch
title: 이펙티브자바, 38. 확장할 수 있는 열거 타입이 필요하면 인터페이스를 사용하라
categories: [java]
tags: [java, effective]
---

## 열거 타입과 인터페이스
- 열거 타입은 인터페이스를 구현할 수 있고, 이를 통해 확장 가능하다.
- 인터페이스는 표준 구현체 역할을 하며, 해당 값을 매개변수로 활용하는 등 유연하게 사용 가능하다.

```java
public interface Operation {
    double apply(double x, double y);
}

public enum BasicOperation implements Operation{
    PLUS("+"){
        public double apply(double x, double y) {return x + y;}
    },
    MINUS("-"){
        public double apply(double x, double y) {return x - y;}
    },
    TIMES("*"){
        public double apply(double x, double y) {return x * y;}
    },
    DIVIDE("/"){
        public double apply(double x, double y) {return x / y;}
    };

    private final String symbol;

    BasicOperation(String symbol){
        this.symbol = symbol;
    }

    @Override
    public String toString(){
        return symbol;
    }
}
public enum ExtendedOperation implements Operation{
    EXP("^"){
        public double apply(double x, double y) {return Math.pow(x,y);}
    },
    REMAINDER("%"){
        public double apply(double x, double y) {return x % y;}
    };

    private final String symbol;

    ExtendedOperation(String symbol){
        this.symbol = symbol;
    }

    @Override
    public String toString(){
        return symbol;
    }
}
```

- 아래의 테스트를 통하여 정상 동작함을 확인할 수 있다. 

```java
@Test
void test(){
    double x = 100d;
    double y = 50d;
    
    for(BasicOperation o :BasicOperation.values()){
        System.out.println("o.toString() = " + o.toString());
        System.out.println("o.apply(x,y) = " + o.apply(x,y));
        System.out.println();
    }

    for(ExtendedOperation o :ExtendedOperation.values()){
        System.out.println("o.toString() = " + o.toString());
        System.out.println("o.apply(x,y) = " + o.apply(x,y));
        System.out.println();
    }
}
```

- 필요하다면 제네릭의 유연성을 활용하여 메서드를 구현할 수 있다. 
- 이 때 메서드의 매개변수는 enum을 받거나 인터페이스를 받을 수 있다.

```java
// Enum 클래스를 받고, 해당 클래스를 values()로 루핑한다.
private <T extends Enum<T> & Operation> void enumMethod
        (Class<T> opEnumType, double x, double y){
    for (Operation o : opEnumType.getEnumConstants()) {
        System.out.println("o.toString() = " + o.toString());
        System.out.println("o.apply(x,y) = " + o.apply(x,y));
        System.out.println();
    }
}

@Test
void test2(){
    double x = 20d;
    double y = 80d;
    enumMethod(BasicOperation.class, x, y);
}

// 배열 (values())가 아닌 List 컬렉션을 받는다.
// Operation 인터페이스로 받는다.
private void collectionMethod(
        Collection<? extends Operation> opSet, double x, double y){
    for (Operation o : opSet) {
        System.out.println("o.toString() = " + o.toString());
        System.out.println("o.apply(x,y) = " + o.apply(x,y));
        System.out.println();
    }
}

@Test
void test3(){
    double x = 30d;
    double y = 60d;
    collectionMethod(Arrays.asList(BasicOperation.values()), x, y);
}
```