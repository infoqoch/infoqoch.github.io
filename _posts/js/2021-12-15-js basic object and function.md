---
layout: post
author: infoqoch
title: 자바스크립트 기본 함수와 객체
categories: [js]
tags: [js]
---

## 함수
### 함수선언식
- function 뒤에 함수의 이름을 설정하는 방식을 함수 선언식(Function Declarations) 이라 한다.
- 변수의 값이 할당되지 않을 경우에 대비하여 default 값을 설정할 수 있다. 
- 호이스팅으로 인해 함수 선언식은 정의하기 전에 호출해도 동작한다. 
- var 는 undefined 문제로 사용을 꺼린다면, 함수 선언식은 호이스팅으로 인하여 어디서든 해당 기능을 사용할 수 있으므로 선호하는 경우가 있다. 

```js
greeting()

function greeting(name = '여러분'){
  const msg = `Hello, ${name}`;
  console.log(msg)
}

greeting('김길동')
```

### 함수 표현식 
- 반대로 변수를 먼저 선언하고 함수를 대입하는 방식이 함수표현식(Function Expression)이다. 지금까지 익명함수라고 알고 있었는데...!
- 함수표현식은 호이스팅을 지원하지 않아, 해당 기능을 선언하기 전에 호출하면 에러를 만든다. 
  
```js
// greeting('함수표현식!') // "ReferenceError: Cannot access 'greeting' before initialization

const greeting = function (name = '여러분'){
  const msg = `Hello, ${name}`;
  console.log(msg)
}

greeting('함수표현식!')
```

### 화살표현식
- 자바에서는 람다라고 하는데 js는 화살표현식이라 한다.
- -> 에서 => 로 차이를 가진다. 

```js 
let greeting = (name) => console.log(`Hello, ${name}`);

greeting('김길동')
```

## 객체
### 선언과 조작
- JS의 객체 선언은 황당할 정도로 간단했다. 
- 지금까지 나는 객체 선언을 아래와 같이 하는지 알았다.

```js
let kim = new Object();
kim.age = 12;
kim.name = '김길동'

console.log(kim);
```

- 더 쉬운 방법이 있다. json 을 다루는 것과 유사하다.

```js
let kim = {
  name:'김길동',
  age:20
}
    
console.log(kim);
```

- 객체의 각각의 값을 properties라고 한다. properties의 입력과 삭제, 수정은 다음과 같다.


```js
kim.city = '서울';
kim.age = 15;
delete kim.age;

console.log(kim)
```

### 매서드
- 객체의 함수를 매서드라 한다.
- 객체의 프로퍼티스를 사용하기 위해서는 반드시 this 를 사용해야 한다. this를 사용하지 않는 경우 전역변수를 사용한다.

```js
let kim = {
  name:'김길동',
  age:20,
  toString : function(){
    console.log(`저의 이름은 ${this.name}이며 나이는 ${this.age}입니다.`)
    
  }
}

kim.toString()
```

```js
const kim = {
  name:'김길동',
  age:20,
  toString : function(){
    console.log('저의 이름은 '+ name +'입니다.') // "저의 이름은 JS Bin Output 입니다." // jsbin.com 을 사용중이며 name 이 전역변수로 있는 것 같다. 
    console.log('나이는 ' + age + '입니다.') // ReferenceError: age is not defined

  }
}

kim.toString()

```

### 화살표 함수와 메서드
- 화살표함수의 this는 지역변수가 아닌 전역변수이다. 

```js
let kim = {
  name:'김길동',
  age:20,
  toString : () => console.log(`저의 이름은 ${this.name}입니다.`)
}

kim.toString() // "저의 이름은 JS Bin Output 입니다."
```

### this 가 전역변수일 때
- js 를 학습할 때 this 로 인하여 많은 어려움을 겪는다고 한다. 현재 나는 단순하게 정리하지만 얼마나 더 많은 함정이 숨어있을지... 암튼,
- 전역변수로서 this 는 웹브라우저에서는 window이며 웹서버 환경(nodejs)에서는 global 이라 한다.


## 나아가며
- 이번 정리 덕분에 js에서 애매하게 알고 넘어가던 많은 것들을 알게되었다. 좀 더 깊숙하게 배우고자 한다. 
- 아래의 링크를 참고했다. jquery 를 자주 사용했다면 쉽게 이해할 수 있으리라 생각한다! 유튜브를 보면 중급과정도 있어서 더 들을 예정이다ㅎㅎ. 좋다. 
  
> 참고
- [유튜브 코딩앙마](https://www.youtube.com/watch?v=KF6t61yuPCY)  강추!😜
- [jsbin js 웹 에디터](https://jsbin.com/?js,console) 강추!😜 autorun을 끄고 ctrl+enter 로 사용합니다!
