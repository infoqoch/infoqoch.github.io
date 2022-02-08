---
layout: post
author: infoqoch
title: jpa, jpql 의 기초 1
categories: [jpa]
tags: [jpa, java]
---

## JPQL 이란?
- 객체지향 쿼리.
- 테이블이 아닌 객체를 대상으로 하는 SQL.

## 기본 문법
- `select m from Member m where m.age > 18`

- 엔티티와 속성은 대소문자를 구분. Member는 테이블 MEMBER를 의미하는 것이 아니라, 엔티티 객체 Member 클래스를 의미한다. 
- 엔티티는 별칭(위에서는 Member 의 m)을 필요로 한다. 
- JPQL 키워드(select, from 등)는 대소문자를 구분하지 않는다.
- 그 외 문법은 SQL과 거의 일치한다. 

## 주요 매서드
- TypeQuery : 반환 타입이 명확할 때
- Query : 반환 타입이 명확하지 않을 때
- getSingleResult : 유일한 결과값을 리턴 할 때. 그렇지 않은 경우 예외가 발생한다.
- getResultList : 리스트 형태로 결과값을 리턴 할 때. 없을 경우 null을 반환. 주로 사용한다. 

```java
Member member1 = new Member();
member1.setName("kim");
em.persist(member1);

Member member2 = new Member();
member2.setName("lee");
em.persist(member2);

// 타입이 명확할 때 TypedQuery 를 리턴한다.
final TypedQuery<Member> typedQueryResult = em.createQuery("SELECT m FROM Member m", Member.class);

// 타입이 명확하지 않을 때 Query 를 리턴한다.
final Query query = em.createQuery("SELECT m FROM Member m where m.name = 'kim'");

// 결과가 컬렉션일 경우 getResultList()를 사용한다.
// 없을 경우 null을 반환한다. 그러므로 getSingleResult() 보다 선호한다.
final List<Member> resultList = typedQueryResult.getResultList();

System.out.println("size : " + resultList.size());

for (Member member : resultList) {
    System.out.println("member = " + member);
}

// 결과가 정확하게 하나이다.
// 정확하게 하나가 아닐 경우 예외가 발생한다.
try {
    final Member singleResult = typedQueryResult.getSingleResult();
}catch (Exception e){
    System.out.println("예외 발생!!");
    e.printStackTrace();
}

// 스트림을 지원한다. 
// 동적 파라미터를 지원한다. 
final Member singleResult2 =
        em.createQuery("select m from Member m where m.name = :name", Member.class)
        .setParameter("name", "kim")
        .getSingleResult();

System.out.println("singleResult2.getName() = " + singleResult2.getName());

tx.commit();
```

## 프로젝션 SELECT
- select를 넘어서 다양한 값타입을 지원한다. select 절을 통해 스칼라(기본타입), 임베디드 타입, 컬렉션 타입 등을 리턴한다.
- 프로젝션으로 출력한 데이터는 엔티티 컨텍스트가 관리한다. 


### 프로젝션과 영속성 컨텍스트
- 프로젝션으로 꺼내온 데이터는 영속성 컨텍스트가 관리한다.
- 객체를 변경할 경우 update 쿼리가 생성된다. 

```java
Member member = new Member();
member.setName("kim");
em.persist(member);

em.flush();
em.clear();

final List<Member> resultList = em.createQuery("select m from Member m", Member.class).getResultList();

final Member findMember = resultList.get(0);

findMember.setName("new Name"); // 수정할 경우? 
```

```sql
Hibernate: 
    /* update
        jpa8_query.b_jpql.Member */ update
            Member 
        set
            age=?,
            name=? 
        where
            MEMBER_ID=?
```

### 엔티티 프로젝션
- 프로젝션을 통하여 필드 중 엔티티를 출력할 수 있다. 

```java
Team team = new Team();
team.setName("teamA");
em.persist(team);

Member member = new Member();
member.setName("kim");
member.setTeam(team);
em.persist(member);

em.flush();
em.clear();

//            final Team findTeam = em.createQuery("select m.team from Member m", Team.class).getResultList().get(0);
final Team findTeam = em.createQuery("select t from Member m join m.team t", Team.class).getResultList().get(0);

System.out.println("findTeam.getName() = " + findTeam.getName());

tx.commit();
```

```sql
Hibernate: 
    /* select
        m.team 
    from
        Member m */ select
            team1_.id as id1_2_,
            team1_.name as name2_2_ 
        from
            Member member0_ 
        inner join
            Team team1_ 
                on member0_.TEAM_ID=team1_.id
findTeam.getName() = teamA
```

