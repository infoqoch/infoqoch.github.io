---
layout: post
author: infoqoch
title: JAVA 자바 데이터 타입, 변수 그리고 배열
last_modified_at: 
categories: [java]
tags: [java]
---


## 1. 자바의 데이터 타입
- 자바의 데이타 타입을 크게 분류하면 기본 타입(primitive type)과 참조 타입(reference type)으로 나뉘어 있다. 

### 1.1 기본 타입(primitive type)
- 기본 타입은 리터럴(literal)을 그 값으로 가지며, 리터럴의 종류는 아래와 같다

<table>
  	<tr>
      <td rowspan="1">구분</td>
      <td>리터럴 타입</td>
      <td>형태</td>
      <td>길이</td>
	</tr>
	<tr>
      <td rowspan="1">논리타입</td>
      <td>boolean</td>
      <td>true/false</td>
      <td>1byte</td>
	</tr>
  	<tr>
      <td rowspan="2">문자타입</td>
      <td>char(아스키코드)</td>
      <td>'a', '4', '(', ' ', '\t'</td>
      <td>2byte</td>
	</tr>
  <tr>
      <td>char(유니코드)</td>
      <td>'파', '이', '썬'</td>
      <td>2byte</td>
	</tr>
  <tr>
      <td rowspan="4">정수타입</td>
      <td>byte</td>
      <td>-127, 0, 128</td>
      <td>1byte</td>
	</tr>
  <tr>
      <td>short</td>
      <td>-300, 0, 3</td>
      <td>2byte</td>
	</tr>
  <tr>
      <td>int</td>
      <td>-123, 0, 1234</td>
      <td>4byte</td>
	</tr>
  <tr>
      <td>long</td>
      <td>-2134L, 0, 565L</td>
      <td>8byte</td>
	</tr>
    <tr>
      <td rowspan="2">실수타입</td>
      <td>float</td>
      <td>-14.34F, 1.0F, 0.345F</td>
      <td>4byte</td>
	</tr>
  <tr>
      <td>double</td>
      <td>-54.345, 0, 3.454</td>
      <td>8byte</td>
	</tr>
</table>

#### 1) 논리타입
- true/false로 이뤄져 있다. 
  
#### 2) 문자타입
- 문자타입은 유니코드이며 2바이트이다. 유니코드에는 아스키코드, 한글이 포함되어 있다. 문자타입을 초기화 할 떄 ''(작은따옴표)로 블럭을 한정 한다. 
- 문자타입을 선언할 때 해당 유니코드를 알고 있다면 그 값을 대신하여 입력할 수 있다. 그 예시는 아래와 같다. 
  
```java
char var1 = 'a';
char var2 = 97;
System.out.println(var1==var2); // true
```

#### 3) 정수타입 
- 정수타입으로서 소수점이 존재하지 않는다. 
- long의 경우 숫자 마지막에 L을 붙인다. 30L, -19L
  
#### 4) 실수타입
- 실수타입으로서 소수점이 존재한다.
- float의 경우 숫자 마지막에 F를 붙인다. 343.234F

### 1.2 참조타입 (reference type)
- 참조타입은 선언된 변수의 값이 실제 값이 아닌 주소를 가진 타입을 의미한다. 참조타입의 메모리 저장의 방식은 아래 표와 같다. 

<table style="border : 1px black solid">
  <tr style="border : 1px black solid">
    <td colspan="2">스택</td>
    <td colspan="2">힙</td>
  </tr>
  <tr>
    <td>변수</td>
    <td>값</td>
    <td>주소</td>
    <td>값</td>
 </tr>
  <tr>
    <td>int a</td>
    <td>3</td>
    <td></td>
    <td></td>
 </tr>
  <tr>
    <td>String b</td>
    <td>heap 30번지</td>
    <td>heap30번지</td>
    <td>"java"</td>
 </tr>
 </table>

