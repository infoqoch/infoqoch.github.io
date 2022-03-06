---
layout: post
author: infoqoch
title: 자바, 클래스, 인터페이스 등 기초적인 지식에 대한 짧은 메모
categories: [java]
tags: [java]
---

## 들어가며
- 이펙티브 자바에서 클래스/메서드 파트를 공부를 하였고, 이에 대한 기초 지식이 부족함을 느꼈다. 기초적인 지식 중 놓친 내용에 대하여 간략하게 정리하고자 한다. 
- 신용권 개발자님의 이것이 자바다를 참고하였다. 

## 클래스의 선언과 class 파일의 생성 
- 소스파일의 이름과 동일하게 코드에서의 클래스 이름을 정해야 한다. 그리고 public 으로 접근 제어자를 부여해야 한다.
- 소스파일 내부에 public class 이외에 클래스를 작성할 수 있다. 해당 클래스는 소스코드로는 한 파일에 저장되지만 컴파일 시점에서 다른 파일(.class)로 분리 된다. `class Tire`의 경우 package-private 상태이기 때문에, class가 외부에 생성되더라도 동작 과정에서는 문제가 되지 않는다. 


```java
public class PublicClass {

}

class PackagePrivateClass{

}
```

- 아래의 내용처럼 실제로 분리된다! 신기하다!

![](/assets/pasteimage/2022-03-05-java%20class%20basic/2022-03-05-23-41-10.png)

## 정적 초기화 블록
- 인스턴스의 경우 생성자에서 초기화를 하며, 이때 필드를 채울 수 있다. 
- 정적 필드의 경우 static 블록에서 수행한다.

```java
public class StaticInitBlock {
    public static final String RANDOM_UUID;

    static {
        System.out.println("정적 클래스에 대한 초기화 블록이 실행됩니다!");
        RANDOM_UUID = UUID.randomUUID().toString();
    }

    public static void main(String[] args) {
        System.out.println("StaticInitBlock.RANDOM_UUID = " + StaticInitBlock.RANDOM_UUID);
    }
}
```

- 정적 메서드에서 인스턴스 필드에 바로 접근할 수 없다. 메인 메서드 역시도 static이므로 동일하다.

```java
public class StaticInitBlock {
    public static final String RANDOM_UUID;
    public String instanceField;

    static {
        System.out.println("정적 클래스에 대한 초기화 블록이 실행됩니다!");
        RANDOM_UUID = UUID.randomUUID().toString();

        // instanceField = "abc";
    }

    public static void main(String[] args) {
        System.out.println("StaticInitBlock.RANDOM_UUID = " + StaticInitBlock.RANDOM_UUID);

        // instanceField = "abc";
        final StaticInitBlock instance = new StaticInitBlock();
        instance.instanceField = "abc";
    }
}
```

## 패키지와 import
- 클래스에 접근하는 방법은 세 가지이다. 
    - 경로를 다 적거나, 
    - import로 경로를 적고 클래스 이름만 적거나, 
    - import static로 경로를 적고 매서드만 적는 방법이다. 

```java
import java.time.LocalDate;

import static java.time.LocalDateTime.*;

public class ImportTest {
    public static void main(String[] args) {
        System.out.println("java.time.Instant.now() = " + java.time.Instant.now());
        System.out.println("LocalDate.now() = " + LocalDate.now());
        System.out.println("now() = " + now());
    }
}
```

```log
java.time.Instant.now() = 2022-03-05T16:21:05.917352400Z
LocalDate.now() = 2022-03-06
now() = 2022-03-06T01:21:06.026354400
```

## 어너테이션의 정책
- 어너테이션을 구현할 때 보통 @Target과 @Retention을 어너테이션으로 가진다. 
- @Target은 TYPE, FIELD, METHOD 등 어너테이션을 사용하려는 대상을 지정할 때 사용한다.
- @Retention은 어너테이션의 유지 기간을 정한다. 대체로 어너테이션은 리플렉션 기능과 함께 사용하기 때문에, 보통은 유지 기간을 RUNTIME으로 한다. 


## 접근 제한자와 상속
- private은 상속할 수 없고 해당 클래스 내부에서만 사용 가능하다.
- package-private(default)은 같은 패키지에 있는 경우에만 접근할 수 있다. 
- protected는 상속한 경우 접근 가능하다. 
- 상속을 할 수 있고, 상속을 통해 조작 가능한 데이터는 공개되어 있는 것과 같다. 그러니까 public을 포함한 protected는 접근 제어자로 공개한 것과 같다. 
- 그러므로 protected는 상속을 통해 변경 및 튜닝이 필요한 부분에 대해서만 제한적으로 사용한다. 가능하면 private 혹은 package-private을 한계로 한다. 

### 같은 패키지 내의 접근 예시

