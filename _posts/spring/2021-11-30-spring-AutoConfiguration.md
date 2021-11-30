---
layout: post
author: infoqoch
title: 스프링 부트의 AutoConfiguration
categories: [spring]
tags: [spring]
---

## @SpringBootApplication
- 스프링부트는 빈을 생성하고 컨텍스트를 만드는 과정을 내장하고 있다. 이는 @SpringBootApplication 으로 설정한다. 해당 어너테이션은 3개의 설정관련한 어너테이션을 포함한다. 
    - @SpringBootConfiguration
    - @EnableAutoConfiguration
    - @ComponentScan
- @ComponentScan은 해당 클래스 이하의 component에 대하여 빈을 생성한다.
- @EnableAutoConfiguration은 다양한 Configuration 파일을 읽고 자동으로 빈을 생성한다. 특히 /META-INF/spring.factories 의 설정 파일을 읽는다.
- @ComponentScan 수행 후 @EnableAutoConfiguration 을 수행한다. 중복 수행 되면 덮어쓰기가 되어 @EnableAutoConfiguration 에서 등록한 빈이 최종 등록된다. 

## @EnableAutoConfiguration
- 아래의 구현은 @EnableAutoConfiguration 에 대한 예제이다.
- 하나의 어플리케이션에 원하는 빈을 등록하고, 해당 어플리케이션을 install 하여 jar 파일로 만든 후, 해당 jar 를 @SpringBootApplication(사실은 @EnableAutoConfiguration)을 통해 빈을 가져온다. 
- 결론적으로, jar 파일의 빈을 다른 어플리케이션의 빈으로 등록하는 것이 현재 내용의 목표이다. 

## 베이스 패키지의 생성
- 메이븐에 아래의 디펜던시를 추가하여 @EnableAutoConfiguration 의 대상이 되도록 한다. 

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-autoconfigure</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-configuration-processor</artifactId>
    <optional>true</optional>
</dependency>
```

- 아래의 객체를 생성한다.

```java
@Data
public class TesterVO {
	private String name;
	private int age;

	public TesterVO() {

	}

	public TesterVO(String name, int age) {
		this.name=name;
		this.age=age;
	}
}
```

- 이 방법을 통해 빈을 초기화하는 방법은 두 가지이다. 첫 번째는 값을 세터나 생성자에 값을 부여하는 방법과 프로퍼티스로 접근하는 방식이다. 아래의 예제는 그 두 가지 방법을 모두 보여준다. 
- 자동설정이 컴퍼넌트스캔보다 우선권이 강하다. 그러므로 ConditionalOnMissingBean을 해야 한다.

```java
@Configuration
@EnableConfigurationProperties(TesterProperties.class) // properties 를 사용
public class TesterConfig {

	@Bean
	@ConditionalOnMissingBean // ComponentScan 에 우선권을 준다. 
	public TesterVO testerVO(TesterProperties properties) {
		return new TesterVO(properties.getName(), properties.getAge()); // properties 를 사용
//		return new TesterVO("kim", 64); // 그냥 초기화
	}
}
```

- 다음은 프로퍼티스 객체이다. 

```java
@ConfigurationProperties("test")
@Data
public class TesterProperties {
	private String name;
	private int age;
}

```

- spring.factories에 자동설정할 빈을 명시한다. 

```text
\src\main\resources\META-INF\spring.factories

org.springframework.boot.autoconfigure.EnableAutoConfiguration=\ 
spring.config.TesterConfig
```

- 마지막으로 maven - install 을 한다.
- .m2 폴더에 해당 데이타가 들어가있음을 확인한다.

## jar 파일의 빈을 사용한다. 

- 해당 jar 를 디펜던시에 등록한다. 그 내용은 pom.xml에 설정한 값을 따른다. 

```xml
<dependency>
    <groupId>test</groupId>
    <artifactId>spring_config</artifactId>
    <version>0.0.1-SNAPSHOT</version>
</dependency>
```

- 프로퍼티스에 등록하거나 빈으로 등록한다.

```properties
test.name = 'kim'
test.age = 4
```

```java
@Configuration
public class RunnerConfig {

	@Bean
	public TesterVO testerVO(TesterProperties prop) {
		return new TesterVO("aoi", 66);
	}
}
```

- 컨텍스트로부터 빈을 가져온다. 

```java
@Autowired
TesterVO testerVO;

@Override
public void run(String... args) throws Exception {
    log.info("====CommandLineRunner====");
    log.info("result : {}", testerVO.toString());

}
```

## 느낀점
- 나는 개인적으로 이번 학습 내용이 좋았다. (백기선 개발자님의 강의! 추천합니다.) 왜냐하면 하나의 완성된 어플리케이션을 만들어 jar 파일로 배포하는 것이 나의 목표이기 때문이다! 이를 위한 기초적인 지식을 배울 수 있어서 좋았다. 