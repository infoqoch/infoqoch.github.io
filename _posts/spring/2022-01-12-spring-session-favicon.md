---
layout: post
author: infoqoch
title: 스프링, 크로미움에서 세션이 풀리는 문제(favicon.ico)
categories: [spring]
tags: [spring]
---

## 크롬에서만 특정 세션이 풀린다.
- 자꾸 특정 세션만 풀렸다. 분명 세션은 들어갔는데 어느 순간 해당 세션이 휘발된다. 
- 이 문제의 원인은 /favicon.ico에 대한 url 요청 때문이었다. 이를 인터셉터에 처리하지않고 무시하자 해소할 수 있었다. 
- `.excludePathPatterns("/favicon.ico")`
- 크로미움 기반의 브라우저에서 발생하는 문제로 보이는데, 이 버그가 왜 발생하는지는 잘 모르겠다. 더하여 이 문제는 단순한 스프링 문제가 아니었다. 2010년에 올라온 php와 관련한 질문(https://stackoverflow.com/questions/2953536/randomly-losing-session-variables-only-in-google-chrome-url-rewriting) 에도 올라온 것으로 보아, 버그가 아닌 어떤 특징이 아닌가 싶다. 
- 추가적으로 세션이 풀린 것은 객체 형태였다. 완전히 동일한 조건에서 문자열, 원시 타입 등으로 세션을 추가할 경우 그것들은 유지가 되는데 객체 형태의 세션만 자꾸 사라졌다. 
- url 호출과 세션 삭제는 쉽게 연결되지 않는 문제이기 때문에, 이와 유사한 상황이 발생할 경우 난감할 수 있을 것 같다. 이 글이 도움 되기를 바란다. 