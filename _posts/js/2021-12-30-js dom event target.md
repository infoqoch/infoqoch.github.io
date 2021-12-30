---
layout: post
author: infoqoch
title: js dom event와 target, dispatch
categories: [js]
tags: [js]
---

## 들어가며
- 이벤트는 버블링이 된다. 그러니까 노드의 최하단을 클릭했을 경우, 그것은 동시에 그것의 부모 노드를 동시에 클릭한 것과 같다. li -> ul -> div -> body -> html. 이를 이벤트 버블링이라 하며 이벤트의 전파라 한다. 
- 이러한 전파 덕분에 부모는 특정 자식에 대한 일괄적인 이벤트를 할 수 있다. click을 하고 그것을 처리하는 노드가 부모라 하더라도, 클릭이란 이벤트 자체는 최하단부터 전파되기 때문에, 최하단의 노드가 무엇인지 부모는 알 수 있다. 
- `someNode.onclick = function(e){}` 과 같은 이벤트가 있다고 가정하면, 해당 클릭 이벤트를 발생한 최하단의 노드를 e.target 를 통해 접근할 수 있다. 
- 이벤트 버블링의 장점은 중복되는 명령을 단 하나의 명령으로 끝낼 수 있다. 단점은 영향력이 크기 때문에 언제나 제한하는 방향으로 해야 한다.


## 예시
```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <style>
        table,
        tr,
        th,
        td {
            border: 1px solid black;
        }
        img{
            height:40px;
        }
    </style>
</head>

<body>
    <h2>HTML Table</h2>
    <h3></h3>
    <img id="title-img" style="height:200px">
    <hr>
    <table>
        <button class="btn-up">위로</button>
        <button class="btn-down">아래로</button>
        <button class="btn-del">선택삭제</button>
        <button class="btn-swap">바꾸기</button>
        <button class="btn-sort">정렬</button>
        <thead>
            <tr>
                <th><input type="checkbox"></th>
                <th>Company</th>
                <th>Contact</th>
                <th>Country</th>
                <th>img</th>
                <th>buttons</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><input type="checkbox"></td>
                <td>Alfreds Futterkiste</td>
                <td>Maria Anders</td>
                <td>Germany</td>
                <td><img src="https://cdn.pixabay.com/photo/2017/07/02/00/43/bundestag-2463236_960_720.jpg"></td>
                <td>
                    <button class="good inner-btn-sel">선택</button>
                    <button class="inner-btn-mod">수정</button>
                    <button class="inner-btn-del">삭제</button>
                </td>
            </tr>
            <tr>
                <td><input type="checkbox"></td>
                <td>Centro comercial Moctezuma</td>
                <td>Francisco Chang</td>
                <td>Mexico</td>
                <td><img src="https://cdn.pixabay.com/photo/2016/11/29/09/51/day-of-the-dead-1868836_960_720.jpg"></td>
                <td>
                    <button class="inner-btn-sel drunken">선택</button>
                    <button class="inner-btn-mod">수정</button>
                    <button class="inner-btn-del">삭제</button>
                </td>
            </tr>
            <tr>
                <td><input type="checkbox"></td>
                <td>Ernst Handel</td>
                <td>Roland Mendel</td>
                <td>Austria</td>
                <td><img src="https://cdn.pixabay.com/photo/2019/03/10/16/38/vorarlberg-4046557_960_720.jpg"></td>
                <td>
                    <button class="inner-btn-sel">선택</button>
                    <button class="inner-btn-mod">수정</button>
                    <button class="inner-btn-del">삭제</button>
                </td>
            </tr>
            <tr>
                <td><input type="checkbox"></td>
                <td>Island Trading</td>
                <td>Helen Bennett</td>
                <td>UK</td>
                <td><img src="https://cdn.pixabay.com/photo/2019/06/17/07/08/london-4279246_960_720.jpg"></td>
                <td>
                    <button class="hi hi inner-btn-sel good-job">선택</button>
                    <button class="inner-btn-mod">수정</button>
                    <button class="inner-btn-del">삭제</button>
                </td>
            </tr>
            <tr>
                <td><input type="checkbox"></td>
                <td>Laughing Bacchus Winecellars</td>
                <td>Yoshi Tannamuri</td>
                <td>Canada</td>
                <td><img src="https://cdn.pixabay.com/photo/2017/05/09/03/46/alberta-2297204_960_720.jpg"></td>
                <td>
                    <button class="inner-btn-sel">선택</button>
                    <button class="inner-btn-mod">수정</button>
                    <button class="inner-btn-del">삭제</button>
                </td>
            </tr>
            <tr>
                <td><input type="checkbox"></td>
                <td>Magazzini Alimentari Riuniti</td>
                <td>Giovanni Rovelli</td>
                <td>Italy</td>
                <td><img src="https://cdn.pixabay.com/photo/2014/03/03/16/12/village-279013_960_720.jpg"></td>
                <td>
                    <button class="inner-btn-sel">선택</button>
                    <button class="inner-btn-mod">수정</button>
                    <button class="inner-btn-del">삭제</button>
                </td>
            </tr>
        </tbody>
    </table>

    <script>
        var btnUp = document.querySelector('.btn-up');
        var btnDown = document.querySelector('.btn-down');
        var tbodyNode = document.querySelector('tbody');
        var trList = tbodyNode.querySelectorAll('tr');      

        var titleImg = document.querySelector('#title-img');

        // for(var i=0; i<trList.length; i++){
        //     trList[i].querySelector('img').onclick = function(e){
        //         titleImg.src = e.target.src;
        //     }
        // }

        document.querySelector('table').onclick = function(e){
            var target = e.target;
            if(target.classList.contains("inner-btn-sel")){
                target.parentElement.parentElement.style['background-color'] = 'blue';
            };
        };

        document.querySelector('body').onclick=function(e){
            if(e.target.nodeName!="TD")
                return;
            
            var h3 = document.querySelector('h3');
            h3.innerText = e.target.innerText;
            console.log('text changed')
        }

        tbodyNode.onclick=function(e){
            if(e.target.nodeName!="IMG")
                return;
            titleImg.src = e.target.src;
            console.log('image changed');
        };
        
        </script>
</body>
</html>
```

## dispatcher
- 특정 이벤트를 다른 이벤트에 연결할 수 있다. 

```html
<style>
    #input-file{
        display:none;
    }
    .file-button{
        background-color: aqua;
        border: 1px solid darkcyan;
    }
    .file-button:hover{
        background-color: aquamarine;
    }
</style>
<input type="file" id="input-file">
<span id="file-button" class="file-button">파일선택</span>

<script>
    var fileBtn = document.getElementById('file-button');
    var inputFile = document.getElementById('input-file'); 

    fileBtn.addEventListener("click", function(){ // 해당 노드에 클릭 이벤트를 등록한다.

        // 실제 이벤트를 정의한다. 아래는 최신 방식이지만 익스플로러는 지원하지 않는다. 
        // var event = new MouseEvent("click", { 
        //     'view':window,
        //     'bubble':true,
        //     'cancelable':true,
        // });

        // 익스플로러가 지원하는 형태이다.
        var event = document.createEvent('MouseEvent');
        event.initEvent('click', true,true)

        inputFile.dispatchEvent(event); // inputFile 이 실행(트리거)되는 이벤트를 추가한다. 
    });
</script>
```