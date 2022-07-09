---
layout: post
author: infoqoch
title: 테스트 환경을 복잡하게 만드는 요소들.. 대역과 프로파일, 리소스의 문제
categories: [tdd]
tags: [tdd, spring]
---

# 테스트를 통한 개발을 하며 직면한 어려움들
- 테스트 주도 개발을 할 때 발생하는 다양한 문제가 존재한다.
- 테스트를 할 때 테스트의 종류와 테스트에 사용하는 객체에 따른 복잡성 문제가 발생한다.
    - 유닛 테스트
    - 대역 객체를 활용한 유닛 테스트
    - 통합테스트
    - 대역 객체를 활용한 통합 테스트

- 테스트의 환경을 관리하는 과정에서도 다양한 문제가 발생한다. 
    - 복잡하게 구현한 대역과 관리
    - 통합테스트(@SpringBootTest)에서의 메인(main)과 테스트(test)의 동시 호출 문제
    - 대역이나 유닛테스트의 인자로 전달할 대역 데이터 생성 로직 

- 이러한 문제를 해소하는데 있어서 아래의 원칙을 지키고자 노력했다.
    - 최대한 유닛테스트로 테스트한다.
    - 통합 테스트를 할 때 최소한의 자원을 사용하도록 노력한다.
    - main 파티션의 코드가 test 파티션 코드에 영향을 받는 코드를 최대한 작성하지 않는다.

# 테스트와 대역 
## 대역의 필요성
- 테스트에서의 대역은 다양한 의미를 가진다. 외부와 통신하는 api, 객체를 영속화 하는 리포지토리를 우리는 항상 실제를 사용할 수는 없다. 
- 외부 API의 경우 항상 그것이 열려 있는지를 보장할 수 없고, 열려 있다 하더라도 모든 테스트마다 이에 대한 리소스를 활용하는 것은 낭비이다.
- 리포지토리도 마찬가지이다. Set이나 Map을 통해 리포지토리를 간단하게 구현하고 싶을 수 있다. 그런데 이런 상황에서 jpa로 구현하고, 테스트 할 때 마다 통합테스트를 사용하고, 테스트 마다 create database -> create table -> insert into 의 과정을 계속 반복할 필요는 없다. 

## 리포지토리의 대역

```java
public class SomeServiceTest{
    @Test
    @DisplayName("에러가 발생했을 때, 로그를 작성하는 리포지토리에 에러인 로그가 존재하는가?")
    void is_touched(){
        service.save("exception"); // 
        assertThat(logRepository.findByStatus("ERROR")).size().isGreaterThan(0); // 
    }
}
```

- "exception"을 인자로 삽입할 경우 내부에 예외가 발생하도록 하였다. 
- 이 경우 단순하게 log_repository에 데이터가 삽입되는 로직이 동작하였는지의 여부만 살펴보면 된다. 
- 이때 굳이 repository를 jpa로 구현하여 SpringBootTest를 통한 통합 테스트를 할 필요가 없다. 메모리 DB를 로딩하고 jpa가 create table을 하도록 만드는 것은 낭비이다. FakeRepository를 생성하고, 자료구조에 데이터가 들어갔는지만 확인하거나, 그것도 번거롭다면 spy객체를 만들어서 단순하게 호출되었는지만을 확인하면 된다. 

- 유닛테스트와 대역의 구현이 유리함은 분명하다. 이에 따라 대역을 구현할 경우, 그만큼 관리해야 할 코드가 늘어난다.
    - `interface LogRepository`
    - `class MemoryLogRepository implements LogRepository`
    - `interface JpaLogRepository extends LogRepository, JpaRepository<Log, Long>`

## 통합 테스트로에서의 jpa 기능 최소화
- 대역은 통합 테스트에도 사용할 수 있다. 통합 테스트에서 jpa의 기능을 사용할 필요는 없다. 
- profile을 아래와 같이 설정하였다. none_jpa 프로파일이 동작할 때, jpa의 ddl-auto를 종료하였다. 만약 jpa의 기능이 필요 없는 테스트일 경우, `@ActiveProfile("none_jpa")` 를 사용한다.

