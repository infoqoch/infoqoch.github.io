---
layout: post
author: infoqoch
title: jsp model 의 pojo를 js의 객체로 변환하기
categories: [jsp]
tags: [jsp]
---

## jsp 와 js 간 통신은 생각보다 자주 있다.

- jsp를 사용할 때 jsp 로 모든 데이타가 전달되면 가장 좋지만, 그렇지 않은 경우가 있다. 불가피하게 java object를 js object로 변환해야 할 때가 있다.
- 이 경우 다양한 방식이 있지만 개인적으로 아래와 같은 방식을 사용한다.
- 물론, 가장 베스트는 처음부터 json으로 전달하는 것이라 생각한다. 

## jsp의 반복문으로 js의 리스트를 채운다

```jsp
var productList  = {};
<c:forEach var="product" items="${productList}}" varStatus="status">
    productList['<c:out value="${product.name}"/>'] = '<c:out value="${product.count}"/>';
</c:forEach>
```
