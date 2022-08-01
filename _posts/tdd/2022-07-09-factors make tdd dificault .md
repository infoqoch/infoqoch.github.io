---
layout: post
author: infoqoch
title: 테스트 환경을 복잡하게 만드는 요소와 해소 - 대역
categories: [tdd]
tags: [tdd, spring]
---

# 테스트를 통한 개발을 하며 직면한 어려움들
- 테스트의 종류와 테스트에 사용하는 요소에 따라 테스트의 난이도가 다르다.
    - 유닛 테스트
    - 대역을 활용한 유닛 테스트
    - 통합테스트
    - 대역을 활용한 통합 테스트

- 테스트 소스를 관리하는 과정에서도 어려움이 있다.
    - main과 관련 없는 대역 소스의 관리
    - 통합테스트(@SpringBootTest)에서의 메인(main)과 테스트(test) 리소스의 동시 호출 문제
    
- 여러 문제에 대해서, 아래의 원칙을 지키고자 노력했다.
    - 최대한 유닛테스트로 테스트한다.
    - 통합 테스트를 하더라도 최소한의 자원만 사용한다.
    - 통합 테스트 시, main의 소스가 test 소스에 최소한의 영향을 받는다.

# 테스트와 대역 
## 대역의 필요성
- 테스트에서 대역은 가상의 인자를 포함하여 외부 API와 리포지토리를 포함한다. 
- 특히 외부 API나 리포지토리에 대한 대역을 구현하는 것은 중요하다. 외부 API의 경우, 항상 열려 있는지를 보장할 수 없고, 열려 있다 하더라도 모든 테스트마다 외부 API와 연결하는 것은 자원 낭비이다.
- 리포지토리도 마찬가지이다. 모든 테스트를 수행함에 있어 DB와 연결할 필요는 없다. in memory db를 사용한다 하더라도, create database -> create table -> insert into ...의 과정을 겪을 필요는 없다. 

## 리포지토리의 대역

```java
public class UserServiceTest{
    @Test
    @DisplayName("회원가입 과정에서 예외가 발생하면, ERROR를 상태로 하여 DB에 저장된다.")
    void signup_exception(){
        userService.signup(new User("exception", 12)); 
        assertThat(someRepository.findByStatus("ERROR")).size().isGreaterThan(0); 
    }
}
```

- UserService#signup 이 인자로 받는 User객체를 UserRepository#save 를 통해 저장한다. UserService는 회원가입 과정에서 에러가 발생한 객체에 대하여 "ERROR"를 상태로 회원 가입을 시킨다. 
- 이 때, 우리는 테스트를 위하여 실제 운영에서 사용하는 UserRepository에 특정 값을 전달하면 예외를 던지는 특정 메서드를 넣어야 할까? 아니면 통합테스트에서 예외가 발생할 상황을 마련하여 예외를 일으키도록 해야 할까?
- 둘 다 좋은 방법은 아니다. 애당초 우리의 관심사는 UserRepository가 아닌 UserService이다. UserService가 의존성을 주입받거나 사용하는 객체에 대해서 우리는 자유롭게 조작할 수 있다. 이때 이상적인 방법은 UserRepository를 대역으로 만드는 방식일테다. 

```java
public class UserMemoryRepository implements UserRepository{
    @Autowired
    public User save(User user){
        if(user.getName().equals("exception")) throw new IllegalStateException();
        // 후략
    }
}

public class UserServiceTest{
    UserMemoryRepository userRepository = new UserMemoryRepository();
    UserService userService = new UserService();

    @BeforeEach
    void setUp(){
        userRepository = new UserMemoryRepository();
        userService = new UserService(userRepository);
    }

    // 이하 테스트 코드 작성
}
```

- 다만 이 경우 관리해야할 테스트 코드가 늘어난다. 
    - UserRepository의 메서드가 늘어나면 UserMemoryRepository가 구현해야할 메서드가 발생한다. 
    - JPA를 사용할 경우, JpaRepository, UserRepository를 상속받는 리포지토리를 main에서 관리해야 한다. 
- 대역 클래스가 굳이 필요 없다면 Mockito를 활용해도 좋다. 이 경우 대역을 구현할 필요가 없다. 다만 매번 Mockito가 테스트코드 마다 발생할 수 있다.

