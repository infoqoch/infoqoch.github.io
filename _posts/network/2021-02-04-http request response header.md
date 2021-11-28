---
layout: post
author: infoqoch
title: HTTP의 request - response 메시지의 헤더와 친해지기
categories: [network]
tags: [network, http]
---

### 들어가며
- HTTP 프로토콜의 통신 과정은 request와 response의 교환 과정이다. 클라이언트는 서버에 request를 통해 요구사항을 보내고, 서버는 클라이언트에게 response를 통해 응답한다. 정확한 통신을 위하여 HTTP 에는 통신 규칙이 있다. 
  
### 1. HTTP 메시지의 기본 형태
  
|http 메시지|
|:--:| 
|시작줄|
|헤더|
|줄바꿈(CRLF)|
|본문(entity)|
    
- request의 기본적인 형태는 아래와 같다.

|request message|  
|:--:|
|GET /read/001.html HTTP/1.1 |
|HOST : www.infoqoch.com|
  
- 시작줄은 요청메소드 - 요청URL - http의 버전으로 이뤄져 있다.
- 요청URL은 단축 URL로서 그것의 기저 URL을 명시한다.  

- reponse의 기본적인 형태는 아래와 같다.

|response message|  
|:--:|
|HTTP/1.1 200 OK|
|Content-Type : text/html|
|Content-length : 600|
||
|http란 Hypertext Transfer Protocol의 준말로 TCP/IP의 통신 방식 중 하나로서..... (후략)|
  
  
- 시작줄은 http의 버전 / 상태코드 / 사유구절로 이뤄져 있다. 사유구절은 사람이 이해할 수 있은 형식으로 표현을 했을 뿐, 중요한 부분은 앞의 두 내용이다.
- 헤더에서는 본문(Entity)의 데이타 타입과 길이를 명시했다. 데이터 타입은 MIME에 따라 작성한다. 

### 2. 헤더 필드의 분류
- 헤더는 필드와 필드값으로 이뤄져 있다. 필드는 4가지로 분류된다. 
  - 일반헤더 : 일반적인 내용을 다룸
  - 요청헤더 : 클라이언트가 서버에 요청 메시지를 위한 내용
  - 응답헤더 : 서버가 클라이언트에 응답 메시지를 위한 내용
  - 엔티티헤더 : 본문에 관련한 내용

- 현재의 블로깅으로는 간단하게 정리하고자 하며, 구체적인 내용은 [링크](https://developer.mozilla.org/ko/docs/Web/HTTP/Headers){:target="_blank"} 혹은 다른 자료를 참고하자.

#### 2.1 일반헤더
- Date : 메시지가 생성 일자
- via :  메시지가 이동한 경로를 누적하여 기록 (1.0 프록시서버....1.1 게이트웨이....)
  
#### 2.2 요청헤더 
- Host
  - http 1.1 구약에 따라 request 헤더가 반드시 가져야 할 필드. 
  - 아이피에 여러 인터넷 호스트가 존재할 경우 host 필드 값을 명확하게 해야 함. 
- Accept 
  - 서버에 요청하는 데이타의 타입
  - HTTP는 MIME의 방식으로 인코딩/디코딩 및 데이타 통신을 함. 그러므로 필드값은 MINE 문법에 따라 작성
	- `Accept : */*` : 모든 데이타 행태를 받는다. 
 	- `Accept : text/html, application/json` : html과 json을 값으로 받는다.
    - `Accept : image/jpg, image/*;p=0.5` : p는 0과 1 사이의 정수이며 우선순위를 의미한다. 기본 값은 1이다. 예의 경우, jpg를 최우선으로 받되, 해당 포맷이 아닐 경우 그 이외의 숫자를 0.5의 우선순위로서 받는다는 의미이다.
- Authorization : (특히 401 Unauthorized에 대한 응답으로서) 서버가 요구에 따른 인증값을 서버에 제출한다. 이를 통해 request 의 인증, 인가를 검토한다. BASIC, DIGEST 등등 다양한 형태의 보안방식이 존재한다. 
- Expect : 서버에 특정 동작을 요구함. 원하는 HttpStatus(100, 200, 404 등)을 입력

##### 2.21 조건부 리퀘스트 (if)  
- 클라이언트가 소유한 엔티티가 서버의 엔티티와 같은지 여부를 판단할 때 사용. 
- 클라이언트의 사본과 서버의 원본 엔티티의 고유번호(태그)가 같은지(it-match), 사본과 원본의 수정일이 같은지(if-modified-since)를 확인. 
- 한편, range라는 기능을 통해, 용량이 큰 엔티티를 분할해서 받을 수 있는데, 아직 다운로드 받지 못한 부분의 엔티티의 태그의 값이 서버가 가진 값과 다르면, 무조건 새로운 엔티티를 서버가 클라이언트에 전달함. 
  
#### 2.3 응답헤더
- age : 클라이언트가 받은 엔티티의 사본이 얼마나 오래 되었는지를 보여줌. 서버는 사본의 max-age, expired(엔티티헤더) 등을 통해 엔티티의 유효기간을 정하며, 그 기간 동안 서버로부터 데이터를 가져오지 않고, 캐쉬로 응답한다. 이를 통해 서버의 자원을 아낀다. 
- ETag : 엔티티의 고유번호를 부여하여 캐싱처리한다. 엔티티 리소스가 갱신될 경우 ETag도 변경되며 이전의 ETag를 가진 경우 요청을 보내고 그렇지 않으면 캐싱처리 한다. 
- WWW-Authenticate / Proxy - Authenticate : 서버가 클라이언트에 보안을 요구. 
  
#### 2.4 엔티티 헤더 필드
- Allow : request가 요청한 리소스에서 가능한 통신 매서드를 답변. Get, Post 등.
- Content-Encoding : 데이타를 전달할 때 압축 형식을 지정
- Content-Length : 리소스의 용량
- Content-Location : 리소스의 위치(URI)
- Content-MD5 : 데이타의 유효성 검사를 위하여 MD5알고리즘에 의해 생성된 값을 전달(그러나 MD5 역시 변조가 가능하므로 완전하게 신뢰할 수 없음)
- Content-Type : 엔티티 바디가 포함하는 미디어 타입과 문자 인코딩 타입을 전달. 
  - `Content-Type : text/html; charset=utf-8`
    
#### 2.5 그 외
- set-cookie : 쿠키 생성
- 사용자의 정의 아래에 필드와 그 값을 설정할 수 있음. 
  
  
### 나아가며
- 헤더란 무엇이고 헤더의 종류에 대하여 간단하게 정리했다. 
- 학습을 하면서 모르고 사용했던 http 통신에 대하여 조금은 더 익숙해지고 알아간다는 느낌을 받는다. 
- 하지만 지식을 정리한 느낌이지 체화했다는 느낌을 받지는 않는다. 좀 더 다뤄야 할 것 같다. 