---
layout: post
author: infoqoch
title: jpa 페치 조인 join fetch
categories: [jpa]
tags: [jpa, java]
---

## fetch join
- jpa 성능 최적화를 위한 매우 중요한 기능.
- sql 기본 문법에는 없는, jpa의 조인 기법.
- 연관된 엔티티와 컬렉션을 한 번에 조회할 수 있음. 즉시 로딩과 유사. 객체 그래프 전체를 한 번에 가져온다.
- 다만, fetch join을 명시하여 한방 쿼리를 날리는 순간을 정할 수 있다는 점이 즉시로딩과의 차이.
- OneToMany를 기준으로 객체를 출력할 때 중복 문제가 발생. distinct 를 사용해야 한다.
- 대부분의 n+1의 문제를 해소한다. (lazy 로딩으로 인한 프록시 셀렉으로부터)


## 요구사항 
- 회원1과 회원2가 팀1 을 바라보고
- 회원3이 팀2를 바라본다.
- 회원4, 팀3는 생략한다.

![](/assets/pasteimage/2022-02-08-jpa-jpql-start-2/2022-02-08-19-48-08.png)

- 공통 코드 
  
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
```

## lazy 로딩
- Member는 Team과의 연관관계를 가지며 페치 전략이 lazy 이다. 
- 그러므로 아래의 쿼리로는 Member만 가져 오며, team은 프록시 상태이다. 
- `member.getTeam().getName()` 의 코드가 동작할 때, 프록시가 엔티티를 호출한다. 

```java
System.out.println("======== lazy 로딩 ===========");

String query = "" +
        " select m " +
        " from Member m ";
final List<Member> resultList0 = em.createQuery(query, Member.class).getResultList();

for (Member member : resultList0) {
    System.out.println("member.getName() = " + member.getName());
    System.out.println("member.getTeam().getName() = " + member.getTeam().getName());
}
```


```sql
======== lazy 로딩 ===========
Hibernate: 
    /*  select
        m  
    from
        Member m  */ select
            member0_.MEMBER_ID as member_i1_2_,
            member0_.age as age2_2_,
            member0_.name as name3_2_,
            member0_.TEAM_ID as team_id5_2_,
            member0_.type as type4_2_ 
        from
            Member member0_
member.getName() = kim -- lazy 로딩
Hibernate: 
    select
        team0_.id as id1_4_0_,
        team0_.name as name2_4_0_ 
    from
        Team team0_ 
    where
        team0_.id=?
member.getTeam().getName() = teamA -- teamA 가 프록시에서 엔티티로
member.getName() = lee
member.getTeam().getName() = teamA -- teamA 가 영속성 컨텍스트에 호출되었으므로 sql을 다시 쿼리하지 않는다. 
member.getName() = choi
Hibernate: 
    select
        team0_.id as id1_4_0_,
        team0_.name as name2_4_0_ 
    from
        Team team0_ 
    where
        team0_.id=?
member.getTeam().getName() = teamB -- teamB 가 프록시에서 엔티티로
```

## lazy 로딩에서 join fetch 로
- join fetch 를 한 방 쿼리로 가져온다.

```java
System.out.println("======== lazy 로딩 -> join fetch  ===========");

String query1 = " " +
        " select m " +
        " from Member m " +
        " join fetch m.team ";
final List<Member> resultList = em.createQuery(query1, Member.class).getResultList();

for (Member member : resultList) {
    System.out.println("member.getName() = " + member.getName());
    System.out.println("member.getTeam().getName() = " + member.getTeam().getName()); // lazy -> 프록시 -> 이때 select
}
```

```sql
======== lazy 로딩 -> join fetch  ===========
Hibernate: 
    /*   select
        m  
    from
        Member m  
    join
        fetch m.team  */ select
            member0_.MEMBER_ID as member_i1_2_0_,
            team1_.id as id1_4_1_,
            member0_.age as age2_2_0_,
            member0_.name as name3_2_0_,
            member0_.TEAM_ID as team_id5_2_0_,
            member0_.type as type4_2_0_,
            team1_.name as name2_4_1_ 
        from
            Member member0_ 
        inner join
            Team team1_ 
                on member0_.TEAM_ID=team1_.id
