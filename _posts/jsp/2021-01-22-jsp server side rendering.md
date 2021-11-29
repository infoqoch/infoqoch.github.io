---
layout: post
title: Servlet JSP 와 서버사이드 렌더링
author: infoqoch
categories: [jsp]
tags: [jsp, servlet]
---

### servlet이란?
- 서블릿(servlet)은 자바 웹 개발을 위해 만들어진 기능이다. 
- 서블릿은 HTTP 통신의 핵심 흐름인 request와 response을 다룬다. 서블릿은 HTTP 통신을 위한 생명 주기를 가진다.
  - init
  - service
  - doGet, doPost
  - destroy
- 세션, 쿠키, 필터 등 기타 다양한 기능을 제공한다.

### servlet의 렌더링(view)
- 서블릿의 가장 중요한 특징은 아무래도 html 을 java 언어로 출력한다는 점이다. 그리고 그 내용을 자바를 통해 통제할 수 있다는 점이다. 

```java
public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
    PrintWriter out = response.getWriter();

    out.println("<!DOCTYPE html>");
    out.println("<html>");
    out.println("<head>");
    out.println("<title>title</title>");            
    out.println("</head>");
    out.println("<body>");
    out.println("<h1>");
    out.println("Hello, World!");
    out.println("</h1>");
    out.println("</body>");
    out.println("</html>");
}
```
- 다음처럼 자바의 기능을 활용하여 값을 동적으로 넣을 수 있다. 

```java
SamplePerson person = new SamplePerson("홍길동", 45, "서울시");
out.println("<body>");
out.println("<h1>"+person.getName()+"의 프로필</h1>);
out.println("나이 : "+person.getAge()+"<br>");
out.println("사는 곳 : "+person.getAddress()+"<br>");
out.println("</body>");
```

### JSP의 렌더링
- JSP는 서블릿에서 한 단계 더 나아간다.
- HTML 형태를 유지한 채, 필요한 위치에만 동적인 값을 입력한다. 

```jsp
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>    
<body>
    (예시 1)
    <% 
    String name = "홍길동";
    int age=30;
    double  height = 180;
    %>
    
    <h4>저의 이름은<%= name %> 입니다. </h4>
    저의 나이는 <%=age %> 살 입니다.<br>
    저의 키는 <%=height %> 입니다.
    
    (예시 2)
    <%
    SimpleBean sb = new SimpleBean();
    sb.setMsg("반갑습니다.");
    String returnMsg = sb.getMsg();
    out.print("returnMsg : "+returnMsg);  
    %>    

    (예시 3)
    <h4>저의 이름은 ${param.name}입니다. </h4>
    저의 나이는 ${param.age} 살 입니다.<br>
    저의 키는 ${param.height} 입니다.

</body>
</html>
```

- 예시 1의 경우 스크립트릿(<% %>) 내부에서 자바와 동일한 문법을 사용 가능하다. 그리고 그 문법은 HTML 문서 내의 <%= %>로 동적으로 입력된다. 
- 예시 2의 경우 객체를 만드는 것을 볼 수 있다. 앞서 봤던 response 객체의 out.print()의 메서드를 사용하는 것을 볼 수 있다. 
- 예시 3의 경우 el태그를 활용하여 get param 값을 가져올 수 있다. 
- 그 외 다양한 방식으로 JSP를 활용 가능하다. 

### JSP는 servlet으로 변환된다.
- jsp에서 자바 언어를 사용할 수 있는 이유는 무엇일까? 
- jsp 파일은 자동으로 servlet으로 변환된다. servlet은 자바(.java)파일로서 컴파일시 클래스(.class)로 변환된다. 
- 위의 예시는 서블릿 -> JSP 순서로 변환되지만, 사실은 JSP 입장에서는 JSP->Servlet 으로 변환된다. 그러니까 `"저의 나이는 ${param.age} 살 입니다.<br> "`는 서블릿에서 `out.print("저의 나이는"+request.getParameter("age")+"살 입니다.<br>"); `로 변환해주는 아주 편리한 기능이라 볼 수 있다.
- jsp와 servlet으로 view를 출력하는 것을 서버사이드렌더링이라 부른다. 서버에서 jsp와 서블릿을 가지고 html을 조작 및 출력하기 때문이다. 