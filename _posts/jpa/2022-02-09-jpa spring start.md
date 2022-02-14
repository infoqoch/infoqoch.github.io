---
layout: post
author: infoqoch
title: jpa 스프링으로 시작하기
categories: [jpa]
tags: [jpa, spring]
---

## 스프링과 JPA
- 스프링이 다른 라이브러리를 쉽게 개발하도록 보조하듯, JPA 역시 상당 부분 자동 세팅을 한다.

## 의존성 및 설정
- 현재 환경은 spring boot, gradle, h2 이다.
- `spring-boot-starter-data-jpa` 을 사용한다. 
- JPA는 기본적으로 로깅 기능을 제공한다. 더 좋은 로깅을 위하여 `p6spy-spring-boot-starter` 을 사용한다.
- 데이타베이스는 `com.h2database:h2`을 사용한다. 
  
```groovy
plugins {
    id 'org.springframework.boot' version '2.6.3'
    id 'io.spring.dependency-management' version '1.0.11.RELEASE'
    id 'java'
}

group = 'qoch'
version = '0.0.1-SNAPSHOT'
sourceCompatibility = '11'

repositories {
    mavenCentral()
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    implementation 'org.springframework.boot:spring-boot-starter-thymeleaf'
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation('org.springframework.boot:spring-boot-devtools')
    implementation('com.github.gavlyukovskiy:p6spy-spring-boot-starter:1.8.0')
    compileOnly 'org.projectlombok:lombok'
    runtimeOnly 'com.h2database:h2'
    annotationProcessor 'org.projectlombok:lombok'
    implementation 'org.springframework.boot:spring-boot-starter'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}

tasks.named('test') {
    useJUnitPlatform()
}
```

- applictaion.yml 을 설정한다.

```yml
spring:
  datasource:
    url: jdbc:h2:tcp://localhost/~/jpashop
    username: sa
    password:
    driver-class-name: org.h2.Driver

  jpa:
    hibernate:
      ddl-auto: create
    properties:
      hibernate:
        # show_sql: true # -> system.out
        format_sql: true # -> log

logging.level:
  org.hibernate.SQL: debug # SQL 전체.
  org.hibernate.type: trace # SQL의 파라미터의 값

# p6spy-spring-boot-starter 는 의존성을 주입할 경우 프로퍼티 설정없이 자동적으로 적용 된다. 

```

## 코드 작성
- 영속성 컨텍스트를 가지고 온다.

```java
@Entity
@Getter
@Setter
public class Member {
    @Id
    @GeneratedValue
    private Long id;

    private String userName;
}

@Repository
public class MemberRepository {

    @PersistenceContext
    private EntityManager em;

    // 커맨드와 쿼리를 분리해라.
    // 사이드 이펙트가 있을 수 있으므로 insert의 경우 id 정도만 리턴한다.
    public Long save(Member member){
        em.persist(member);
        return member.getId();
    }

    public Member find(Long id){
        return em.find(Member.class, id);
    }
}

```

- 테스트 및 수행한다.
- 트랜잭션으로 엔티티매니저가 동작한다. 반드시 @Transaction을 선언해야 한다. 
- 리포지토리에서 em.persist로 영속화한 객체와 em.find로 찾은 객체의 동일성 비교가 true로 나온다. 실제로 find 할 때, select 쿼리가 발생하지 않았다. 

```java
@SpringBootTest
// 엔티티매니저는 트랜잭션이 없으면 동작하지 않는다.
// Transactional은 자바 표준이 아닌 스프링 사용
@Transactional 
class MemberRepositoryTest {

    @Autowired
    MemberRepository memberRepository;

    @Test
    void test(){
        //given
        Member member = new Member();
        member.setUserName("memberA");

        //when
        final Long memberId = memberRepository.save(member);

        final Member findMember = memberRepository.find(memberId);

        //then
        Assertions.assertThat(member).isEqualTo(findMember); // 동등성 비교. 같은 엔티티임.
    }
}
```