member.getName() = kim
member.getTeam().getName() = teamA
member.getName() = lee
member.getTeam().getName() = teamA
member.getName() = choi
member.getTeam().getName() = teamB
```

## OneToMany 입장에서의 join fetch, 컬렉션 페치 조인
- Member 입장에서는 레코드가 3개 이므로 특별한 문제가 없다.
- fetch join은 inner join의 성향을 가지고 있으며, Team이 2개더라도 Member에 따른다.
- 그러니까 아래의 쿼리에서는 Team이 두 개밖에 없지만 3개를 출력한다. 

```java
System.out.println("======== OneToMany 입장에서 join fetch  ===========");

String query2 = "" +
        " select t " +
        " from Team t " +
        " join fetch t.members ";
final List<Team> resultList1 = em.createQuery(query2, Team.class).getResultList();
for (Team team : resultList1) {
    System.out.println("team.getName() = " + team.getName());
    System.out.println("team.getMembers().size() = " + team.getMembers().size());
}
```

```sql
======== OneToMany 입장에서 join fetch  ===========
Hibernate: 
    /*  select
        t  
    from
        Team t  
    join
        fetch t.members  */ select
            team0_.id as id1_4_0_,
            members1_.MEMBER_ID as member_i1_2_1_,
            team0_.name as name2_4_0_,
            members1_.age as age2_2_1_,
            members1_.name as name3_2_1_,
            members1_.TEAM_ID as team_id5_2_1_,
            members1_.type as type4_2_1_,
            members1_.TEAM_ID as team_id5_2_0__,
            members1_.MEMBER_ID as member_i1_2_0__ 
        from
            Team team0_ 
        inner join
            Member members1_ 
                on team0_.id=members1_.TEAM_ID
team.getName() = teamA
team.getMembers().size() = 2
team.getName() = teamA
team.getMembers().size() = 2
team.getName() = teamB
team.getMembers().size() = 1
```

- 위의 방식은 Team이 중복된다. 그러니까 List<Team> resultList 를 사용 할 때, index 를 통해 총 3개의 Team 이 있는 것처럼 보이지만 사실은 Team이 3개가 있는 상태이다. JPA는 기본적으로 sql의 결괏값을 기준으로 데이터를 추출한다. 
- 이 때 distinct 를 사용한다. 

## 컬렉션 페치 조인과 distinct
- **distinct**는 sql 기본 문법에서 중복 값을 삭제하는 역할을 하지만 동시에 **중복된 엔티티를 없애는 역할**을 가진다. 

```java
System.out.println("========== 컬렉션 fetch join 과 distinct ==============");
String query3 = "" +
        " select distinct t " +
        " from Team t " +
        " join fetch t.members ";
final List<Team> resultList2 = em.createQuery(query3, Team.class).getResultList();

for (Team team : resultList2) {
    System.out.println("team.getName() = " + team.getName());
    System.out.println("team.getMembers().size() = " + team.getMembers().size());
}
```

```sql
========== 컬렉션 fetch join 과 distinct ==============
Hibernate: 
    /*  select
        distinct t  
    from
        Team t  
    join
        fetch t.members  */ select
            distinct team0_.id as id1_4_0_,
            members1_.MEMBER_ID as member_i1_2_1_,
            team0_.name as name2_4_0_,
            members1_.age as age2_2_1_,
            members1_.name as name3_2_1_,
            members1_.TEAM_ID as team_id5_2_1_,
            members1_.type as type4_2_1_,
            members1_.TEAM_ID as team_id5_2_0__,
            members1_.MEMBER_ID as member_i1_2_0__ 
        from
            Team team0_ 
        inner join
            Member members1_ 
                on team0_.id=members1_.TEAM_ID
