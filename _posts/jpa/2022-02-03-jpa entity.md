---
layout: post
author: infoqoch
title: jpa entity 와 ddl 생성
categories: [jpa]
tags: [jpa, java]
---

## @Entity 와 생성 규칙
- Entity가 붙은 클래스는 JPA가 관리한다.
- 리플렉션 등 기술을 사용하기 때문에 기본 생성자가 필수이다. 
- final, enum, interface 등 사용할 수 없다. 
- 엔티티의 데이타베이스를 위한 설정값(not null, unique 등) 이 반드시 자바 객체로서의 상태와 일치하는 것은 아니다. 

## Entity와 데이타베이스 스키마(DDL)의 생성
### hibernate.hbm2ddl.auto
- JPA는 엔티티를 기반으로 테이블을 자동 생성하는 기능이 있다.
- 데이타베이스가 객체에 의하여 통제된다. 객체 지향적 개발이 가능하다.
- DDL은 데이타베이스에 맞게 적절하게 생생된다.

### 자동생성의 옵션
- create : drop + create
- create-drop : drop + create + (종료 시점에서) drop
- update : 변경 값만 반영(alter table ... 등)
- validate : 엔티티와 테이블 간 정상 맵핑여부를 확인
- none : 사용하지 않음

### 주의점
- create 의 경우 drop 이 되기 때문에 데이터 변경 위험이 있음. 
- update의 경우 테이블의 변경 과정에서 락이 걸려 운영에 문제가 발생할 수 있음.
- DDL 생성 기능은 편리하나, 완전하게 신뢰할 수 없음. 운영에서는 생성된 DDL을 적절한 값으로 변경하여 반영해야 함. 다만, 엔티티에 가능한 구체적으로 제약조건을 작성하는 것이 확인하는데 좋음.
- 테스트 서버 이상에서는 validate 혹은 none을 추천.

## 필드 - 컬럼 맵핑

```java
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;
import java.time.LocalDateTime;
import java.util.Date;

@Entity
@Getter
@Setter
public class Members {

    @Id
    private Long id;

    @Column(name = "name", length = 100)
    private String username;

    @Column(nullable = false, updatable = false)
    private Integer age;

    @Enumerated(EnumType.STRING)
    private RoleType roleType;

    @Temporal(TemporalType.TIMESTAMP)
    private Date createdDate;

    private LocalDateTime lastModifiedDate;

    @Transient
    private String temp;

    @Lob
    private String description;
}
```

```sql
drop table if exists Members CASCADE 

create table Members (
    id bigint not null,
    age integer not null,
    createdDate timestamp,
    description clob,
    lastModifiedDate timestamp,
    roleType varchar(255),
    name varchar(100),
    primary key (id)
)

alter table Members 
    add constraint UK_kmi8n3huapsyxj254we3nsij0 unique (name)
```

- 위는 자바 엔티티 코드이며 아래는 이로 생성된 SQL 쿼리이다.

- Column 을 통해 다양한 값을 입력할 수 있다. 
  - 칼럼의 이름 
    - 특히 카멜케이스와 언더스코어 간 문법 차이 존재. 이로 인해 명시하여 사용하기도 함.
    - 스프링부트에서 사용할 경우 칼럼을 카멜케이스로 작성하더라도 언더스코어로 변환함.
  - not null
  - length
  - updatable
- Enumerated 를 통해 enum의 효과를 줄 수 있다. 다만 기본 값인 ordinary 의 경우 enum 클래스의 변경을 반영하지 못하고 순서로 값을 부여하기 때문에, 반드시 STRING을 값으로 해야한다.
- Temporal는 시간에 대한 데이터를 정의할 때 사용하지만, 자바 8 이후부터 어떤 어너테이션도 필요로 하지 않고 LocalDateTime으로 정의한다. 
- Transient은 엔티티와 테이블 간 맵핑을 하지 않는 값을 정의할 때 사용한다. 
- Lob은 varchar 를 초과하는 데이타를 다룰 때 사용한다. 데이타 타입에 따라 자동으로 Clob 등으로 변경한다. 


