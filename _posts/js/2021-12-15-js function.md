---
layout: post
author: infoqoch
title: js function 함수
categories: [js]
tags: [js]
---

## 함수
- js는 primitive type이 wrapper인 것처럼 함수 또한 객체이다.
- 함수는 closure 와 같이 함수를 리턴할 수 있다. 

```js
const fn = new Function("x, y", "return x+y");
console.log(fn(1,7));
```

- 위의 방식보다는 아래의 함수선언식과 함수표현식을 주로 사용한다. 

## 함수선언식
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

## 함수 표현식 
- 반대로 변수를 먼저 선언하고 함수를 대입하는 방식이 함수표현식(Function Expression)이다. 익명함수라고도 한다. 
- 함수표현식은 호이스팅을 지원하지 않아, 해당 기능을 선언하기 전에 호출하면 에러를 만든다. 
- 다만 함수가 객체임을 들어내는 방식이기 때문에 이로 인하여 선호하기도 한다. 
  
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

### 화살표 함수와 메서드
- 화살표함수의 this는 지역변수가 아닌 전역변수이다. 
- 브라우저 환경에서 this 는 window를 의미한다. 
  
```js
let kim = {
  name:'김길동',
  age:20,
  toString : () => console.log(`저의 이름은 ${this.name}입니다.`)
}

kim.toString() // "저의 이름은 JS Bin Output 입니다."
``` 