```yaml
# /test/resources/application.yml
spring:
  profiles:
    active: test
  jpa:
    hibernate:
      ddl-auto: create # 격리성을 위하여 항상 테이블을 새로 생성한다. 
---
spring:
  profiles:
    active: none_jpa
  jpa:
    hibernate:
      ddl-auto: none # jpa를 사용하지 않으면 ddl을 생성하지 않더라도 통합테스트에 문제가 없다.
```

```java
// src/test/.../MemoryLogRepository.java
@Primary
@Profile("none_jpa")
@Repository
class MemoryLogRepository implements LogRepository{
    // 중략
}
```

```java
@ActiveProfiles("none_jpa")
@SpringBootTest
class NoneDBTest {
    // 중략
}
```

# 통합테스트(@SpringBootTest)에서의 메인(main)과 테스트(test)의 동시 호출 문제
- 현 문제는 reflect 사용 중에 발생한 문제이다.
- 특정 어너테이션을 읽고, 해당 어너테이션의 값이 유일함을 보장해야 한다고 가정한다. 대표적으로 스프링의 `@GetMapping` 가 그러하다.
- 이때 메인과 테스트에서 둘 다 동일한 어너테이션과 value를 구현하고 싶을 수 있다. 예를 들면 아래와 같다.

```java
// main/.../MainController.java
@Controller
public class MainController {
    @GetMapping("/main")
    public void main(){
        // 중략
    }
}

// test/.../TestController.java
@Controller
public class TestController {
    @GetMapping("/main")
    public void main(){

    }
}
```

- 예외가 발생한다! `to {GET [/main]}: There is already 'testController' bean method`;

- 그런데 통합테스트`@SpringBootTest`의 상황에서 왜 이런 이유가 발생할까? 그 이유는 소스코드를 읽는 url의 문제 때문이다.

```java
@SpringBootTest
public class ApplicationTests {
    @Test
    void contextLoads() {
        final Collection<URL> urls = ClasspathHelper.forPackage(UpdateDispatcher.class.getPackageName());
        for (URL url : urls) {
            // 결과가 두 개 나오며 그 url은 아래와 같다.
            // url = file:/C:/Users/USER/IdeaProjects/dictionary-v3/dictionary-bot/out/test/classes/
            // url = file:/C:/Users/USER/IdeaProjects/dictionary-v3/dictionary-bot/out/production/classes/
            System.out.println("url = " + url);
        }
    }
}
```

- 참고로 위의 url은 그래들 기준이다. 메이븐은 다음과 같은 경로를 가진다. `/test-classes` 

- 이에 따라 main 파티션에서 어너테이션을 읽을 때는 test 리소스가 있는 곳을 바라보지 않도록 하였다. 리플렉션과 관련한 테스트는 유닛테스트를 통해 충분하게 개발이 가능했기 때문이다. 
- 다만, 테스트와 관련한 코드가 메인에 위치하기 때문에, 좋은 코드인가에 대한 고민이 있다. 

```java
@Configuration
public class SomeAnnotationResolver{
    
    @Bean
    public SomeResolver someResolver(){
        Set<Url> urls = onlyMainUrl();
        // 후략
    }    

    public Set<Url> onlyMainUrl(){
        return ClasspathHelper.forPackage(UpdateDispatcher.class.getPackageName()).stream()
                .filter(url -> !url.toString().contains("/test-classes")) // 메이븐 
                .filter(url -> !url.toString().contains("/test/classes")) // 그래들
                .collect(Collectors.toSet());
    }
}
```

