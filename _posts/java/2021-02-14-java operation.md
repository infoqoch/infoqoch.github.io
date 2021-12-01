---
layout: post
author: infoqoch
title: java 연산자
categories: [java]
tags: [java]
---
  
## 1. 연산자와 연산식
- 자바는 데이타를 처리하고 결과를 산출하는 과정을 연산(Operations)이라고 한다. 연산을 위한 연산자(operator)와 연산하는 대상으로의 피연산자(opreand)가 있다. 이러한 코드를 연산식(expression)이라 한다. 
- 연산자의 종류에 따라 연산의 우선 순서와 방향이 차이를 가진다. 괄호 ()는 최우선 순위이므로 필요에 따라 적절하게 사용한다. 
- 연산자는 다른 연산자를 합쳐서 하나의 새로운 연산자를 만들 수 있다(+, ++, <, <=)
- 연산자의 경우 단항연산자(!, --), 이항연산자(a+b), 삼항연산자(a?b:c) 등, 연산식에 사용하는 연산자의 갯수에 따라 구분한다. 

## 2. 산술 연산자
### 2.1 산술 연산자란
- 산술연산자는 +,-,*,/,% 로 이뤄져 있다. 
- 정수끼리 연산을 하면, 피연산자 중에 long이 있을 경우 다른 피연산자는 long으로 변환 후 수행되며, 그 미만의 정수는 int 변환된 후 수행한다. 
- 실수와 정수간 연산을 하면, 실수가 아닌 정수는 실수로 변환 후 수행한다.
- 정수 간 연산을 한 후 실수로 데이타를 변환한다 하더라도 소수점은 버림이 된 상태로 값을 출력한다. 

### 2.2 산술연산자의 오버플로우 방지
- 오버플로우는 연산의 결과가 해당 데이타 타입의 수용가능한 범위를 초과할 때 발생한다. 오버플로우에 대응하는 코드는 아래와 같음.

```java
int a = 1000000000;
int b = 1000000000;
System.out.println(a*b);  // -1486618624

if(a>=Integer.MAX_VALUE/b){
    System.out.println("오버플로우 발생");  // 오버플로우 발생
}
```

### 2.3 산술연산자의 부동소수점 문제

```java
System.out.println(7*0.1); // 0.7000000000000001
```

- 위의 코드에서 우리가 기대하는 값은 0.7이다. 그러나 실제로는 0.7000000000000001 을 출력한다. 숫자 처리를 엄밀하게 해야할 경우 문제가 발생할 수 있다. 
- 이러한 문제가 발생하는 이유는 부동소수점 타입(double, float) 때문이라 한다. 해결책은 bigDecimal을 통해 가능하다. 예시는 아래와 같다.

```java
BigDecimal c = BigDecimal.valueOf(7.0);
BigDecimal d = BigDecimal.valueOf(0.1);
System.out.println(c.multiply(d)); // 0.70
```

### 2.4 NaN과 infinity, ArithmeticException
- 0으로 나누는 경우 아래와 같은 오류가 발생한다. 

```java
1/0 // ArithmeticException
1/0.0 // Infinity
1%0.0 // NaN
```
- 산술예외에 대해서는 예외처리를, Infinity와 NaN에 대해서는 Double.isInfinity(), Double.isNan()을 통해 true와 false 값을 받는 것으로 해결 가능하다. 
- 하지만 NaN의 경우 그 값이 String이라 하더라도 Double로 인식된다. 이에 대한 대응을 필요로 하며 그것은 아래와 같다.

```java
Double val = Double.valueOf("NaN"); // 컴파일 오류가 발생하지 않는다.
System.out.println(val+3); // NaN

if(val.isNaN()){
    val=0.0;
}
System.out.println(val+3); //3.0
```

### 2.5 문자열 연결 연산자(+)
- 숫자와 문자열을 연결할 수 있다. 한편, 숫자와 문자열이 혼합된 상태라면, 그것의 위치에 따라 산술연산이 되기도, 문자열 연결이 되기도 한다. 구체적인 내용은 아래와 같다.

```java
System.out.println(1+2+"번"); // 3번
System.out.println(1+(2+"번")); // 12번
```

### 3. 비교 연산자
- 피연산자를 비교하여 boolean 타입인 true/false를 산출하기 위한 연산자이다. <, <=, =, >, ==, != 등이 있다.
- 2.3의 부동소수점 문제가 동일하게 발생할 수 있다. 그러므로 double과 float의 비교 연산은 주의를 해야 한다.

```java
0.1==0.1f // false
```

- String의 경우 문자열이 동일하면 같은 해당 변수는 같은 주소를 가르킨다. 그러므로 비교 연산자가 작동한다. 하지만 new를 통해 새로운 객체를 생성하면 그 문자열이 동일하더라도 항상 false이다. 그때는 equals() 메서드를 사용해야 한다. 


## 4. 논리 연산자
<table>
  <tr>
    <td>논리곱(AND)</td>
    <td>&&,&</td>
    <td>좌항우항 모두 true</td>
  </tr>
    <tr>
    <td>논리합(OR)</td>
    <td>||,|</td>
    <td>둘 중 하나 혹은 양항 모두 true</td>
  </tr>
    <tr>
    <td>배타적논리합(XOR)</td>
    <td>^</td>
    <td>양항 중 단 하나만 true</td>
  </tr>
    <tr>
    <td>논리부정(NOT)</td>
    <td>!</td>
    <td>피연산자의 논리값을 바꿈</td>
  </tr>
