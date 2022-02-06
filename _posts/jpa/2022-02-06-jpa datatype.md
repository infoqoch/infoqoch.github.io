---
layout: post
author: infoqoch
title: jpa와 데이터타입
categories: [jpa]
tags: [jpa, java]
---

## jpa를 기준으로 본 데이터 타입
- jpa를 기준으로 데이터 타입은 엔티티와 엔티티 아닌 것으로 구분한다.

### entity 타입
- @Entity 로 정의하는 객체
- 데이터가 변하더라도 식별자를 통해 추적 가능.

### 값 타입
- int, Integer, String 등 자바의 기본 타입이나 객체
- 식별자가 없으며 추적 불가능.

### 값 타입의 분류
- 기본값 타입(기본타입, wrapper type, String)
- 임베디드 타입 embedded type
- 컬렉션 값 타입 collection value type

### 데이터의 공유로 인한 사이드이펙트
- 기본값 타입은 공유로 인한 문제가 발생하지 않는다. wrapper 클래스는 참조 변수를 공유할 수 있지만 데이터를 수정할 수 없다.

```java
Integer a = 10;
Integer b = a;
a = 20;

System.out.println("a = " + a);  // 20 
System.out.println("b = " + b);  // 10
```

## 임베디드 타입

```java
@Entity
@Setter
@Getter
public class Member {
    @Id
    @GeneratedValue
    @Column(name = "MEMBER_ID")
    private Long id;

    private String name;

//    private LocalDateTime startDate;
//    private LocalDateTime endDate;

    @Embedded
    private Period wordPeriod;

//    private String city;
//    private String street;
//    private String zipcode;

    @Embedded
    private Address homeAddress;

    @Embedded
    @AttributeOverrides({
            @AttributeOverride(name = "city", column = @Column(name = "WORK_CITY")),
            @AttributeOverride(name = "street", column = @Column(name = "WORK_STREEET")),
            @AttributeOverride(name = "zipcode", column = @Column(name = "WORK_ZIPCODE"))
    })
    private Address wordAddress;

}

@Getter
@Setter
@Embeddable
@NoArgsConstructor
@AllArgsConstructor
public class Address {
    private String city;
    private String street;
    private String zipcode;
}

@Getter
@Setter
@Embeddable
@NoArgsConstructor
@AllArgsConstructor
public class Period {
    private LocalDateTime startDate;
    private LocalDateTime endDate;
}
```

```java
Member member = new Member();
member.setName("user");
member.setHomeAddress(new Address("seoul", "some-gil","1234"));
member.setWordAddress(new Address("busan", "any-gil","56547"));
member.setWordPeriod(new Period());

em.persist(member);
```

- 특정 필드값을 묶어서 하나의 클래스로 만든다. 이를 jpa에서는 embedded 타입이라 하며 해당 객체에는 @Embedded로 어너테이션을 붙이고, 해당 클래스는 @Embeddable을 붙인다.
- 기본생성자를 꼭 필요로 한다. NoArgsConstructor을 사용했다.
- 동일한 클래스를 중복사용할 경우 AttributeOverrides 어너테이션을 사용한다. 

### 임베디드 타입의 특징과 장점
- 임베디드 타입의 사용과 관계없이 테이블의 상태는 동일하다. 
- 엔티티 객체를 효과적으로 모델링할 수 있다. 세밀하게 맵핑 가능하다.
- 잘 설계된 ORM 어플리케이션은 매핑한 테이블의 수보다 클래스의 수가 더 많다. 

