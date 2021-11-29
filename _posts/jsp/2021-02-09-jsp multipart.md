---
layout: post
author: infoqoch
title: HTTP 파일 업로드 및 호출(multipart, cos.jar)
last_modified_at: 
categories: [jsp]
tags: [jsp, java, http]
---

## 들어가며
- JAVA에서는 기본적으로 제공되는 FILE과 PATH 클래스를 통해 파일에 접근하고 관리할 수 있는 기능을 제공한다. 하지만 HTTP 통신 과정에서는 라이브러리를 사용하며, cos.jar(http://www.servlets.com/cos/)를 통한 방법을 살펴보겠다.
- form 을 다루는 것과 file을 다루늘 때는 Content-type 을 달리한다. MIME 에 multipart/form-data 을 명시해야 한다.  
- form 의 input 을 서블릿은 request param 으로 받고 이를 객체의 필드값으로 손쉽게 바인딩한다. 하지만 multipart/form-data 로 데이터를 받을 경우, reqeust 가 아닌  MultipartRequest 등 파일 타입을 위한 데이타 타입으로 초기화 및 바인딩 된다. 이러한 객체로부터 필요한 데이타를 추출해야 한다. 
- MultipartRequest의 경우 file 의 갯수와 관계 없이 배열 형태로 받는다. 
- 파일을 서버에 저장할 때는 절대경로(config.getServletContext())를 path로 사용하며, 파일을 클라이언트에 출력할 때는 상대경로(request.getContextPath())를 path로 사용한다. 
  
### 1. form page

```html
<form method="post" action="Ex01_proc.jsp" enctype="multipart/form-data"> .........(1)

	input_text : <input type="text" name="input_text" value="작성자 : infoqoch"> <br>
	input_file : <input type="file" name="input_file" value="abc.jpg"> <br>
	
	<input type="submit" value="업로드">
	
</form>
```

- (1) 이미지를 다룰 때는 반드시 post 방식을 사용하며, 인코딩 타입을 multipart/form-data로 해야한다. 이를 통하여 http는 range를 사용하여 데이타를 분할 전송할 수 있다(대용량 파일을 송수신 할 수 있다).   

### 2. multipart/form-data 데이타의 처리 과정 (jsp)

```jsp
<%

int maxSize = 1024*1024*5; 

String configPath = config.getServletContext().getRealPath("img"); .................(2)
System.out.println("configPath : "+configPath); // C:\JSP\.metadata\.plugins\org.eclipse.wst.server.core\tmp0\wtpwebapps\uploadtest\img

String contextPath = request.getContextPath()+"/img"; .................(8)
System.out.println("contextPath: "+contextPath); // /14_Upload/img

System.out.println("(param)text 객체 : "+request.getParameter("input_text") ); // null
System.out.println("(param)file 객체 : "+request.getParameter("input_file") ); // null
............(1)

MultipartRequest multi = new MultipartRequest(
		request,
		configPath, ...........(2)
		maxSize,
		"utf-8",.............(3)
		new DefaultFileRenamePolicy()...............(4)
		);

System.out.println("(multi)text 객체 : "+multi.getParameter("input_text")); // 작성자 : infoqoch
System.out.println("(multi)file 객체 : "+multi.getParameter("input_file")); // null
............(5)

String fullPath1 = null;
String fullPath2 = null;

Enumeration<String> files = multi.getFileNames();

while(files.hasMoreElements()){...................(6)
	String file = files.nextElement();
	String fileName = multi.getFilesystemName(file);...........(7)
	System.out.println("(반복문)file : "+file); // input_file
	System.out.println("(반복문)file name : "+fileName); // abc.jpg
	.................(7)
    
	fullPath1 = configPath+"\\"+fileName;
	fullPath2 =  contextPath+"\\"+fileName;..................(8)
}

%>
<br>
<img src="<%=fullPath1 %>" width="300px"> // 오류 (절대경로)
<img src="<%=fullPath2 %>" width="300px"> // 사진이 출력됨

```

- (1) request.getParameter로 접근하여도 어떤 값도 가질 수 없다. 
- (5) MultipartRequest 객체를 생성한 후 그 객체를 통해서만 form의 값에 접근할 수 있다. 
- (7) MultipartRequest 객체를 각 각의 요소(element)를 통해 접근하고 나서야 파일 이름을 얻을 수 있다. 

- (2) MultipartRequest에서 파일을 저장하는 위치는 서버 내부의 절대경로로 해야 한다. config 객체를 사용한다.
- (3) 문자 인코딩 방식을 설정해야 한다. 
- (4) 파일 이름에 대한 규칙을 정의한다. 기본 값은 중복되는 이름에 대하여 숫자를 붙인다.
- (6) 업로드한 파일을 확인하는 과정이다. 반복문은 form의 요소들(elements)를 하나씩 꺼내는 방식이다. 방식은 ResultSet과 Iterator와 같다. 
- (7) 해당 파일을 클라이언트에 제공하기 위해서는 반드시 저장된 파일의 이름을 가져와야 한다. 왜냐하면 (4)DefaultFileRenamePolicy()으로 인해 이름이 변경될 수 있기 때문이다. 
- (8) 클라이언트에 제공할 때는 상대경로(context)를 통한다. 

- 파일을 삭제할 경우는 다음과 같은 방식으로 진행한다. 

```jsp
<%
File deleteFile1 = new File(fullPath1); //config를 통한 절대경로를 매개변수로 한다.
deleteFile1.delete();
%>
```