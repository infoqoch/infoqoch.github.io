---
layout: post
author: infoqoch
title: spring-data-jpa @EntityGraph, @QueryHints, @Lock
categories: [jpa]
tags: [jap, spring]
---

## spring-data-jpa 에서 제공하는 몇 가지 기능 
- 이번 블로그에서는 몇 가지 기능을 가볍게 정리한다.

## @EntityGraph
- 지연로딩을 join을 통해 xToOne 객체를 불러올 때 유용하게 사용하는 fetch join을 스프링데이터jpa 역시 지원한다.

```java
// 엔티티매니저를 사용한 기존의 fetch join 형태이다.
public List<Member> findMemberFetchJoin(){
    final String query = " " +
            "select m " +
            "from Member m " +
            "join fetch m.team t ";
    return em.createQuery(query, Member.class).getResultList();
}


@Override // 기존에 정의된 메서드에 대해서도 사용 가능하다. 
@EntityGraph(attributePaths = {"team"}) // fetch join을 하고 싶은 객체를 선택한다. 
List<Member> findAll();

@EntityGraph(attributePaths = {"team"})
// @Query("select m from Member m ") // jpql을 직접 짜서 사용할 수도 있다. 
List<Member> findEntityGraphMemberByUsername(String username); // 사용자 메서드에도 가능하다.
```

## @Hint
- sql hint 와 관계 없다.
- Hint는 보통 readonly를 사용하기 위해 사용한다.
- 영속 객체는 메모리를 두 배로 사용한다. 하나는 리턴 값, 하나는 원본 값이다. 두 개를 비교하여 차이를 찾는 과정을 더티체킹이라 하며, 이 과정을 통해 update의 여부를 판단할 수 있기 때문이다.
- jpa hint 기능은 readonly를 강제하여 더티체킹을 막고 메모리를 아낄 수 있다. 
- 다만 대체로 잘 사용하지 않는다. 이러한 문제로 성능 상 문제가 생기면 다른 방향으로 해결하는 것이 더 좋고 빠르다. 

```java
@QueryHints(value = @QueryHint(name ="org.hibernate.readOnly", value="true"))
Member findReadOnlyMemberByUsername(String username);
```


## @Lock
- `select .... for update;` 쿼리를 날린다. 

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
List<Member> findLockByUsername(String username);
```