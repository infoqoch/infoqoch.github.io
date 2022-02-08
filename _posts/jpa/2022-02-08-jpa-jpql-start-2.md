---
layout: post
author: infoqoch
title: jpa, jpql 의 기초 2
categories: [jpa]
tags: [jpa, java]
---

## 경로 표현식과 묵시적 조인
- .을 찍어 객체 그래프를 탐색하기

```java
String query1 = "" +
        "select " +
        "   m.name " +
        "from Member m " +
        "join Team t " +
        "on m.team.id = t.id " +
        "where m.name = 'kim' ";
final String singleResult = em.createQuery(query1, String.class).getSingleResult();

System.out.println("singleResult = " + singleResult);
```

- 경로표현식으로 출력할 수 있는 값은 상태 필드와 연관 필드이다.
- 상태 필드는 해당 엔티티의 칼럼을 의미하여, 연관필드는 연관관계로 묶인 엔티티를 의미하며, 단일값(XToOne)과 컬렉션 값(XToMany)로 이뤄져 있다. 
- 경로표현식으로 연관필드를 추출 할 경우 join절을 사용하며, join을 생략할 경우 자동으로 생성한다. 이를 묵시적 조인이라 한다. 

### 단일 엔티티 타입

- 경로표현식으로 연관관계를 가져올 경우 아래와 같은 형태로 진행된다. 

```java
String query2 = " " +
        " select m.team.name" +
        " from Member m";
final List<String> resultList = em.createQuery(query2, String.class).getResultList();

for (String s : resultList) {
    System.out.println("s = " + s);
}
```

```sql
Hibernate: 
    /*   select
        m.team.name 
    from
        Member m */ select
            team1_.name as col_0_0_ 
        from
            Member member0_ cross 
        join
            Team team1_ 
        where
            member0_.TEAM_ID=team1_.id
s = teamA
s = teamA
```

- 위의 쿼리는 JOIN이 없지만 자동적으로 JOIN이 생성된다.
- sql 입장에서는 member로부터 team을 가져오기 때문에 join을 하는 것이 당연하다. 더 나아가 member로부터 team을 추출하기 때문에, member를 추출하여 team_id를 추출하고, team_id로 team을 두 번 쿼리를 날릴 이유가 없다. 그런 측면에서 합리적인 쿼리로 볼 수 있다.
- 하지만 1) 작성한 sql과 동작하는 sql이 다를 경우 혼란을 초래할 수 있으며, 2) 직접 join을 튜닝하여 성능상 이점을 챙길 수 있기 때문에, **묵시적 조인은 사용하지 않는다**. 
- 아래의 코드를 통해 명시적으로 join을 사용한다. 

```java
String query3 = " " +
        " select m.team.name" +
        " from Member m" +
        " join m.team ";
em.createQuery(query3, String.class).getResultList();
```

### 컬렉션 엔티티 타입
- 컬렉션 값의 경우 객체 그래프를 사용할 수 없다. 
- 단일 엔티티 연관 필드와 마찬가지로 묵시적 조인을 사용한다. 

```java
String query4 = "" +
        " select t.members " +
        " from Team t ";
final List<Collection> resultList1 = em.createQuery(query4, Collection.class).getResultList();
```

```sql
select
            members1_.MEMBER_ID as member_i1_2_,
            members1_.age as age2_2_,
            members1_.name as name3_2_,
            members1_.TEAM_ID as team_id5_2_,
            members1_.type as type4_2_ 
        from
            Team team0_ 
        inner join
            Member members1_ 
                on team0_.id=members1_.TEAM_ID
```

- 명시적 조인을 사용한다.
- 별칭(t.member 의 m)으로 객체그래프를 사용하는 것이 유리하다. 

```java
String query5 = "" +
        " select m.name " +
        " from Team t " +
        " join t.members m ";
final List<String> resultList2 = em.createQuery(query5, String.class).getResultList();

for (String s : resultList2) {
    System.out.println("s = " + s);
}
```

### 객체그래프 사용시 명시적 조인을 사용한다.
- 결론적으로 **묵시적 조인을 사용해선 안된다**.
- 명시적 조인을 통한 별칭으로 객체 그래프를 들어가는 것이 훨씬 효과적이다.

```sql
select o.member.team from Order o -- order의 member 의 tema을 사용한다. join이 두 번 이뤄지는 복잡한 쿼리가 발생한다. 
select t.members from Team -- 묵시적 조인이 발생한다. 
select t.members.username from Team t -- 컬렉션 엔티티 필드는 select에서 객체그래프를 사용할 수 없다.
select m.username from Team t join t.members m -- 객체의 컬렉션 엔티티 필드를 join으로 하여 그것의 별칭을 두면, 객체그래프를 사용 가능하다. 
```

## Type, Treat
- 상속(Inheritance)를 한 경우 사용한다. 
- 부모타입의 엔티티를 조회할 때 자식타입에 대한 조작을 할 때 사용한다. 
- Item 은 부모 타입이고 Book, Movie 는 자식 타입이다.

```sql
select i from Item i where type(i) in (Book, Movie);

select i from Item i where treat(i as Book).author = 'kim';
```  

## 엔티티의 직접 사용 (기본키)
- jpql 은 엔티티로 비교를 하지만 동시에 pk, fk로 조회 할 수 있다.
- sql로 출력될 때는 pk 나 fk 를 사용한다.


