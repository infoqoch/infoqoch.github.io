---
layout: post
title: VS CODE tips
author: infoqoch
categories: [tools]
tags: [tools, vscode]
---

## 단축키
- Ctrl + Shift + e : 탐색기(사이드메뉴)
- Ctrl + Shift + f : 내용 검색
- Ctrl + Shift + h : 내용 검색 + 수정
- Ctrl + b : 메모장 전체화면(사이드메뉴 없애기)

- Ctrl + k, Ctrl + o : 폴더로 열기
- Ctrl + ` : 터미널 열기
- Ctrl + p : 파일 검색
- Ctrl + p, > : 설정 검색

- Ctrl + n : 새로운 문서 열기

- 문자열 드래그, Ctrl + f2 : 동일한 문자열 다중커서

- Ctrl + space : 문자열 자동완성 제안

## 설정
- 보통 툴의 기본 설정을 최대한 따른다. 불가피하게 새로 설치하는 경우 번거로운 세팅을 최소화할 수 있다. 
- 아래의 내용은 vscode를 사용하며 불가피하게 수행한 설정이다(특히 지금 사용하는 지킬-마크다운을 위하여!)
- 한편, vs code를 본격적으로 사용하려면 설정의 변경은 불가피하다고 생각한다. 왜냐하면 파일 포맷이나 플러그인으로 인하여 기존의 단축키가 다른 단축키로 인해 엉키는 경우가 많다.

### 단축키 변경
- 설정 검색 키워드 : keyboard shortcut -> 🎡버튼 클릭

- 나의 설정은 아래와 같음. 
    
```text
Ctrl + b, Ctrl + b : 메모장 전체 화면을 추가 (마크다운 사용시 해당 키가 bold로 변경 됨)
Alt + n : 새 폴더
```

### 사용자 문자열 자동완성 제안
- 설정 검색 키워드 : user snippets -> 원하는 포맷 검색 (markdown 등)

- 나의 설정은 아래와 같음
 
```text
	"code block": {
		"prefix": "코드블럭",
		"body": [
			"",
			"```$1",
			"```",
			""
		],
		"description": "java block on MD"
	},
	"post init": {
		"prefix": "게시글 작성",
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
		"description": "post init on MD"
	},
	"link_newtab": {
		"prefix": "링크 새창",
		"body": [
			"[$1](){:target='_blank'}"
		],
		"description": "post init on MD"
	},
	"img_mapping": {
		"prefix": "이미지 연결",
		"body": [
			"![image](/assets/image/$1){:.aligncenter}"
		],
		"description": "post init on MD"
	},
```
- 마크다운의 코드블럭과 다른 것 사이에는 줄바꿈(\n)이 두번 필요하다(빈 문단이 하나 필요하다). 이를 자꾸 헷갈려서 코드블럭 위아래로 줄바꿈을 넣어줬음.
- 지킬에서 블로그 포스트를 작성할 때 기본적으로 써야하는 내용을 추가하였음.
- $1의 경우 커서 위치임. 여기에 원하는 포맷을 설정함.

### 플러그인
- **Excel to Markdown table**
  - 엑셀의 테이블을 마크다운 테이블로 변경. 강추!
  - Shift+Alt+V
- **Paste Image**
  - 스크린샷을 원하는 폴더에 저장하고 markdown으로 이미지 연결. 강추!
  -  Ctrl+Alt+V
- Insert Date String 
  - 날짜 문자열 넣기
  - Ctrl + Shift + i 
- vscode-icons 
  - 예쁜 아이콘