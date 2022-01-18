---
layout: post
author: infoqoch
title: maven 공통 모듈
published: false
categories: [maven]
tags: [maven, spring]
---

## 메이븐 공통모듈
- 공통모듈의 장점은 하나을 다른 모듈이 공유한다는 점이다. 
- 의존성, 구현한 객체, static 파일 등이 상당한 부분을 공유한다. 그러므로 공통모듈 구현은 어플리케이션 유지보수에 매우 유리하다. 
- 다만 공통모듈이 너무 커지면 사실상 하나의 어플리케이션을 다루는 것과 다름 없는 상태가 된다. 무거워지고 유지보수가 어려워 진다. 그러므로 보통 공통 유틸 정도로 공통모듈의 크기를 제한한다. 

## 구현 방식
- 모듈 전체를 감싸는 부모 프로젝트는 부모를 스프링부트로 한다.
- 자식 모듈은 부모를 부모 프로젝트로 한다. 
- 부모 프로젝트는 공통 모듈을 의존성으로 가진다.


## 계층도
- parent
  - base : 공통 모듈
  - api, web, ...etc : 모듈

## parent

```xml
<groupId>infoqoch</groupId>
<artifactId>parent</artifactId>

<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.6.1</version>
    <relativePath/>
</parent>

<modules>
    <module>web</module>
    <module>api</module>
    <module>base</module>
</modules>
<dependencies>
    <dependency>
        <groupId>infoqoch</groupId>
        <artifactId>base</artifactId>
        <version>1.0-SNAPSHOT</version>
    </dependency>
</dependencies>
```

## base
```xml
<groupId>infoqoch</groupId>
<artifactId>base</artifactId>

<parent>
    <groupId>infoqoch</groupId>
    <artifactId>parent</artifactId>
    <version>1.0-SNAPSHOT</version>
</parent>
```

## api, web, ...etc

```xml
<groupId>infoqoch</groupId>
<artifactId>web</artifactId>

<parent>
    <groupId>infoqoch</groupId>
    <artifactId>parent</artifactId>
    <version>1.0-SNAPSHOT</version>
</parent>
```