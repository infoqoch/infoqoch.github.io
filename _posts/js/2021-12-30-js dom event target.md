---
layout: post
author: infoqoch
title: js dom event target
categories: [js]
tags: [js]
---

## 들어가며
- js에서는 이벤트를 발생시킨 element를 출력할 수 있다. 이는 다음처럼 표현한다. `something.function(e){}` 이 코드에서 e 가 event이며, e.target 으로 접근한다. e.nodeName; 으로 해당 element를 확인할 수 있다. 
- 이벤트의 타겟과 실제 이벤트의 대상이 다를 수 있다. `parent.function(e){e.target.nodeName}` 에서 nodeName의 값이 parent의 자식이 될 수 있다. 
- 이처럼 선택한 이벤트가 상위의 부모로 전파가 되고, 부모로 설정한 이벤트가 반대로 하위의 자식에게 영향을 미친다. 이를 이벤트 버블링이라 한다.
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