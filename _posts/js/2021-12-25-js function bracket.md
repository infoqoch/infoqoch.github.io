---
layout: post
author: infoqoch
title: js 함수를 대입할 때 소괄호(bracket)는 무슨 차이를 만드는가?
categories: [js]
tags: [js]
---

## 함수의 대입
- js 에서 함수는 객체이다. 그러므로 어떤 변수에 어떤 함수를 대입할 수 있다. 이러한 특징을 살린 것이 클로저 함수이다.
- 그럼 fn(); 과 fn; 의 차이는 무엇일까? 이를 구체적으로 살펴보고자 한다.

```js
const fn =  function(){
  console.log('fn의 log 동작!')
  return 'fn의 응답값';
}

console.log(fn)
// function fn(){
//     return 'fn의 응답값';
// }

console.log(fn())
// "fn의 응답값"
```

- fn 을 출력할 경우 함수 그 자체를 출력한다. 반대로 fn()은 해당 함수를 실행하고 발생한 결과값을 출력한다. 
- 그러므로 특정 변수가 해당 함수를 가리키게 만들고 싶다면 fn을 사용하며, 해당 함수를 수행하고 싶으면 소괄호를 붙여서 fn()이라 해야 한다. 
- fn()에 변수를 대입하면 어떻게 될까? `const value = fn()` 그것은 `fn()`의 리턴 값인 `"fn의 응답값"`을 대입한다. 
- 자바로 치면 전자는 참조변수의 복제, 그러니까 주소값의 복제와 유사한 것 같다. 후자의 경우 참조변수의 함수를 수행한 결과값을 해당 변수에 대입하는 것과 유사하다.

```js
const fn =  function(){
  console.log('fn의 log 동작!')
  return 'fn의 응답값';
}
const ref = fn(); // console.log의 값인 "fn의 log 동작!" 을 출력한다.
console.log(ref) // fn()의 리턴값인 "fn의 응답값" 을 출력한다. 
```

## onload 와 소괄호
- window.onload 를 사용할 때, 우리는 대괄호가 없이 사용한다. 이것은 어떻게 봐야 하는가?
- 아래의 코드를 살펴보자. 내가 기대하는 것은 html 파일을 모두 읽고 해당 함수를 가장 마지막에 수행하는 것이다. 

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
    <ul id='unordered-list'>
    </ul>
    <script>
        
        function addList(value){
            let list = document.createElement("li");
            list.append(document.createTextNode(value));

            let unorderedList = document.querySelector('#unordered-list');
            unorderedList.append(list);

            return 'SUCCESS';
        }

        addList("스크립트 첫번째 지점!");

        window.onload = addList("소괄호 사용!"); 

        addList("스크립트 마지막 지점!");
    </script>
</body>
</html>

```

- 결과는 아래와 같다.

```text
스크립트 첫번째 지점!
소괄호 사용!
스크립트 마지막 지점!
```

- 만약 `window.onload = addList("소괄호 사용!")` 을 `window.onload = addList`로 변환할 경우 어떨까?
- 결과는 아래와 같다.

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
    <ul id='unordered-list'>
    </ul>
    <script>
        
        function addList(value){
            let list = document.createElement("li");
            list.append(document.createTextNode(value));

            let unorderedList = document.querySelector('#unordered-list');
            unorderedList.append(list);

            return 'SUCCESS';
        }

        addList("스크립트 첫번째 지점!");

        window.onload = addList;

        addList("스크립트 마지막 지점!");
    </script>
</body>
</html>

```

- 원하는 방향대로 해당 함수가 가장 마지막이 수행된다.
  
```text
스크립트 첫번째 지점!
스크립트 마지막 지점!
[object Event]
```

### window.onload()
- `window.onload` 는 윈도우 객체의 프로퍼티이다. 모든 document가 로딩된 후 해당 함수를 실행한다. `window.onload();`
- 그러므로 `window.onload = addList("소괄호 사용!")` 란 사실,
  - `addList("소괄호 사용!");`를 호출하여 "소괄호 사용!" 을 리스트에 넣고
  - 그것의 리턴값을 onload 프로퍼티에 주입하는 방식이다. 
  - 하지만 "SUCCESS"를 `window.onload();`를 통해 수행할 수 없다.

- 반대로 `onload = addList` 는 onload의 변수가 특정 함수를 수행하도록 주소값을 전달한다. 그러니까 모든 html과 스크립트가 로딩 된 후, `window.onload();` 가 호출되는 시점에서의 행위를 정의한다.
- 실제로 `onload = addList` 으로 작성한 후, 브라우저 -> F12 -> 콘솔 에 `window.onload`를 명령하면 아래의 함수가 출력됨을 확인할 수 있다. 

```console
> window.onload;
< ƒ addList(value){ let list = document.createElement("li");list.append(document.createTextNode(value));let unorderedList = document.querySelector('#unordered-list'…

> window.onload();
< 'SUCCESS' // 그리고 list가 추가된다.
```