- 참조타입은 클래스, 필드, 배열, 문자열 등 리터럴을 제외한 모든 데이타의 주소를 값으로서 가진다. 


## 2. 변수
### 2.1 기본타입과 참조변수의 선언과 초기화
- 변수의 선언, 초기화를 하는 방법은 다음과 같다. 

```
int i;.............(1)
i = 10; 

int j = 10; ..............(2)
```

- (1) int는 데이타 타입, i는 변수의 이름, 10은 변수의 값, 세미콜론(;)은 코드가 끝났음을 알리는 연산자이다. 첫번째 문장은 선언으로서, 변수의 데이타 형태와 변수의 이름을 정하는 것을 의미한다. 초기화는 값을 부여하는 행위이다. 이 경우 선언과 초기화를 따로 했다. 
- (2) 변수의 선언과 초기화를 같이 했다. 
  
- 참조변수의 선언과 초기화는 다음과 같다.

```java
String str1 = "java";
System.out.println(str1); // java
String[] strs1 = {"hello", "world"};
for (String s : strs1) {
    System.out.println(s); // hello world
}

int[] ints1 = {1,2,3,4};
for (int i : ints1) {
    System.out.print(i); // 1234
}

int[][] ints2 ={
        {1,2,3},
        {4,5},
        {6,7,8,9}
};

for (int[] ints : ints2) {
    System.out.print("[");
    for (int i : ints) {
        System.out.print(i);
    }
    System.out.println("]");
} // [123] [45] [6789]
```

### 2.2 지역변수(local variable)의 범위(scope)와 생명주기(life cycle)
- 지역변수는 아래와 같이 하나의 스레드 안에서 선언되고 초기화 되는 변수를 의미한다. 지역변수의 생명주기는 소속되어 있는 스레드(스택)이나 매서드의 생명주기와 같이한다. 가비지컬렉터를 통하여 관리된다. 
- 지역변수는 그것이 선언된 블럭에 따라 범위를 달리한다. 아래의 코드를 참고하자. 

```java
public static void main(String[] args) {
    int localInt1 = 0;  ................(1)
    int localInt2;   ................(2)
    String localStr1 = "java";

    if(localInt1==0){
        localInt1 = 1;
        localInt2 = 2;
        int localInt3 = 3; ...........(3)
    }

    if(!localStr1.equals("hello")){
        System.out.println(localInt1);  // 1
        System.out.println(localInt2);  // 컴파일에러
        System.out.println(localInt3);  // 컴파일에러
    }
}
```

- (1) 메인 쓰레드에서 선언과 초기화가 동시에 이뤄졌다. 해당 쓰레드 내부에 있는 모든 블럭에서 접근 가능하며, 해당 값을 변경할 수 있다. 
- (2) 컴파일 에러 : Variable 'localInt2' might not have been initialized. 메인 쓰레드에서 선언을 하고, 첫 번째 if 제어문에서 초기화됐다. 하지만 두 번째 if 제어문에서는 컴파일 에러가 발생한다. 첫 번째 if 제어문이 true이므로 반드시 초기화(initialized) 될 것임에도 불구하고, 컴파일이 불가능하다. 블럭이 다를 경우 선언될 것으로 기대되나 문법 오류이다.
- (3) 컴파일 에러 : Cannot resolve symbol 'localInt3'. resolve는 추상의 값으로 실질적인 값에 접근함을 의미한다. localInt3이 선언된 블럭이 달라 접근 자체가 불가능하기 때문에, 두 번째 제어문의 블럭 입장에서는 존재하지 않는 것과 다름 없다. 
   
### 2.3 정적 맴버, 인스턴스 맴버의 범위와 생명주기
- 지역변수로서 하나의 스레드 혹은 매서드에 선언되는 것이 아닌, 클래스 블럭 안에서 선언되는 변수가 존재한다. 그러한 변수는 static 키워드의 존재 여부에 따라 정적 맴버, 매서드와 인스턴스 맴버, 매서드로 나뉜다. 아래는 두 형태의 맴버의 범위와 생명주기를 보여주는 코드이다. 

