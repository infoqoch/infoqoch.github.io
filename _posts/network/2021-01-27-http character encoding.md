---
layout: post
author: infoqoch
title: http 통신의 문자인코딩 과정
categories: [network]
tags: [network, http, tomcat]
---

### 들어가며
- http 통신에 있어서 가장 먼저 부딪히는 것은 문자인코딩 문제이다. http의 통신 과정은 아래와 같다. 
- 클라이언트(브라우져) -> request(get / post) -> 웹서버(was, tomcat) -> response(get / post) -> 클라이언트
- 위의 모든 과정을 단 한 번의 인코딩으로 정리할 수 있었으면 좋았을테다. 그러나 모든 과정마다 인코딩 문제가 발생한다. browser마다, web container마다 다 다르다.

### http Get method
- http표준에서는 get 방식으로 전달하는 파라미터에 대한 인코딩의 규약이 존재하지 않는다. 
- 브라우저에 따라 인코딩 방식이 다르다. 인터넷익스플로러는 MS949를 사용하고, 크롬은 utf-8을 사용한다. 
- 그러므로 url을 통한 파라미터의 경우 encoding과 decoding에 신경써야 하며, 자바는 이러한 라이브러리를 제공한다.

```java
String value = URLEncoder.encode("안녕", "utf-8");
response.sendRedirect("/content/sayhello.jsp?name="+value);
```

### 웹 컨테이너, 클라이언트
- 웹 컨테이너에 따라서 인코딩 방식이 다 다르다. 
- 특히 톰캣의 경우 버전마다 다르다. 톰캣 7의 경우 ISO-8859-1을 기본 값으로 사용한다. 톰캣 8 이후부터는 UTF-8 기본 값으로 사용한다. 
- 클라이언트 역시 마찬가지다. 특히 클라이언트는 인코딩을 넘어서 plain text 파일에 대하여 인식하는 방식이 다르다. 익스플로러 계열은 plain text를 plain text로 이해하지만, 크롬의 경우 html 형태로 이해한다. 그러므로 단순히 인코딩을 결정하는 것이 아니라, 컨텐츠의 타입을 설정해야 한다. 
- 그러므로 아래와 같은 방식으로 웹페이지의 인코딩 방식을 선언한다. 

```jsp
<!-- jsp 파일 html 설정 -->
<%@ page contentType = "text/html; charset=UTF-8"%>

<!-- jsp 혹은 controller에서 설정 -->
<%
request.setCharacterEncoding("utf-8");
%>
```

```java
// Servlelt의 경우는...
public class TestServlet extends HttpServlet {
	@Override
	protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		request.setCharacterEncoding("utf-8");
		response.setCharacterEncoding("UTF-8");
		response.setContentType("text/html; charset=utf-8");
		PrintWriter out = response.getWriter();
		for(int i=0; i<100; i++) {
			out.println(i + ": 안녕!<br>");			
		}
	}	
}
```

- web.xml에서 편리하게 필터를 적용할 수 있다. 

```xml
  <filter>
   <filter-name>encodingFilter</filter-name>
   <filter-class>org.springframework.web.filter.CharacterEncodingFilter</filter-class>
   <init-param>
    <param-name>encoding</param-name>
    <param-value>utf-8</param-value>
   </init-param>   
  </filter>
  
  <filter-mapping>
   <filter-name>encodingFilter</filter-name>
   <url-pattern>/*</url-pattern>
  </filter-mapping>
```