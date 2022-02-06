---
layout: post
author: infoqoch
title: spring jpa를 왜 사용하는가? sql 중심 개발의 문제점
categories: [jpa]
tags: [jpa, java]
---

## 관계형 데이타베이스의 헤게모니
- DB의 경우 관계형 데이타베이스가 대세이다.
- 자바를 통해서는 객체지향적 개발을 지향하지만, DB와의 패러다임 불일치 문제로 인한 문제가 계속 발생한다. 

## 객체지향과 관계형 데이타베이스의 패러다임 불일치 문제
### 상속
![image](/assets/image/jpa/001.jpg){:.aligncenter}

- 객체지향에서의 상속의 개념이 관계형 데이타베이스에는 존재하지 않는다. 슈퍼타입과 서브타입이 유사하지만 그러나 큰 차이를 가진다. 

```java
list.add(album); // 객체 내부에 어떤 참조 변수가 있든 컬렉션에 자유롭게 삽입 가능
Item item = list.get(albumId); // 부모타입도 활용 가능. 
```

```sql
insert into item... 
insert into album...
-- 자바의 객체의 내용이 무엇이 있든 상관 없이 테이블은 분리해서 저장해야 한다. 

select * 
from item
join album
on ....
-- join으로 select 하거나, 테이블마다 분리해서 데이터를 추출한다.

```

- 자바에서는 다형성과 컬렉션을 통하여, 객체지향적 개발이 가능하다. 하지만 sql은 사실상 상속 관계가 존재하지 않고 분리된 테이블을 다뤄야 한다. 


### 연관관계
#### 참조의 방식의 차이
- 객체는 참조를 사용. `member.getTeam();`
- 테이블은 외래키를 사용 : `join on m.team_id = t.team_id`
- 한편, 객체는 일방향임. 테이블은 fk를 통해 양방향으로 조회 가능. 

#### 객체지향적 모델링의 어려움
- 기본적인 객체지향적 객체는 아래와 같다. 

```java
class Member{
    String id;
    Team team;
    String username;
}

class Team{
    Long id;
    String name;
}
```

- 한편, DB와 통신하며 insert, select를 하는 객체는 아래의 형태와 같다. 

```sql
select id, team_id, username from member;
select id, name from team
```

```java
class MemberVO{
    String id;
    Team team;
    String username;
}

class TeamVO{
    Long id;
    String name;
}
```

- sql로 호출한 데이터와 자바의 객체지향적 데이터를 연결하기 위해서는 복잡한 과정을 거쳐야 한다. 

```java
MemberVO memberVO = memberMapper.findById(id);
TeamVO teamVO = teamMapper.findById(teamId);

Member member = new Member();
member.setId(meberVO.getId());
member.setUsername(memberVO.getUsername);
member.setTeam(teamVO);

return member;
```

- 만약 객체지향적인 개발을 고집할 경우, 복잡한 객체 그래프의 탐색 과정의 구현이 어려워지며, 데이터 자체에 대한 신뢰성 문제가 발생한다.

```java
class Member{
    Long id;
    Order order;
}

class Order{
    Long id;
    Delivery delivery;
}

class Deliver{
    // 중략
}
```

```java
Member member = memberService.findById(id);
member.getOrder(); // Order 객체가 존재하는가?
member.getOrder().getDelivery(); // Delivery 객체가 존재하는가?
```

- 객체 그래프로 탐색하는 과정에서 모든 데이터가 있는지에 대한 신뢰를 하기가 어렵다. 결국, 해당 데이터 어떻게 들어오는지 알기 위해서는 쿼리를 직접 확인하는 수밖에 없다. 
- 결국 생산성 등 문제로 인하여 슈퍼 DTO를 만들고 그 데이터를 채우는 것이 그나마 나은 방식이 될 수밖에 없음.
- 위의 복잡한 과정을 생략하기 위하여 아래와 같이 superDTO라는 형태로 사용한다. 

```sql
select 
    m.id
    , m.team_id
    , m.username
    , t.id
    , t.name
from member m
join team t
on m.team_id = t.id
where m.id = #{id}
```

```java
MemberWithTeam memberWithTeam = memberMapper.findBy(id);
return memberWithTeam;
```

- 객체 지향적으로 개발하면 할 수록 업무가 늘어나고 복잡해진다. 


### 비교하기
- 쿼리로 가져온 데이터의 경우 동일함을 보장하지 못함.

```java
Member member1 = memberDAO.getMember(memberId);
Member member2 = memberDAO.getMember(memberId);
// member1 != member2
```

- 하지만 java의 컬랙션에서 가져온 동일한 데이터는 동일함을 보장함.