```java
Team team1 = new Team();
team1.setName("teamA");
em.persist(team1);

Member member1 = new Member();
member1.setName("kim");
member1.changeTeam(team1);
em.persist(member1);

Member member2 = new Member();
member2.setName("lee");
member2.changeTeam(team1);
em.persist(member2);

Team team2 = new Team();
team2.setName("teamB");
em.persist(team2);

Member member3 = new Member();
member3.setName("choi");
member3.setTeam(team2);
em.persist(member3);

em.flush();
em.clear();

System.out.println("========== count(엔티티) ============");

String query1 = " " +
        " select count(m) " +
        " from Member m ";
final Long result1 = em.createQuery(query1, Long.class).getSingleResult();

System.out.println("result1 = " + result1);

em.flush();
em.clear();

System.out.println("========== count(pk) ============");

String query2 = " " +
        " select count(m.id) " +
        " from Member m ";
final Long result2 = em.createQuery(query2, Long.class).getSingleResult();

System.out.println("result1 = " + result2);

em.flush();
em.clear();

System.out.println("========== where m =: entity ============");

String query3 = " " +
        " select m " +
        " from Member m " +
        " where m =: memberEntity ";
final List<Member> resultList3 = em
        .createQuery(query3, Member.class)
        .setParameter("memberEntity", member1)
        .getResultList();

for (Member member : resultList3) {
    System.out.println("member.getName() = " + member.getName());
}

em.flush();
em.clear();

System.out.println("========== where m.id =: Long ============");

String query4 = " " +
        " select m " +
        " from Member m " +
        " where m.id =: memberId ";
final List<Member> resultList4 = em
        .createQuery(query4, Member.class)
        .setParameter("memberId", member1.getId())
        .getResultList();

for (Member member : resultList4) {
    System.out.println("member.getName() = " + member.getName());
}

em.flush();
em.clear();

tx.commit();
```

## named 쿼리
- 미리 정의해서 이름을 부여하고 사용하는 JPQL
- 정적 쿼리
- 어노테이션, XML에 정의
  - XML이 우선. 운영 환경에 따른 쿼리 사용
- **어플리케이션 로딩 시점에 초기화 후 재사용**
  - sql 을 로딩 시점에서 생성하기 때문에 성능 이점 발생
- **어플리케이션 로딩 시점에 쿼리를 검증**
  - 가장 좋은 에러 : 컴파일 에러
  - 중간 정도 좋은 에러 : 어플리케이션 로딩 시점에서의 런타임 에러 ✔✔
  - 가장 나쁜 에러 : 클라이언트가 클릭 했을 때 발생하는 런타임 에러
- Spring data jpa 의 기반 기술. spring-data-jpa -> @Query -> named query -> jpql 로의 변환.
- 다만 Member entity 에 NamedQuery를 사용하는 것은 비추. 너무 복잡해지니까. Spring data jpa를 잘 쓰자.

```java
// ... 전략 
@NamedQuery(
        name = "Member.findByName"
        , query = "select m from Member m where m.name = :name "
)
public class Member {
// 후략 ...
```

```java
final List<Member> resultList = em.createNamedQuery("Member.findByName", Member.class)
        .setParameter("name", "lee")
        .getResultList();
```


## 벌크 연산
- insert update 를 한 번에 수행함.
- 기본적으로 엔티티매니저는 하나의 객체를 영속화 하는 방식(em.persist())이며, jpa는 단건을 조작하는데 특화되어 있음. 
- 벌크연산은 영속성 컨텍스트를 무시하고 데이터베이스에 직접 쿼리.
  - DB에는 변경되었으나 자바 객체는 동기화되지 않을 수 있음. 
    - 양방향 연관관계에서는 양방향 객체의 엔티티 필드를 동시에 변경하는 메서드로 처리. 벌크 연산은 이러한 과정이 어려움.
    - 벌크연산의 경우, 트랜잭션에서 가장 먼저 실행. 이로 인하여 다른 엔티티를 불러 올 때 해당 벌크가 적용되도록 함. 
    - 해당 엔티티를 강제로 초기화하거나, 영속성 컨텍스트를 초기화한다. 


```java
Member member1 = new Member();
member1.setName("kim");
member1.setAge(13);
em.persist(member1);

Member member2 = new Member();
member2.setName("lee");
member2.setAge(50);
em.persist(member2);

// 벌크연산 전에 FLUSH는 자동으로 진행함.
final int resultCount = em.createQuery("update Member m set m.age = 10")
        .executeUpdate();
System.out.println("resultCount = " + resultCount);

System.out.println("==== 영속성 컨텍스트를 초기화하지 않음 === ");
System.out.println("member1.getAge() = " + member1.getAge()
);

em.clear(); // 영속성 컨텍스트를 초기화 한다.

System.out.println("==== 영속성 컨텍스트를 초기화 함 ==== ");

final Member findMember = em.find(Member.class, member1.getId()); // 준영속 상태이므로 더는 1차 캐시에서 데이터를 출력할 수 없다. em.find()를 통해 DB로부터 초기화한다.
System.out.println("findMember.getAge() = " + findMember.getAge());
```

```sql
Hibernate: 
    /* update
        Member m 
    set
        m.age = 10 */ update
            Member 
        set
            age=10
resultCount = 2
==== 영속성 컨텍스트를 초기화하지 않음 === 
member1.getAge() = 13
==== 영속성 컨텍스트를 초기화 함 ==== 
Hibernate: 
    select
        member0_.MEMBER_ID as member_i1_2_0_,
        member0_.age as age2_2_0_,
        member0_.name as name3_2_0_,
        member0_.TEAM_ID as team_id5_2_0_,
        member0_.type as type4_2_0_ 
    from
        Member member0_ 
    where
        member0_.MEMBER_ID=?
findMember.getAge() = 10
```

- 스프링 데이터 jpa의 경우 벌크연산인 @Modifying 이 있다. 이 경우 영속성 컨텍스트의 clear 를 자동수행하는 기능이 true 로 기본값이 세팅되어 있다. 