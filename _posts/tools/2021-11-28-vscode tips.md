---
layout: post
title: VS CODE 단축키 및 설정 팁
author: infoqoch
categories: [tools]
tags: [tools, vscode]
---

## 주요 단축키
- Ctrl + Shift + e : 탐색기(사이드메뉴)
- Ctrl + Shift + f : 내용 검색
- Ctrl + Shift + h : 내용 검색 + 수정
- Ctrl + b : 메모장 전체화면(사이드메뉴 없애기)

- Ctrl + k, Ctrl + o : 폴더로 열기
- Ctrl + ` : 터미널 열기
- Ctrl + p : 파일 검색
- Ctrl + p, > : 설정 검색

- Ctrl + n : 새로운 문서 열기

- Ctrl + f2 : 동일한 문자열 다중커서

- Ctrl + space : 문자열 자동완성 제안

## 설정
- 보통 툴의 기본 설정을 최대한 따른다. 프로그램을 재설치할 때 번거로운 세팅을 최소화한다.
- 아래의 내용은 마크다운이나 지킬을 사용하기 위하여 불가피하게 적용한 설정이다.
- 한편, vs code를 본격적으로 사용하면 이러한 설정의 변경은 불가피하다. 파일 포맷이나 플러그인에 따라 기존 단축키가 사라지는 등 다소 이해가 가지 않은 상황이 발생하기 때문이다.

### 단축키 변경
- `Ctrl + p` - `>keyboard shortcut` -> 🎡버튼 클릭
    
```text
Ctrl + b, Ctrl + b : 메모장 전체 화면을 추가 (마크다운 사용시 해당 키가 bold로 변경 됨)
Alt + n : 새 폴더
```

### 사용자 문자열 자동완성 제안
- - `Ctrl + p` - `>user snippets` -> 원하는 포맷 검색 (markdown 등)

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

- 지킬의 경우 코드블럭 시작 전 한 줄과 종료 후 한 줄이 공란이어야 한다. 이로 인하여 코드블럭 자동완성 시 앞 뒤로 공란을 한 줄씩 추가하였다. 
- $1의 경우 커서 위치이다. 자동완성 후 바로 title을 타이핑 할 수 있다. 

### 플러그인
- **Excel to Markdown table**
  - 엑셀의 테이블을 마크다운 테이블로 변경. 강추!
  - Shift+Alt+V

- **Paste Image**
  - 스크린샷을 원하는 폴더에 저장하고 markdown으로 이미지 연결. 매우 강추! 최고임!
  - Ctrl+Alt+V

- Insert Date String 
  - 날짜 문자열 넣기
  - Ctrl + Shift + i 

- vscode-icons 
  - 예쁜 아이콘