```java
Member member1 = list.get(memberId);
Member member2 = list.get(memberId);
// member1 == member2
```

### JPA와 객체지향적 개발
- 객체답게 모델링을 할 수록 맵핑 작업만 늘어난다.
- sql 중심의 개발을 할 경우 객체지향적 개발에서 멀어지고 DB와의 맵핑 작업에 몰두하게 된다. insert, select, update 등... crud의 무한 반복이다. 
- 칼럼을 하나 추가해야 하면 쿼리를 처음부터 끝까지 다시 수정해야 한다.
- 객체를 자바 컬렉션에 저장하듯이 DB에 저장할 수는 없을까? 1980년 대부터 고민한 문제이며, 자바에서의 해결책은 JPA이다. 


## ORM? JPA?
- 객체지향적 개발과 관계형 데이타베이스 간 한계에 대해서는 ORM 프레임워크가 중간에서 해결한다. JPA가 자바의 객체지향적 개발의 내용을 분석하고 SQL로 변환하고 DB에 요청한다.  ResultSet을 알아서 분석하여 객체에 삽입한다. 이를 통해 패러다임의 불일치 문제를 해결한다. 
- 자바 진형에서는 EJB를 표준으로 하려고 하였으나 실패하였다. Hibernate가 오픈소스로 나왔으며, 이것을 표준으로 만든 것이 JPA이다. 
- JPA는 스펙의 모음(인터페이스)이다. JPA를 구현한 것 중 하나가 Hibernate 이다.

## JPA를 왜 사용해야 하는가?
### 생산성

```java
jpa.persist(member); // 저장
Member member = jpa.find(memberid); // 조회
member.setName("kim"); // 삽입
jpa.remove(member);  // 수정
```

- 마치 컬렉션을 다루는 것처럼 데이터를 다룬다. 매우 간편하고 객체지향적으로 개발 가능하다.


### 유지보수
- 필드값의 변경이 간단해진다. 


### 패러다임 불일치 문제의 해소
- 단순한 컬렉션 출력처럼 사용하지만, 내부적으로는 jpa가 자동으로 sql을 생성한다. 
- 객체 그래프에 대한 신뢰성있는 호출 및 탐색이 가능하다. 객체의 데이터를 완성하기 위하여 처음부터 데이터 전체를 호출할 수 있지만, 이는 메모리와 DB의 낭비로 이뤄진다. jpa는 지연 로딩을 지원하며 필요한 경우에만 더 깊이 있는 데이터를 조회한다. 

```java
jpa.persist(member); 

Member member = jpa.find(memberId);
member.getTeam();
member.getTeam().getDelivery(); 
```

```sql
-- sql을 아래와 같이 자동으로 생성한다.

insert into member...
insert into team...

select *
from member
join team
on ....
join delivery
```

### 비교하기
- 동일한 트랜잭션에서 조회한 엔티티는 같음을 보장한다.


### JPA의 성능 최적화 기능
- JPA가 오히려 성능에 좋을 수 있다.

#### 1차 캐시와 동일성 보장
- 같은 트랜잭션 안에서는 같은 엔티티를 반환. 조회 성능을 향상한다.

```java
Member m1 = jpa.find(Member.class, memberId); // SQL
Member m2 = jpa.find(Member.class, memberId); // 캐시

// m1 == m2
```

#### 트랜잭션을 지원하는 쓰기 지연 insert
- 트랜잭션을 커밋할 때 insert sql을 모와서 한 번에 전송. JDBC BATCH SQL. 
- 이 방식이 가능한 이유는, 트랜잭션이 종료 될 때 그 결과물을 마지막에 DB에 삽입하면 됨. 내부 로직 과정에서 DB와 통신을 최대한 뒤로 미룬다. 

```java
transaction.begin();

em.persist(memberA);
em.persist(memberB);
em.persist(memberC);

transaction.commit();
```

#### 지연로딩과 즉시로딩
- 지연로딩과 즉시로딩을 필요에 따라 옵션을 통해 선택 가능하다. 
- 기본적으로 지연로딩을 하며 최적화가 필요할 때 즉시로딩을 사용한다. 

```java
// 지연로딩 
Member member = memberDAO.find(memberId); // select * from member...
Team team = member.getTeam(); // select * from team....

// 즉시로딩
Member member = memberDAO.find(memberId); // select * from member join team....
Team team = member.getTeam(); 
```

### 나아가며
- ORM 객체와 RDB 개발 둘 다 잘해야 한다. 
- 하지만 더 중요한 것은 관계형 데이터베이스이다. 