---
layout: post
author: infoqoch
title: jpa와 jpa를 활용하기 위한 다양한 방법들
categories: [jpa]
tags: [jpa, java]
---

## JPQL
- 테이블이 아닌 객체를 대상으로 검색하는 객체 지향 SQL.
- 단순한 persist 로 해결할 수 없는 복잡한 쿼리를, 직접 SQL을 작성하여 구현. 
- 표준 SQL을 따르며 관련한 문법을 지원. 
- DB마다의 방언으로 자동 번역.
- JPA의 잘 활용하기 위한 가장 기본적인 기술. 

## QueryDSL
- QueryDSL은 일종의 JPQL의 빌더. 
- JPQL의 문법 오류를 QueryDSL로 사용할 경우 컴파일 시점에서 잡아 내기 때문에, QueryDSL를 자주 사용. 
- 다만 QueryDSL을 이해하기 위해서는 JPQL에 대한 깊은 이해가 필요.
- QueryDSL과 JPQL로 사실상 대부분의 문제를 해소할 수 있음.

## JPQL과 QueryDSL로 해소가 안되는 문제는? 네이티브 SQL, JDBC의 직접 사용

### 네이티브 SQL
- JPA는 JPQL로 해결할 수 없는 것에 대하여 네이티브 SQL을 지원함. 
- 엔티티 매니저를 통해 사용할 수 있음. 
- JPQL과 더불어 네이티브SQL은 해당 쿼리를 호출하기 전에 자동으로 flush 기능이 있음.  

```java
Member member1 = new Member();
member1.setName("kim");
em.persist(member1);

Member member2 = new Member();
member2.setName("lee");
em.persist(member2);

// em.flush();
// em.clear();

final List<Member> resultList = em.createNativeQuery("SELECT * FROM MEMBER WHERE NAME = 'kim'", Member.class).getResultList();

System.out.println("size : " + resultList.size());

for (Member member : resultList) {
    System.out.println("member = " + member);
}
```

```sql
Hibernate: 
    /* dynamic native SQL query */ SELECT
        * 
    FROM
        MEMBER 
    WHERE
        NAME = 'kim'
size : 1
member = jpa8_query.a_native.Member@53c6f96d
```

### JDBC, SpringJdbcTemplate 의 사용
- JPQL, 네이티브 sql로 해결할 수 없으면 JDBC나 SpringJdbcTemplate을 사용함. 
- 영속성 컨텍스트로 관리되지 않으므로, flush가 자동적으로 수행되지 않아, 데이터 불일치가 일어날 수 있음.
- 그러므로 JDBC 등을 JPA와 함께 사용할 때는 반드시 강제로 플러시를 해야함.