- persist에서 insert 쿼리가 발생하고, find 때 select 쿼리가 발생하지 않음.
- repository로 값이 리턴된다 하더라도, Transaction으로 묶여 있으면, 같은 영속성 컨텍스트임을 알 수 있다. 

## 영속성 컨텍스트의 초기화

```java
final Long memberId = memberRepository.save(member);

// 영속성 컨텍스트의 초기화
em.flush(); // commit이 동작한다.
em.clear(); // 영속성 컨텍스트를 초기화 한다.

final Member findMember = memberRepository.find(memberId);
```

- 만약 위와 같이 수행할 경우 flush 할 때 insert 쿼리가 발생함을 확인할 수 있다. 
- 동일한 영속성 컨텍스트 내부에서 insert는 트랜잭션이 종료하는 커밋 시점에서 진행된다. 이 말은, 하나의 트랜잭션에서 insert(persist)를 하고 select(find)한 객체는, db에 아예 들어가지도 않는, 영속성 컨텍스트 내부의 자바 메모리라는 의미이다. 그리고 rollback이 자동으로 수행되기 때문에, insert 자체를 수행할 일이 없다. 
- 그러므로 영속성 컨텍스트를 초기화하는 방식과 더불어, @Rollback(falue)를 하더라도 insert 쿼리가 발생함을 확인할 수 있다. 왜냐하면 commit을 날리기 때문이다. 


## JPA 사용의 주의점
### setter를 사용하지 않는다. 
- mybatis의 경우 query를 생성하기 전까지는 DB가 변경되지 않는다. 
- jpa는 영속 상태의 객체를 setter로의 변경하면 데이터가 바뀐다. setter를 사용하지 않고 별도의 매서드를 사용한다. 

### 연관관계를 설정 할 떄 패치 전략을 lazy로 한다.
- 필요시 fetch join 을 사용한다. 

### 컬렉션은 필드에서 초기화 한다. 
- 널포인트예외로부터 안전하다. 
- 하이버네이트는 영속성 컨텍스트 동작 과정에서 엔티티 컬렉션에 대하여 상속 및 주입한다. 그러니까 클래스 자체가 변경된다. 초기화 되지 않은 컬렉션 필드는 영속성 컨텍스트에 종속된 소스블럭에서 초기화 및 사용할 가능성이 있다. 이러한 가능성을 원천적으로 차단한다. 

```java
Member member = new Member();
System.out.println(member.getOrders().getC lass());
em.persist(team);
System.out.println(member.getOrders().getClass());
//출력 결과
class java.util.ArrayList
class org.hibernate.collection.internal.PersistentBag
```

### 스프링의 테이블, 컬럼명 생성 전략
- `SpringPhysicalNamingStrategy` 전략에 따른다. 
- 카멜케이스(자바) -> 언더스코어(sql) 전략을 사용한다. 

### 연관관계 편의 메서드를 사용한다.
- 양방향을 사용할 경우, 영속성 컨텍스트가 자바 - DB간 패러다임의 불일치가 일어난다. 
- 연관관계 주인만 대상 엔티티에 대한 데이터를 가져도 대상 엔티티의 데이터가 영속화 된다. 자바 객체의 측면에서는 대상 엔티티의 주인 필드의 데이터가 채워져 있지 않다. 엔티티와 자바 객체 간 격차를 없애기 위하여 연관관계 편의 메서드를 사용한다. 
- 테스트 코드 작성에도 유리하다.

```java
public void setMember(Member member){
        this.member = member;
        member.getOrders().add(this);
    }
```

### @Transactional(readOnly = true)
- 트랜잭션이 있어야 영속성 컨텍스트를 사용할 수 있으며, DB와 통신 가능하다. 
- 트랜잭션을 열어 놓으면 setter만으로 데이타가 변경된다. 이러한 위험을 보호하기 위하여, 서비스 레이어는 readonly를 한다. 
- 실제 데이터를 변경할 메서드에만 @Transaction 을 붙인다.