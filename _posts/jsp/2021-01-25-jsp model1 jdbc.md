---
layout: post
author: infoqoch
title: JSP만 사용하여 DB와 통신하기(jdbc, model1)
categories: [jsp]
tags: [jsp, model1]
---

### 들어가며
- JSP에서 DB와 통신 과정은 순수한 자바코드로 DAO를 만들어 통해 통신하는 과정과 동일하다. 
- DB와의 통신을 위한 핵심적인 태그인 form의 활용 방법도 다루고자 한다. 

### html, form

```jsp
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
    
updateForm.jsp<br>
수정을 원하는 아이디와 비밀번호를 입력하십시오. <br>

<form method='post' action='updateProc.jsp'>
<input type="text" name = "searchId" >
<input type="text" name = "searchPw" >
<input type="submit" value = "제출">

</form>	
```

- 태그 < form>은 http 통신 과정에서 빼놓을 수 없는 주요 태그이다. form의 속성인 method는 데이터 통신 방식을 의미하여 GET/POST가 있다. action은 form의 값을 전달할 목적지를 의미한다. 
- JSP는 자바 언어를 사용할 수 있다. 스크립트릿을 활용하여 jdbc를 활용한다. 
- 아래의 코드는 그 예시이다. 시나리오는 아이디와 비밀번호를 검색하고, 실제 비밀번호와 비교하는 코드이다.
  
```jsp
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.Timestamp"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.DriverManager"%>
<%@page import="java.sql.Connection"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%
request.setCharacterEncoding("utf-8");

String driver = "oracle.jdbc.OracleDriver";
String url = "jdbc:oracle:thin:@localhost:1521:XE";
String user = "jspid";
String pw = "jsppw";

Class.forName(driver);  // 오라클과 연결할 드라이버의 객체를 만드는 과정이다. driver 자체는 스스로 객체를 형성하여 JVM에서 작동하지 않는다고 한다. DriverManager가 그 역할을 한다. Class.forName("package.ClassName") 매소드만을 입력하면, DriverManager가 해당 드라이버를 등록하고, getConnection()을 통해 DB와 연결한다. 

Connection conn = DriverManager.getConnection(url, user, pw); 

String searchSql = "select * from member where id = ?"; 

PreparedStatement ps = conn.prepareStatement(searchSql); 

ps.setString(1, request.getParameter("searchId")); 

ResultSet rs = ps.executeQuery(); // Get 방식의 쿼리문은 executeQuery() 매서드를 사용하며, 그 값은 ResultSet으로 반환받는다. 

if(rs.next()){  // ResultSet이 하나밖에 없으므로 if를 사용한다. 만약 하나 이상이면 while을 통해 여러 개를 받을 수 있다. 여기서는 searchId의 값으로 DB에서 탐색했는데, 해당 값이 있는지 없는지 여부를 통해 해당 id가 있는지를 확인할 수 있다. 
	String id = rs.getString("id"); 
	String passwd = rs.getString("passwd"); 	
	String name = rs.getString("name");
	
	if(passwd.equals(request.getParameter("searchPw"))){
%>
  
<form method='post' action='updateProc2.jsp'>

<input type="text" name = "id" value=<%=id %>>
<input type="text" name = "passwd" value=<%=passwd %>>
<input type="text" name = "name" value=<%=name %>>
<input type="submit" value = "제출">

</form>	

<%
	}else{
		out.print("비밀번호가 틀립니다.");
	}
	
}else{
	
	out.print("없는 아이디 입니다.");
	
}

%>
```

- 자바의 코드의 흐름에 따라 html을 매우 유연하게 조작할 수 있음을 확인할 수 있다. 
- 자바 코드와 html이 복잡하게 섞여 있어 이해하기가 어렵다. 특히 if문 사이에 스크립트릿을 넣는 것은 언제 봐도 복잡하다. 
- action을 보면 updateProc2.jsp로 전달됨을 확인할 수 있다. 아래의 코드는 updateProc2.jsp이다. 
- 
    
```jsp
<%@page import="java.sql.Timestamp"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.DriverManager"%>
<%@page import="java.sql.Connection"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
    
updateProc2.jsp<br>

<%
request.setCharacterEncoding("utf-8");

String driver = "oracle.jdbc.OracleDriver";
String url = "jdbc:oracle:thin:@localhost:1521:XE";
String user = "jspid";
String pw = "jsppw";

Class.forName(driver);

Connection conn = DriverManager.getConnection(url, user, pw);

String sql = "update member set passwd = ?, name = ? where id = ?";

PreparedStatement ps = conn.prepareStatement(sql); 

ps.setString(1, request.getParameter("passwd"));
ps.setString(2, request.getParameter("name"));
ps.setString(3, request.getParameter("id"));

int count = ps.executeUpdate(); // post로 받은 값은 executeUpdate() 매서드를 통해 DB에 insert 혹은 update 한다. 리턴값 int는 변경된 레코드의 갯수를 반환한다. 

if (count != 0) {
	out.print("테이터 삽입 성공!");
} else {
	out.print("삽입 실패");
}
%>
  ```
  
- 위의 과정은 수정한 값을 executeUpdate를 통해 DB와 통신하여 완료하는 모습이다. 
- 자바 코드로 dao를 생성하는 것과 동일하다. 다만, dao와 다른 점은 사용한 객체를 종료(.close())하는 과정이 생략됐다.
- 절차지향적으로 html을 작성할 수 있어서 위에서 아래로 편하게 책을 읽듯 읽을 수 있었다. 

### 글을 마치며..
- 위의 방식을 디자인패턴으로 바라보면, MVC 디자인패턴의 model1 방식이다. JSP가 모든 작업을 처리한다. 
- JSP가 모든 작업을 처리하기 때문에 작성하기 쉽고 흐름도 이해하기 쉽다. 그러나 단점은 복잡하고 유지보수가 어렵고 불필요하게 중복된 값이 많다(DB와 커넥션 과정을 JSP 파일마다 반복해야한다). 이러한 불편함을 해소하기 위하여, 코드를 작성하는 일종의 규칙과 방식이 정립되는데, 이를 디자인패턴이라 한다. model1을 해소하기 위한 방식으로 model2가 있으며 보통 이러한 디자인 패턴을 사용한다. 
- JSP로만 구성한 간단한 프로젝트가 있다. 혹시 궁금하다면 아래의 링크를 참고 바란다. 
- https://github.com/infoqoch/JspShopProject
  