team.getName() = teamA
team.getMembers().size() = 2
team.getName() = teamB
team.getMembers().size() = 1
```

## SQL 입장에서의 distinct 
- 한편, SQL 입장에서는 distinct 는 위의 쿼리에서 정상 동작하지 않는다. 아래의 쿼리를 살펴보자.

```sql
select t.*, m.*
from team t
join member  m
on t.id = m.team_id
```

|ID|NAME|MEMBER_ID|AGE|NAME|TYPE|TEAM_ID|
|--|--|--|--|--|--|--|
|1|teamA|2|0|kim|null|1|
|1|teamA|3|0|lee|null|1|
|4|teamB|5|0|choi|null|4|

- 위의 결괏값을 보면 레코드 세 개는 모두 다른 레코드이다. Member를 기준으로 각기 다른 3개의 Member가 있다. Member의 pk는 모두 다르다. 
- 그러므로 의도하는 SQL을 만들면 아래와 같은 형태가 된다.

```
select t.*
from team t
join member  m
on t.id = m.team_id ;
```

- team 의 레코드만 출력할 때 기대하는 결괏값이 생성된다.

```sql
select t.*
from team t
join member  m
on t.id = m.team_id; 
```

|ID|NAME|
|--|--|
|1|teamA|
|1|teamA|
|4|teamB|

- 위의 쿼리에서 distinct 를 사용할 떄, 가장 깔끔한 결괏값이 생성된다.

```sql
select distinct t.*
from team t
join member  m
on t.id = m.team_id ;
```

|ID|NAME|
|--|--|
|1|teamA|
|4|teamB|

- 하지만 JPA의 입장에서는 Team 엔티티가 Member.name, Member,id 를 가진 것이 아니라, List<Member> 필드 혹은 참조변수를 가진 형태이다. 
- 그러므로 sql 상으로 `select m.*, t.*` 을 가지지만 JPA의 패러다임으로는 `select distinct t.*` 형태로 Team 엔티티를 추출하는 형태가 되어야만 한다. 

![](/assets/pasteimage/2022-02-08-jpa-jpql-start-2/2022-02-08-20-44-22.png)


- 마지막으로 team의 값이 중복된다 하더라도, 그것이 새로운 메모리를 할당받는 것은 아니다. 같은 메모리를 가리키는 참조 변수가 여러 개 생긴다. 
- 그러므로 set으로 삽입한 후 사이즈가 2로 나온다. (Team의 equals는 동등비교로  오버라이드 하지 않았다.)

```java
System.out.println("======== OneToMany 입장에서 join fetch  + 메모리가 바라보는 위치는? ===========");

String query4 = "" +
        " select t " +
        " from Team t " +
        " join fetch t.members ";
final List<Team> resultList4 = em.createQuery(query4, Team.class).getResultList();
Set<Team> setTeam = new HashSet<>();
for (Team team : resultList4) {
    setTeam.add(team);
}
System.out.println("setTeam.size() : " + setTeam.size());
```

```sql
======== OneToMany 입장에서 join fetch  + 메모리가 바라보는 위치는? ===========
Hibernate: 
    /*  select
        t  
    from
        Team t  
    join
        fetch t.members  */ select
            team0_.id as id1_4_0_,
            members1_.MEMBER_ID as member_i1_2_1_,
            team0_.name as name2_4_0_,
            members1_.age as age2_2_1_,
            members1_.name as name3_2_1_,
            members1_.TEAM_ID as team_id5_2_1_,
            members1_.type as type4_2_1_,
            members1_.TEAM_ID as team_id5_2_0__,
            members1_.MEMBER_ID as member_i1_2_0__ 
        from
            Team team0_ 
        inner join
            Member members1_ 
                on team0_.id=members1_.TEAM_ID
