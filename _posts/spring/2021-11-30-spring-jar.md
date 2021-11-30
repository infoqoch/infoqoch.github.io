---
layout: post
author: infoqoch
title: Spring Boot Jar 와 독립실행
categories: [spring]
tags: [spring]
---

## 실행가능한 하나의 파일을 위하여
- 스프링부트의 중요한 목표 중 하나는 실행 가능한 하나의 파일을 만드는 것이며, jar 를 통해 이것이 실행가능해졌다.
- 스프링 부트에는 톰캣이 내장되어 있으며,
- jar 파일 하나로 스프링 코드가 동작한다.

## jar 파일에는..
- JarFile과 JarLauncher가 있으며, 이를 통해 jar 파일을 동작한다. 
- MANIFEST 의 설정을 참고한다. 