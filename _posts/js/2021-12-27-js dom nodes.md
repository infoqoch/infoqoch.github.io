---
layout: post
author: infoqoch
title: js dom 과 node
categories: [js]
tags: [js]
---

## 들어가며
- js로 파싱되는 html의 객체들은 일종의 속성과 계층적 관계가 생긴다. 이러한 속성과 관계 전체를 js는 노드라고 한다. 
- document는 head와 body를 자식으로 하며, body는 div와 form 을 자식으로 하고, form 내부에는 input 과 h3 이 형제의 관계를 가진다. 이러한 element 의 계층적 관계와 각 각의 태그는 모두 노드이다. img는 src, width 를 속성으로 가지며 input은 value, title, type 등을 속성으로 가진다. 이러한 속성 attribute 역시 노드이다. 그 외 주석, 텍스트 등 html 을 이루는 모든 것이 노드이며, js 를 통해 출력하고 조작할 수 있는 대상이 된다. 
- 결국 dom을 조작한다는 것은 document의 node 를 이해하고 그것을 통제한다는 의미이다.

### 들어가기 전에, kebab-case 와 camelCase?
- html은 kebab-case 를 사용하고 js는 camelCase를 사용한다. 
- node 는 그것의 이름을 기본적으로 js 의 네이밍 문법으로 번역된다. `something.camelCase`
- html 스타일로 접근 가능하다. `something.['kebab-case']` 
- 어떤식으로 접근하든 상관 없지만, html 블럭에서는 kebab-case으로 명명해야 하며, js 블럭에서는 camelCase로 접근해야 한다. 그래서 아래와 다음과 같은 형태의 코드를 작성해야 한다.
  - `<input type="button" class="btn-add">`
  - `var btnAdd = myForm.getElementsByClassName('btn-add')[0];`


## element node에 접근하기
### getElementBy, querySelect
- getElementBy___ 를 통하여 html의 element를 식별하는 속성이나 태그 이름 등으로 노드에 접근 가능하다.
  - id는 하나이므로 하나만 반환한다. class, name은 복수가 가능하므로 리스트를 반환하며 index로 값에 접근한다. 
- css 문법을 이용하는 querySelect를 요새는 주로 사용한다. querySelectAll로 접근할 경우 index로 추출한다. 

```js
// !html 생략

<section>
    <h4>EX1 :  getElementBy</h4>
    <input type="text" id="txt-x">
    +
    <input type="text" id="txt-y">
    <input type="button" id="btn-add" value="=">
    <input type="text" id="txt-sum">
    <hr>
</section>
<script>
    var txtX = document.getElementById('txt-x');
    var txtY = document.getElementById('txt-y');
    var btnAdd = document.getElementById('btn-add');
    var txtSum = document.getElementById('txt-sum');
    
    btnAdd.onclick = function() {
        txtSum.value = adder(txtX.value, txtY.value);
    };            

    var adder = function(x, y){
        return parseInt(x) + parseInt(y);
    }
</script>

<section id="sec2">
    <h4>EX2 : element 선택 개선</h4>
    <input type="text">
    +
    <input type="text">
    <input type="button" class="btn-add" value="=">
    <input type="text">
    <hr>
</section>
<script>
    var sec2 = document.getElementById('sec2');
    var inputs = sec2.getElementsByTagName('input');
    var txtX = inputs[0];
    var txtY = inputs[1];
    var btnAdd = inputs[2];
    var txtSum = inputs[3];
    
    btnAdd.onclick = function() {
        txtSum.value = adder(txtX, txtY);
    };            

    var adder = function(x, y){
        console.log(x, y)
        return parseInt(x.value) + parseInt(y.value);
    }
</script>

<section id="sec21">
    <h4>EX2-1 : element 선택 개선2</h4>
    <input type="text" class="txt-x">
    +
    <input type="text" class="txt-y">
    <input type="button" class="btn-add" value="=">
    <input type="text" class="txt-sum">
    <hr>
</section>
<script>
    var sec21 = document.getElementById('sec21');

    var txtX = sec21.getElementsByClassName('txt-x')[0];
    var txtY = sec21.getElementsByClassName('txt-y')[0];
    var btnAdd = sec21.getElementsByClassName('btn-add')[0];
    var txtSum = sec21.getElementsByClassName('txt-sum')[0];
    
    btnAdd.onclick = function() {
        txtSum.value = adder(txtX, txtY);
    };            

    var adder = function(x, y){
        console.log(x, y)
        return parseInt(x.value) + parseInt(y.value);
    }
</script>

<section id="sec3">
    <h4>EX3 : selectors api level 1 </h4>
    <input type="text" class="txt-x">
    +
    <input type="text" class="txt-y">
    <input type="button" class="btn-add" value="=">
    <input type="text" name="txt-sum">
    <hr>
</section>
<script>
    var sec3 = document.querySelector('#sec3');

    var txtX = sec3.querySelector('.txt-x');
    var txtY = sec3.querySelectorAll('.txt-y')[0];
    var btnAdd = sec3.querySelector('.btn-add');
    var txtSum = sec3.querySelector('input[name="txt-sum"]');
    
    btnAdd.onclick = function() {
        txtSum.value = adder(txtX, txtY);
    };            

    var adder = function(x, y){
        console.log(x, y)
        return parseInt(x.value) + parseInt(y.value);
    }
</script>
```

