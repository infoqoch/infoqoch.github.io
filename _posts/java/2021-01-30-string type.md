---
layout: post
author: infoqoch
title: String의 다양한 특징들
categories: [java]
tags: [java]
---

### String 타입은 참조변수
- 처음 자바를 배울 때 가장 먼저 배우는 데이터 타입은 String 이다. 왜냐하면 `System.out.println("Hello, World!");` 를 출력해야 하니까. 그런데 String 은 primitive type 과 다른 참조타입과는 다소 성격이 다르다. 오히려 이해하기가 까다롭다. 
- 기본변수와 참조변수로 int 와 String을 비교하자. int의 경우 그 값은 stack에 저장된다. 그러나 String의 객체는 heap에 저장되고 그것의 주소만 스택에 저장된다. 
- 만약 아래와 같이 String 과 int가 선언된다면 그것의 데이터는 아래의 표와 같이 저장된다.  

```java 
int a = 3; 
String b = "java"; 
```

|변수|값|주소|값|
|---|---|---|---|
|int a|3| | |
|String b|heap 30번지|heap30번지|"java"|

- 이러한 특징으로 값이 없는 String 은 null 을 반환하고 int 는 0을 반환한다.
  
```java
String[] strs = new String[3];
System.out.println(strs); // 값 : Ljava.lang.String;@3b6eb2ec
for (String str : strs) {
    System.out.println(str); // 값 : null / null / null
}

int[] ints = new int[3];
System.out.println(ints); // 값 : [I@1e643faf
for (int i : ints) {
    System.out.println(i); // 값 : 0 / 0 / 0
}
```
### String과 다른 참조변수 간 비교
- 하지만 String은 보통의 객체와 컬렉션과는 차이를 가진다. 그 특징은 다음과 같은데,
  - String 은 new 를 객체를 생성하지 않으며,
  - 데이터가 정확하게 일치하면 이를 선언한 변수는 동일한 객체를 가리키며,
  - 데이터가 일치하지만 다른 주소의 다른 객체를 생성하고 싶으면 new 를 통해 생성한다.   

> 참고로 참조변수 간 == 은 메모리의 주소값이 동일한지를 확인하는 과정이다. 
```java
String a = "java";
String b = "java";
System.out.println(a==b);  // true 

String aa = new String("spring");
String bb = new String("spring");
System.out.println(aa==bb); // false

String aaa = "aaa";
String bbb = aaa;
System.out.println(aaa==bbb); // true

LocalDate date = "2021-01-01"; // 컴파일 오류. String 이외에 어떤 객체도 객체 생성 없이 초기화할 수 없다.
```

### String 의 array 로서의 특징들
- String 은 기본타입처럼 새로운 객체 생성 없이 변수에 값을 대입할 수 있다는 특별한 특징을 지닌다. 동시에 다른 객체나 콜렉션이 가지는 다양한 매서드를 사용할 수 있다. 
- 특히 String 은 배열로의 특징을 가지고 있어서, subString(), indexOf(), length, charAt() 등 index에 따른 데이터 조작이 가능하다. 
  
```java
String str = "abcdefg";
int length = str.length();
String substring = str.substring(0, 3);
str.charAt(4);
```