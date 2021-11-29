---
layout: post
author: infoqoch
title: Thymeleaf 시작하기, 반복문, if문, redirect, input form
categories: [thymeleaf]
tags: [thymeleaf, spring]
---

## 들어가며
- 타임리프(Thymeleaf)는 현재 스프링부트에서 밀고 있는 프레임워크이다. JSP는 자바소스(.java)에서 바이트코드(.class)로 변환하는 과정을 거친다. 그러나 타임리프는 그런 과정 없이 순수한 html에 타임리프 태그를 추가하여 html을 조작한다. 
- 순수한 html로 작동하기 때문에 동적 렌더링 없이도 해당 페이지를 html 로 띄울 수 있다. 이를 통한 퍼블리셔와의 협업이 가능하다. 

## 타임리프의 기본적인 형태
- 타임리프로 구현한 html 파일은 아래와 같다. 

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org"> ........... (1)
<head>
    <meta charset="UTF-8">
    <title>$Title$</title>
    <style>
        table{
            border: 1px black solid;
        }
        td{
            border: 1px black solid;
        }
    </style>
</head>
<body>
    <table>
        <tr>
            <td>id</td>
            <td>pw</td>
            <td>name</td>
            <td>regDate</td>
        </tr>
        <tr th:each="dto : ${result.dtoList}"> ........(2)
            <td>[[${dto.id}]]</td>.........(3)
            <td>[[${dto.pw}]]</td>
            <td>[[${dto.name}]]</td>
            <td>[[${#temporals.format(dto.regDate,'yyyy/MM/dd')}]]</td> ........(4)
        </tr>

    </table>
</body>
</html>
```

- (1) 타임리프를 로딩한다. th는 타임리프 기능을 호출할 때 사용한다. 
- (2) HTML로서 그 형태를 완벽하게 유지한 상태에서 타임리프의 기능을 사용할 수 있다. jsp의 경우 `<c:if>` 혹은 `<c:foreach>` 등의 jsp 의 태그를 사용해야 한다. 그러나 타임리프는 html 태그와 함께 사용하며 html 문법을 지킨다. 
- (3) 태그 안에서 데이터를 호출하는 것과 태그 밖에서 호출하는 방식이 다르다. 태그에서는 ${}을 쓰며 밖에서는 [[]] 을 추가한[[${}]]을 사용한다.
- (4) JSP 는 사용 가능한 date api가 한정되고 조작하기 어렵다. 타임리프의 경우 자바 8에서 만들어진 LocalDateTime(regDate) 을 손쉽게 바인딩 가능하다. 

## 타임리프의 리다이렉트
- 타임리프에서 redirect를 하는 방법은 아래와 같다.
  
```html
<a th:href="@{/member/modify(id=${dto.id})}"><input type="button" value="modify"></a>
```

|코드|설명|
|:---|:---|
|th:href|redirect를 위한 태그|
|@{/.....}|@을 식별자로 하여 url을 작성|
|(id=${dto.id})|GET으로의 param을 적용할 때, ?을 사용하지 않고, 소괄호를 사용|

## if문
- 타임리프에서 if문을 사용하는 방법은 아래와 같다. 아래는 페이징 기능을 구현하며 만들었다. 
  

```html
<ul>
    <li th:if="${result.prev}">.......(1)
        <a th:href="@{/member/list(page=${result.start-1})}">prev</a>
    </li>
    <li th:each="page: ${result.pageList}">
        <a th:href="@{/member/list(page=${page})}" th:class="${result.page==page?'bold':''}">[[${page}]]</a>......(2)
    </li>
    <li th:if="${result.next}">
        <a th:href="@{/member/list(page=${result.end+1})}">next</a>
    </li>
</ul>
```

- (1) boolean 의 값에 따라 태그가 생성되거나 사라진다. 
- (2) (1)과 달리 태그 자체는 남는다. 태그의 속성 중 하나인 class의 값을 if문을 통해 부여한다. 향상된 if문을 사용한다. 

## input types
- 타임리프에서 input을 다루는 방법은 아래와 같다. 검색기능을 구현하며 작성한 코드이며 제이쿼리를 사용했다. 
  
```html
<form action="/member/list" method="get" id="searchForm">
    <input type="hidden" name="page" value="1">
    <input type="text" name="keyword" placeholder="검색어입력" th:value="${pageRequestDTO.keyword}"> ............ (1)
    <select name="type">
        <option value="" th:selected="${pageRequestDTO.type==null}">-----</option> ........... (2)
        <option value="p"  th:selected="${pageRequestDTO.type=='p'}">pw</option> 
        <option value="n" th:selected="${pageRequestDTO.type=='n'}">name</option>
        <option value="pn" th:selected="${pageRequestDTO.type=='pn'}">pw+name</option>
    </select>
    <input type="button" class="btn-search" value="search">
    <input type="button" class="btn-clear" value="clear">
</form>
<script th:inline="javascript"> ...........(3)
    var searchForm = $("#searchForm");

    $('.btn-search').on('click', function (){
        searchForm.submit();
    });

    $('.btn-clear').on('click', function (){
        searchForm.empty().submit();
    });

</script>
```

- (1) th:value를 통해 그 값을 전달 받는다. 
- (2) th:selected는 true / false를 통해 selected 속성을 추가할지 하지 않을지를 결정한다. `th:selected`를 통해 서두에 목적이 있어서,  `<c:if test="....">slected</c:if>` 라는 형태로 주입하는 jsp 보다 간결해보인다. 
- (3) script를 선언할 수 있으며 이 경우 th:inline 태그를 사용한다.


