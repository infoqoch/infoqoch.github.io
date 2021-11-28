---
layout: post
title: VS CODE tips
author: infoqoch
categories: [tools]
tags: [tools, vscode]
---

### 단축키
- Ctrl + Shift + e : 탐색기
- Ctrl + Shift + f : 내용 검색
- Ctrl + Shift + h : 내용 검색 + 수정
- Ctrl + b : 메모장 전체화면(사이드메뉴 없애기)

- Ctrl + k, Ctrl + o : 폴더로 열기
- Ctrl + ` : 터미널 열기
- Ctrl + p : 파일 검색
- Ctrl + p, > : 설정 검색

- Ctrl + n : 새로운 문서 열기

- Ctrl + e : 동일한 문자열 다중커서

- Ctrl + space : 문자열 자동완성 제안

### 설정
- 나는 보통 툴의 기본 설정을 최대한 따른다. 불가피하게 새로 설치하는 경우 번거로운 세팅을 최소화할 수 있다. 
- 아래의 내용은 vscode를 사용하며 어쩔 수 없이 추가한 기능이다. 
- 텍스트의 포맷이나 플러그인으로 인하여 기존의 단축키가 다른 단축키로 엉키는 경우가 많다. 이에 대한 대안이다. 
- 자동완성의 경우 문법 실수를 줄이기 위한 기능으로 사용 중이다. 

#### 단축키 변경
- 사용하는 파일의 포맷이나 플러그인으로 인하여 키매핑이 생각보다 잘 바뀜. 
- 설정 검색하기 -> keyboard shortcut -> 설정버튼 클릭(🎡 모양으로 생겼음. 최우단) 

- 나의 설정은 아래와 같음
  
```text
Ctrl + b, Ctrl + b : 메모장 전체 화면을 추가 (마크다운 사용시 해당 키가 bold로 변경 됨)
Alt + n : 새 폴더
Ctrl + n : 
```

#### 사용자 문자열 자동완성 제안
- 설정 검색하기 -> user snippets -> 원하는 포맷 검색 
- 아래와 같이 추가하였음.
- 마크다운의 코드블럭은 다른 텍스트 사이에 줄바꿈(\n)이 없으면 깨지는 경우가 있음. 이를 자꾸 헷갈려서 코드블럭 위아래로 줄바꿈을 넣어줬음.
- 지킬에서 깃허브 블로그를 쓸때 기본적으로 작성해야하는 내용을 추가함.
- $1의 경우 커서 위치임. 여기에 원하는 포맷을 설정함.

```text
	"code block": {
		"prefix": "code block",
		"body": [
			"",
			"```$1",
			"```",
			""
		],
		"description": "java block on MD"
		},
	"post init": {
		"prefix": "code block",
		"body": [
			"---",
			"layout: post",
			"author: infoqoch",
			"title: $1",
			"last_modified_at: ",
			"categories: []",
			"tags: []",
			"---",
			""
		],
		"description": "java block on MD"
		}
```

#### 사용하는 플러그인
- 맞춤법 검사기 vscode-hanspell 
  -  설정 검색 -> 맞춤법
- 날짜 문자열 넣기 : Insert Date String 
  - Ctrl + Shift + i 

#### 들여쓰기
- 마크다운의 경우 들여쓰기의 단위를 띄어쓰기 두 개로 인식하는 것 같다. 그러나  tab 이나 띄어쓰기 4개를 기본으로 한다. 이를 수정한다.
- >Indent Using Spaces
- 마크다운에만 두 개를 들여쓰기로 할 수는 없을까?