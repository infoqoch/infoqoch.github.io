---
layout: post
author: infoqoch
title: spring-data-jpa 사용자 정의 리포지토리
categories: [jpa]
tags: [jpa, spring]
---

## 매서드를 정의하여 사용할 수 없을까?
- JpaRepository를 상속받은 인터페이스는 메서드에 어너테이션을 기반으로 정의해야 한다. 해당 인터페이스를 구현하여 Override 할 수 없다. 
- 하지만 필요에 따라 특정 매서드는 구체적으로 구현해야할 필요가 있다. 동시에 스프링 데이타 jpa의 기능을 함께 사용하고 싶을 수 있다. 
- 이러한 것에 대하여 스프링 데이터 jpa는 지원한다. 

## 사용자 정의 리포지토리 구현 
- 인터페이스의 다중 상속 기능을 통해, JpaRepository와 사용자 정의 리포지토리를 동시에 상속(extends) 한다. 
- 사용자 정의 리포지토리는 인터페이스와 구현 클래스로 이뤄져야 한다. 인터페이스는 어떤 명칭을 사용해도 상관 없다. 하지만 구현 클래스의 명칭은 반드시 다음과 같아야 한다.
    - MemberRepository로 하여금 상속시키려면 MemberRepositoryImpl 라고 명명해야 한다. 이러한 규칙을 변경할 수 있지만 기본값은 {이름} + Impl 이다. 
- 구현 클래스에는 컴퍼넌트 등으로 빈을 등록할 필요가 없다. 자동으로 등록한다.
- 구현 클래스는 원하는 라이브러리를 사용 가능하다. 마이바티스, jdbc template, query dsl 등. 대체로 QueryDsl 을 자주 사용한다. 

- 인터페이스

```java
public interface MemberRepositoryCustom {
    List<Member> findMemberCustom();
}
```

- 구현 클래스

```java
@RequiredArgsConstructor
public class MemberRepositoryImpl implements MemberRepositoryCustom{

    private final EntityManager em;

    // 인터페이스의 내용을 구현한다.
    // 아래는 jpa, jpql로 구현하였다.
    // jdbc, querydsl, myabits 등 원하는 것으로 구현하면 된다. 
    @Override
    public List<Member> findMemberCustom() {
        return em.createQuery("select m from Member m").getResultList();
    }
}
```

- 스프링 데이터 jpa 인터페이스

```java
public interface MemberRepository
        extends
        JpaRepository<Member, Long>,
        MemberRepositoryCustom // 사용자 정의 리포지토리의 인터페이스이다. 인터페이스의 명칭은 어떻게 해도 상관 없다. 
{
    // 중략
}
```

## 커맨드와 쿼리의 분리에 대하여
- Spring-data-jpa 의 인터페이스 기능이 막강하다. 하지만 기능이 막강하다고 하여 해당 클래스에 수많은 매서드가 엉키게 되고, 그리고 사용자 정의 리포지토리까지 섞이게 되면, 매우 복잡해진다. 
- 핵심 비지니스로직과 프레젠테이션에 종속되는 쿼리는 분리되어야 한다. 사용자 정의 리포지토리를 사용하게 되면 이러한 것들이 섞이기 십상이다. 
- 한편, 사용자 정의 리포지토리를 사용하게 될 상황이라면 대체로 복잡한 쿼리로서 프레젠테이션에 종속되는 쿼리일 가능성이 높다. 그러므로 해당 기능을 사용할 때면, 리포지토리를 분리하는 것에 고민할 때일 수도 있다. 