### childNodes, children
- 노드에 대하여 직접적으로 접근 가능하다. 
  - childNodes를 통해 부모노드가 가진 모든 자식 노드에 접근한다. 
  - children를 통해 부모노드가 가진 모든 element 자식 노드에 접근한다.

```js
<section id="sec4">
    <h4>EX4 : childNode </h4>
    <input type="text" class="txt-x">
    +
    <input type="text" class="txt-y">
    <input type="button" class="btn-add" value="=">
    <input type="text" name="txt-sum">
    <hr>
</section>
<script>
    var sec4 = document.querySelector('#sec4');

    console.log("child nodes", sec4.childNodes); // element를 포함하여 문자열, 주석 등 모든 노드에 접근한다.

    var txtX = sec4.childNodes[3];
    var txtY = sec4.childNodes[5];
    var btnAdd = sec4.childNodes[7];
    var txtSum = sec4.childNodes[9];
    
    btnAdd.onclick = function() {
        txtSum.value = adder(txtX, txtY);
    };            

    var adder = function(x, y){
        console.log(x, y)
        return parseInt(x.value) + parseInt(y.value);
    }
</script>

<section id="sec5">
    <h4>EX5 : children </h4>
    <input type="text" class="txt-x">
    +
    <input type="text" class="txt-y">
    <input type="button" class="btn-add" value="=">
    <input type="text" name="txt-sum">
    <hr>
</section>
<script>
    var sec5 = document.querySelector('#sec5');

    console.log("children", sec5.children); // children은 element만을 값으로 한다.

    var title = sec5.children[0];
    var txtX = sec5.children[1];
    var txtY = sec5.children[2];
    var btnAdd = sec5.children[3];
    var txtSum = sec5.children[4];
    
    btnAdd.onclick = function() {
        txtSum.value = adder(txtX, txtY);
    };            

    var adder = function(x, y){
        console.log(x, y)
        return parseInt(x.value) + parseInt(y.value);
    }
</script>
```

## attr node 의 출력과 조작
- element 에 접근하고 그것의 속성까지 조작할 수 있다. 
- datalist는 ES5에 나온 문법으로 select 과 유사하다.
- style의 모든 값은 string이다. 그러므로 `mySpan.style.fontSize="10px"` 이런 식으로 해야한다.
  
```js
<section id="sec6">
    <h4>EX6 : element node 에 대한 속성 및 CSS 스타일 변경 </h4>
    <input class="border-input" list="border-list">
    <datalist id="border-list">
        <option value="10px solid red">border1</option>
        <option value="3px dotted blue">border</option>
        <option value="30px dashed green">border</option>
    </datalist>

    <select id="img-select">
        <option value="/4169e1/ffffff?text=royalblue">img1</option>
        <option value="/008080/EEEEEE?text=teal">img2</option>
        <option value="/320x100/800080/EEEEEE?text=purple">img3</option>
    </select>   
    
    <input type="button" value="선택" class="btn-img">
    <hr>
    <img class="img">
    <hr>
</section>
<script>
    var sec6 = document.querySelector('#sec6');

    var img = sec6.querySelector(".img");
    var btnAdd = sec6.querySelector(".btn-img");
    var imgSelect = sec6.querySelector("#img-select");
    var borderInput = sec6.querySelector(".border-input");

    var acc = accrue();
    btnAdd.onclick = function() {
        img.src = "http://placehold.it/320x100" + imgSelect.value;
        img.style.border = borderInput.value;
        img.style.marginLeft = acc() + "px";
        img.style['margin-top'] = acc() + "px";
    };            

    function accrue(){
        var num = 10;
        return function (){
            num = num * 1.25 
            return num;
        }
    }
</script>
```

### 나아가며
- function 이 리턴값이 될 수 있다는 사실만큼 받아드리기 어렵지만 가장 익숙하지만 파트가 바로 이번의 node 파트였다.
- 단순하게 접근하면 좋을 것 같다. element에 접근하는 방법은 children, getElement, querySelect으로 접근하며, 접근한 객체에 대한 속성은 something.value, something.style.color 스트림처럼 접근한다. 