```java
public class Test2 {
    private static String staticStr = "static field"; ..........(1)
    private String str = "filed"; ............ (2) 

    public Test2() {
    }

    public Test2(String str) {
        this.str = str;
    }

    public static void main(String[] args) {
        System.out.println(staticStr); ........... (3) 
        System.out.println(str);.......... (4) : 컴파일 에러

        Test2 test2 = new Test2("instance"); ......... (5)
        System.out.println(test2.str); .........(6)
    }

}
```

- (1) 정적 맴버는 클래스 로더가 작동 할 떄 런타임 데이타 영역(Runtime Data Area) 중 메소드 영역(Method Area)에 저장된다. 메소드 영역의 데이타는 그것의 생명주기와 범위가 어플리케이션의 것과 동일하다. 이 말은, 정적 맴버는 해당 어플리케이션 안에서는 언제 어디서나 사용 가능하다. 그러므로 (3)에서 아무런 설정 없이 접근 가능하다. 
- (2) 인스턴스 맴버는 해당 클래스를 데이타 타입으로 하는 객체(인스턴스)를 통해서만 사용 가능하다. 그러므로 그것의 사용 범위는 해당 객체가 생성되는 위치에 한정되며, 생명주기는 객체가 생성된 메서드나 제어문의 생명주기에 의존한다. 그러므로 (4)에서 볼 수 있는 것처럼 해당 객체가 존재하지 않는 메인 스레드에서는 str에 접근이 불가능하다. (5)를 통해 해당 객체를 heap에 저장하고 그 주소를 가진 (6) test2 매개변수를 선언한 후에서야 접근이 가능하다. 
  
  
## 3. 타입 변환 
- 타입 변환이란 해당 변수의 데이타 타입을 다른 데이타 타입으로 변경하는 것을 의미한다. 참고로 타입 변환은 해당 객체의 데이타 타입을 변경하는 것이 아닌, 해당 객체의 값을 다른 데이타 타입을 가진 변수에 값을 부여하며 초기화한다.
- 타입은 참조타입과 기본타입 양측 다 가능하다. 여기서는 기본 타입만을 다루겠다. 

### 3.1 자동 타입 변환(Promotion)
- 리터럴 중 정수 타입을 길이를 기준으로 정렬하면 다음과 같다. byte(1byte) < short(2byte) < int(4byte) < long(8byte). 네 가지의 데이타 타입은 모두 정수이며 길이의 차이만을 가진다. 그러므로 byte가 short으로 변환할 때 특별한 문제 없이 자동 타입 변환이 가능하다. 
- 정수를 실수로 변경할 떄도 유지되는 경우가 있다. 이 경우 자동 타입 변환이 가능하다. 실수와 정수를 함께 비교하면 다음과 같이 정렬할 수 있다. byte(1byte) < short(2byte) < int(4byte) < long(8byte) < float(4byte) < double(8byte)

```java
Byte byte1 = 10; 
int int1 = byte1; // 10

double do2 = byte1; // 10.0
```

### 3.2 강제 타입 변환(Casting)
- 자동 타입 변환과 달리, 기존의 값이 변경될 가능성이 있을 경우, 캐스팅을 해야한다. 
- 길이가 긴 타입을 그것보다 짧은 타입으로 변경하거나, 실수를 정수로 변경할 때 발생한다. 
- 강자 타입 변환을 해야하는 경우, 값이 보존되는 것을 보장하기 위하여, 메서드나 제어문으로 통제해야 한다. 

