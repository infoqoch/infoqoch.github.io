---
layout: post
author: infoqoch
title: jpa 연관관계 매핑
categories: [jpa]
tags: [jpa, java]
---

## DB와 객체지향 개발과의 차이, 외래키와 참조
- 객체형 데이타베이스에서 연관된 레코드를 검색할 때 외래 키로 조회한다. 객체지향적 프로그래밍에서 객체는 참조를 통해 조회한다. 두 개의 간격을 해소해야 한다.
- 필드에 외래키를 가지는 `Long teamId` 형태의 데이타 중심의 개발로부터, `Team team`으로의 객체 지향적 개발로 전환한다.
- 이러한 격차의 해소가 JPA의 중요한 문제 중 하나이다.

## 단방향 연관관계와 외래키의 참조
- JPA는 이러한 문제에 대하여 연관관계를 통해 해소한다. 
- Team team 을 가진 객체Member가, 영속화된 team을 주입하고, member를 영속화할 경우, jpa는 이를 자동으로 RDB에 맞춰서 sql을 생성한다.

```java
@Entity
@Setter
@Getter
public class MemberV2 {
    @Id
    @GeneratedValue
    private Long id;
    @Column(name = "USERNAME")
    private String name;

//    더 이상 외래키를 받지 않는다.
//    @Column(name = "TEAM_ID") 
//    private Long teamId; // 

//    객체를 받는다.
    @ManyToOne // Player 입장에서 다수이다.
    @JoinColumn(name ="TEAM_ID")
    private TeamV2 team;
}

@Entity
@Getter
@Setter
public class TeamV2 {
    @Id
    @GeneratedValue
    @Column(name = "TEAM_ID")
    private Long id;
    private String name;

}
```

- 아래와 같은 형태로 단반향 연관관계를 형성한다.

```java
TeamV2 team = new TeamV2();
team.setName("teamA");
em.persist(team);

MemberV2 member = new MemberV2();
member.setName("memberA");
member.setTeam(team);

em.persist(member);
```

- 위와 같이 영속성을 구현하면, 아래와 같이 쿼리가 생성된다.

```sql
Hibernate: 
    /* insert hellojpa3_entities_mapping.b.TeamV2
        */ insert 
        into
            TeamV2
            (name, TEAM_ID) 
        values
            (?, ?)
Hibernate: 
    /* insert hellojpa3_entities_mapping.b.MemberV2
        */ insert 
        into
            MemberV2
            (USERNAME, TEAM_ID, id) 
        values
            (?, ?, ?)
```

- 객체 그래프를 통하여 아래와 같이 데이터를 추출하면 쿼리는 아래와 같이 생성된다.

```java
final MemberV2 findMember = em.find(MemberV2.class, member.getId());
```

```sql
Hibernate: 
    select
        memberv2x0_.id as id1_0_0_,
        memberv2x0_.USERNAME as username2_0_0_,
        memberv2x0_.TEAM_ID as team_id3_0_0_,
        teamv2x1_.TEAM_ID as team_id1_1_1_,
        teamv2x1_.name as name2_1_1_ 
    from
        MemberV2 memberv2x0_ 
    left outer join
        TeamV2 teamv2x1_ 
            on memberv2x0_.TEAM_ID=teamv2x1_.TEAM_ID 
    where
        memberv2x0_.id=?
```

- 이러한 구현을 통하여 우리는 `Long teamId` 로부터 `Team team`이라는 객체를 엔티티로부터 즉각적으로 받아올 수 있게 된다. 
- 이러한 구현을 위해서는 연관관계의 주인(insert, update, delete 등 데이타를 조작하는 주체)를 설정해야 한다. `@ManyToOne`, `@JoinColumn(name ="TEAM_ID")` 등을 통하여 연관관계의 주인임을 설정한다. 
- 현재 코드는 Member가 연관관계의 주인임을 보여준다. 

## 누가 연관관계의 주인이 되는가?
- 위의 코드에서 연관관계의 주인은 Member가 된다. 왜냐하면 Member 가 team 객체를 필드로 가지고, 이를 기준으로 sql을 생성하기 때문이다. 
- 그런데 Team 이 member를 가지고 싶을 수도 있다. Member보다 Team이 중요한 코드가 존재할 수 있기 때문이다. 이를 구현한 코드는 아래와 같다. 
- List<Member>의 경우 초기화를 해야 한다. 

```java
@Entity
@Setter
@Getter
public class MemberV21 {
    @Id
    @GeneratedValue
    private Long id;
    @Column(name = "USERNAME")
    private String name;

}

@Entity
@Getter
@Setter
public class TeamV21 {
    @Id
    @GeneratedValue
    @Column(name = "TEAM_ID")
    private Long id;
    private String name;

    @OneToMany // 연관관계의 주인임을 설정한다.
    @JoinColumn
    private List<MemberV21> members = new ArrayList<>();
}
```

- 위의 코드로 영속화 하면 아래와 같은 코드와 쿼리가 생성된다.

