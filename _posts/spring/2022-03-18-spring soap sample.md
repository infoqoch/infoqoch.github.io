---
layout: post
author: infoqoch
title: 스프링 soap(wsdl) 다루기
categories: [spring]
tags: [spring]
---

## soap 와 wsdl 을 만나다 
- 최근은 rest api가 대세이다. 
- 한편, soap를 api를 사용해야 하는 상황이 발생했다. 다뤄야 할 소스는 php로 되어 있었다. 혹시 자바/스프링으로 해당 문제를 해소할 수 있을까 하여, 관련한 내용들을 찾고 공부해봤다. 그러나 아쉽지만 php을 기반으로 원하는 결과물을 생산해낼 수밖에 없었다. 
- 다만, 그 와중에 soap와 wsdl, 마셜링 등 자바 스프링으로 다루는 과정에서 학습한 내용을 정리하고자 글을 작성한다.
- 참고한 자료는 스프링 공식 문서이며, 이 글은 이에 대한 간단한 주석이기 때문에 바로 아래의 링크를 활용해도 좋을 것 같다.
> https://spring.io/guides/gs/producing-web-service/
> https://spring.io/guides/gs/consuming-web-service/

## soap 와 wsdl은 무엇인가?
- soap는 wsdl을 기반으로 통신하는 프로토콜을 의미한다.
- wsdl이란 무엇인가? xml이다. 우리가 평소에 사용하는 html이 일종의 xml이다. 

## 자바-스프링은 soap 통신의 편의를 위하여 마셜링 기능과 서버의 명세서를 클라이언트에 복사하는 기능을 제공한다. 
- 위의 스프링 공식 문서를 통해 몇 가지 정말로 탁월한 기능들을 접할 수 있었다.
- 가장 먼저 놀라운 점은 producing-web-service 을 다루는 과정에서 그러했는데, 명세서를 작성하면 이에 따라 클래스 파일을 만들어줬다. 

- resources/countries.xsd

```xsd
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tns="http://spring.io/guides/gs-producing-web-service"
           targetNamespace="http://spring.io/guides/gs-producing-web-service" elementFormDefault="qualified">

    <xs:element name="getCountryRequest">
        <xs:complexType>
            <xs:sequence>
                <xs:element name="name" type="xs:string"/>
            </xs:sequence>
        </xs:complexType>
    </xs:element>

    <xs:element name="getCountryResponse">
        <xs:complexType>
            <xs:sequence>
                <xs:element name="country" type="tns:country"/>
            </xs:sequence>
        </xs:complexType>
    </xs:element>

    <xs:complexType name="country">
        <xs:sequence>
            <xs:element name="name" type="xs:string"/>
            <xs:element name="population" type="xs:int"/>
            <xs:element name="capital" type="xs:string"/>
            <xs:element name="currency" type="tns:currency"/>
        </xs:sequence>
    </xs:complexType>

    <xs:simpleType name="currency">
        <xs:restriction base="xs:string">
            <xs:enumeration value="GBP"/>
            <xs:enumeration value="EUR"/>
            <xs:enumeration value="PLN"/>
        </xs:restriction>
    </xs:simpleType>
</xs:schema>
```

- pom.xml

```xml
<dependency>
    <groupId>wsdl4j</groupId>
    <artifactId>wsdl4j</artifactId>
</dependency>
```

```xml
<plugin>
	<groupId>org.codehaus.mojo</groupId>
	<artifactId>jaxb2-maven-plugin</artifactId>
	<version>2.5.0</version>
	<executions>
		<execution>
			<id>xjc</id>
			<goals>
				<goal>xjc</goal>
			</goals>
		</execution>
	</executions>
	<configuration>
		<sources>
			<source>${project.basedir}/src/main/resources/countries.xsd</source>
		</sources>
	</configuration>
</plugin>
```

- wsdl4j와 jaxb2를 활용하여 countries.xsd에 작성된 내용 그대로의 클래스파일이 생성된다. 
- 예전에 나는 파싱, 바인딩, 마셜링 등 일종의 데이터의  변환 과정에서 사용하는 단어들에 대하여 그 차이를 이해하지 못했다. 하지만 이번에 나는 마셜링이나 직렬화가 무엇인지에 대하여 직관적으로 이해할 수 있었다. 특정 명세서가 pojo로 변경되는 이러한 기능이 바로 마셜링과 직렬화였다. 

- 더 놀라운 점은, 클라이언트가 이러한 명세서를 가져오고 바로 클래스파일로 만든다는 것이었다. 아래의 코드를 보자. 

- pom.xml

```xml
<profiles>
	<profile>
		<id>java11</id>
		<activation>
			<jdk>[11,)</jdk>
		</activation>

		<dependencies>
			<dependency>
				<groupId>org.glassfish.jaxb</groupId>
				<artifactId>jaxb-runtime</artifactId>
			</dependency>
		</dependencies>
	</profile>
</profiles>

<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
        <!-- tag::wsdl[] -->
        <plugin>
                <groupId>org.jvnet.jaxb2.maven2</groupId>
                <artifactId>maven-jaxb2-plugin</artifactId>
                <version>0.14.0</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>generate</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <schemaLanguage>WSDL</schemaLanguage>
                    <generatePackage>com.example.consumingwebservice.wsdl</generatePackage>
                    <schemas>
                        <schema>
                            <url>http://localhost:8080/ws/countries.wsdl</url>
                        </schema>
                    </schemas>
                </configuration>
        </plugin>
        <!-- end::wsdl[] -->
    </plugins>
</build>
```

- 위의 pom.xml 중 `http://localhost:8080/ws/countries.wsdl` 이 보인다. 해당 서버의 해당 메서드에 접근하여, 서버의 것 그대로의 명세서와 클래스 파일을 클라이언트에 복사한다. 와, 난 여기서 놀랐다. 이런 편리한 기능이...! rest api에서는 이런 기능 없나?

- 어떻게 soap 를 잠깐 건들면서 여러 개념에 대하여 공부하는 계기가 되었다. 내부 구조나 동작 원리는 잘 모르겠지만 자바에 대해 좀 더 알게 된 기분이다. 재밌었다.

## 마지막으로, 위의 스프링 예제가 동작하지 않을 때.
- 맨 처음에서 위의 프로젝트 두 개를 로딩했을 때 클라이언트 쪽에서 빌드가 되지 않는 문제가 있었다. 혹시 유사한 문제가 발생하는 것을 우려하여 간략하게 해소방법을 작성한다. 
- 나는 STS로 하나의 워크스페이스에 프로듀서와 클라이언트의 서버를 함께 돌렸다. 이렇게 하니까 클라이언트 쪽에서 빌드를 하지 못했다. 이에 대한 해결책으로는 서버를 윈도우 cmd에서 로딩하고, 클라이언트를 sts에서 돌리는 것으로 해소했다. 