# 대역의 관리
## 대역 데이터
- `@PostMapping("/order/")` 라는 api가 존재하고 `json`이 `ClientOrderRequest` 객체로 넘어온다고 가정한다.
- Controller에서의 `ClientOrderRequest`를 검증한다. 데이터를 약간 수정하여 `OrderRequest`로 변경 후 Service로 넘긴다. Service가 `OrderRequest`를 조금 변경하여 `Order`로 바꾼다. repository에서 `Order`를 저장한다.
- 이때 각 레이어마다 테스트마다 필요로한 데이터는 다음과 같다.
    - Json
    - ClientOrderRequest
    - OrderRequest
    - Order

- 더 나아가 Service에서 Order객체를 만들기 위하여 Orderer로서의 Member를 추출하고 상품인 Product를 추출해야 한다. 이때 OrderRequest로부터 Member와 Product를 추출하는 로직 또한 구현해야 한다. 
- 결과적으로 Service에서 OrderRequest를 필요로하는 엔티티는 다음과 같다.
    - Member
    - Product
    - Ship

## 대역 
- 대역 또한 대역 데이터와 유사하다.
- 인터페이스를 통한 컴퍼지션 패턴은 테스트를 위해 필수 불가결한 패턴이다.
- 다만 문제가 있다. 상위 클래스를 테스트할 때는, 하위 클래스의 인터페이스 전체를 구현해야 한다.

```java
public SomeHandlerTest{
    SomeHandler handler;

    @BeforeEach
    void setUp{
        // .... 전략 ....
        A1Repository a1Repository = new A1RepositoryImpl();
        AService aService = new AService(a1Repository, a2Repository)
        BService bService = new BService(b1Repository, b2Repository)
        handler = new SomeHandler(aService, bService);
    }
}
```

- 이러한 문제가 발생할 때, 컴퍼지션이 아니라 static method를 사용하고 싶다는 욕구가 치솟는다.....!
- 다만, 대역 데이터와 마찬가지로 각각의 서비스 역시 공통 사용할 가능성이 매우 높다. 

## 대역의 관리
- 각각의 대역에 대하여, 각각의 테스트 코드 마다 작성하기보다 factory를 만들기로 하였다. 변수로 사용할 부분에 대해서만 인자로 남기고, 나머지는 필요에 따라 리턴하도록 구현한다.

```java
public class ClientOrderRequestGenerator{
    public static String clientOrderRequestJson(String orderer, String orderItem, String receiverAddress){}
    public static ClientOrderRequest clientOrderRequest(String orderer, String orderItem, String receiverAddress){}
    public static OrderRequest orderRequest(String orderer, String orderItem, String receiverAddress){}
    public static Order order(String orderer, String orderItem, String receiverAddress){}
}

public class SomeTest{
    @Test
    void test(){
        ClientOrderRequest request = ClientOrderRequestGenerator.clientOrderRequest("김순애", "과자", "서울시 용산구");
        // 후략
    }
}
```

```java
public class AServiceGenerator{
    public static AService defaultAService(){}
}

public class SomeTest{
    SomeHandler handler;
    @BeforeEach
    void setUp{
        handler = new (AServiceGenerator.defaultAService(), null);
    }
}
```

- 각각의 레이어와 엔티티에 맞춰 대역 데이터를 계속 생성한다는 것은 상당한 코드를 필요로 한다. 상당한 노동력과 상당한 중복을 요구받는다. 사실 매우 피곤한 일이다.
- 나의 경우 결과적으로 static 메서드를 구현하여, 단순하게 추출하는 방향으로 대응할 수밖에 없었다. 유닛테스트의 격리성에 다소 부정적이지만 어쩔 수 없었다. 
- 이러한 대역은 "mock" 패키지에서 공통 관리하였다.

# 나아가며
- 테스트코드의 가치는 분명하다. 그러나 그 만큼 관리의 대상이 늘어난다. 그리고 테스트 과정에서 발생하는 복잡한 환경 문제를 해소해야 한다. 이 과정에서 겪었던 문제와 해결 방안을 나열해보았다. 
- 이러한 방식이 좋은 방식인지는 좀 더 경험해야 알 것 같다. 지금의 글은 계속 리팩터링 될 예정이다.