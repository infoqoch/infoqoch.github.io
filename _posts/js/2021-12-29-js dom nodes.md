---
layout: post
author: infoqoch
title: js dom, node 비교 및 정렬하기
categories: [js]
tags: [js]
---

## 들어가며
- node 간 비교, 교체 및 정렬 가능하다. 
- 아래의 내용을 참고하자.

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
    </style>
</head>

<body>
    <h2>HTML Table</h2>
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
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><input type="checkbox"></td>
                <td>Alfreds Futterkiste</td>
                <td>Maria Anders</td>
                <td>Germany</td>
            </tr>
            <tr>
                <td><input type="checkbox"></td>
                <td>Centro comercial Moctezuma</td>
                <td>Francisco Chang</td>
                <td>Mexico</td>
            </tr>
            <tr>
                <td><input type="checkbox"></td>
                <td>Ernst Handel</td>
                <td>Roland Mendel</td>
                <td>Austria</td>
            </tr>
            <tr>
                <td><input type="checkbox"></td>
                <td>Island Trading</td>
                <td>Helen Bennett</td>
                <td>UK</td>
            </tr>
            <tr>
                <td><input type="checkbox"></td>
                <td>Laughing Bacchus Winecellars</td>
                <td>Yoshi Tannamuri</td>
                <td>Canada</td>
            </tr>
            <tr>
                <td><input type="checkbox"></td>
                <td>Magazzini Alimentari Riuniti</td>
                <td>Giovanni Rovelli</td>
                <td>Italy</td>
            </tr>
        </tbody>
    </table>

    <script>
        var btnUp = document.querySelector('.btn-up');
        var btnDown = document.querySelector('.btn-down');
        var tbodyNode = document.querySelector('tbody');
        var trList = tbodyNode.querySelectorAll('tr');         
        // console.log(trList[0]); //tbody에서 tr리스트를 추출할 수 있고
        // console.log(tbodyNode.firstElementChild); // tbody에서 첫번째 자식을 선택할 수 있다. 
        var firstTr = tbodyNode.firstElementChild;
        
        // firstTr.remove();
        // console.log(firstTr); // 삭제하더라도 첫 번째 자식은 계속 유지가 된다. 그러니까 dom이 형성된 순간의 순서가 계속 유지되는 것으로 보인다. 
        
        btnDown.onclick = function(){         
            var nextNode = firstTr.nextElementSibling;
            if(nextNode==null){
                alert('멈춤');
                return;
            }

            // tbodyNode.removeChild(nextNode);
            // tbodyNode.insertBefore(nextNode, firstTr);
            firstTr.insertAdjacentElement("beforebegin", nextNode);
        };        
        btnUp.onclick = function(){         
            var prevNode = firstTr.previousElementSibling;
            if(prevNode==null){
                alert('멈춤');
                return;
            }

            // tbodyNode.removeChild(firstTr);
            // tbodyNode.insertBefore(firstTr, prevNode);
            firstTr.insertAdjacentElement("afterend", prevNode);
            // https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentElement
        };
        var theadNode = document.querySelector('thead');
        var theadCheckbox = theadNode.querySelector('input[type="checkbox"]');
        theadCheckbox.onchange = function(){
            var boxes = tbodyNode.querySelectorAll("input[type='checkbox']");
            for(var i=0; i<boxes.length; i++){
                boxes[i].checked = theadCheckbox.checked;
            }            
        }

        var btnDel = document.querySelector('.btn-del');
        btnDel.onclick = function(){ 
            var selectedBoxes = tbodyNode.querySelectorAll("input[type='checkbox']:checked");
            for(var i=0; i<selectedBoxes.length; i++){
                selectedBoxes[i].parentElement.parentElement.remove();
            }
        }
        
        var btnSwap = document.querySelector('.btn-swap');
        btnSwap.onclick = function(){
            var selectedBoxes = tbodyNode.querySelectorAll("input[type='checkbox']:checked");

            if(selectedBoxes.length!=2){
                alert('두 개만 선택 바랍니다!');
                return;
            }
            
            // 내가 한 방식
            var firstNode =  selectedBoxes[0].parentElement.parentElement
            var secondeNode =  selectedBoxes[1].parentElement.parentElement;
            var firstNodeClone = firstNode.cloneNode(true);
            
            // secondeNode.insertAdjacentElement("afterend", firstNodeClone);
            // firstNode.insertAdjacentElement("beforebegin", secondeNode);
            // firstNode.remove();

            secondeNode.replaceWith(firstNodeClone);
            firstNode.replaceWith(secondeNode);
        }

        var sorted = false;
        btnSort = document.querySelector('.btn-sort');
        btnSort.onclick = function(){
            // var list = tbodyNode.children;
            // var list = tbodyNode.querySelectorAll('tr');
            var list = Array.from(tbodyNode.children); // node리스트는 array가 아니다.
            if(!sorted){
                list.sort(function(a,b){
                    var at = a.querySelectorAll('td')[2].innerText;
                    var bt = b.querySelectorAll('td')[2].innerText;
                    if(at>bt){
                        return 1;
                    }else if(at<bt){
                        return -1;
                    }else{
                        return 0;
                    }   
                });
                sorted = true;
            }
            list.reverse();
            tbodyNode.innerHTML = '';
            for(var i=0; i<list.length; i++){
                tbodyNode.appendChild(list[i]);
            }
        };

        </script>
</body>
</html>
```
