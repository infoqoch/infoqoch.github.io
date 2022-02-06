---
layout: post
author: infoqoch
title: jpa 지연로딩lazy, 즉시로딩eager, 프록시
categories: [jpa]
tags: [jpa, java]
---

## 즉시로딩과 지연로딩
- JPA나 그것의 구현체는 기본적으로 즉시로딩을 이상적으로 본다. 그러니까 해당 엔티티의 연관관계를 가진 객체가 채워진 형태를 이상적으로 본다.
- 하지만 이 경우 n+1의 문제나 불필요한 데이터의 호출 등을 만들기 때문에, 실무에서는 **무조건 지연로딩**을 사용한다. 
- 즉시로딩의 장점인 데이터의 일괄 호출로 인한 효율은 fetch 나 기타 기법으로 해소 가능하다. 
- 지연로딩은 프록시 기법을 사용하기 때문에 앞서 정리한 jpa 와 프록시와 관련한 블로그를 참고 바란다. 

## 즉시로딩

```java
@Entity
@Setter
@Getter
public class Member {
    @Id
    @GeneratedValue
    private Long id;
    private String name;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "TEAM_ID")
    private Team team;
}

@Entity
@Setter
@Getter
public class Team {
    @Id
    @GeneratedValue
    @Column(name = "TEAM_ID")
    private Long id;
    private String name;
}
```

```java
Team team = new Team();
team.setName("teamA");
em.persist(team);

Member member = new Member();
member.setName("kimA");
member.setTeam(team);
em.persist(member);

em.flush();
em.clear();

final Member findMember = em.find(Member.class, member.getId());

final Team getTeamByMember = findMember.getTeam();
System.out.println("team class : "+getTeamByMember.getClass());
getTeamByMember.getName();

tx.commit();
```

```text
Hibernate: 
    select
        member0_.id as id1_0_0_,
        member0_.name as name2_0_0_,
        member0_.TEAM_ID as team_id3_0_0_,
        team1_.TEAM_ID as team_id1_1_1_,
        team1_.name as name2_1_1_ 
    from
        Member member0_ 
    left outer join
        Team team1_ 
            on member0_.TEAM_ID=team1_.TEAM_ID 
    where
        member0_.id=?
team class : class jpa6_proxy.b_lazy.Team
```

- 즉시로딩으로 호출할 경우 join 을 통해 데이터를 출력한다.
- 그리고 Team의 클래스가 Team임을 확인할 수 있다.


## 즉시로딩의 n+1 문제
- 위와 같이 간단한 경우 특별한 문제를 만들지 않는다.
- 하지만 지연 로딩은 n+1이란 치명적인 문제를 가지고 있다. n+1이란, 의도한 1개의 쿼리와 함께 의도하지 않은 n개의 쿼리가 발생한다는 의미이다. 

```java
Team team = new Team();
team.setName("teamA");
em.persist(team);

Member member = new Member();
member.setName("kimA");
member.setTeam(team);
em.persist(member);

Team team2 = new Team();
team2.setName("teamA");
em.persist(team2);

Member member2 = new Member();
member2.setName("kimA");
member2.setTeam(team2);
em.persist(member2);

em.flush();
em.clear();

em.createQuery("select m from Member m").getResultList();

tx.commit();
```

```sql
Hibernate: 
    /* select
        m 
    from
        Member m */ select
            member0_.id as id1_0_,
            member0_.name as name2_0_,
            member0_.TEAM_ID as team_id3_0_ 
        from
            Member member0_
Hibernate: 
    select
        team0_.TEAM_ID as team_id1_1_0_,
        team0_.name as name2_1_0_ 
    from
        Team team0_ 
    where
        team0_.TEAM_ID=?
Hibernate: 
    select
        team0_.TEAM_ID as team_id1_1_0_,
        team0_.name as name2_1_0_ 
    from
        Team team0_ 
    where
        team0_.TEAM_ID=?
```

- 위의 JPQL의 경우 member 테이블의 모든 데이터를 출력하는 쿼리이다. 이 경우 우리의 기대는 `select * from member` 라는 하나의 쿼리이다. 
- 하지만 의도와 달리 두 번의 select 쿼리를 한 것을 확인할 수 있다. JPA는 먼저 요청한 쿼리 한 번 `select * from member` 을 수행한다. 그리고 Team team 객체를 채워야 함을 확인하고, 그것의 객체의 수만큼 `select * from team where team_id = ? ` 을 쿼리한다. 

## 지연로딩 
- 지연로딩을 세팅하는 방법은 아래와 같이 간단하게 수행한다.

```java
@Entity
@Setter
@Getter
public class Member {
    @Id
    @GeneratedValue
    private Long id;
    private String name;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "TEAM_ID")
    private Team team;
}
```

```java
Team team = new Team();
team.setName("teamA");
em.persist(team);

Member member = new Member();
member.setName("kimA");
member.setTeam(team);
em.persist(member);

em.flush();
em.clear();

final Member findMember = em.find(Member.class, member.getId());

final Team getTeamByMember = findMember.getTeam();
System.out.println("getTeamByMember.getClass() = " + getTeamByMember.getClass());
System.out.println("=== before ===");
getTeamByMember.getName();
System.out.println("=== after ===");
```

```text
getTeamByMember.getClass() = class jpa6_proxy.c_lazy.Team$HibernateProxy$JBUnp834
=== before ===
Hibernate: 
    select
        team0_.TEAM_ID as team_id1_1_0_,
        team0_.name as name2_1_0_ 
    from
        Team team0_ 
    where
        team0_.TEAM_ID=?
=== after ===
```

- 지연로딩으로 할 경우 프록시로 리턴함을 확인할 수 있다. 
- 프록시를 getName()으로 강제초기화 할 때 실제 엔티티 객체를 호출하고 데이터를 출력함을 확인할 수 있다. 

## 정리
- JPA는 이론적으로 지연로딩과 즉시로딩을 해당 객체의 조건에 따라 적절하게 쓰는 것을 의도했다. Member 를 출력할 때 Team 을 사용하는 경우가 80퍼센트 이상이라면, 즉시로딩을 사용하는 것이 좋을테니까. 하지만 실제 하이버네이트는 즉시로딩으로 인한 문제가 매우 많다. 그러므로 **즉시로딩은 사용하면 안된다**. 
- **무조건 지연로딩**을 사용한다.
- 지연로딩의 부족한 부분은 fetch 조인이나 엔티티 그래프 등을 사용한다. 