```java
long long2 = 99999999999L;
int int2 = (int) long2; ...........(1)
long long3 = 1234L;
int int3 = (int) long3; ............(2)

long long4 = 1234L; ...........(3) 
long long4 = 99999999999999999L; ........... (4)
if(long4>Integer.MAX_VALUE || long4<Integer.MIN_VALUE){  .......(5)
    System.out.println("long 변수의 값이 int가 저장할 수 있는 범위를 초과하여 변경할 수 없습니다.");  ............ (6)
}else{
    int int4 = (int) long4;
    System.out.println("해당 변수가 다음과 같이 변경되었습니다 : "+int4); .........(7)
}
```

- (1) long2의 값이 int의 가용범위를 넘어서기 때문에 기존의 값을 잃어버렸다.
- (2) long2의 값이 int의 가용범위를 넘지 않기 때문에 기존의 값을 보존했다.
- (5) 기존의 값을 유지할 수 있을 경우 타입을 변환하고 그렇지 않은 경우 에러메시지를 출력하는 if 제어문이다. (3)의 경우 (7)을 출력하고 (4)의 경우 (6)을 출력한다.
  
- 실수에서 정수로 강제 타입 변환을 할 때, 그것의 결과물은 산수의 "버림(`Math.floor()`)"과 같다.

```java
double dou5 = 10.123; // 10 
int int5 = (int) dou5; // 10 
```
  
### 3.3 연산식에서의 자동 타입 변환
- 정수타입을 연산 할 때 자바는 byte 나 short 으로 할 수 없다. 그러니까 byte와 short을 강제로 int로 변환하고 연산한다. 그리고 결과값 또한 int이다.
- 그러므로 특별한 이유가 없으면 int 혹은 long을 정수의 기본 데이터타입으로 한다. 

```java
byte by1 = 23;
byte by2 = 10;

int  sum2 = by1 + by2; ..........(1)
byte sum1 = (byte) (by1 + by2); ........(2) 
```

- (1) byte 간 연산한 결과의 값은 int 타입이므로 캐스팅을 필요로 하지 않는다.
- (2) int의 결과값을 byte로 출력하기 위해서는 캐스팅을 해야 한다.


- 정수 타입과 실수 타입을 연산 할 때, 그 값은 실수타입을 따라간다. 실수의 형태로 값을 출력하려면 캐스팅을 필요로 한다.

```java
int intA = 10;
double douA = 5.5;
double douSum = intA + douA; // 15.5
int intSum = intA + (int)douA; // 15
```

- char 타입은 유니코드에 따라 리터럴 타입으로 변경 가능하다. 그러므로 연산 또한 가능하다.

```java
char var1 = 'a';
char var2 = 97;
System.out.println(var1==var2); // true
```

## 4. 변수와 관련한 추가 내용
### 4.1 상수(constant) 변수
- 값이 변경되지 않는 변수를 상수라고 한다. 선언 시 final 키워드를 추가한다. 
- 상수를 정의할 때 1) 선언과 초기화를 하거나 2) 선언을 먼저 한 후 나중에 초기화를 할 수 있다. 
- 초기화를 한 이후부터는 값을 바꿀 수 없다. 
  
```java
final int conInt1;
final int conInt2  = 0;

conInt1 = 1; ....(1)
conInt1 = 2; ....(2) 
conInt2 = 3; ....(3)
```
- (1) 선언을 먼저한 후 초기화를 차후에 했다. 문제 없이 작동한다.
- (2) 컴파일 에러 : Variable 'conInt1' might already have been assigned to. 이미 값이 할당(assigned) 되어 에러가 발생한다.
- (3) 컴파일 에러 : Cannot assign a value to final variable 'conInt2'. 상수 변수는 값을 할당할 수 없다. 
  
### 4.2 var (타입 추론)
- 변수를 선언할 때 데이타 타입을 정의 하지 않는다. 초기화 할 때의 값을 가지고 데이타 타입을 자동적으로 부여한다. 

```java
var msg = "hi?";
System.out.println(msg.getClass().toString()); // class java.lang.String
```



  

  
  