```java
MemberV21 member = new MemberV21();
member.setName("memberA");
em.persist(member);

TeamV21 team = new TeamV21();
team.setName("teamA");
team.getMembers().add(member);
em.persist(team);

em.flush();
em.clear();

final TeamV21 teamV21 = em.find(TeamV21.class, member.getId());
```

```sql
Hibernate: 
    /* insert hellojpa3_entities_mapping.b_oneway.bb_fk_not.MemberV21
        */ insert 
        into
            MemberV21
            (USERNAME, id) 
        values
            (?, ?)
Hibernate: 
    /* insert hellojpa3_entities_mapping.b_oneway.bb_fk_not.TeamV21
        */ insert 
        into
            TeamV21
            (name, TEAM_ID) 
        values
            (?, ?)
Hibernate: 
    /* create one-to-many row hellojpa3_entities_mapping.b_oneway.bb_fk_not.TeamV21.members */ update
        MemberV21 
    set
        members_TEAM_ID=? 
    where
        id=?
Hibernate: 
    select
        teamv21x0_.TEAM_ID as team_id1_1_0_,
        teamv21x0_.name as name2_1_0_ 
    from
        TeamV21 teamv21x0_ 
    where
        teamv21x0_.TEAM_ID=?
```

- 위의 코드는 앞서의 코드와 달리 update 쿼리가 생성됨을 확인할 수 있다. 그리고 그 업데이트는 Member에 대하여 진행된다.
- 사실 위의 코드는 sql의 입장에서는 당연하다. Member 가 team_id를 가지고 있다. Team은 member_id를 가지고 있지 않다. 그러므로 연관관계의 주인이 Team이라 하더라도 team_id를 가진 Member를 수정할 수밖에 없다.
- 결과적으로 연관관계의 주인을 설정할 때, **외래키를 가진 객체를 주인**으로 하는 것이 이해하기 쉽고 단순한 쿼리를 생성한다. 

## 양방향 연관관계
- 연관관계의 주인을 정했다. 이제부터 FK를 가진 객체가 연관관계의 주인임을 약속했다. 그런데 Team에서 List<Member> 를 조회하고 싶을 수 있다. 이 경우는 어떻게 하는가?
- 이러한 경우를 양방향 연관관계라 한다. 그리고 조회만을 할 수 있도록 일종의 메타데이터를 적용해야 한다. 이것이 바로 'mappedBy'이다.

```java
@Entity
@Setter
@Getter
public class MemberV31 {
    @Id
    @GeneratedValue
    private Long id;

    @Column(name = "USERNAME")
    private String name;

    @ManyToOne
    @JoinColumn(name ="TEAM_ID")
    private TeamV31 team;
}

@Entity
@Getter
@Setter
public class TeamV31 {
    @Id
    @GeneratedValue
    @Column(name = "TEAM_ID")
    private Long id;

    private String name;

    @OneToMany(mappedBy = "team")
    private List<MemberV31> members = = new ArrayList<>();

}
```

- 아래의 코드를 통해 양방향 탐색을 한다. Member 객체의 객체 그래프를 통하여 team을 구한다. 
- flush, clear를 한 이유는 영속성 컨텍스트를 비우기 위해서이다. 그렇지 않으면 1차 캐시에서 데이타를 추출하여 db와의 통신(sql 쿼리)를 확인할 수 없기 때문이다. 

```java
TeamV31 team = new TeamV31();
team.setName("teamA");
em.persist(team);

MemberV31 member = new MemberV31();
member.setName("memberA");
member.setTeam(team);
em.persist(member);

// team.getMembers().add(member); // 주인이 아닌 곳(mappedBy 가 있는 OneToMany)에는 삽입하더라도 정상 동작하지 않는다.

em.flush();
em.clear();

final TeamV31 findTeam = em.find(TeamV31.class, team.getId());
final List<MemberV31> members = findTeam.getMembers();
for (MemberV31 memberV31 : members) {
    System.out.println("members : "+ memberV31.getName());
}

tx.commit();
```

```sql
Hibernate: 
    /* insert hellojpa3_entities_mapping.c_twoway.ca_basic.TeamV31
        */ insert 
        into
            TeamV31
            (name, TEAM_ID) 
        values
            (?, ?)
Hibernate: 
    /* insert hellojpa3_entities_mapping.c_twoway.ca_basic.MemberV31
        */ insert 
        into
            MemberV31
            (USERNAME, TEAM_ID, id) 
        values
            (?, ?, ?)
Hibernate: 
    select
        teamv31x0_.TEAM_ID as team_id1_1_0_,
        teamv31x0_.name as name2_1_0_ 
    from
        TeamV31 teamv31x0_ 
    where
        teamv31x0_.TEAM_ID=?
Hibernate: 
    select
        members0_.TEAM_ID as team_id3_0_0_,
        members0_.id as id1_0_0_,
        members0_.id as id1_0_1_,
        members0_.USERNAME as username2_0_1_,
        members0_.TEAM_ID as team_id3_0_1_ 
    from
        MemberV31 members0_ 
    where
        members0_.TEAM_ID=?
members : memberA
```

## DB는 필요로 하지만 객체는 필요로 한 것들 : getMember().add();
- JPA는 완전하지는 않아서 DB와의 완전한 일치를 수행할 수 없다. 위의 엔티티로 아래와 같은 코드를 작성한다면 어떨까?

