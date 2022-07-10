---
layout: post
author: infoqoch
title: 스프링 profiles 정리
categories: [spring]
tags: [spring]
---

# 스프링 프로파일?
- 스프링 프레임워크를 동작할 때, 프로파일에 따라 설정을 달리할 수 있다
- 간단하게는 dev - prod 등 개발과 운영으로 나눌 수 있고, 필요에 따라 더 복잡하게 구현할 수 있다. 
- 프로파일 설정에 대한 블로그는 매우 많다. 하지만 예전 방식도 존재하고, 아예 동작하지 않는 세팅도 존재하였다. 프로파일 설정 방법을 찾는데 생각보다 많은 시간이 들었다. 
- 실제로 어플리케이션이 동작하는 것을 확인하고, 그것을 간단하게 정리하였다. *도움이 되기를 바랍니다!!*
- 스프링 부트 2.7.1 버전을 사용하였다. 

# 프로파일 설정
- 프로파일 설정은 두 개로 나눠서 생각해야 한다.
    - application.yml
    - application-XXX.yml

# application.yml
- 프로파일이 설정되지 않거나 공통 설정은 application.yml에 작성한다.
- 나의 경우 다음과 같은 경우에서 application.yml에 작성하였다.
    - 공통의 설정을 작성한다.
    - 설정이 필요한 설정을 선언하되 공란으로 둔다. 다른 프로파일이 오버라이드 하도록 의도한다.
    - 사용할 프로파일을 선언하지 않는 경우, 기본적으로 사용할 프로파일을 설정한다. `spring.profiles.active`
    - 프로파일을 그룹핑한다. `spring.profiles.group`

## spring.profiles.active
- 프로파일을 설정하지 않고 동작할 경우, `spring.profiles.active`에서 설정한 값으로 동작한다.
- 다른 프로파일이 오버라이드 하기 기대하는 값들을 미리 선언해 놓는다. 

```yaml
# application.yml

spring:
  profiles:
    active: dev, mariadb # 프로파일에 대한 설정이 없으면 dev와 mariadb 프로파일이 동작한다. 
  datasource:
    driver-class-name: # 공란으로 남겼다. mariadb 프로파일 설정파일이 오버라이딩 하기를 기대한다. 
    username: 
    password: 
    url: 
  jpa:
    hibernate:
      ddl-auto: 
    properties:
      hibernate:
        format_sql: true # 공통적인 부분은 작성한다.
```

## spring.profiles.group
- 프로파일을 그룹핑한다. 하나의 프로파일로 여러 개의 프로파일을 동시에 적용한다. 
- 환경에 따른 배포나 테스트에 아주 큰 장점을 발휘한다.
- 현재 개발하는 서비스가 1) 외부 API와 연동하고 2) mariadb를 사용하고 3) 서버는 리눅스인데 개발은 윈도우라고 가정하자.
- 이 변수에 따라 다음과 같이 프로파일을 작성하였다.
    - application-linuxMariadbApidev.yml
    - application-windowMariadbApidev.yml
    - application-linuxMemdbApidev.yml
    - application-windowMemdbApidev.yml
    - application-linuxMemdbApiprod.yml
    - application-windowMemdbApiprod.yml
- `java -jar -Dspring.profiles.active=linuxMariadbApidev application.jar` -> 나는 리눅스에서 마리아디비를 사용하고 외부 api는 개발용으로 해야지! 

- 그룹핑을 이러한 문제를 아주 편리하게 해소한다. 

```yaml
# application.yml
spring:
  profiles:
    group:
      "test_maria": "window,mariadev,apidev"  # test_maria를 프로파일로 쓰면 window, mariadb, apidev를 동시에 사용한다. 
      "test_mem": "window,mem,apidev"      
```

- 나는 테스트할 때 그룹핑을 주로 사용한다. 
- 단순한 테스트는 inMemoryDB인 H2를 사용한다. 격리성을 위하여 ddl-auto는 create로 설정한다. 
- H2에서 하는 것도 좋지만, 실제 데이타베이스에서 테스트 또한 해야 한다. 테스트 서버이지만 기존의 데이터를 drop 할 수 없을 수 있다. 이럴 때는 mariadev의 ddl-auto를 validation로 설정한다.
- 이러한 디테일을 각각의 프로파일에서 설정하고, 실제 테스트할 때는 `test_mem`를 active하여 간편하게 테스트할 수 있다. 

## spring.config.activate.on-profile 과 ---
- `spring.config.activate.on-profile`을 사용하여 특정 프로파일에 대한 설정임을 선언한다.
- `spring.config.activate.on-profile=abc`는 application-abc.yml에 작성한 것과 동일한 효과를 가진다. 
- `---`은 하나의 yml 파일에서 두 개의 파일을 가지는 것과 유사하다. 이를 통해 한 장의 yml에 여러 프로파일에 대한 설정을 할 수 있다.

```yaml
# application.yml

spring:
  datasource:
    driver-class-name: org.h2.Driver # 프로파일이 설정되지 않으면 h2를 기본적으로 사용한다. 
    username: sa
    password:
    url: jdbc:h2:mem:test
  jpa:
    hibernate:
      ddl-auto: create

--- # 프로파일 설정 페이지가 분리된다. 위와 아래는 나뉘어진 파일과 같다. 

spring:
  config:
    activate:
      on-profile: mariadb # maraidb에 대한 프로파일의 설정을 작성한다.  #application-mariadb.yml 에 작성한 것과 동일한 효과를 준다. 
  datasource:
    driver-class-name: org.mariadb.jdbc.Driver
    url: jdbc:mariadb://localhost:3306/test
    username: test
    password: test
  jpa:
    hibernate:
      ddl-auto: validation 
```

# application-XXX.yml
- `application-XXX.yml`의 형태를 가지면 XXX 프로파일에 대한 설정으로서 동작한다. 
- `spring.config.activate.on-profile` 를 사용할 필요가 없다. 
- 나의 경우 오버라이드를 위하여 사용한다. 앞서의 예제와 같이 공란을 사용해도 되지만, 이번에는 변수 `${}`를 사용하였다.

```yaml
# application.yml

spring:
  datasource:
    driver-class-name: org.mariadb.jdbc.Driver
    url: jdbc:mariadb://${my.db.ip}:3306/#{my.db.name}
    username: ${my.db.username}
    password: ${my.db.pwd}

# application-mariadev.yml
my:
  db:
    ip: localhost
    name: dev_db
    username: dev
    pwd: test

# application-mariaprod.yml
my:
  db:
    ip: 123.123.123.123
    name: prod_db
    username: prod
    pwd: w%efj#8WEF45jflk$gv!u8i
```