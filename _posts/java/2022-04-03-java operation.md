---
layout: post
author: infoqoch
title: 자바, 연산자, 오버플로우와 부동소수점 문제
categories: [java]
tags: [java]
---

## 연산에서의 오버플로우 대응
- 연산 과정에서 오버플로우가 발생하더라도 자바에서는 어떤 예외처리도 해주지 않는다. 오버플로우 한 결과값을 전달할 뿐이다. 
-  Math 메서드를 사용할 경우 오버플로우가 발생할 때 예외처리를 한다. 

```java
public class OverflowSafetyOperationTest {
    @Test
    @DisplayName("덧샘, 정상")
    void add(){
        final int result = Math.addExact(123, 234);
        Assertions.assertThat(result).isEqualTo(357);
    }

    @Test
    @DisplayName("덧셈, 오버플로우")
    void add_overflow(){
        Assertions.assertThatThrownBy(()->{
            Math.addExact(Integer.MAX_VALUE, 1);
        }).isInstanceOf(ArithmeticException.class);
    }

    @Test
    @DisplayName("곱셈, 정상")
    void multi(){
        final int multi = Math.multiplyExact(10, 6);
        Assertions.assertThat(multi).isEqualTo(60);
    }
    
    @Test
    @DisplayName("곱셈, 오버플로우")
    void multi_overflow(){
        Assertions.assertThatThrownBy(()->{
            Math.multiplyExact(Integer.MAX_VALUE/5, 6);
        }).isInstanceOf(ArithmeticException.class);
    }
}
```

- 자바의 기본 라이브러리에서 좋은 기능을 제공하지만, 단순한 호기심으로 오버플로우를 어떤 식으로 감지하는지에 대해여 검토해보고 싶었다. 복잡한 메서드를 만들기보다, 단순하게 양수 두 개에 대하여 덧샘과 곱샘을 구현해보고자 하였다.
- 오버플로우의 특징은 기본타입의 특징으로부터 비롯하는데, int가 8바이트의 초괏값에 대해서는 32비트 이상의 것을 생략하는 것으로부터 발생한다. 이 말은, 오버플로우를 해소하는 메서드를 만들기 위해서는, 결괏값이 32비트를 초과하는지를 검증하면 된다.

### 덧샘과 오버플로우
- 8비트의 가장 큰 숫자를 더한 값과 가장 작은 숫자를 더해봤다. 
- 8자리와 8자리를 더하면 무조건 9자리가 되는 것을 확인할 수 있다. 
- 사실 십진수는 100+100은 200으로 3의 자리이지만, 이진수는 0아니면 1이며, 1이어야지만 자리수를 차지한다. 그러니까 같은 자리수를 가진 숫자를 더하면 반드시 한 자리가 올라갈 수 밖에 없다.

```java
    @Test
    @DisplayName("덧샘의 바이트 환산 및 오버플로우 확인")
    void add_overflow() {
        final int maxOf8bit = Integer.parseInt("11111111", 2);
        System.out.println("Integer.toBinaryString(maxOf8bit*2).length() = " + Integer.toBinaryString(maxOf8bit*2).length()); // 9

        final int minOf8bit = Integer.parseInt("10000000", 2);
        System.out.println("Integer.toBinaryString(minOf8bit*2).length() = " + Integer.toBinaryString(minOf8bit*2).length()); // 9
    }

```

### 곱셈의 오버플로우
- 앞서의 내용과 동일한 방식으로 구현했다. 
- 곱셈의 경우 각 정수의 자릿수의 합이 가능한 최대한의 자릿수가 되는 것을 확인할 수 있다. 
- 곱셈의 자릿수는 십진수와 이진수가 다르다. 십진수는 두 개의 정수의 자릿수를 더한 다음 1을 빼야 한다. 하지만 이진수는 두 개의 정수의 자릿수를 더한 값이거나 혹은 1을 뺀 값이 나온다. 

```java
    @Test
    @DisplayName("곱셈의 바이트 환산 및 오버플로우 확인")
    void multi_overflow() {
        final int maxOf8bit = Integer.parseInt("11111111", 2);
        System.out.println("Integer.toBinaryString(maxOf8bit * maxOf8bit).length() = " + Integer.toBinaryString(maxOf8bit * maxOf8bit).length()); // 16

        final int minOf8bit = Integer.parseInt("10000000", 2);
        System.out.println("Integer.toBinaryString(minOf8bit * minOf8bit).length() = " + Integer.toBinaryString(minOf8bit * minOf8bit).length()); //15
    }
```

### Integer.parseInt()와 signed 자료구조
- 위의 내용을 테스트하며 Integer.parseInt("이진수", 2); 를 자주 사용했다.
- 한편, 분명하게 32비트를 표현한 정수인데 예외가 발생하는 경우가 있다. 해당 코드는 아래와 같다.

