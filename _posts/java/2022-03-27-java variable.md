---
layout: post
author: infoqoch
title: 자바, 변수와 타입
categories: [java]
tags: [java]
---

## 데이터 타입
### 기본 타입
#### byte
- bit가 8개 모여 byte를 이룬다. byte는 음수 표현을 위하여 최상위 비트(첫 자리)로 음수와 양수를 표현한다.
- 0을 기준으로 1을 빼거나 더한다고 생각하면 아래의 표가 이해하기 쉽다.

|이진수|정수|
|-----|----|
|01111111|127|
|00000001|1|
|00000000|0|
|11111111|-1|
|10000001|-127|
|10000000|-128|

#### char
- 자바는 모든 문자를 유니코드로 처리한다. 
- 유니코드는 `'\u0041'` 이란 형태로 출력할 수 있다.

```java
char c1 = 'A';
char c2 = 65;
char c3 = '\u0041';

System.out.println("c1 = " + c1);
System.out.println("c2 = " + c2);
System.out.println("c3 = " + c3);
```

### int
- 4byte의 정수이다.
- 8진수와 16진수는 아래와 같으며, 전화번호(01012341234)를 int로 저장할 수 없는 이유가 여기에 있다. 

```java
int i1 = 10;
int i2 = 01012341234;
int i3 = 0x1234;

System.out.println("i1 = " + i1);
System.out.println("i2 = " + i2); // 136954524
System.out.println("i3 = " + i3); // 4660
```

###  그외
- long은 8byte 의 정수이다. 
- float은 4byte, double은 8byte의 정수이다.

```java
long l1 = 123l;
long l2 = 123;
float f1 = 123.123f;
// float f2 = 123.123; // 컴파일 에러
double d1 = 2134.4235d;
double d2 = 1231.34534;
```

## 타입변환
- 타입변환에는 자동타입변환(promotion)과 강제타입변환(cast)가 있다. 
- 작은 것에서 큰 것으로 변환할 때를 자동타입변환이라 하며 기존의 데이타는 변화가 없다.
- 큰 것에서 작은 것으로 변환할 때를 강제타입변환이라 하며, 데이터가 엉킬 수 있다. 그러므로 명시적으로 캐스팅 `(int) 123123123l;` 을 해야 한다.
- 4byte의 int를 1byte의 byte로 변환할 때, int의 마지막 1byte를 가지고 간다. 캐스팅 때 음수가 나오는 이유는, 최상위 비트가 음수와 양수를 결정하기 때문이다. 

```java
public class CastTest {
    @Test
    void promotion(){
        byte b1 = 12;
        int i1 = b1;
        System.out.println("i1 = " + i1);
    }

    @Test
    void cast(){
        int i1 = 1234;
        byte b1 = (byte) i1;
        System.out.println("b1 = " + b1);

        int i2 = 1231231238;
        byte b2 = (byte) i2;
        System.out.println("b2 = " + b2);
        System.out.println("Integer.toBinaryString(i2) = " + Integer.toBinaryString(i2));  // 마지막 8자리 00000110
        System.out.println("Integer.toBinaryString(b2) = " + Integer.toBinaryString(b2));  // 110
    }
}
```

### 연산식에서의 자동변환
- 정수의 연산식의 최소단위는 int이다. 그러므로 int 이하의 정수는 int로 promotion된 후 연산을 수행한다.
- 자동변환의 오버헤드 문제로 인해 대체로 int 미만의 정수는 사용하지 않는다. 

```java
byte b1 = '1';
byte b2 = 'A';
int result = b1 + b2;
System.out.println("result = " + result); //114
```