```java
public class AccessTest {
    public static void main(String[] args) {
        final String publicField = PackagePrivateClass.PUBLIC_FIELD;
        final String protectedField = PackagePrivateClass.PROTECTED_FIELD;
        final String packagePrivateField = PackagePrivateClass.PACKAGE_PRIVATE_FIELD;
        // final String privatePrivateField = PackagePrivateClass.PRIVATE_PRIVATE_FIELD; // 컴파일 에러
    }
}

class PackagePrivateClass{
    public static final String PUBLIC_FIELD = "hi!";
    protected static final String PROTECTED_FIELD = "hi!";
    static final String PACKAGE_PRIVATE_FIELD = "hi!";
    private static final String PRIVATE_PRIVATE_FIELD = "hi!";
}
```

### 다른 패키지에서의 접근
- 디렉토리가 access.a 이다. 상속하거나 접근할 대상이다. 

```java
package access.a;

public class AccessTest {
    public static final String PUBLIC_FIELD = "hi!";
    protected static final String PROTECTED_FIELD = "hi!";
    static final String PACKAGE_PRIVATE_FIELD = "hi!";
    private static final String PRIVATE_PRIVATE_FIELD = "hi!";
}
```

- 디렉토리가 access.b 이다. 앞의 클래스에 접근하고자 한다.

```java
package access.b;

import access.a.AccessTest; 

public class AccessTestTest {
    public static void main(String[] args) {
        // final String protectedField = AccessTest.PROTECTED_FIELD; // 컴파일 오류가 발생한다.
        final String publicField = AccessTest.PUBLIC_FIELD;
    }
}

class AccessExtends extends AccessTest{
    public static void main(String[] args) {
        final String protectedField = AccessTest.PROTECTED_FIELD; // 상속을 하니 protected 까지 접근 가능하다. 
        final String publicField = AccessTest.PUBLIC_FIELD;
    }
}
```

## 인터페이스의 필드는 무조건 public 상수이다. 
- 클래스에서 생성자를 누락할 경우 자동으로 기본 생성자를 생성해준다. 
- 인터페이스의 필드 역시 예약어를 누락한다 하더라도 자동으로 public final static을 붙여 준다. 
- 인터페이스의 메서드는 모두 public abstract이다. 
- 인터페이스의 구현체는 리스코프의 원칙에 따라 하위 객체가 상위 객체로 치환되어야 한다. 그러므로 인터페이스 구현 객체는 언제나 public이어야만 한다. 

```java
public interface InterfaceJava8 {

    String abc =  "abc";

    LocalDateTime getDate();

}
```

```java
public class Main {
    public static void main(String[] args) throws NoSuchFieldException, NoSuchMethodException {
        final Field abc = InterfaceJava8.class.getDeclaredField("abc");
        System.out.println("abc = " + abc);

        final Method getDate = InterfaceJava8.class.getDeclaredMethod("getDate");
        System.out.println("getDate = " + getDate);
    }
}
```

```log
abc = public static final java.lang.String interfaces.a.InterfaceJava8.abc
getDate = public abstract java.time.LocalDateTime interfaces.a.InterfaceJava8.getDate()
```

## 오버라이딩 없이 사용하는 매서드, static, default, java 8
- 자바8 이전에는 모든 인터페이스 메서드는 abstract 메서드였다. 
- 자바8 이후 구현하지 않고 사용할 수 있는 메서드 default 와 static이 생겼다.
- default는 인스턴스에서 사용하고 static은 정적 메서드로 사용한다.

```java
public interface InterfaceJava8 {

    String abc =  "abc";

    LocalDateTime getDate();

    default String defaultMethod(){
        return "defaultMethod";
    }

    static String staticMethod(){
        return "staticMethod";
    }

}
```

- 정적 매서드에 대하여 인터페이스에서 바로 static method를 호출함을 확인할 수 있다. 
- 람다로 작성한 인터페이스 익명 구현 객체에서 default method를 호출함을 확인할 수 있다. 

```java
public class Main {
    public static void main(String[] args) throws NoSuchFieldException, NoSuchMethodException {
        System.out.println("InterfaceJava8.staticMethod() = " + InterfaceJava8.staticMethod());

        final InterfaceJava8 interfaceJava8 = () -> LocalDateTime.now();
        System.out.println("interfaceJava8.defaultMethod() = " + interfaceJava8.defaultMethod());

    }
}
```

```log
InterfaceJava8.staticMethod() = staticMethod
interfaceJava8.defaultMethod() = defaultMethod
```

- 마지막으로 Interface와 그것의 구현객체는 다음과 같다. 구현객체는 interface가 아닌 class임을 확인할 수 있다. 

```java
System.out.println("InterfaceJava8.class = " + InterfaceJava8.class);
System.out.println("interfaceJava8.getClass() = " + interfaceJava8.getClass());
```

```log
InterfaceJava8.class = interface interfaces.a.InterfaceJava8
interfaceJava8.getClass() = class interfaces.b.Main$$Lambda$1/0x0000000800067040
```

