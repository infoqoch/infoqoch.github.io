---
layout: post
author: infoqoch
title: jpa 엔티티 맵핑의 다양한 종류(x to x)
categories: [jpa]
tags: [jpa, java]
---

## 양방향과 단방향
- JPA는 여러가지의 연관관계를 지원한다. 다대일, 일대다, 일대일, 다대일. 사실상 일대다와 일대일 연관관계만 사용한다. 일대다는 아주 가끔 쓰고 다대다는 사용하지 않는다. 
- 연관관계는 기본적으로 단방향만 있다. 그러므로 다대일과 일대다는 다르다. 다대일 단방향과 다대일 양방향이 있다. 
  
## 다대일, 일대다
- 일대다, 다대일은 이전의 블로그에 정리하였으므로 생략한다.
- 대체로 다대일을 사용한다. 정확하게는 외래키를 가진 쪽을 주인으로 하는 방식을 선택한다. 이래야지 jpa가 sql을 생성할 때 직관적이다. 

## 일대일
- 일대일 관계 역시 다대일과 유사한 형태로 DB가 쌓인다. 그러니까 외래키가 있는 쪽과 없는 쪽이 있다. 둘 중 한 곳을 선택할 수 있다.
- 일대일 관계를 분명하게 하기 위해서는 unique 제약 조건을 걸어야 한다. 그렇지 않을 경우 다대일이 될 테니까.

```java
@Entity
@Getter
@Setter
public class Locker {
    @Id
    @GeneratedValue
    @Column(name = "LOCKER_ID")
    private Long id;
    private String name;

    @OneToOne(mappedBy = "locker")
    private MemberV4 member;
}

@Entity
@Setter
@Getter
public class MemberV4 {

    @Id
    @GeneratedValue
    @Column(name = "MEMBER_ID")
    private Long id;

    private String name;

    @OneToOne
    @JoinColumn(name ="LOCKER_ID")
    private Locker locker;
}

```

### 누가 주인이 되는가? 누가 fk를 가지는가?
- 일대일의 경우 FK가 있는 경우에만 연관관계 설정 가능하다. FK가 없는 대상 엔티티에서 주인이 될 수 없다. 지원 자체를 하지 않는다.
- 다만, 누가 FK(동시에 연관관계의 주인)을 가지느냐는 쟁점이 있다. 

![member가 외래키를 가진다](/assets/pasteimage/2022-02-05-jpa-xToxmapping/2022-02-06-12-51-39.png)
- member가 외래키를 가진다.

![locker가 외래키를 가진다](/assets/pasteimage/2022-02-05-jpa-xToxmapping/2022-02-06-12-51-51.png)
- locker가 외래키를 가진다

- DBA 입장에서는 fk를 locker가 가지는 것이 맞다고 볼 수 있다. 현재는 일대일 관계이지만 차후 하나의 회원이 여러 사물함을 가질 가능성이 높기 때문이다. 하나의 락커를 여러 회원이 공유하기는 쉽지 않을 테다. 그러므로 장기적으로 테이블의 관계가 변화함을 가정한다면, locker가 fk를 가지는 것이 맞다. 
- 더하여, member 테이블에 locker_id가 null일 수 있다. 그러니까 외래키에 null이 삽입될 수 있다. 
- (위의 방식이 장기적으로 옳다고 가정하더라도) 개발자 입장에서 fk는 member가 가지는 것이 맞다. 왜냐하면 전체의 비지니스 로직에서 member를 조회할 일이 더 많고, 객체 그래프를 통해 getLocker()를 탐색할 경우가 더 많다고 예상할 수 있다. 
- 추가적으로 외래키가 없는 대상테이블이 연관관계의 주인이 될 경우 양방향은 즉시로딩만 지원한다. (이 부분이 큰 문제라 한다. 그래서 일대일의 경우 단방향으로 구현한다).
- 이 경우 DBA와 잘 협의해야 한다.


## 다대다
- 다대다는 사실상 사용하지 않음.
- 앞서 우리는 @JoinColume을 사용했고, 이것은 두 개의 엔티티를 어떤 방식으로 연결하냐를 선언하는 것과 같다. @JoinColumn이 없을 경우 기본값은 @JoinTable로 한다. @JoinTable은 두 개의 테이블을 연결하는 테이블을 만드는 방식이며, 각 각의 테이블의 PK를 FK로 하는 칼럼 두 개를 생성한다. JoinTable의 경우 FK 두 개의 칼럼을 제외한 어떤 칼럼도 생성할 수 없다. 
  
![다대다](/assets/pasteimage/2022-02-05-jpa-xToxmapping/2022-02-06-13-13-41.png)

- 다대다의 경우 무조건 @JoinTable을 통해 테이블을 연결한다. 이러한 테이블의 생성으로 관계를 정확하게 보기 어렵고, 그러므로 다대다는 추천하지 않는다. 
- 다대다의 JoinTable을 직접 엔티티로 구현하는 것을 추천한다. `@ManyToMany - jointable - @ManyToMany` -> `@OneTOMany - @ManyToOne - @OneToMany` 로 변경. 중간 테이블(엔티티)를 직접 구현한다. 

![](/assets/pasteimage/2022-02-05-jpa-xToxmapping/2022-02-06-13-15-26.png)

### 추가적으로... PK는?
- PK의 경우 의미있는 값보다 의미가 없는 값으로 하는 것이 좋다. 중간 엔티티의 스펙이 어떻게 변할지 알 수 없기 때문이다. 
- 다대다를 포함한 모든 엔티티 구현에 있어서도, PK는 의미 없는 값으로 한다. 
  
![](/assets/pasteimage/2022-02-05-jpa-xToxmapping/2022-02-06-13-16-41.png)