setTeam.size() : 2
```

## 일반 조인은?
- 일반 조인은 sql에서 작성한 보통의 조인과 동일하다.
- 셀렉트 프로젝션에서 t 만을 대상으로 하였기 때문에 team의 칼럼만 가져온다. join fetch 에서의 t와 그냥 조인의 t는 다르다.
- member의 어떤 데이터도 가져오지 않기 때문에, member의 필드를 꺼내올 때, sql을 한 번 더 문의한다.

```java
System.out.println("======== 일반 조인은? ===========");

String query5 = "" +
        " select t " +
        " from Team t " +
        " join t.members ";
final List<Team> resultList5 = em.createQuery(query5, Team.class).getResultList();
```

```sql
======== 일반 조인은? ===========
Hibernate: 
    /*  select
        t  
    from
        Team t  
    join
        t.members  */ select
            team0_.id as id1_4_,
            team0_.name as name2_4_ 
        from
            Team team0_ 
        inner join
            Member members1_ 
                on team0_.id=members1_.TEAM_ID
```


## fetch 조인의 한계
### 별칭을 줄 수 없다. 별칭을 가능하면 주지 않는다.
- 페치 조인은 별칭을 줄 수 없다. 가능하더라도 해서는 가능해서는 안된다.
- JPA의 패러다임에 맞지 않다. 엔티티의 연관관계 컬렉션은, 객체 그래프를 통하여 완전한 값을 출력하기를 기대한다. 총 10개의 컬렉션이 있는데 별칭을 사용하여 5개만 조회할 경우, 데이터의 정합성 문제가 발생한다. 
- 이 경우 처음부터 연관관계를 가진 객체를 5개를 꺼내오는 형태로 한다.
- fetch join을 별칭을 주는 경우는 여러 개의 객체를 동시에 fetch join 하는 경우에만 사용한다. 

#### 별칭을 준 쿼리
```java
String query1 = " " +
        " select distinct t " +
        " from Team t " +
        " join fetch t.members m" +
        " where m.name = 'choi'";
final List<Team> resultList1 = em.createQuery(query1, Team.class).getResultList();

for (Team team : resultList1) {
    System.out.println("team.getName() = " + team.getName());
    System.out.println("team.getMembers().size() = " + team.getMembers().size());
}
```

#### 필요한 엔티티는 페치조인을 사용하지 말고 직접 가져온다

```java
System.out.println("====== 별칭 보단 해당 데이터를 바로 가져온다.======");
String query2 = " " +
        " select m " +
        " from Member m  " +
        " join m.team t on t.id = 1L " +
        " where m.name = 'choi'";
final List<Member> resultList2 = em.createQuery(query2, Member.class).getResultList();

for (Member member : resultList2) {
    System.out.println("member.getName() = " + member.getName());
}
```

### 둘 이상의 컬렉션을 페치 조인할 수 없다. 조인해서는 안된다. 
- 페치 조인으로 이미 데이터의 뻥튀기 문제가 발생한다. 하나 더 컬렉션이 섞일 경우 뻥튀기가 매우 복잡하게 발생한다. 
- 가능하더라도 해서는 안된다.

### 컬렉션(일대다) 페치조인을 할 경우 페이징 API를 사용할 수 없다. 사용해서는 안된다. 
- OneToMany 의 distinct 와 연관된다. sql의 기준으로 뻥튀기된 데이터를 페이징처리 할 수 없다. 
- 하이버네이트는 메모리를 통해 페이징 처리를 한다. 
- 아래 경고 메시지가 발생한다.
- limit 절이 없다. Team과 관련한 모든 레코드를 출력한다. 

```java
System.out.println("====== 메모리에서 페이징 처리 ======");
String query3 = " " +
        " select distinct t " +
        " from Team t " +
        " join fetch t.members m";