```java
TeamV31 team = new TeamV31();
team.setName("teamA");
em.persist(team);

MemberV31 member = new MemberV31();
member.setName("memberA");
member.setTeam(team);
em.persist(member);

em.flush();
em.clear();

final List<MemberV31> members = team.getMembers();
System.out.println("team name : "+team.getName()); // team name : teamA
System.out.println("members size : "+members.size()); // members size : 0

tx.commit();
```

- 위의 코드의 결과(members size)는 0이다. 분명 member는 team을 필드값으로 가지며 persist 로 영속화하였고, flush를 통해 db에 삽입했다. 그럼 결과는 1이 되어야 하는데 왜 0일까?
- 그 이유는 자바의 메모리와 DB의 데이터 간 차이를 가지기 때문이다. JPA를 통해 엔티티객체와 DB를 연동하더라도, 해당 객체를 영속성으로부터 다시 로딩하지 않는한, 자바로서의 메모리를 유지된다. 
- 이러한 한계를 해소하기 위하여 엔티티객체를 자바객체를 다루는 것처럼 조작해야 한다. 그러니까 List<Member>를 추출하고 조작할 때, 1) 초기화를 위하여 `List<Member> members = new ArrayList<>();` 로 선언해야 하며 2) 엔티티 객체 양 쪽에다가 데이터를 삽입해야 한다. `setTeam(team)과 함께 .getMembers().add(member);`
- 그렇게 구현한 코드는 아래와 같다. changeTeam 매서드를 만든다. setTeam의 경우 마치 예약어처럼 사용되는 이름이므로 다른 이름으로 구현한다.

```java
public class MemberV32 {
    // 중략
    public void changeTeam(TeamV32 team){
        this.team = team;
        team.getMembers().add(this);
    }
    // 중략
```

- 결과는 `team name : teamA \n members size : 1` 으로 잘 나온다.
- 이러한 방식의 장점은 1) java - jpa - db 간 틈을 채우는 역할을 하며 2) 테스트 코드를 사용할 때 활용 가능하다. 

## 주의점, 양방향 매핑과 무한루프
- toString(), lombok, JSON 등을 사용할 때 team 이 getMembers()를 호출하고, member는 getTeam을 호출하는 등, 무한 루프에 빠지기 쉽다. 그러므로 toString, lombok을 사용할 때 주의해야 한다. 
- 컨트롤러에서 엔티티를 보낼 때, JSON으로 생성하는데, 그 방식이 위와 동일하다. 그러므로 컨트롤러에서 엔티티를 전달할 때, DTO 등 구현체를 통해 통신한다. 
- 컨트롤러를 DTO로 전달하는 것이 중요한 이유는, 엔티티의 스펙이 변화할 수 있는데, 변화할 수 있는 것으로 통신을 할 경우, 통신과 관련한 합의가 틀어지는 문제가 발생할 수 있기 때문이다. 

## 정리
- 객체의 입장에서 연관관계는 참조 형태로 한다. `Team team; - List<Member> members;`
- 테이블은 외래키로 연관관계를 가진다. `select * from team where team_id = ?`, `select * from member where team_id = ?` 
- JPA는 이러한 한계를 연관관계를 통해 해소한다. 객체가 setTeam()을 통해 필드에 넣는 객체 지향적인 코드를 구현하느 것만으로, jpa는 그것에 맞춘 sql을 생성하고 db와 통신한다. 
- 다만, 이러한 연관관계에서 insert, update, delete 등을 관리할 주인을 필요로 한다. 이 주인의 역할을 어떤 객체에나 부여할 수 있다. 하지만 **외래키를 가진 객체를 주인**으로 하는 것을 권장한다. 
- jpa의 연관관계는 단방향이 기본이다. 그러나 주인이 아닌 쪽에서도 주인의 객체를 탐색하고 싶을 수 있다. 그러니까 앙뱡향 연관관계를 지원한다. 
- 양방향 연관관계를 할 때 주의할 점은 주인이 아닌 객체의 필드에 **반드시 mappedBy 메타 데이터**를 삽입하여, 주인이 아님을 정의해야 한다. 이 경우 조회만 가능하다. 
- 양방향을 구현 할 때 주의점은, 자바의 입장에서, 주인과 주인 아닌 객체 모두 데이터를 주입해야 한다는 점이다. DB에는 두 개의 관계가 영속화되었으나, 자바 메모리 상 한 쪽에만 필드를 수정할 경우 다른 한쪽은 해당 필드가 수정됨을 알 수 없기 때문이다. 그러므로 객체 양 측 모두 필드를 채워야 한다. 
- 양방향 연관관계를 구현할 경우 고민해야할 지점이 많다. 그리고 영속성과 관련하여 양방향은 어떤 영향도 미치지 않는다(단방향으로 구현해도 DB와의 연동은 잘 작동한다). 그러므로 **기본적으로 단방향 연관관계를 구현한 후 차후 필요시 앙뱡향을 구현**한다. 
- 마지막으로 **toString 등으로 인한 무한루프**를 주의한다. 