### 임베디드 타입과 상속 타입 중 무엇을 사용하는가?
- 아래의 김영한 선생님의 답변이 있다. (https://www.inflearn.com/questions/18578)

```text
CreatedDate, UpdatedDate 둘을 합쳐서 하나의 임베디드 타입으로 정의하는 것과 @MappedSuperclass로 정의하는 것의 차이가 궁금하신 거지요?

결국 상속을 사용하는 것과 위임을 사용하는 것의 차이 입니다.

객체지향의 일반적인 법칙을 따르면 상속보다는 위임이 더 좋기 때문에 위임을 사용하겠지만, 이 경우는 상속을 사용하는게 더욱 편리합니다.

임베디드 타입으로 만들면 예를 들어서 다음과 같이 만들게 됩니다.

class TraceDate {

  TYPE createdDate;

  TYPE updatedDate;

}

이런 경우 JPQL 쿼리를 하려면 다음과 같이 항상 traceDate라는 식으로 임베디드 타입을 적어주어야 합니다.

select m from Member m where m.traceDate.createdDate > ?

상속을 사용하면 다음과 같이 간단하고 쉽게 풀립니다.

select m from Member m where m.createdDate > ?

결국 둘중 선택이기는 합니다만, 편리함과 직관성 때문에, 저는 이 경우 상속을 사용합니다^^

감사합니다.
```

### 값 타입 공유 참조의 문제
- 임베디드 타입을 여러 엔티티에서 공유하면 위험하다.
- 사이드 이펙트가 발생한다. 

![](/assets/pasteimage/2022-02-06-jpa%20datatype/2022-02-06-22-20-11.png)

```java
final Address seoul = new Address("seoul", "some-gil", "1234");

Member member = new Member();
member.setName("user");
member.setHomeAddress(seoul);
em.persist(member);

Member member2 = new Member();
member2.setName("user");
member2.setHomeAddress(seoul);
em.persist(member2);

member.getHomeAddress().setCity("newCity");
```

```sql
Hibernate: 
    /* insert jpa7_datatype.b_share.Member
        */ insert 
        into
            Member
            (city, street, zipcode, name, endDate, startDate, MEMBER_ID) 
        values
            (?, ?, ?, ?, ?, ?, ?)
Hibernate: 
    /* insert jpa7_datatype.b_share.Member
        */ insert 
        into
            Member
            (city, street, zipcode, name, endDate, startDate, MEMBER_ID) 
        values
            (?, ?, ?, ?, ?, ?, ?)
Hibernate: 
    /* update
        jpa7_datatype.b_share.Member */ update
            Member 
        set
            city=?,
            street=?,
            zipcode=?,
            name=?,
            endDate=?,
            startDate=? 
        where
            MEMBER_ID=?
Hibernate: 
    /* update
        jpa7_datatype.b_share.Member */ update
            Member 
        set
            city=?,
            street=?,
            zipcode=?,
            name=?,
            endDate=?,
            startDate=? 
        where
            MEMBER_ID=?
```

- member에 대한 address를 변경하려고 했다. 그러나 member2에 대한 address도 같이 변경되었다. 
- 매우 치명적인 사이드이펙트이며 수정하기가 매우 어렵다. 

```java
final Address seoul2 = new Address(seoul.getCity(), seoul.getStreet(), seoul.getZipcode());

Member member2 = new Member();
member2.setName("user");
member2.setHomeAddress(seoul2);
em.persist(member2);
```

- 그러므로 위와 같이 객체의 복사를 통해 코드를 짜야 한다. 
- 하지만 자바에서 직접 정의한 값 타입은 자바에서는 기본타입이 아니라 객체 타입이다.
- 객체 타입의 참조를 막고 복사를 강제할 방법은 존재하지 않는다. 
- 객체의 공유는 피할 수 없다. 

### 불변 객체
- 객체 타입을 수정할 수 없도록 부작용을 원천 차단.
- 값 타입은 불변 객체로 설계해야 한다.
- 생성자로만 값을 설정하고 Setter를 만들어서는 안된다.
- Integer, String은 자바가 제공하는 대표적인 불변객체이다. 

```java
@Getter
//@Setter
@Embeddable
@NoArgsConstructor
@AllArgsConstructor
public class Address {
    private String city;
    private String street;
    private String zipcode;
}
```

```java
final Address seoul = new Address("seoul", "some-gil", "1234");

Member member = new Member();
member.setName("user");
member.setHomeAddress(seoul);
em.persist(member);

// member.getHomeAddress().setCity("newCity"); // 세터 사용 불가능

final Address busan = new Address("busan", seoul.getStreet(), seoul.getZipcode());
member.setHomeAddress(busan); // 임베디드 타입 자체를 교체한다.

tx.commit();
```

- 세터를 없애고 생성자를 통해서만 값을 넣는다.  (그 이외에 불변객체를 만드는 다양한 방법 중 하나를 선택한다. )
- 모든 임베디드 타입은 반드시 세터를 막아야 한다.


## 값 타입 컬렉션
- 하나의 엔티티로 사용하기에는 내용이 좁지만, 컬렉션의 형태로 다양한 값을 가져야 하는 경우가 있다. 회원이 있으면, 회원의 선호하는 음식이 있을 수 있으며, 이를 객체에서는 `List<String> favoriteFood;` 로 필드에 넣을 수 있다. 
- 하지만 관계형 데이타베이스에서는 칼럼에 컬렉션을 넣을 수 없다. 최근에는 JSON을 통해 컬렉션을 넣기도 하지만, 기본적으로는 불가능하다.
- 이를 값 타입 컬렉션으로 해소한다.

![](/assets/pasteimage/2022-02-06-jpa%20datatype/2022-02-06-22-44-51.png)


```java
@Entity
@Setter
@Getter
public class Member {
    @Id
    @GeneratedValue
    @Column(name = "MEMBER_ID")
    private Long id;

    private String name;

    @ElementCollection
    @CollectionTable(
            name = "FAVORITE_FOOD"
            , joinColumns = @JoinColumn(name = "MEMBER_ID")
    )
    @Column(name = "FOOD_NAME")
    private Set<String> favoriteFoods = new HashSet<>();

    @Embedded
    private Address homeAddress;

    @ElementCollection
    @CollectionTable(
            name = "ADDRESS"
            , joinColumns = @JoinColumn(name = "MEMBER_ID")
    )
    private List<Address> addressHistory = new ArrayList<>();
}

@Getter
@Embeddable
@NoArgsConstructor
@AllArgsConstructor
public class Address {
    private String city;
    private String street;
    private String zipcode;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Address address = (Address) o;
        return Objects.equals(city, address.city) && Objects.equals(street, address.street) && Objects.equals(zipcode, address.zipcode);
    }

    @Override
    public int hashCode() {
        return Objects.hash(city, street, zipcode);
    }
}

```

- 위의 코드는 선호하는 음식과 주소 내역을 값타입으로 가진다.
- Embedded 타입도 가능하다. 
- CollectionTable 을 통해 새로운 테이블을 생성하고 해당 테이블의 FK와 PK를 객체의 Id로 하고 한다. 
- 값 타입의 출력은 지연로딩을 기본으로 한다. 
- 값 타입 컬렉션은 엔티티의 값 타입과 같이 생명주기를 엔티티에 의존한다. cascade.all 과 고아객체 제거 기능을 이미 가지고 있는 것과 같다. 

- 실제로 위의 코드를 구현하면 아래와 같다. 

```java
Member member = new Member();
member.setName("kim");
member.setHomeAddress(new Address("seoul", "some-gil", "12345"));
member.getAddressHistory().add(new Address("Cairo", "some-gil", "12345"));
member.getAddressHistory().add(new Address("San Tiago", "some-gil", "12345"));

member.getFavoriteFoods().add("김치");
member.getFavoriteFoods().add("치킨");

em.persist(member);

em.flush();
em.clear();

System.out.println("=========A==========");
final Member findMember = em.find(Member.class, member.getId());

System.out.println("==========B=========");
final List<Address> addressHistory = findMember.getAddressHistory();

for (Address address : addressHistory) {
    System.out.println("address = " + address.getCity());
}
```

```sql
Hibernate: 
    /* insert jpa7_datatype.c_collection.Member
        */ insert 
        into
            Member
            (city, street, zipcode, name, MEMBER_ID) 
        values
            (?, ?, ?, ?, ?)
Hibernate: 
    /* insert collection
        row jpa7_datatype.c_collection.Member.addressHistory */ insert 
        into
            ADDRESS
            (MEMBER_ID, city, street, zipcode) 
        values
            (?, ?, ?, ?)
Hibernate: 
    /* insert collection
        row jpa7_datatype.c_collection.Member.addressHistory */ insert 
        into
            ADDRESS
            (MEMBER_ID, city, street, zipcode) 
        values
            (?, ?, ?, ?)
Hibernate: 
    /* insert collection
        row jpa7_datatype.c_collection.Member.favoriteFoods */ insert 
        into
            FAVORITE_FOOD
            (MEMBER_ID, FOOD_NAME) 
        values
            (?, ?)
Hibernate: 
    /* insert collection
        row jpa7_datatype.c_collection.Member.favoriteFoods */ insert 
        into
            FAVORITE_FOOD
            (MEMBER_ID, FOOD_NAME) 
        values
            (?, ?)
=========A==========
Hibernate: 
    select
        member0_.MEMBER_ID as member_i1_2_0_,
        member0_.city as city2_2_0_,
        member0_.street as street3_2_0_,
        member0_.zipcode as zipcode4_2_0_,
        member0_.name as name5_2_0_ 
    from
        Member member0_ 
    where
        member0_.MEMBER_ID=?
==========B=========
Hibernate: 
    select
        addresshis0_.MEMBER_ID as member_i1_0_0_,
        addresshis0_.city as city2_0_0_,
        addresshis0_.street as street3_0_0_,
        addresshis0_.zipcode as zipcode4_0_0_ 
    from
        ADDRESS addresshis0_ 
    where
        addresshis0_.MEMBER_ID=?

address = Cairo
address = San Tiago
```

- 각 각의 테이블을 생성하여 insert함을 볼 수 있다.
- 지연로딩으로서 강제로 초기화 할 때 프록시가 엔티티를 호출함을 확인할 수 있다.

```java
System.out.println("==========D=========");
findMember.getFavoriteFoods().remove("치킨");
findMember.getFavoriteFoods().add("라면");

findMember.getAddressHistory().remove(new Address("seoul", "some-gil", "12345")); // 이 경우 반드시 동등성 비교를 하도록 equals를 override 해야 한다.
findMember.getAddressHistory().add(new Address("new Seoul", "some-gil", "12345"));
```

```sql
==========D=========
Hibernate: 
    select
        favoritefo0_.MEMBER_ID as member_i1_1_0_,
        favoritefo0_.FOOD_NAME as food_nam2_1_0_ 
    from
        FAVORITE_FOOD favoritefo0_ 
    where
        favoritefo0_.MEMBER_ID=?
Hibernate: 
    /* delete collection jpa7_datatype.c_collection.Member.addressHistory */ delete 
        from
            ADDRESS 
        where
            MEMBER_ID=?
Hibernate: 
    /* insert collection
        row jpa7_datatype.c_collection.Member.addressHistory */ insert 
        into
            ADDRESS
            (MEMBER_ID, city, street, zipcode) 
        values
            (?, ?, ?, ?)
Hibernate: 
    /* insert collection
        row jpa7_datatype.c_collection.Member.addressHistory */ insert 
        into
            ADDRESS
            (MEMBER_ID, city, street, zipcode) 
        values
            (?, ?, ?, ?)
Hibernate: 
    /* insert collection
        row jpa7_datatype.c_collection.Member.addressHistory */ insert 
        into
            ADDRESS
            (MEMBER_ID, city, street, zipcode) 
        values
            (?, ?, ?, ?)
Hibernate: 
    /* delete collection row jpa7_datatype.c_collection.Member.favoriteFoods */ delete 
        from
            FAVORITE_FOOD 
        where
            MEMBER_ID=? 
            and FOOD_NAME=?
Hibernate: 
    /* insert collection
        row jpa7_datatype.c_collection.Member.favoriteFoods */ insert 
        into
            FAVORITE_FOOD
            (MEMBER_ID, FOOD_NAME) 
        values
            (?, ?)
```

- 값을 변경하는 경우 임베디드 타입과 동일하게 불변 객체로 다뤄야 한다. 
- 값 타입의 경우 컬렉션을 수정하는 것과 동일하기 때문에, add 및 remove 등 컬렉션 매서드를 사용한다. 객체 형태의 데이터를 삭제할 때는, 그것의 비교를 동등성을 기반으로 해야하므로, 반드시 **equals를 override** 해야 한다. 그렇지 않으면 계속 insert만 된다.
- 값 타입 컬렉션을 변경할 때, delete를 수행한 후 insert를 수행함을 확인할 수 있다. 이로 인하여 값의 변경에 대한 추적이 어렵다. 언제나 삭제되고 새로 생성된다.
- 값 타입은 엔티티와 다르게 식별자가 없다. 이로 인하여 update가 불가능하여 관리가 어렵다. 

## 값 타입의 사용 제한
- 정말로 단순하고 데이터가 사라져도 전혀 문제가 없는 것에 대해서만 사용한다. 선호하는 음식 등 매우 단순하 것을 사용한다.
- 실무에서는 엔티티를 만드는 것으로 해결한다. 

```java
@Entity
@Setter
@Getter
public class Member {
    @Id
    @GeneratedValue
    @Column(name = "MEMBER_ID")
    private Long id;

    private String name;

    @Embedded
    private Address homeAddress;

    @OneToMany(cascade =  CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "MEMBER_ID")
    private List<AddressEntity> addressHistory = new ArrayList<>();
}

@Getter
@Entity
@NoArgsConstructor
@Table(name = "ADDRESS")
public class AddressEntity {

    @Id
    @GeneratedValue
    @Column(name = "ADDRESS_ID")
    private Long id;

    @Embedded
    private Address address;

    public AddressEntity(String city, String street, String zipcode)
    {
        address = new Address(city, street, zipcode);
    }

    public void setId(Long id) {
        this.id = id;
    }
}
```

```java
Member member = new Member();
member.setName("kim");
member.setHomeAddress(new Address("seoul", "some-gil", "12345"));

member.getAddressHistory().add(new AddressEntity("Cairo", "some-gil", "12345"));
member.getAddressHistory().add(new AddressEntity("San Tiago", "some-gil", "12345"));

em.persist(member);
```

```sql
Hibernate: 
    /* insert jpa7_datatype.d_collection2entity.Member
        */ insert 
        into
            Member
            (city, street, zipcode, name, MEMBER_ID) 
        values
            (?, ?, ?, ?, ?)
Hibernate: 
    /* insert jpa7_datatype.d_collection2entity.AddressEntity
        */ insert 
        into
            ADDRESS
            (city, street, zipcode, ADDRESS_ID) 
        values
            (?, ?, ?, ?)
Hibernate: 
    /* insert jpa7_datatype.d_collection2entity.AddressEntity
        */ insert 
        into
            ADDRESS
            (city, street, zipcode, ADDRESS_ID) 
        values
            (?, ?, ?, ?)
Hibernate: 
    /* create one-to-many row jpa7_datatype.d_collection2entity.Member.addressHistory */ update
        ADDRESS 
    set
        MEMBER_ID=? 
    where
        ADDRESS_ID=?
Hibernate: 
    /* create one-to-many row jpa7_datatype.d_collection2entity.Member.addressHistory */ update
        ADDRESS 
    set
        MEMBER_ID=? 
    where
        ADDRESS_ID=?
```

- 위와 같은 방식으로 진행한다.
- 다만 OneToMany 단방향 맵핑이 되며 update 쿼리가 발생한다.