---
layout: post
author: infoqoch
title: jpa, spring-data-jpa 시작하기, 메서드 구현
categories: [jpa]
tags: [jpa, spring]
---

## Spring-data-jpa 란?
- spring-data-jpa 는 스프링을 아주 편리하게 사용하도록 도와주는 라이브러리이다.
- 반복되는 공통 매서드를 미리 구현했다. spring-data의 인터페이스를 상속한다. 

### 사용법

```java
public interface MemberRepository extends JpaRepository<Member, Long> {

}
```

- JpaRepository 상속받은 interface로 구현한다. 
- @Repository 혹은 컴퍼넌트로의 선언이 필요 없다. 해당 인터페이스는 jpa가 자동으로 감지하여 구현한다. 

![](/assets/pasteimage/2022-02-15-jpa%20spring-data-jpa%20start/2022-02-15-21-25-39.png)


## 공통 인터페이스의 적용
- JpaRepository는 `org.springframework.data.jpa.repository`을 패키지로 한다. 
- JpaRepository가 상속하는 인터페이스 PagingAndSortingRepository, Repository 등은 `org.springframework.data.repository` 을 패키지로 한다. 
- spring-data-jpa 는 spring-data 을 상속한다. 해당 인터페이스를 구현한 라이브러리 중 하나가 spring-data-jpa 이다.
- spring-data를 상속하는 기능 간 기능과 사용법이 예측 가능하다는 장점이 있다. 

![](/assets/pasteimage/2022-02-15-jpa%20spring-data-jpa%20start/2022-02-15-21-34-53.png)

## 공통 언티페이스를 넘어서
- spring-data는 스펙으로 find, findAll, save, delete 등을 설정하였다. jpa는 이를 구현하였고, interface에 구현 없이 사용 가능하다.

```java
public interface MemberRepository extends JpaRepository<Member, Long> {
    // List<Member> findAllById(Long memberId); 
    // 메서드 없이 동작한다. 왜냐하면 부모 인터페이스에서 이미 해당 기능을 구현했기 때문이다. 
```

```java
public interface JpaRepository<T, ID> extends PagingAndSortingRepository<T, ID>, QueryByExampleExecutor<T> {
    // 중략
    
    @Override
    List<T> findAllById(Iterable<ID> ids);

    // 중략
}
```

- 만약, spring-data-jpa 에서 이미 스펙으로 선언한 메서드 이외에 다른 메서드를 사용하고 싶으면 어떠한가? `findByUsername(String name)`
- 도메인에 특화된 메서드을 스펙을 통해 정의하기에는 다소 어폐가 있다. 도메인에 특화되었다고 하여 이러한 메서드를 모두 직접 jpql로 구현해야 하는가?

```java
public List<Member> findByUsernameAndAgeGreaterThan(String username, int age){
    return em.createQuery("select m from Member m where m.username = :username and m.age > :age", Member.class)
            .setParameter("username", username)
            .setParameter("age", age)
            .getResultList();
}
```

- spring-data-jpa는 이에 대한 세 가지 대안을 제공한다. 쿼리 메서드, 네임드 메서드, 인터페이스 메서드. 

## 쿼리 메서드 
- 필드의 이름을 메서드의 이름으로 조합하여 쿼리를 생성한다. 

```java
public interface MemberRepository extends JpaRepository<Member, Long> {
    List<Member> findMemberByUsernameAndAgeGreaterThan(String username, int age);
}
```

- https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.query-methods.query-creation
- {명령}...by...by 의 형태의 문법을 가진다. 
- find / count / exsist / delete / remove / distinct / limit 등을 제공한다. 
- 간단하고 짧은 쿼리에 대해서 자주 사용한다.
- 이름이 너무 길어지는 단점이 있다. 
- 필드명이 변경될 경우 매서드 이름도 변경해야 한다. 매서드명이 잘못되더라도 이 에러는 어플리케이션 로딩 시점에서 잡아준다. 

## NamedQuery
### 코드
- 쿼리를 작성한 다음, 해당 쿼리의 명칭으로 sql을 검색, 사용한다. 

- 엔티티

```java
@NamedQuery(
        name="Member.findByUsername",
        query="select m from Member m where m.username = :username"
)
public class Member {
    // 후략
}
```

- 구현

```java
public List<Member> findByUsername(String username){
    return em.createNamedQuery("Member.findByUsername", Member.class)
            .setParameter("username", username)
            .getResultList();
}
```

### 설명 
- 엔티티로 구현하거나, xml을 통해 외부에서 구현할 수도 있다.
- 네임드쿼리의 역시 sql 쿼리의 오류를 어플리케이션 로딩 시점에서 찾아준다.
- 다만, 인터페이스 메서드가 더 편리하고 유연하기 때문에 자주 사용하지 않는다. 

## @Query, 리포지토리에서 메서드 바로 정의하기
- 쿼리를 직접 짜고 싶은 경우가 있다. 이를 구현체로 구현하지 않는다(만약 그러면 모든 인터페이스의 매서드를 구현해야 한다). @Query 어너테이션을 통해 jpql로 쿼리를 작성한다. 
- jpql로 유연하게 쿼리를 짤 수 있어서 편하다. 
- 어플리케이션 로딩 시점에서 쿼리의 오류를 잡아준다. 

```java
public interface MemberRepository extends JpaRepository<Member, Long> {
    
    // entity로 리턴
    @Query("select m.username from Member m")
    List<String> findUsernameList();

    // 인자는 @Param으로 한다. 
    @Query("select m from Member m where m.username = :username and m.age > :age")
    List<Member> findUser(@Param("username") String username, @Param("age") int age);

    // dto로 반환할 수 있다. 
    @Query("select new qoch.datajpa.dto.MemberDto(m) from Member m")
    List<MemberDto> findMemberDto();

    // 인자를 collect 형태로 할 수 있다. 
    @Query("select new qoch.datajpa.dto.MemberDto(m) from Member m where m.username in :names")
    List<MemberDto> findMemberDto(@Param("names") List<String> names);

}
```

