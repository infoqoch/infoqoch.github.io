---
layout: post
author: infoqoch
title: js 변수의 선언, 활용
categories: [js]
tags: [js]
---

## 모든 변수는 참조변수
- 자바의 경우 primitive type 이 존재하지만 자바스크립트는 언제나 객체만 존재한다. 그러니까 변수는 언제나 참조변수이고 값은 객체이다. 
- 숫자 `123` 나 문자열 `"hello world"` 는 사실상 `new Number(123)` 이나 `new String("hello world")`와 같다. 

## 변수의 선언
### var
- var를 선언하더라도 그 변수의 유일함을 보장받지 못한다. 그러므로 가능하면 사용하지 않는다.

```js
var hi = 'hi';
console.log(hi);
var hi = 'hello';
console.log(hi);

// hi
// hello

const hi = 'hi';
const hi = 'hello';

// "SyntaxError: Identifier 'hi' has already been declared
```

### var 가 없는 변수는?
- var 는 호이스팅이 적용되기 때문에, var 와 함께 선언된 변수는 var 로서 적용된다. 
- 선언은 하단에 있고(`var value;`) 이 값을 상단에서 활용(`console.log(value)`)할 경우 다만 그 값이 없기 때문에 `undefined` 를 리턴한다.
- 그렇다면, `var`  자체를 사용하지 않고 선언한 변수는 어떻게 될까? 이는 전역변수 window 의 프로퍼티로 동작한다. 

```js
console.log(value) // undefined
var value = "hi";
```

- 아래의 동작은 사실 `window.value = 10` 과 동일하다. 
- 특정 지역에 한정되지 않는 this의 경우 전역변수로서 window를 의미한다.

```js
value = 10;
console.log(value) // 10 
console.log(this.value) // 10
```

### const와 let
- const는 상수로서, 변하지 않는다. 
- let은 변수로서 대입에 따라 값이 변한다.

```js
const hi = 'hi';
hi ='hello';
console.log(hi);

// "TypeError: Assignment to constant variable.

let hi = 'hi'
hi = 'hello'
console.log(hi);

// "hello"
```

### const 를 사용하고 필요시 let 으로 바꾼다.
- 데이타가 엉키지 않는 것이 가장 이상적이기 때문에 가능하면 대부분의 값을 const로 한다. 필요시 let으로 바꾼다.

### 호이스팅
- 호이스팅이란 끌어올린다는 의미로서 변수와 함수의 변수를 먼저 읽는다.
- var varName 의 경우 먼저 해당 변수를 읽고 (`var varName`), 이 값은 `undefined` 이기 때문에 `console.log(varName)`의 값을 가진다.
- 하지만 호이스팅을 하지 않는 let 과 const 는 존재하지 않는 변수를 호출했기 때문에 에러를 생성한다.(물론 키워드 없이 변수를 선언하고 그것은 암묵적으로 var로 받아드리지만, 여기서는 `Cannot access 'letName' before initialization` 라는 식으로 에러를 생성한다).

```js
console.log(varName) // undefined
var varName = "Choi"

console.log(letName); // error
let letName = "Kim"; 

console.log(constName); // error
const constName  = 'aoi'
```

### global 과 local
- 변수의 선언은 전역변수와 지역변수가 있다. 
- 변수의 이름이 같더라도 변수의 scope에 따라 서로 다르다. 
- 변수는 언제나 scope 가 좁을 수록 좋다. 

```js
const msg = 'goodjob'
console.log(msg);
function greeting(name){
  const msg = `hello ${name}`;
  console.log(msg);
}
greeting('kim');
```

## 데이타타입
### 선언
- 숫자는 그냥 쓴다.
- 문자열은 '', "", `` 중 하나로 감싼다.
- `` 을 사용할 경우 원하는 변수를 ${} 형태로 넣을 수 있다. 자바의 printf 의 %s 혹은 log.info("{}"); 와 유사하다. 

```js
const a = '10'
const b = 20

console.log(typeof a);
console.log(typeof b);
```

### 자동형변환
- js의 prompt 의 결괏값은 string 이다. 

```js
const target = prompt('숫자를 입력해보세요.');
console.log(typeof target);
```

- 문자열을 더하면 문자열을 합친다. 나누기는 숫자로 형변환한다. 

```js
const a = '10'
const b = '20'

console.log((a+b)/2) // "10"+"20" = "1020". "1020"/2 = 510
```

### 오류 
- infinity 는 0으로 나눌 때,
- NaN 은 NoneOfNumber로 숫자가 아닌 데이타타입이 사용될 때 발생한다.

```js
console.log(10/0)
console.log('abc'/0)
```

- null 과 undefined 은 유사하다. 그러나 차이는 null 은 의도적으로 선언했을 때(null 도 선언이라고 표현할 수 있는지 모르겠지만) null로 반환하며, 그 이외 null 로 나올 것 같은 상황에서는 undefined 이 발생된고 한다. 두 개 모두 어찌됐든 변수에 값의 할당의 문제이다.

```js
var a = null;
console.log(a) // null

let b;
console.log(b) // undefined
```

## 비교 연산자
### == 과 ===
- == 은 값의 일치함을 확인하고
- === 은 데이타타입은 물론이거니와 데이타의 메모리의 주소값의 일치 여부도 판단한다. 
- 자바의 String 타입과 비슷하게, 생성자 없이 선언한 js string 타입은 그 값이 같으면 === 로 같다고 출력한다. 왜냐하면 메모리 위치는 동일하기 때문이다. 
- 반대로, 생성자를 통해 데이타를 선언하면 ===을 할 경우 값이 같더라도 false를 리턴한다.

```js
const a = '123';
const b = 123;

console.log(a==b); // true
console.log(a===b); // false

let a = 10;
let b = 10;

console.log(a==b);
console.log(a===b);

let c = 20;
let d = new Number(20);

console.log(c==d);
console.log(c===d);
```

### if와 &&, ||, =, !=
- 자바는 && 을 할 경우 양변 모두 검사를 하고 &을 할 경우 앞의 것이 false면 탐색이 종료된다. JS 는 && 을 할 경우 자바의 &와 동일하다.

### 문자열 비교
- 문자열을 비교할 경우 아스키코드를 기준으로 비교한다.

```js

if('a'>'c'){
  console.log('a는 c보다 크다')
}else{
  console.log('a는 c보다 작다')
}
```