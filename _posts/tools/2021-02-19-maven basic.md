---
layout: post
author: infoqoch
title: 빌드도구 Maven 의 기본적인 사용법
categories: [tools]
tags: [tools, maven]
---

## 들어가며
- 스프링부트를 사용할 때 대체로 메이븐, 그래들 둘 중 하나를 빌드도구로 선택한다. 그 중 메이븐에 대하여 간략하게 정리하였다.
- 개발자 뉴렉님의 강의(https://www.youtube.com/watch?v=VAp0n9DmeEA)를 참고하였다.
  
## 간편한 라이브러리의 구성과 환경 설정(pom.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.4.3</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	<groupId>com.example</groupId>
	<artifactId>demo</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<name>demo</name>
	<description>Demo project for Spring Boot</description>
	<properties>
		<java.version>11</java.version>
	</properties>
	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-data-jpa</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-thymeleaf</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-devtools</artifactId>
			<scope>runtime</scope>
			<optional>true</optional>
		</dependency>
		<dependency>
			<groupId>org.projectlombok</groupId>
			<artifactId>lombok</artifactId>
			<optional>true</optional>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
	</dependencies>

	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
				<configuration>
					<excludes>
						<exclude>
							<groupId>org.projectlombok</groupId>
							<artifactId>lombok</artifactId>
						</exclude>
					</excludes>
				</configuration>
			</plugin>
		</plugins>
	</build>
</project>
```

- 스프링 스타터(https://start.spring.io)를 사용할 때 위와 같이 pom.xml이 생성된다.
- pom.xml 한 장으로 프로젝트에 필요로 모든 설정을 간편하게 한다. 스프링부트의 버전, 자바의 버전, 프로젝트의 명칭, 의존성, 빌드 및 플러그인 규칙을 설정한다. 
- 메이븐 리모트 리포지토리가 있기 전, 개발자들은 필요로 한 라이브러리 파일(jar)을 프로젝트에 내부 폴더에 삽입하였다. 메이븐 이후 `<dependency></dependency>` 에 라이브러리와 버전을 명시하여 파일을 관리할 필요가 없고 간단하게 공유할 수 있게 되었다. 
- 메이븐은 동일한 빌드파일과 소스코드만 존재하면 언제 어디서 누가 사용하든 동일한 프로젝트를 생성할 수 있다.
  
## 빌드도구는 생명주기를 가지며 개발을 편리하게 만든다.
- validate - validate the project is correct and all necessary information is available
- compile - compile the source code of the project
- test - test the compiled source code using a suitable unit testing framework. These tests should not require the code be packaged or deployed
- package - take the compiled code and package it in its distributable format, such as a JAR.
- verify - run any checks on results of integration tests to ensure quality criteria are met
- install - install the package into the local repository, for use as a dependency in other projects locally
- deploy - done in the build environment, copies the final package to the remote repository for sharing with other developers and projects.

> 출처 : https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html

- 메이븐은 생명주기를 관리한다. 위는 메이븐의 생명주기이다. 
- java 파일을 class로 변경하는 컴파일, 프로젝트의 테스트, 완성된 프로젝트를 배포하기 위하여 jar(자바), war(웹) 형태로의 패키지, 완성한 파일을 로컬 혹은 메이븐서버에 저장하는 인스톨과 디플로이라는 생명주기를 가진다. 

## 기타
- 다운로드 받은 의존성의 무결성을 검증하지 않는다. 만약 라이브러리와 관련한 문제가 있을 경우 의존성이 저장되는 .m2 폴더를 삭제한다.