final List<Team> resultList3 =
        em.createQuery(query3, Team.class)
                .setFirstResult(0)
                .setMaxResults(1)
                .getResultList();

for (Team team : resultList3) {
    System.out.println("team.getName() = " + team.getName());
}
```

```sql
====== 메모리에서 페이징 처리 ======
Hibernate: 
    /*   select
        distinct t  
    from
        Team t  
    join
        fetch t.members m */ select
            distinct team0_.id as id1_4_0_,
            members1_.MEMBER_ID as member_i1_2_1_,
            team0_.name as name2_4_0_,
            members1_.age as age2_2_1_,
            members1_.name as name3_2_1_,
            members1_.TEAM_ID as team_id5_2_1_,
            members1_.type as type4_2_1_,
            members1_.TEAM_ID as team_id5_2_0__,
            members1_.MEMBER_ID as member_i1_2_0__ 
        from
            Team team0_ 
        inner join
            Member members1_ 
                on team0_.id=members1_.TEAM_ID
team.getName() = teamA

WARN: HHH000104: firstResult/maxResults specified with collection fetch; applying in memory!
```

- 다대일 ManyToOne 에서는 가능하다.

```java
System.out.println("====== 다대일로 페이징 처리 ======");
String query4 = " " +
        " select m " +
        " from Member m " +
        " join fetch m.team " ;
final List<Member> resultList = em.createQuery(query4, Member.class)
        .setFirstResult(0)
        .setMaxResults(1)
        .getResultList();

```

### 일대다에서 페이징을 할 경우 batch를 사용한다.
- lazy 상태에서 n+1 쿼리가 발생할 경우 batch를 통해 한 번에 묶어서 seelct 한다.
- in 절로 묶어서 조회함을 확인할 수 있다. limit을 기준으로 하지 않고(다대일 기준으로 뻥튀기가 발생하므로), in을 기준으로 2개 가져온다.

```java
// ... 전략
@BatchSize(size = 100)
@OneToMany(mappedBy = "team")
private List<Member> members = new ArrayList<>();
// 후략 ...
```

```java
System.out.println("====== 일대다로 사용해야 할 경우 lazy + batch 로 해결한다. ======");
String query5 = " " +
        " select t " +
        " from Team t ";
final List<Team> resultList5 = em.createQuery(query5, Team.class)
        .setFirstResult(0)
        .setMaxResults(2)
        .getResultList();

for (Team team : resultList5) {
    System.out.println("team.getMembers().size() = " + team.getMembers().size());
}
```

```sql
Hibernate: 
    /*   select
        t  
    from
        Team t  */ select
            team0_.id as id1_4_,
            team0_.name as name2_4_ 
        from
            Team team0_
Hibernate: 
    /* load one-to-many jpa8_query.b_jpql.Team.members */ select
        members0_.TEAM_ID as team_id5_2_1_,
        members0_.MEMBER_ID as member_i1_2_1_,
        members0_.MEMBER_ID as member_i1_2_0_,
        members0_.age as age2_2_0_,
        members0_.name as name3_2_0_,
        members0_.TEAM_ID as team_id5_2_0_,
        members0_.type as type4_2_0_ 
    from
        Member members0_ 
    where
        members0_.TEAM_ID in (
            ?, ?
        )
team.getMembers().size() = 2
team.getMembers().size() = 1
```

## fetch join 정리
- 연관된 엔티티를 SQL 한 방으로 해결한다. 성능 최적화. 
- 엔티티에 직접 적용하는 글로벌 로딩 전략보다 우선한다. 
- **페치 조인은 객체 그래프를 유지할 때 효과적**. 
- 엔티티를 유지하지 않는 데이터를 필요로 할 경우, DTO로 반환하는 것이 효과적. 
  - 1) 엔티티를 유지한다.
  - 2) 엔티티를 추출하여 자바에서 DTO를 생성한다.
  - 3) JPA 차원에서 DTO를 출력한다. 