</table>

- 논리곱과 논리합은 각각 연산자를 두 개를 가진다. &의 경우 좌항이 false일 경우 해당 연산식을 false로 처리한다. |의 경우 좌항이 true일 경우 해당 연산식을 true로 처리한다. &&과 ||의 경우 좌항의 논리값과 관계 없이 우항을 처리한다.

## 5. 비트 연산자
- 비트연산자는 0과 1로 이뤄진 bit 데이타를 의미한다. 데이타 타입 중 bit를 다루는 것은 자바에 존재하지 않는다. 그러므로 비트 연산자는 연산하고자 하는 정수를 int로 변환하고, 비트연산자(&, |, ^, ~, <<, >>, >>>)와 비트 논리 연산자(&, |, ^)를 처리한 후, int 값으로 산출한다. 
- 비트 연산자의 값을 출력하고 싶으면, Integer.toBinaryString() 매서드를 통해 String 값으로 받아야 한다. 추가적으로 비트 반전 연산자는 ~이며, 0을 1로 1을 0으로 바꾼다. 그 예시는 아래와 같다.

```java
System.out.println(Integer.toBinaryString(7)); // 111
System.out.println(Integer.toBinaryString(~7)); // 11111111111111111111111111111000
```

- 아래는 비트연산의 예시이며 그 아래의 table은 그것의 처리 과정이다. 

```java
System.out.println(6^3); // 5
```

<table>
  <tr>
    <td>값</td>
    <td>4</td>
    <td>2</td>
    <td>1</td>
  </tr>  
  <tr>
    <td>6</td>
    <td>1</td>
    <td>1</td>
    <td>0</td>
  </tr>  
  <tr>
    <td>3</td>
    <td>0</td>
    <td>1</td>
    <td>1</td>
  </tr>  
    <tr>
    <td>XOR(둘 중 하나만 true)</td>
    <td>true</td>
    <td>false</td>
    <td>true</td>
  </tr>  
  <tr>
    <td> 값 : 5</td>
    <td>1</td>
    <td>0</td>
    <td>1</td>
  </tr>  
</table>

- 비트 이동 연산자는 그 값을 좌측 혹은 우측으로 해당 값 만큼 밀어내는 것을 의미한다. 아래는 111을 좌측으로 3칸 옮기는 것을 의미한다. 

```java
System.out.println(Integer.toBinaryString(7<<3)); // 111000
```

## 6. 대입연산자(assignment operator)
- 대입연산자(=)를 통해 우항을 좌항의 변수의 값으로 저장한다. 
- 대입연산자에 다른 연산자를 추가하여 복합 대입 연산자를 만들 수 있다. 그럴 경우 변수의 값이 좌항이 되고, 대입연산자가 아닌 연산자를 연산자로 하며, 대입하는 값을 우항으로 한다. 설명으로는 복잡한데, 아래의 코드로는 쉽게 이해 가능하다. 

```java
double assign = 10.0;
System.out.println(assign+=10); // 20.0 (assign = assign + 10.0)
System.out.println(assign/=10); // 2.0 (assign = assign / 10.0)
```

## 7. 삼항연산자
- 삼항 연산자는 세 개의 피연산자를 통해 if문을 간략하게 처리한다. 그래서 조건 연산식이라고도 불린다. 

```java
String str = (10>6)?"10이크다":"6이크다";
System.out.println(str); // 10이크다
```

## 8. instanceof
- 부모타입의 객체를 자식타입으로 강제 타입 변환(Casting)을 할 수 있다. 하지만 상속관계가 없는 경우 ClassCastException이 발생할 수 있다. 그러므로 instanceof를 통해 해당객체가 해당타입에 상속관계인지를 true/false를 통해 보여준다. 그 말은 타입 변환이 가능하다는 의미와 같다. 

```java
if(parent instanceof Child){
	Child child = (Child) parent;
}
```

## 9. 화살표 연산자(람다식, ->)
- 인터페이스는 매소드는 존재하지만 구체적인 정의는 되어있지 않다. 이를 상황과 조건에 따라 정의하고 사용할 수 있다. 이때 사용하는 것이 람다식이다.
- 인터페이스 변수 = 람다식; 으로 정의한다. 람다식은 (타입 매개변수) -> {실행문}의 구조이다. 구체적인 코드는 아래와 같다.

```java
public interface TestInterface {
    public void method(int x);
}
public class test {
    public static void main(String[] args) {
        TestInterface test;
        test = x-> {
            System.out.println(x*5);
        };
        test.method(5); // 25
    }
}
```

- TestInterface는 반드시 단 하나의 메서드를 가져야 한다. 그렇지 않으면 어떤 메서드를 호출하는지 확인할 수 없기 때문이다.
- 인터페이스의 메서드는 리턴값의 여부(void, int)와 매개변수(int x)를 정의할 수 있다.
- 람다에서 정의할 때는 인터페이스에서 정의한 매서드의 형식에 맞춰서 리턴과 매개변수를 정의해야 한다. 