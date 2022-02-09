---
layout: post
author: infoqoch
title: Spring boot 에서 in-memory-db로 테스트 진행하기(jpa)
categories: [tdd]
tags: [tdd, spring, jpa]
---

## 테스트의 DB는?
- 테스트를 진행할 때 DB와 통신이 필요한 경우가 많다. 
- 스프링부트에서는 in-memory-db에서 테스트를 지원한다. 

## 세팅하기
- 그래들에 h2 의존성을 추가한다.
- `runtimeOnly 'com.h2database:h2'`
  
- 테스트를 위한 application.yml 을 설정한다. 경로는 test/resources/application.yml 이다.
- url 을 인메모리 db로 한다. 

```yml
spring:
 datasource:
   url: jdbc:h2:mem:test # h2 support in-memory-db
   username: sa
   password:
   driver-class-name: org.h2.Driver

 jpa:
   hibernate:
     ddl-auto: create
   properties:
     hibernate:
       format_sql: true # log

logging.level:
  org.hibernate.SQL: debug
```

- 테스트를 진행하면 `jdbc:h2:mem:test` 로 db를 접속함을 확인할 수 있다. 

- 테스트를 위한 설정이 번거롭다면, 그냥 application.yml 파일만 생성해도 된다. 그럴 경우 인메모리DB로 자동적으로 설정한다. 반대로 application.yml 이 없으면 main 폴더에 있는 설정파일에 따르기 때문에, 해당 설정파일에 설정한 DB로 테스트를 진행한다. 
- jpa를 사용할 경우 어떤 세팅도 하지 않으면 create-drop 으로 자동 ddl이 생성된다. jpa의 경우 엔티티에 준해서 ddl을 생성하기 때문에, mybatis로 사용하는 것보다 훨씬 간단하고 빠르게 인메모리db에서 테스트가 가능하다. jpa를 사용해야하는 이유가 여기에 또 하나 만들어진다. 