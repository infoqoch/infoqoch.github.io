---
layout: post
author: infoqoch
title: spring interceptor에서 http body를 추출할 수 있을까?
categories: [spring]
tags: [spring]
---

# spring interceptor는 body를 추출할 수 없다.
- 스프링을 사용할 때 인터셉터는 공통 로그를 남길 때 효과적으로 사용할 수 있다. 특히 paramter는 get과 post와 관계 없이 추출할 수 있다. 
- 좀 더 욕심을 내서 rest api의 json을 로그로 남기고 싶었다. 여러 시도를 했지만 결과적으로 실패하였다. 
- 실패한 이유와 해결책은 다음 블로그에 잘 정리되어 있다. https://stuffdrawers.tistory.com/9 
- 해당 내용을 정리하면 대략 아래와 같다.

# filter와 interceptor 사이에 inputStream이 고갈된다.
- body가 interceptor로 넘어오기 전, 스프링은 body 데이터가 있는 inputStream 를 사용하고 close() 한다.
- inputStream을 interceptor에서 사용하기 위해서는 filter에서 해당 데이터를 복제해야 한다. 복제한 데이터를 HttpServletRequest에 넘기고, interceptor는 복제한 객체를 꺼내서 사용한다. 
- filter에서 interceptor로 inputStream의 데이터를 전달할 때 사용하는 데이터 타입이 HttpServletRequestWrapper 이다.

