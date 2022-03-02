---
layout: post
author: infoqoch
title: 이펙티브자바, 15-17 클래스의 접근 및 변경 가능성을 최대한 제한한다. 
categories: [java]
tags: [java, effective]
---

## 15. 클래스와 멤버의 접근 권한을 최소화하라. 
### 접근 권한의 최소화 
- 잘 설계된 컴퍼넌트를 구현하기 위해서는 다른 컴퍼넌트와 API로만 통신해야 한다. 
- 외부에서는, 컴퍼넌트의 API 이외에는 접근하지 못한다. 그러니까 개발과정에서 API의 명세가 변경되지 않는 한, 내부 동작은 어떤 식으로든 변경할 수 있게 된다. 개발 속도와 신뢰도를 높힌다. 
- 기본 원칙은 모든 클래스와 멤버의 접근성을 가능한 좁힌다. 가장 이상적인 방식은 private이며, 불가피한 상황에서는 package-private 으로 한다. 
- public, protected가 되는 순간, 그 클래스와 필드는 외부와 통신하는 API로 동작하게 되며, 변경 및 유지보수 과정에서 하위 호환성을 위하여 영원히 관리하게 된다. 

### public 클래스의 인스턴스 필드는 public이 아니게 하라
- 필드에 대하여 public 으로 선언하느 순간, 해당 필드에 대한 어떤 제한도 불가능하다. 그러므로 가능하면 public을 사용하지 않는다. 
- 불변 객체로 안정성을 보장하기 위하여 final을 붙이더라도 문제가 발생한다. 객체 내부의 로직을 통한 변경이 불가능하다. 어떤 방식으로든 인스턴스의 필드에 대해서는 접근 권한을 최소한으로 하고 내부 로직을 통해 해당 필드를 조작하는 형태로 가게 된다. 
- 결과적으로 인스턴스의 필드에 접근할 때, 메서드를 통해 접근하도록 한다. getter나 기타 매서드를 사용하도록 강제한다. 

### public 클래스의 상수 필드의 경우 공개할 경우 해당 객체가 불변임을 static final을 통해 보장하라. 다만 배열의 경우 이를 제한하지 못한다. 
- 정적 필드를 공개해야 하는 경우가 있다. 이 경우 public static final 을 사용할 수 있다.
- 하지만 배열의 경우 배열 내부 요소값에 대한 조작을 제한할 수 없다. 

```java
public static final Thing[] VALUES  = {...} ; // 조작 가능하다. 

private static final Thing[] PRIVATE_VALUES = {....} ; // 접근 불가능하다. 
public static final List<Thing> values(){ // 메서드를 통해 접근하며, 해당 값은 방어적으로 복사한다. 
    return PRIVATE_VALUES.clone();
}
```

## 17. 변경 가능성을 최소화하라(불변클래스)
- 가장 안정적인 객체는 절대로 변하지 않는 객체이다. 이를 불변 객체라 한다. 
- String, BigInteger, BigDecimal 이 주요 불변 객체이다.

### 불변객체의 조건
- 객체의 상태를 변경하는 메서드를 제공하지 않는다.
- 클래스를 확장할 수 없도록 한다.
    - 하위 클래스를 만들 수 없다.
- 모든 필드를 final로 선언한다.
- 모든 필드를 private으로 선언한다.
    - 클라이언트에서 직접 접근하여 수정하는 일을 막는다. 
- 자신 외에는 내부의 가변 컴포넌트에 접근할 수 없도록 한다. 
    - 클래스에서 외부의 가변 객체를 참조한 필드가 있어서는 안된다. 해당 값을 가진 필드가 있어서는 안되고, 해당 값을 반환해서도 안된다. 
    - 필요할 경우 방어적 복사를 수행해야 한다. 

### 불변 객체의 장점
- 불변 객체는 근본적으로 스레드로부터 안전하다. 그러므로 clone과 같은 복사를 할 필요가 없이 공유 가능하다.
- 공유 가능하기 때문에 해당 객체를 상수로 만들고 재활용할 수 있다. 

### 예시
- 기존에는 복소수라는 예제로 사용하는데, 복소수의 개념 자체가 어려워서 좀 더 단순한 PhoneNumber의 예제를 수정하여 사용했다.

```java
public final class PhoneNumber { // final을 키워드로 삽입하여 상속할 수 없도록 하였다. 
    private final int areaCode, prefix, lineNum; // private final로 불변하다. + 외부의 데이타를 참조하지 않는다. 
 
    public PhoneNumber(int areaCode, int prefix, int lineNum) { // 생성자 이외에 어떤 방식으로도 데이터를 변경할 수 없다. 
        this.areaCode = rangeCheck(areaCode, 999, "area code");
        this.prefix   = rangeCheck(prefix,   999, "prefix");
        this.lineNum  = rangeCheck(lineNum, 9999, "line num");
    }

    private static int rangeCheck(int val, int max, String arg) {
        if (val < 0 || val > max)
            throw new IllegalArgumentException(arg + ": " + val);
        return val;
    }

    @Override
    public String toString() { 
        return "전화번호는 다음과 같습니다 : "+ areaCode + "-"+ prefix +"-"+ lineNum;
    }
}
```

```java
public final class PhoneNumberTest {
    public static final PhoneNumber MY_MOTHER_PHONE_NUMBER = new PhoneNumber(111, 123,1235); // 불변 객체는 근본적으로 스레드 안전하다. 안심하고 공유할 수 있으며 이러한 재활용은 좋다. 더 나아가 안전하기 때문에 clone 등 복사할 필요가 없다. 
    public static final PhoneNumber MY_FATHER_PHONE_NUMBER = new PhoneNumber(222, 321,5321);

    @Test
    void test(){
        System.out.println((new PhoneNumber(222, 123, 1234))); // 참조변수르
        System.out.println("MY_MOTHER_PHONE_NUMBER = " + MY_MOTHER_PHONE_NUMBER);
    }
}
```

### 정적 팩토리로 생성자를 대체
- 아래의 방식을 통해 유연하게 구현할 수 있다. 

```java
public class PhoneNumberTest {

    private PhoneNumberV2(int areaCode, int prefix, int lineNum) {
        this.areaCode = rangeCheck(areaCode, 999, "area code");
        this.prefix   = rangeCheck(prefix,   999, "prefix");
        this.lineNum  = rangeCheck(lineNum, 9999, "line num");
    }

    public static PhoneNumberV2 valueOf(int areaCode, int prefix, int lineNum){
        return new PhoneNumberV2(areaCode, prefix, lineNum);
    }

//...
}
```

### 정리
- 가능하면 모든 것을 불변으로 만든다. 인스턴스에 대해서 private final을 최대한 적용한다.
- 생성자는 불변식 설정이 모두 완료된, 초기화가 완벽히 끝난 상태의 객체를 생성해야 한다. 그 외의 생성자에 대해서는 제한한다. 