- 쿼리는 `select m.team from Member m` 지만, 실제로는 쿼리에 join이 함께 생성된다. (묵시적 join / 명시적 join을 참고)
- 예상하지 못한 쿼리가 발생할 수 있다. 그러므로 jpql에 join을 명시한다. 
- jpql은 on을 사용하지 않는 대신 m.team t 의 형태로 join 한다.

### 임베디드 타입 프로젝션
- 임베디드 타입에 대하여 출력할 수 있다. 

```java
Order order = new Order();
order.setAddress(new Address("busan", "bukkan-gil", "1234"));
em.persist(order);

em.createQuery("select o.address from Order o").getResultList();
```

```sql
Hibernate: 
    /* select
        o.address 
    from
        
    Order o */ select
        order0_.city as col_0_0_,
        order0_.street as col_0_1_,
        order0_.zipcode as col_0_2_ from
            ORDERS order0_
```

### 스칼라 타입 프로젝션
- 기본 타입을 출력한다.

```java
final List resultList = em.createQuery("select m.name, m.age from Member m").getResultList();
```

```sql
Hibernate: 
    /* select
        m.name,
        m.age 
    from
        Member m */ select
            member0_.name as col_0_0_,
            member0_.age as col_1_0_ 
        from
            Member member0_
```

- 스칼라 타입이 다양할 경우, Object, Object[], new SomethingDTO 로 받는다.

```java
Member member = new Member();
member.setName("kim");
member.setAge(10);
em.persist(member);

em.flush();
em.clear();

// 타입을 알 수 없는 경우 Object로 받는다.
final List resultList = em.createQuery("select m.name, m.age from Member m").getResultList();

for (Object obj : resultList) {
    final Object[] oArray = (Object[]) obj;
    for (Object oValue : oArray) {
        System.out.println("oValue = " + oValue);
    }
}

// Object[] 로 리턴할 수도 있다.
final List<Object[]> resultList1 = em.createQuery("select m.name, m.age from Member m", Object[].class).getResultList();
for (Object[] objects : resultList1) {
    for (Object object : objects) {
        System.out.println("object = " + object);
    }
}

// DTO를 활용한다.
// new 명령어로 조회하며, 해당 인자를 받는 생성자를 만들어야 한다. 생성자의 인자의 순서가 일치해야 한다. 
final List<MemberDTO> resultList2 = em.createQuery("select new jpa8_query.b_jpql.MemberDTO(m.name, m.age) from Member m", MemberDTO.class).getResultList();

for (MemberDTO memberDTO : resultList2) {
    System.out.println("memberDTO = " + memberDTO);
}
```

- 스칼라 타입을 하나로만 받을 경우, 해당 타입을 String.class로 명시하고 List<String>으로 리턴할 수 있다. 
- 하지만 여러 개를 받을 경우 불가피하게 Object 타입으로 받는다.
- Object가 아닌 객체를 통해 받을 수 있으며, 이 방법을 권장한다. 다만 new SomethingDTO를 쿼리 내부에 작성해야 하며, 그것의 패키지를 복잡하게 적어야 한다. 
- QueryDSL은 이에 대한 간단한 빌드패턴을 제공한다. 


## 페이징
- JPA는 페이징 기능을 아주 쉽게 제공한다.
- 페이징을 위한 다양한 방언을 매우 쉽게 해결한다. 

```java
for(int i=0; i<100; i++){
    Member member = new Member();
    member.setName("kim"+i);
    member.setAge(10);
    em.persist(member);
}

final List<Member> resultList = em.createQuery("select m from Member m order by m.id desc", Member.class)
        .setFirstResult(1)
        .setMaxResults(10)
        .getResultList();

for (Member member : resultList) {
    System.out.println("member.getName() = " + member.getName());
}
```

## 조인
- 조인은 inner join, outer join, cross join 등을 지원한다.
- 연관관계가 있을 경우 join에 on을 생략한다. 다만 연관관계의 객체를 엔티티 그래프로 표현한다.

```java
Team team = new Team();
team.setName("teamA");
em.persist(team);

Member member = new Member();
member.setName("kim");
member.setAge(10);
member.changeTeam(team);
em.persist(member);

final String query = "select m from Member m join m.team t"; // 이너 조인
final String query = "select m from Member m left join m.team t"; // 아우터 조인
final String query = "select m from Member m, Team t where m.name = t.name"; // 크로스 조인
final List<Member> result = em.createQuery(query, Member.class)
        .getResultList();

for (Member m : result) {
    System.out.println("m.getName() = " + m.getName());
}
```

- on 의 경우 연관관계 없는 경우 사용한다.
- 문자열을 삽입하거나, 연관관계가 없는 테이블 간 조인할 때 사용한다.

