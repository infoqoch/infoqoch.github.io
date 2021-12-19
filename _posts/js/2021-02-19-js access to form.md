---
layout: post
author: infoqoch
title: js 와 jquery 의 form 태그의 접근 방식
categories: [js]
tags: [js, jquery]
---


## 들어가며

- 클라이언트에서 서버로 데이타를 전달함에 있어 가장 기본적이며 손쉬운 방법은 form과 form 에 딸린 태그이다. 하지만 각 form 의 태그들은 그것을 호출하고 조작하는 방식이 다르다. 이를 정리한다. 
- 참고로, 이러한 객체의 접근방식을 문서객체모델(DOM Document Object Model)이라고 한다. 브라우저 내에 html 페이지를 document라고 하며,  javascript가 해당 html을 객체화하고 조작하고 분석하며 출력하는 전체적인 과정을 의미한다. 
  
### 1. document에 접근하는 방법
- html에서 script를 사용하기 위해서는, `<script></script>` 태그로 블럭을 만들고 그 안에 자바스크립트 코드를 작성한다.  
- 한편, 브라우저는 html을 위에서 아래로 읽는다. 만약 스크립트 블럭에서의 식별자가 그것을 대상으로 하는 자바스크립트 코드보다 아래에 있으면 에러를 만든다.

```js
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <script>
        let before = document.getElementById("testId").innerHTML;
        console.log(`before target : ${before}`); /* null 로 인한 에러 발생 */
    </script>
</head>
<body>
    <div id="testId">안녕!</div> 
    <script>
        let after = document.getElementById("testId").innerHTML;
        console.log(`after target : ${after}`); /* 안녕! */
    </script>
</body>
</html>
```
-  이러한 한계를 해소하기 위하여 html을 모두 출력한 후에 스크립트를 동작시키는 코드는 아래와 같다.
  - 자바스크립트 : window.onload = function(){}
  - 제이쿼리 :   $(document).ready(function(){})    
  
```js
<script type="text/javascript">
    // document.getElementById("a").style.border = "solid black 1px"; // body 보다 위에 있어서 <div id ="a">가 생성되기 전에 id = a를 호출하였음. 그러므로 작동하지 아니함.
    window.onload = function (){ 
    	document.getElementById("a").innerHTML = "hello, js!"
    	document.getElementById("a").style.color = "red";
    }

    $(document).ready(function(){
    	$('#b').css("color", "blue").html("hello, jq!");
    });
</script>

<body>
    <div id="a"></div>
    <br>
    <div id="b"></div>
</body>
```
  
## 2. selector / element 객체 선언, 태그의 속성 부여 및 추출 
- selector의 경우 body, header, h1, span 등 html에서 기본적으로 제공하는 태그를 의미한다. 
- element의 경우 사용자가 지정하는 id, name, class 등을 의미한다. 
- id는 유일무이한 객체로서 단 하나의 태그에만 선언할 수 있다. 
- name/class는 다수의 태그에 선언할 수 있다. 각각의 객체의 값을 js 값으로 변환하거나 조작할 때 리스트로 받고 반복문으로 접근 가능하다.
  - querySelector는 해당하는 객체가 여러개라 하더라도 단 하나만 적용되며, 그것은 document에서 처음으로 출력되는 객체이다. 
  - selectorAll의 경우 해당하는 모든 객체에 적용된다. 
- 속성 부여와 추출은 setAttribute / getAttribute를 통해서도 가능하며, 그 이외에 다양한 방법이 존재한다. 

```js
<script type="text/javascript">
    window.onload = function () {
        document.getElementById("idA").style.color = 'red';
        document.getElementById("idB").style.color = 'blue';
        var nameAList = document.getElementsByName("nameA");
        for(var i=0; i<nameAList.length; i++){
            nameAList[i].style.textDecoration='underline';
        }
        var nameBList = document.getElementsByName("nameB");
        for(var i=0; i<nameBList.length; i++){
            nameBList[i].style.textDecoration='line-through';
        }
        var classAList = document.getElementsByClassName("classA");
        for(var i=0; i<classAList.length; i++){
            classAList[i].style.fontStyle='italic';
        }
        var classBList = document.getElementsByClassName("classB");
        for(var i=0; i<classBList.length; i++){
            classBList[i].style.fontWeight='bold';
        }

        var selectorAllList = document.querySelectorAll('h3');
        for(var i=0; i<selectorAllList.length; i++){
            selectorAllList[i].style.border ="1px red solid";
        }
        document.querySelector('h3').style.border ="5px black solid";
                                               
        var str = document.querySelector('h3').getAttribute('style');
            alert(str);
    }
</script>
```
  
## 3. 문서 객체 내부의 글자로서 html과 text의 선언
  - textContent의 경우 순수한 text/plain 형태이며, innerHtml은 text/html 형태로서 html의 형태로 렌더링된다. 
  - textContent와 innerHTML의 경우 기존의 값을 덮어쓴다. 만약 추가하고 싶을 경우 =이 아닌 += 를 사용한다.
  - 값을 추출하는 방법은 .textContent 매서드를 사용한다.
  
```js
<script type="text/javascript">
    window.onload = function () {
        alert("이전 값 : " + document.getElementById("idB").textContent);
        document.getElementById("idA").innerHTML = "<h3>hello</h3>"
        document.getElementById("idB").textContent = "<h3>hello</h3>"
        document.getElementById("idB").textContent += "<h3>HELLO</h3>"
        alert("이후 값 : " + document.getElementById("idB").textContent);
    }
</script>
<body>
    <div id="idA">반가워요.</div>
    <div id="idB">반가워요.</div>
</body>
```