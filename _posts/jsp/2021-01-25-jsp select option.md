---
layout: post
author: infoqoch
title: jsp, 원하는 option을 selected 하기
categories: [jsp]
tags: [jsp, html]
---

### 들어가며
- html의 form 태그에서 다양한 input type이 존재한다. 대부분은 value 에 값을 부여하여 원하는 값을 주입할 수 있다. 하지만 option - selected의 사용법이 다소 다르다. 

### 원하는 option에 selected 하기
- 보통 form에서 jsp는 아래와 같이 원하는 값을 value에 미리 선언하여, 클라이언트가 그 값을 활용할 수 있도록 한다. 

```jsp
	<form action="insertProc.jsp" method="post">
		이름  : <input type="text" name="name" value="홍길동"><br><br>
		부서번호 :
		<select name="did" >
			<option value="1" selected="selected">1</option>
			<option value="2">2</option>
			<option value="3">3</option>
		</select><br><br>
		급여     : <input type="text" name="salary" value="300"><br><br>
		<input type="submit" value="가입하기">
	</form>
```

-  한편, option은 어떻게 할까? 

```jsp
	<form action="insertProc.jsp" method="post">
		이름  : <input type="text" name="name" value="<%=name%>"><br><br>
		부서번호 :
		<select name="did" value = "<%=name%>" > ----???????
			<option value="1">1</option>
			<option value="2">2</option>
			<option value="3">3</option>
		</select><br><br>
		급여     : <input type="text" name="salary" value="<%=salary%>"><br><br>
		<input type="submit" value="가입하기">
	</form>
```

- option은 value가 존재하지 않는다. 그러므로 작동하지 않는다. 

```jsp
<select name="did" >
 	<%
 		for(int i=1; i<4; i++){
 			if(did==i){
 				out.print("<option value='"+i+"' selected>"+i+"</option>");
 			}else{
 				out.print("<option value='"+i+"'>"+i+"</option>");
 			}
 		}
 	%>
 			 	
</select>

```

- 위와 같이 반복문을 통해 해결할 수 있었다. 