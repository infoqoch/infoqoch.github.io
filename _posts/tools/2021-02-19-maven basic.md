---
layout: post
author: infoqoch
title: Maven(빌드도구)란?
categories: [tools]
tags: [tools, maven]
---


## 들어가며
- 스프링부트를 사용할 때 스타터(https://start.spring.io/)를 통해 프로젝트를 시작한다. 이 때 빌드도구로 메이븐, 그래들 두 개를 제공한다. 이러한 빌드도구를 사용했지만 그것이 무엇인지 정확하게 몰랐다. 유튜브 뉴렉(https://www.youtube.com/watch?v=VAp0n9DmeEA) 에서 메이븐에 대한 설명이 나와서 참고할 수 있었다. 유튜브 영상과 기타 자료들을 참고하여 아래와 같이 정리했다.
  
## 1. 간편한 라이브러리의 구성과 환경 설정(pom.xml)

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

- 메이븐은 pom.xml을 통해 프로젝트에 필요로 한 설정을 간편하게 할 수 있다. 위의 코드는 스타터를 통해 생성한 메이븐 프로젝트이다. 스프링부트의 버전, 자바의 버전, 프로젝트의 명칭 등을 설정한다. 
- dependency/plugins를 통하여 라이브러리를 설정한다. 기존의 방식은 라이브러리 파일(jar)를 다운로드하고, build path - library에 업로드를 하였다. 빌드 도구는 단 한 줄의 코드를 가지고, 외부에 연결된 저장소를 통해 자동으로 의존성을 다운로드 및 세팅한다. 이를 통해 무겁고 버전관리가 어려운 .jar 파일로부터 해방된다. 문서화된 코드를 통해 언제 어디서나 누구나 동일한 프로젝트의 조건을 만들 수 있다.
  
## 2. 빌드도구는 생명주기를 가지며 개발을 편리하게 만든다.

>   validate - validate the project is correct and all necessary information is available
compile - compile the source code of the project
test - test the compiled source code using a suitable unit testing framework. These tests should not require the code be packaged or deployed
package - take the compiled code and package it in its distributable format, such as a JAR.
verify - run any checks on results of integration tests to ensure quality criteria are met
install - install the package into the local repository, for use as a dependency in other projects locally
deploy - done in the build environment, copies the final package to the remote repository for sharing with other developers and projects.
출처 : https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html

- 빌드도구는 의존성의 쉬운 다운로드와 환경설정 뿐만이 아니라, 프로젝트의 생명주기에 절대적인 영향을 미친다. 위의 내용은 메이븐의 생명주기이다. 
- pom.xml로 설정한 환경을 구성하는 컴파일, 프로젝트의 테스트 환경을 구성하는 테스트, 구성한 프로젝트를 jar(자바), war(웹) 형태의 배포용 파일로 만드는 패키지, 완성한 파일을 로컬 혹은 메이븐서버에 저장하는 인스톨과 디플로이라는 생명주기를 가진다. 
  
## 3. 동일한 프로젝트를 보장한다
- 메이븐은 동일한 빌드파일과 소스코드만 존재하면 언제 어디서 누가 사용하든 동일한 프로젝트를 생성할 수 있다.  

## 기타 팁...
- 다운로드 받은 의존성의 무결성을 검증하지 못한다. 그러므로 라이브러리와 관련한 문제가 발생할 경우 의존성을 다운로드 받은 .m2 폴더를 삭제해야할 경우가 있을 수 있다. 