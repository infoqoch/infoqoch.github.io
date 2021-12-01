---
layout: post
author: infoqoch
title: 스프링부트와 properties 설정
last_modified_at: 
categories: [spring]
tags: [spring]
---

## 스프링부트와 설정 properties
- 스프링에는 프로퍼티스를 설정하는 방법이 두 가지 이다.
    - @Value(${abc.test}
    - @ConfigurationProperties("tester") + @Component,

## 우선순위    
- 프로퍼티스에 대한 우선순위가 존재한다.

### 프로퍼티 우선 순위
  1. 유저 홈 디렉토리에 있는 spring-boot-dev-tools.properties
  2. 테스트에 있는 @TestPropertySource
  3. @SpringBootTest 애노테이션의 properties 애트리뷰트
  4. 커맨드 라인 아규먼트
  5. SPRING_APPLICATION_JSON (환경 변수 또는 시스템 프로티) 에 들어있는
  프로퍼티
  6. ServletConfig 파라미터
  7. ServletContext 파라미터
  8. java:comp/env JNDI 애트리뷰트
  9. System.getProperties() 자바 시스템 프로퍼티
  10. OS 환경 변수
  11. RandomValuePropertySource
  12. JAR 밖에 있는 특정 프로파일용 application properties
  13. JAR 안에 있는 특정 프로파일용 application properties
  14. JAR 밖에 있는 application properties
  15. JAR 안에 있는 application properties
  16. @PropertySource
  17. 기본 프로퍼티 (SpringApplication.setDefaultProperties)

### application.properties 의 위치에 따른 우선순위
1. file:./config/
2. file:./
3. classpath:/config/
4. classpath:/

> 출처 : 백기선 개발자님의 스프링부트 개념과 활용


## 테스트에서의 우선순위
- 테스트의 경우 같은 이름의 프로퍼티스가 있으면 그 프로퍼티스를 덮어 쓴다. 이로 인하여 컨텍스트의 구동 과정에서 문제가 생길 수 있다.
- 그러므로 테스트용 프로퍼티스는 다른 이름으로 만들고 그 프로퍼티스를 참조하도록 한다.


### 예제

```properties
<!-- application.properties  -->

tester.name = kim
tester.age = 30
value.abc = aabbcc
```

```java
@Component
@ConfigurationProperties("tester")
@Data
public class TesterProperties {
	private String name;
	private int age;
}
```

```java
@Component
public class Runner implements ApplicationRunner{

	@Autowired
	TesterProperties testerProperties;

	@Value("${value.abc}")
	private String abc;

	private void toDo() {
		System.out.println("----- @ConfigurationProperties(\"tester\") ----");
		System.out.println(testerProperties.getName());
		System.out.println(testerProperties.getAge());

		System.out.println("----- @Value(\"${value.abc}\") ----");
		System.out.println(abc);
	}

	@Override
	public void run(ApplicationArguments args) throws Exception {
		System.out.println("=========== ApplicationRunner starting ===========");
		toDo();
		System.out.println("=========== ApplicationRunner end      ===========");
	}
}
```

### 예제 테스트

```java
@SpringBootTest
@TestPropertySource(properties = "tester.name=TestPropertySource -> properties ") // location 보다 우선순위가 높다.
@TestPropertySource(locations = "classpath:/test.properties")
public class RunnerTest {
	@Test
	void test() {
		System.out.println("===== @SpringBootTest ======");
	}
}
```

```properties
<!-- application.properties  -->

tester.name = testkim
tester.age = ${random.int(0,100)}
value.abc = aabbcc
```

```sql
<!-- test.properties  -->

tester.name = locationTesterName
tester.age = ${random.int(500,600)}
value.abc = gogogo!
```

## 기타
- Properties 빈은 Validation 을 사용가능하다.
- 이 부분은 차후 추가하도록 하겠다. 