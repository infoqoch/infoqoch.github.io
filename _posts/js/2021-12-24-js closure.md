---
layout: post
author: infoqoch
title: js 클로저 함수
categories: [js]
tags: [js]
---

## 클로저
- 클로저Closure는 자바의 함수 구현 방식 중 하나로 프로퍼티의 은닉화를 보장하는 코딩 방식이다. 
- 클로저란 명칭은 메모리와 관련이 있다고 한다. 외부함수의 메모리가 내부 메모리를 참조한 변수가 사라지기 전까지 없어지지 않는다는 의미에서 유래되었다고 한다. 그러니까 내부 함수의 생명주기가 외부 함수의 종료(close)를 좌우한다는 의미이다. 
- 결론적으로 자바스크립트는 클로저를 통해 외부함수의 데이타를 은닉화하며, 원하는 기능을 구현할 수 있다.

### 간단한 클로저
- 클로저는 함수의 리턴값을 함수로 가진다. 
- 외부 함수에는 프로퍼티가 정의되어 있다. 내부 함수를 리턴받은 변수는 절대로 외부 함수의 프로퍼티에 직접 접근할 수 없다.
  
```js
function counter(){
    let num = 0;
    
    return function(){
        return num++;
    };
};

let cnt = counter();
cnt();
```

### 클로저의 다중함수 구현
- 클로저를 좀 더 확대하면 자바의 getter setter 등 다양한 매서드를 구현 가능하다.
- 자바에서 클래스를 상속받은 객체가 서로 다르듯 같은 내부함수를 리턴받은 참조변수는 서로 다른 메모리를 바라보고 있다. 

```js
function counterV2(){
    let num = 0;                   
    
    return {
        adder : function(){
            num ++;
            return num;
        },
        get : function(){
            return num;
        },
    }
};

let cnt1 = counterV2();

cnt1.adder();
cnt1.get();

let cnt2 = counterV2(); // cnt1 과 cnt2는 다르다.
```

