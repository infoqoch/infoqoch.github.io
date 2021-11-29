---
layout: post
author: infoqoch
title: JSP의 레이아웃 모듈 구성 방법과 directive / action tag의 차이
last_modified_at: 
categories: [jsp]
tags: [jsp]
---

## 들어가며
- 서버가 클라이언트에 view를 렌더링 할 때, 결과물은 한 페이지이다. 하지만 서버에서는 그 페이지가 정말 하나일 수 있고, 여러 페이지를 합친 결과일 수도 있다. 이를 레이아웃의 모듈화라 하며, jsp에서는 액션태그 방식과 디렉티브 방식으로 이를 지원한다. 
- 두 가지의 이론적 차이는 다양한 곳에서 설명되었지만, 구체적인 활용 사례는 확인되지 않아 직접 확인해봤다. CSS의 외장/내장 값, getParam의 값, 메인 레이아웃의 지역변수의 값이 각각 적용되는지 확인해보자.  
  

### (1) 메인 레이아웃 : get param : 10 

```jsp
url : "./mainPage.jsp?getparam=10"

<link rel="stylesheet" type="text/css" href="styleTest.css" />.........(2) 외장 css 파일

<style> .......... (3) 내장 css 코드
	div{
		width : 400px;
		border : 1px solid black;
	}
</style>
<%
	String localVar = "10";
%>
<jsp:include page="action.jsp"></jsp:include> .........(4) actiontag include

<br><br>

directive
<%@ include file="directive.jsp"%> ...........(5) directive include

```

### (2) 외장 css 파일

```jsp
div{
	background: gray;
}
```

### (4) 액션태그 모듈 / 디렉티브 모듈 (내용이 동일)
```jsp
<div>
	get request : <%=request.getParameter("getparam") %><br>
	메인 레이아웃의 변수를 호출(localVar) : <%=localVar %>
</div>
```

## 결과
- 실행 결과는 CSS의 경우 (2)외장과 (3)내장의 여부와 관계 없이 div에 모두 작동하는 것을 확인할 수 있었다. url을 통해 접근하는 getParameter의 값은 (4)액션태그와 (5)디렉티브 둘 다 값을 확인할 수 있다. 
- 하지만 메인 레이아웃에서 선언한 지역변수의 경우, (4)액션태그는 "JasperException"을 출력하며 작동하지 않았다. (5)디렉티브의 경우 사용할 수 있다. 
- 액션태그 방식과 디렉티브 방식의 가장 큰 차이는 컴파일 과정에 있다. 
  - 디렉티브 방식은 해당 페이지를 컴파일(.class)을 할 때 호출한 페이지와 부품인 페이지를 한 번에 컴파일한다. 
  - 액션태그 방식은 컴파일을 따로 하며 필요할 때 액션태그를 호출한다. 그래서 보통 변동이 없는 모듈의 경우 디렉티브를 사용하며, 변동이 많은 모듈의 경우 액션태그를 사용한다. 
  
