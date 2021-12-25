---
layout: post
author: infoqoch
title: js의 window, dom이란?
categories: [js]
tags: [js]
---

## js의 최상위 객체는?
- 자바 객체의 최상위 객체는 Object이다.
- js는 무엇일까? 브라우저의 최상위 객체는 window 이다.

## 자바스크립트의 탄생과 발전
- js 의 탄생은 form 의 유효성 검사를 위해 탄생했다. 
- form 이 확대되어 document와 html, 브라우저와 window 까지 확대된다. 

## HTML과 브라우저의 객체화, window와 DOM이란?
- js는 어떻게 form과 html을 다룰까? 객체화를 통해 다룬다.
- html을 데이타를 js의 객체로 변환하고, 그 데이타를 조작한다. 이를 DOM(Document Object Model) 이라 한다.
- js는 document를 넘어서 브라우저를 조작할 수 있다. 이 객체를 window라고 한다.

### document 객체와 친해지기

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <p>안녕! 나는 document의 p 객체 중 첫 번째 객체의 값이야!</p>
</body>
</html>
```

```js
console.log(this);
console.log(document.getElementsByTagName('p')[0].innerText); // "안녕! 나는 document의 p 객체 중 첫 번째 객체의 값이야!"
```

- this를 출력하면 window 의 모든 것이 출력된다. 이 때 key 와 value로 이뤄진 매우 복잡한 데이타를 확인할 수 있다.
- `document.getElementsByTagName('p')[0].innerText`의 의미는 다음과 같다.
  - 브라우저가 출력하는 문서(document)를 객체화한 `document`에 접근한다.
  - `document`는 다양한 프로퍼티를 가지고 있다. 이 중 태그의 이름이 p 인 것 중 첫 번째 객체를 추출하는 메서드를 사용한다. 이것이 `getElementsByTagName('p')[0]` 이다. 이를 통해 `document`의 다양한 객체 중 하나인 `p 태그`의 첫 번째 객체(index : 0)를 가져 온다. 
  - `p 태그`의 다양한 프로퍼티 중, 태그 사이의 문자열을 가리키는 `innerText` 프로퍼티의 value를 추출한다.
- 파싱, 바인딩, 마셜링이란 다양한 단어가 존재하는데, 이것의 핵심은 다른 리소스를 어떤 프로그램이 사용할 수 있는 메모리로 전환하는 행위를 의미한다. DOM 이란 어려운 것이 아니다. HTML을 JS가 이해할 수 있는 형태로 변환하는 것을 의미하며, 이를 객체와 배열 형태로 변환하는 것을 의미한다. 그러니까 key와 value를 가진 프로퍼티의 집합으로 만드는 것이며, 이러한 key와 value를 조작하는 행위를 의미한다. 

### window 객체와 친해지기
- 우리는 윈도우 객체의 프로퍼티스를 넣을 수도 있다. 
- 브라우저 -> F12 -> 콘솔에서 다음과 같이 입력

```js
this.findMe = "find ME!!!!";
window;
```

- window를 호출하면 `Window {window: Window, self: Window, document: document, name: '', location: Location, …}` 과 같이 출력된다. 이 값을 왼쪽 클릭을 하고 'expand recursively' 을 누르면 전체 데이타가 나온다. 
- 전체 데이타에서 'find ME!!!!' 를 검색하면 window 의 프로퍼티로 존재함을 확인할 수 있다. 
- js에서 객체에 프로퍼티스를 `obj.name = 'kim'`으로 추가하는 것처럼 `this.findMe = '나 찾아봐!`라는 식으로 윈도우 객체에 추가 가능하다.

## window의 주요 프로퍼티
- window 객체를 통해 우리는 다양한 것을 출력하고 조작할 수 있다.
- window.location : 브라우저의 url
- window.history : 브라우저의 뒤로가기 버튼
- window.document : html

## window의 주요 매서드
- alert()
- confirm()
- prompt()
- setInterval()