```java
    @Test
    @DisplayName("Integer.parseInt()의 메서드와 예외상황")
    void parseIntTest(){
        Integer.parseInt("01111111111111111111111111111111", 2); // 문자가 32개인 문자열이다.
        Integer.parseInt("11111111111111111111111111111111", 2); // 예외가 발생한다.
        int a = Integer.parseUnsignedInt("11111111111111111111111111111111", 2); // 정상 동작한다. -1 을 반환한다.
    }
```

- 위와 같은 예외가 발생하는 이유는 int의 최대값과 관련이 있다. 기본적으로 자바에서 int는 signed 이다. 하지만 parseInt 메서드는 int의 최대값을 초과할 경우 예외를 던지도록 구현되었기 때문이다(`api 설명 중 : parseInt("2147483648", 10) throws a NumberFormatException`)
- parseUnsignedInt 메서드의 경우 `Long.parseLong(s, radix);` 을 통해 리턴을 하고, 이를 int로 바꾼다. 4바이트를 초과하는 값은 제거하기 때문에, 결과적으로 signed가 된 형태의 결과값, 그러니까 기대한 값이 정확하게 출력된다. 

## double 과 NaN, Infinity 연산
- 나눗셈의 경우 0으로 나눈 결과값에 대하여 NaN 혹은 Infinity 를 반환한다. 정확하게는 / 연산에 대해서 Infinity를 결과로 하며, % 에 대하여 NaN을 리턴한다.
- 이를 검증하는 메서드를 Double이 제공한다.

```java
    @Test
    void test(){
        double right = 5, left =0;

        System.out.println("right / left = " + right / left);
        Assertions.assertThat(Double.isInfinite(right/left)).isTrue();

        System.out.println("right % left = " + right % left);
        Assertions.assertThat(Double.isNaN(right%left)).isTrue();
    }
```

## 부동소수점의 문제
- 만약 아래와 같은 상태에서 두 개의 실수를 비교하면 어떻게 될까?

```java
    @Test
    @DisplayName("부동소수점을 무시한 상태에서 비교한다")
    void compareTest(){
        double d = 2.1d;
        float f = 2.1f;
        System.out.println("d==f = " + (d==f)); // false
        System.out.println("((float)d==f) = " + ((float)d==f)); // true
        System.out.println("(d==(double)f) = " + (d == (double) f)); // false
    }
```

- 자바의 기본 타입 중 double과 float는 실수로, 부동소수점으로 표현한다.
- 현재의 쟁점에서 부동소수점이란 두 가지의 의미를 지닌다. 첫 번째는 십진수가 아닌 이진수로 십진수를 처리한다는 의미이며, 두 번째는 소수점의 처리방식을 부동소수점으로 처리한다는 의미이다.

### 소수점과 십진수와 이진수의 차이
- 십진수의 소수는 딱 떨어지지만 이진수의 입장에서는 소수점이 딱 떨이지지 않을 수 있다. 그러니까 십진수의 입장에서는 단순하기 0.1이지만 이를 이진수로 표현하기 위하여 무한하게 2로 나누는 상황이 올 수 있다. 2로 나눈 값을 다시 실수로 표현하면 예를 들면 0.10000000000000...중략...0000123 이라는 형태의 실수를 반환하게 된다. 
- 다음으로 double이 표현하는 소수의 범위와 float이 표현하는 소수의 범위가 다르다. 
    - float을 기준으로 비교한다면, double은 float이 지원하는 만큼만을 잘라서 비교하기 때문에 d와 f가 같다고 표현하나, 
    - double을 기준으로 비교할 경우 f가 지원하는 범위를 넘어선 순간부터 00000..중략..0000 으로 표현하게 된다. 결국 다르다는 결과값을 출력한다.
- 십진수와 이진수 간 패러다임의 차이로 인하여 실수 간 비교는 조심스럽게 처리해야 한다. 동일한 데이터 타입 간 비교를 하거나 필요하다면 BigDecimal 클래스를 사용해야 한다. 

### 부동소수점이란?
- 컴퓨터가 소수점을 처리하는 방식은 고정소수점과 부동소수점이 있다. 고정소수점은 부호비트(음수/양수)를 제외한 비트를 반절로 나눠 정수부와 소수부를 나누는 방식이다. 4바이트의 실수로 표현할 경우, 각각 1비트, 8비트, 23비트로 구성된다. 단순한 방식이지만 정수부의 표현범위가 너무 적어지는 단점이다. 그러니까 정수의 표현범위가 15bit(2의 15승) 밖에 없다.
- 이러한 한계를 해소하고자 정수부/소수부로 나누는 것이 아닌, 지수부/가수부로 나누는 것을 부동소수점이라 한다. 4바이트의 실수로 표현할 경우, 각각 8비트, 23비트로 구성된다. 지수부에 십진수로서의 자릿수를 표현한다. 가수부는 정수/소수의 여부 관계 없이 하나의 숫자로 보며, 이를 비트로 표현한 부분이다. 이를 통해 더 넓은 숫자를 표현할 수 있다. 다만 이로 인한 정확도가 떨어지는 문제가 발생한다.