## 기본키의 맵핑
- @Id. 기본키에 대한 정의를 직접 할 때 @Id 어너테이션만 사용한다. 
- @GenerateValue. 기본키에 대한 설정을 할 때 사용한다. 

### @GenerateValue 의 옵션
- AUTO : 기본값. JPA가 데이타베이스에 따라 적합하게 선택한다. 
- IDENTITY : Mysql의 AUTO_INCREMENT로 동작한다. 
- SEQUENCE : Oracle의 시퀀스로 동작한다.  `@SequenceGenerator` 을 필요로 한다.
- TABLE : 오라클의 시퀀스와 같은 테이블을 생성한다. 모든 데이타베이스에서 동작한다. `@TableGenerator`을 필요로 한다. 

### 식별자 추천 구현
- 기본키의 제약 조건 : null이 아님. 변하면 안된다. 만약 이를 자연키(임의있는 값, 주민번호, 아이디 등)를 사용할 경우 장기적으로 변할지 아닐지를 알 수 없다. 그러므로 대리키(무의미한 숫자)를 사용하자. 주민번호 이용에 대한 법률적 변화 등.
- Long 혹은 대체키(UUID 등) + 키 생성전략(데이타베이스에 따른 형태 추천)

### IDENTITY 전략과 PK의 추출
- persist() 시점에서 insert를 수행하고 db에서 바로 식별자를 꺼내온다. 트랜잭션까지 미루지 않는다. 성능 상 큰 차이는 없다.
- 이 경우 select가 없이 id 값을 가지고 온다. 

```java
User user = new User();
// user.setId(123L); // GenerateValue를 사용할 경우 키값에 대하여 값을 주입하면 안된다.
user.setName("kim");
System.out.println("=====");
em.persist(user);
System.out.println("user.getId() : " + user.getId());
System.out.println("=====");

tx.commit();
```

```text
=====
Hibernate: 
    /* insert hellojpa2.User
        */ insert 
        into
            User
            (id, name) 
        values
            (null, ?)
user.getId() : 1
=====
```

### SEQUENCE 전략
  
```java
@Entity
@Getter
@Setter
@SequenceGenerator(
        name = "USERS_SEQ_GENERATOR",
        sequenceName = "USERS_SEQ",
        initialValue = 1,
        allocationSize = 50) 
 public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE,
            generator = "USERS_SEQ_GENERATOR")
    private Long id;

    private String name;
}
```

```java
User user = new User();
user.setName("kim");

User user2 = new User();
user2.setName("lee");

User user3 = new User();
user3.setName("choi");

System.out.println("=====");
em.persist(user);
em.persist(user2);
em.persist(user3);
System.out.println("user.getId() : " + user.getId());
System.out.println("user2.getId() : " + user2.getId());
System.out.println("user3.getId() : " + user3.getId());
System.out.println("=====");

tx.commit();
```

```text
Hibernate: create sequence USERS_SEQ start with 1 increment by 1
Hibernate: 
    
    create table User (
       id bigint not null,
        name varchar(255),
        primary key (id)
    )

=====
Hibernate: 
    call next value for USERS_SEQ_GENERATOR
user.getId() : 52
user2.getId() : 53
user3.getId() : 54
=====
Hibernate: 
    /* insert hellojpa2.User
        */ insert 
        into
            User
            (name, id) 
        values
            (?, ?)
Hibernate: 
    /* insert hellojpa2.User
        */ insert 
        into
            User
            (name, id) 
        values
            (?, ?)
Hibernate: 
    /* insert hellojpa2.User
        */ insert 
        into
            User
            (name, id) 
        values
            (?, ?)
```

- 시퀀스 전략의 경우 persist 시점에서 `call next value for USER_SEQ` 을 DB에 쿼리한다. 트랜잭션 때 insert를 버퍼로 쿼리를 보낸다.
- `allocationSize` 을 사용하여 통신을 최소화 한다. 미리 50개의 시퀀스를 가져온다. 동시성 이슈가 없다.