## 통합 테스트에서 jpa가 아닌 대역을 사용
- 만약 대역을 구현하였다면, 통합 테스트에서 필요에 따라 JPA를 사용하거나 사용하지 않을 수 있다. 
- 나의 경우 프로파일을 활용하였다.  

```yaml
# /test/resources/application.yml
spring:
  profiles:
    active: test
  jpa:
    hibernate:
      ddl-auto: create
---
spring:
  profiles:
    active: none_jpa
  jpa:
    hibernate:
      ddl-auto: none
```

```java
// src/test/.../UserMemoryRepository.java
@Primary
@Profile("none_jpa")
@Repository
public class UserMemoryRepository implements UserRepository{
    // 소스코드
}
```

```java
@ActiveProfiles("none_jpa")
@SpringBootTest
class SomeTest {
    // 소스코드
}
```

# 대역의 관리
## 인자 등 데이터
- `@PostMapping("/order/")` 라는 api가 존재하고 `json`이 `ClientOrderRequest` 객체로 넘어온다고 가정한다.
- Controller에서의 `ClientOrderRequest`를 검증한다. 데이터를 약간 수정하여 `OrderRequest`로 변경 후 Service로 넘긴다. Service가 `OrderRequest`를 조금 변경하여 `Order`로 바꾼다. repository에서 `Order`를 저장한다.
- 이때 각 레이어의 테스트마다 필요로한 데이터는 다음과 같다.
    - Json
    - ClientOrderRequest
    - OrderRequest
    - Order

- Service에서 Order객체를 만들기 위하여 엔티티 그래프가 필요할 수 있다. 그러니까 Orderer로서의 Member를 추출하고, 구매하고자 하는 상품인 Product를 추출해야 한다. 
- 결과적으로 인자로 넘어오는 Order 시리즈 이외에 다른 객체가 필요하다.
    - Member
    - Product

## 의존성을 위한 객체
- 테스트 할 객체를 조립 할 때 필요로 한 의존성 역시 관리를 필요로 한다. 
- 만약 이러한 의존성을 유닛테스트를 통해 조립한다면 매우 큰 일이 된다. 왜냐하면 상위 클래스를 테스트할 때는, 그것의 하위 클래스 전체를 구현해야 하기 때문이다.

```java
public SomeHandlerTest{
    SomeHandler handler;

    @BeforeEach
    void setUp{
        A1Repository a1Repository = new A1RepositoryImpl();
        A2Repository a2Repository = new A2RepositoryImpl();
        B1Repository b1Repository = new B1RepositoryImpl();
        B2Repository b2Repository = new B2RepositoryImpl();
        AService aService = new AService(a1Repository, a2Repository);
        BService bService = new BService(b1Repository, b2Repository);
        handler = new SomeHandler(aService, bService);
    }
}
```

## 대역의 관리
- 데이터나 의존성을 위한 객체는 테스트 코드 전반에서 함께 사용될 가능성이 높다. 이 경우 각각의 테스트 코드마다 구현하기 보다, static method나 field를 만드는 것이 더 효율적이고 분명하다.
- 변수로 사용할 부분에 대해서만 인자로 삽입하도록 하였다. 

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

- 의존성을 위한 객체도 팩토리를 통해 생성 가능하다.
- 단순한 의존성 주입을 넘어서 configuration 역할까지 감당해야 한다면, 테스트코드마다 작성하는 것보다 외부 static method에서 꺼내는 것이 더 낫다.

```java
public class AServiceGenerator{
    public static AService defaultAService(){
        // 구현
    }
}

public class SomeTest{
    SomeHandler handler;
    
    @BeforeEach
    void setUp{
        handler = new SomeHandler(AServiceGenerator.defaultAService(), null);
    }
}
```

- 유닛 테스트의 격리성에 대한 의문은 있다. 유닛 테스트는 분리되어야 하는데, 여러 유닛테스트가 공유하는 문제가 발생해버린다.  한편, 테스트에 사용할 데이터나 의존성이 반복되어 사용되는 것도 사실이다. 중복을 없애는 것 또한 중요한 업무이다. 
- 이러한 문제를 최소화 하기 위하여 나의 경우 대역은 하나의 패키지에 공통 관리하였다. 대체로 "mock" 패키지에서 관리하여 테스트 코드 간 분리하였다.