```java
Team team = new Team();
team.setName("teamA");
em.persist(team);

Member member = new Member();
member.setName("kim");
member.setAge(10);
member.changeTeam(team);
em.persist(member);

// on 을 사용 가능. 연관관계가 없는 경우 사용한다.
// 아래의 경우 특정 문자열을 비교한다.
final String query = "select m from Member m join m.team t on t.name like '%team%'";
final List<Member> result = em.createQuery(query, Member.class)
        .getResultList();

for (Member m : result) {
    System.out.println("m.getName() = " + m.getName());
}
```

```java
// 아래의 경우 연관관계 없는 객체 간 비교를 한다.
Order order = new Order();
order.setProductName("apple");
em.persist(order);

Member member2 = new Member();
member2.setName("apple");
em.persist(member2);

final List<Member> resultList = em.createQuery("select m from Member m join Order o on o.productName = m.name", Member.class).getResultList();

for (Member m : resultList) {
    System.out.println("m.getName() = " + m.getName());
}
```

## 서브쿼리
- where, having 절에서 서브쿼리 지원.
- select 절에서는 하이버네이트에서 지원.
- from 은 하이버네이트를 포함한 모든 jpa 구현체에서 지원하지 않음. 
- from의 경우 
  - 최대한 join으로 해결하지만, 실패할 경우 
  - 쿼리를 두 번 날린다음 자바에서 해결하지만, 실패할 경우 
  - nativeSQL로 해결.
- 그 외 exists, any, all, some, in 등 다양한 기능 제공


## JPQL 타입 표현
- 'HELLO', 'She''s'
- 10L(Long), 10D(Double), 10F(Float)
- TRUE, FALSE
- pacakge.enums.MemberType.ADMIN (이넘타입. 패키지 포함)


```java
Member member = new Member();
member.setName("kim");
member.setAge(10);
member.setType(MemberType.ADMIN);
em.persist(member);

em.flush();
em.clear();

final String query = "select m.name, 'HELLO', m.type, true from Member m where m.type = :usertype";
final List<Object[]> resultList = em.createQuery(query, Object[].class)
        .setParameter("usertype", jpa8_query.b_jpql.MemberType.ADMIN) // enum 타입은 경로를 모두 지정해야 한다.
        .getResultList();

for (Object[] objects : resultList) {
    for (Object object : objects) {
        System.out.println("object = " + object);
    }
}
```

- 상속관계로서 타입을 비교할 경우 아래와 같이 type() 을 사용한다. 

```java
@Entity
@Inheritance
public abstract class Item {
    @Id
    @GeneratedValue
    private Long id;

    private int price;
    private String name;
}

@Entity
@Getter
@Setter
public class Book extends Item{
    private String author;
}
```

```java
em.createQuery("select i from Item i where type(i)= Book ").getResultList();
```

## CASE
- JPQL에서는 CASE를 지원한다.

```java
Member member = new Member();
member.setName("kim");
member.setAge(10);
member.setType(MemberType.ADMIN);
em.persist(member);


// case 사용
final String query =
        " select " +
                "case when m.age <= 10 then '학생' " +
                "     when m.age >= 60 then '경로' " +
                "     else '일반' " +
                "end " +
        " from Member m ";
final List<String> resultList = em.createQuery(query, String.class)
        .getResultList();

for (String s : resultList) {
    System.out.println("s = " + s);
}
```

- coalesce, nullif 등도 지원한다.

```java
Member member2 = new Member();
member2.setName(null);
member2.setAge(10);
member2.setType(MemberType.ADMIN);
em.persist(member2);

String query2 = "select coalesce(m.name, '이름없음') from Member m";
final List<String> resultList1 = em.createQuery(query2, String.class).getResultList();

for (String s : resultList1) {
    System.out.println("s = " + s);
}
```

## 표준함수
- JPA는 표준 함수를 제공한다. 
- JPA 표준함수 이외에, 각 DB마다의 함수, 그리고 사용자 정의 함수까지 지원한다. 
- DB에 의존적인 함수는 각 방언(MysqlDialect, H2Dialect)에 이미 등록되어, 바로 사용하면 된다. 사용자 정의 함수는 정의하여 사용하면 된다. 

- 아래의 코드는 JPA 표준 함수 중, JPA 만 가지고 있는 함수인 size를 구현한 내용이다. 
- 엔티티의 갯수를 구한다. 

```java
Team team = new Team();
team.setName("teamA");
em.persist(team);

Member member = new Member();
member.setName("kim");
member.changeTeam(team);
em.persist(member);

Member member2 = new Member();
member2.setName("lee");
member2.changeTeam(team);
em.persist(member2);

em.flush();
em.clear();

String query1 = "select t.members.size from Team t";

final Integer singleResult = em.createQuery(query1, Integer.class).getSingleResult();

System.out.println(singleResult);
```