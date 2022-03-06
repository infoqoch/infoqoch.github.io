---
layout: post
author: infoqoch
title: 자바, 중첩 클래스에 대하여 
categories: [java]
tags: [java]
---

## 중첩 클래스란?
- 클래스 내부에 선언하는 클래스를 중첩 클래스라 한다. 
- 장점으로는,
    - 두 클래스간 필드에 서로 쉽게 접근할 수 있으며,
    - 외부에 불필요한 클래스를 감추며 코드의 복잡성을 줄인다. 
- 중첩클래스는 클래스와 인터페이스 모두에서 사용할 수 있다.

## 중첩 클래스의 종류와 선언, 접근
- 중첩 클래스는 인스턴스 맴버클래스와 정적 맴버클래스가 있다. 그리고 메서드 안에서 선언되는 로컬 클래스가 있다.

### 인스턴스 맴버 클래스와 정적 맴버 클래스의 차이
- 초기화
    - 정적 맴버클래스는 외부(본체, 바깥) 클래스의 인스턴스 메서드나 정적 메서드 어디서든 인스턴스로 초기화 가능하다. 
    - 인스턴스 맴버클래스는 외부 클래스의 인스턴스 매서드에서만 인스턴스로 초기화 가능하다.

- 외부 클래스의 접근
    - 정적 맴버클래스는 외부 클래스의 정적 맴버에만 접근 가능하다.
    - 인스터는 맴버클래스는 외부 클래스의 모든 맴버에 접근 가능하다.


```java
public class SampleClass {

    // 인스턴스가 클래스의 중첩 클래스가 될 수 있으며,
    // 클래스가 인스턴스의 중첩 클래스가 될 수 있다.
    interface InnerInterface{
        int MAX_VALUE = 1234;
        String generateName();

        class InnerClassInInterface{
            String name;
            void printName(){
                System.out.println("name = " + name);
            }
        }
    }

    static String staticField;
    String instanceField;

    // 맴버 클래스, 인스턴스 맴버 클래스
    // 인스턴스 맴버 클래스는 어떤 필드에도 접근할 수 있다.
    class InstanceInnerClass{
        void sayGoodBye(){
            System.out.println("good bye~~");
            System.out.println("instanceField = " + instanceField);
            System.out.println("staticField = " + staticField);
        }
    }

    // 맴버 클래스, 정적 맴버 클래스
    // 정적 맴버 클래스는 인스턴스 필드에 접근할 수 없다. 
    static class StaticInnerClass{
        void sayHello(){
            System.out.println("hello!");
            // System.out.println("instanceField = " + instanceField);
            System.out.println("staticField = " + staticField);
        }
    }


    // 인스턴스 매서드에서, 인스턴스 맴버 클래스와 정적 클래스를 선언하고 초기화함에 있어 제한이 없다.
    void instanceMethod(){
        final InstanceInnerClass instanceInnerClass = new InstanceInnerClass();
        final StaticInnerClass staticInnerClass = new StaticInnerClass();
    }

    // 정적 매서드에서, 인스턴스 매서드는 선언 및 초기화 불가능하다.
    static void staticMethod(){
        // final InstanceInnerClass instanceInnerClass = new InstanceInnerClass(); // 컴파일 에러
        final StaticInnerClass staticInnerClass = new StaticInnerClass();
    }
}
```

### 로컬 클래스, 외부 메서드의 지역변수와 매개변수는 final 속성을 암묵적으로 가진다. 
- 매서드 내부에서 작성되는 클래스이다.
- 로컬클래스는 외부 클래스의 모든 필드에 제한 없이 접근 가능하다.
- 로컬클래스의 외부 매서드의 변수와 인자에도 접근 가능하다. 그러나 접근하는 모든 변수는 명시의 여부와 관계없이 암묵적으로 final 속성을 가진다.
- 그 이유로는 메모리 공간의 차이로부터 발생한다. 스택에 쌓이는 변수는 매서드의 동작 이후 자동으로 삭제된다. 하지만 힙 메모리에 있는 로컬 클래스는 생명주기를 달리한다. 그러므로 컴파일 시점에서 로컬 클래스의 매개 변수와 로컬 변수는 final이 되며, 힙 메모리에 저장된다. 
- 결론적으로 로컬 클래스가 사용 가능한 데이터는 **final로 선언된 변수**이다.
- 람다나 인스턴스 익명 구현 객체 내부의 코드블럭에서는 외부 메서드의 변수를 변경할 수 없었다. 그 이유가 궁금했는데, 이러한 메모리 공간의 차이로부터 발생한 문제였다. 

```java
public class SampleLocalClass {
    String instanceField = "instanceField";
    static String staticField = "staticField";

    void sampleMethod(String arg){ // final String arg
        String localVar = "localVar"; // final String localVar

        class LocalClass{
            void accessVars(){
                instanceField = "hi!";
                staticField = "hi!";
                // localVar = "hi!"; // final이라서 수정불가
                // arg = "hi!"; // final이라서 수정불가
            }
        }
    }
}
```

## 익명 객체
- 익명 객체란 인터페이스나 클래스를 상속하여 구현하는 클래스이다.
- 필드가 되거나 메서드 내 변수가 될 수 있다. 그러니까 맴버 클래스와 로컬 클래스가 될 수 있다. 
- 익명 객체는 부모를 구현하였기 때문에, 익명 객체를 구현할 때 새롭게 만든 매서드나 필드를 참조변수에서 꺼내 쓸 수 없다. 

```java
public abstract class AbstractParent {
    abstract void helloAbstract();
}
public interface InterfaceParent {
    void helloInterface();
}

public class Main {
    final AbstractParent abstractParent = new AbstractParent() { // 필드
        @Override
        void helloAbstract() {
            System.out.println("hello abstract!");
        }
    };

    public static void main(String[] args) {
        final InterfaceParent interfaceParent = new InterfaceParent() { // 로컬 변수
            @Override
            public void helloInterface() {
                System.out.println("hello interface!");
            }

            String newField ="newField";
            void newMethod(){
                System.out.println("new method");
            }
        };

        interfaceParent.helloInterface();
        // interfaceParent.newField; // 부모의 스펙에 종속된다. 새롭게 선언된 메서드나 필드에는 접근할 수 없다.
        // interfaceParent.newMethod();
    }

    static abstract class SampleClass{
        void method1(InterfaceParent interfaceParent) {}
        void method2() {

            method1(new InterfaceParent(){
                @Override
                public void helloInterface() {
                    System.out.println("hihi!!");
                }
            }); // 매개변수로 익명 객체가 사용될 수 있다. 여기서는 method1의 매개변수가 되었다.
        }
    }
}

```

