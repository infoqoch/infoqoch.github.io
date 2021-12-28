---
layout: post
author: infoqoch
title: js dom,node 를 통한 노드 생성과 복제, 조작
last_modified_at: 
categories: [js]
tags: [js]
---

## 들어가며
- dom, node를 통해 노드를 생성하고 복제하고 조작한다.
- element node를 생성하는 방법은 대략 다음과 같다.
  - innerHtml 을 통해 html 형태로 된 문자열을 삽입한다.
  - createElement, createTextNode 를 통해 노드를 생성한다.
  - cloneNode를 통해 이전의 노드를 복사하여 활용한다.
  - importNode를 통해 탬플릿을 복사하여 활용한다.
- 구체적인 구현은 아래의 코드와 같다.

## 실습

```html

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <style>
        input{
            width:50px
        }
    </style>
</head>
<body>
<section id="sec1">
    <template>
        <li><a href=""></a></li>
    </template>
    <h4>EX1 : createNode, removeNode </h4>
    <input type="text" class="input-text">
    <input type="button" class="btn-add" value="추가">
    <input type="button" class="btn-remove" value="제거">
    <ul class="ul-data">
        <li><a href="https://sample.co.kr">sample.co.kr</a></li>
    </ul>
    <hr>
</section>
<script>
    var sec1 = document.querySelector('#sec1');
    var ulTarget = sec1.querySelector('.ul-data');
    var btnAdd = sec1.querySelector('.btn-add');
    var btnRemove = sec1.querySelector('.btn-remove');
    var inputText = sec1.querySelector('.input-text');   
    

    // node 메서드를 활용한다. 
    var add1 = function() {
        var aNode = document.createElement('a');
        aNode.setAttribute('href', "https://" + inputText.value);
        
        // 텍스트 노드 다루기
        // node를 다루는 가장 기본적인 형태. 
        var textNode = document.createTextNode(inputText.value);        
        aNode.appendChild(textNode);
        
        // append를 활용한다. 이 경우 node 가 아니라도 text를 node로 박싱하여 삽입한다.
        // 다만 append 는 낮은 버전에서 사용 불가할 수 있다고 한다. 
        // aNode.append(inputText.value) // append 는 text를 생성할 수 있으며 노드로 받아드린다. 

        // innerText 로 바로 넣어 버린다.
        // aNode.innerText = inputText.value;      
        
        var liNode = document.createElement('li');
        liNode.appendChild(aNode);

        ulTarget.appendChild(liNode);
    };    

    // 문자열을 html 형태로 변환한다. 가장 빠르고 쉽다.
    // 다만, += 로 인한 메모리 낭비 문제가 발생할 수 있다. 객체를 복제하고 추가하고 이전의 것을 삭제 후 교체하는 방식이 된다. 
    var add2 = function() {
        ulTarget.innerHTML += '<li><a href="https://'+inputText.value+'">'+inputText.value+'</a></li>';
    };

    // innerHtml 과 appendChild 를 적절하게 섞는다. 아예 처음 만드는 부분은 노드를 innerHtml 를 통해 구성하고, 추가하는 부분에 대해서 appendChild를 사용할 수 있다. 
    var add3 = function() {
        var liNode = document.createElement('li');
        liNode.innerHTML = '<li><a href="https://'+inputText.value+'">'+inputText.value+'</a></li>'
        
        ulTarget.appendChild(liNode);
    };


    // 복제를 통한 방법
    // 다만 복제할 대상이 있어야 한다.
    // true 의 경우 깊은복제로서 전체 내용을 복제한다.
    var add4 = function() {
        var liTarget = ulTarget.children[0];
        liClone = liTarget.cloneNode(true);
        var aNode =  liClone.getElementsByTagName('a')[0];
        aNode.attr = "https://naver.com";
        aNode.innerText = 'naver.com'
        ulTarget.appendChild(liClone);
    };

    // 탬플릿을 통한 복제
    var isInit = true;
    var add5 = function() {
        
        if(isInit){
            ulTarget.innerHTML = '';
            isInit = false;
        }

        var template = sec1.querySelector('template');

        var liClone = document.importNode(template.content, true);

        // var aNode =  liClone.getElementsByTagName('a')[0]; 이것은 안된다. 이유는 모르겠다.
        var aNode =  liClone.querySelectorAll('a')[0];
        aNode.href = "https://naver.com";
        aNode.innerText = 'naver.com'

        ulTarget.appendChild(liClone);
    };

    var myData =  [
        {"domain" : "naver.com", "color" : "red"},
        {"domain" : "daum.com", "color" : "blachk"},
        {"domain" : "google.com", "color" : "green"},
    ]
    
    // 탬플릿에 json 데이타 삽입
    var isInit = true;
    var add6 = function() {
        if(isInit){
            ulTarget.innerHTML = '';
            isInit = false;
        }

        var template = sec1.querySelector('template');

        var liClone = document.importNode(template.content, true);

        var aNode =  liClone.querySelectorAll('a')[0];

        var data = myData.pop();
        if(data == undefined){
            alert('끝')
            return;
        }
        console.log(typeof data);
        console.log(data);
        console.log(aNode);

        aNode.href = "https://"+data.domain;
        aNode.innerText = data.domain;
        aNode.style.color = data.color;

        ulTarget.appendChild(liClone);
    };

    btnAdd.onclick = add6;

</script>
</body>
</html>
```