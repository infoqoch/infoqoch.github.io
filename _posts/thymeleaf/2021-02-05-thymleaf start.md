---
layout: post
author: infoqoch
title: Thymeleaf 시작하기, 간단한 문법
categories: [thymeleaf]
tags: [thymeleaf]
---

## 타임리프(Thymeleaf)란?
- 타임리프는 현재 스프링부트에서 밀고 있는 프레임워크이다. jps는 별도의 .jsp 포맷에 구현한다. 타임리프는 순수한 html에 타임리프 태그를 추가하여 html을 조작한다. 이러한 특징 덕분에 순수한 html파일이 동작한다. 퍼블리셔와의 협업이 가능하다. 
- 그 외 스프링과의 호응이 좋아졌고 성능이 좋아졌다. 

## 타임리프의 기본적인 형태와 반복문

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
- (2) HTML로서 그 형태를 완벽하게 유지한 상태에서 타임리프의 기능을 사용할 수 있다. jsp의 경우 동적으로 html을 렌더링 하기 위해 `<c:if>` 혹은 `<c:foreach>` 등의 jsp 의 태그를 사용해야 한다. 타임리프는 html의 문법을 지키며 반복문을 수행한다.
- (3) 태그 안에서 데이터를 호출하는 것과 태그 밖에서 호출하는 방식이 다르다. 태그 내부에서는 `${}`을 쓰며 밖에서는 `[[]]` 을 추가한`[[${}]]`을 사용한다.
- (4) JSP 는 사용 가능한 date api가 한정되고 조작하기 어렵다. 타임리프의 경우 자바 8에서 만들어진 LocalDateTime을 손쉽게 html로 렌더링할 수 있다. 

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
- (2) (1)과 달리 boolea의 결과에 의존하지 않고 태그를 유지한다. class의 값이 if문에 의하여 삽입 여부를 결정한다.