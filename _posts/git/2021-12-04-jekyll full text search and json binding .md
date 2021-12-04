---
layout: post
author: infoqoch
title: 지킬의 검색기능 중 full-search-text 설정 과정에서 json 오류 문제
categories: [git]
tags: [jekyll]
---

## 들어가며
- 제목이 다소 장황하다. 더 나아가 지킬, 루비의 문법에 대해 잘 모른다. 그래서 아마 이 블로그 내용도 장황할 것 같다. 아무튼 현재 나의 상황을 정리코자 한다. 

## 나의 현황
- 나는 `simple-jekyll-search` 라는 기능으로 검색 기능을 추가하였다. 검색 기능이 단순하고 쉬워서 마음에 들었으나 문제는 문서 전체 검색이 되지 않았다.
- 그래서 스펙에 따라 search.json을 수정하였다. 해당 내용은 post.content 를 검색 대상으로 한다. 
- 하지만 이때 html 콘솔에서 스크립트 에러를 만들었고, 해당 내용은 json 파일을 정상적으로 가져오지 못한다는 에러였다.
- 지킬의 경우 자바의 target 처럼 _site 에 동적인 파일을 정적으로 변경한다. _site/search.json 을 열어보니, /search.json 에 따라 정의한 내용대로 나의 포스팅이 모두 저장된 것을 확인할 수 있다. 그리고 해당 파일에 대하여 vs code가 문법 오류가 있다고 한다.
- 스펙에 확인한 결과 필터를 사용할 수 있고, 필터는 문제되는 것에 대하여 이스케이프 처리를 한다.
- 그러나 기본적으로 제공하는 것은 `strip_control_and_extended_characters` 의 메서드를 통해 아스키가 아니거나 char(int) 의 32-126 이 아닌 값을 없애는 것으로 보인다. 사실상 영어 이외에 모든 것에 대하여 필터링 처리한다. 
- 결과적으로 해당 매서드를 삭제한 결과 해결할 수 있었다! 너무 행복하다.

### 혹시 전체 검색 기능을 추가하고 싶다면... 정리하자면...
- [프로젝트의 깃]("https://github.com/christian-fei/Simple-Jekyll-Search") 에 들어간다.
- 설명서나 깃에서 /example 의 내용을 참고하여 검색 기능을 추가한다.
- full-text-search 의 내용을 참고하여 search.json 을 수정한다.
- 필터 역시 자신의 블로그에 넣는다. 그 파일은 해당 프로젝트 깃 리포지토리의 /example/plugins 에 있다.
- simple_search_filter.rb 에서 remove_chars 을 정의하는 것 중  strip_control_and_extended_characters 부분을 삭제한다.
- 그리고 반드시 지킬 서버를 죽였다가 살린다. 자동 빌드로는 해당 변경 내용을 반영할 수 없다.

## 교훈
- `Liquid::Template.register_filter()` 라는 식으로 뭔가를 한다. 아마 이게 자바에서 컨텍스트에 빈을 등록하는 과정처럼, 뭔가 매서드를 등록하는 과정 같다. 
- /search.json 의 파일의 경우 `"content"  : "{{ post.content | strip_html | strip_newlines | remove_chars | remove_chars_cn| escape }}"` 이런 식으로 내용을 추가했다. 아마 매서드의 추가방법이 이런가 보다.
- json에서 이스케이프처리를 해야함을 이번에 배웠다. 사실은 그냥 생각 없이 써왔는데, 이런 부분에서 문제가 있을 수 있음을 배웠다. 
- 지킬에 대해 잘 모르는 상황에서 해결하면서 많은 시간을 썼다. 역시 잘 아는 상태에서 문제 해결을 해야 빠르게 해결하는 것 같다. 