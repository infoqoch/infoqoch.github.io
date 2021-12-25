---
layout: post
author: infoqoch
title: js 지역변수와 전역변수
categories: [js]
tags: [js]
---


## global 과 local
### 변수의 경합
- 같은 변수 명이 중복되고, 그것을 호출 할 경우, js 는 그 경합에서 어떤 변수에 손을 들어줄까? 

```js
const y = 10;

const adder = function(x){
  const y = 20;
  const result = x+y;
  console.log(result);
}

adder(20) // 20+20 = 40
```

- js 에서 지역으로 한정할 수 있는 코드블럭은 함수 내부밖에 없다. 그러니까 지역변수는 함수만 가질 수 있다. 
- 만약 함수가 여러 개면 어떨까?

```js
const y = 10;

const adder = function(x){
  const y = 20;

  return function(){
    const y = 30;

    const result = x+y; 
    console.log(result);
  }
}

const adder2 = adder(40);
adder2(); // 30 + 40 = 70
```

- 가장 안에 있는 함수의 변수가 승리한다.

