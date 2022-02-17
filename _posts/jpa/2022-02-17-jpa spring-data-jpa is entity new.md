---
layout: post
author: infoqoch
title: spring-data-jpa가 엔티티가 새 엔티티를 판별하는 방법, Persistable
categories: [jpa]
tags: [jpa, spring]
---

## save()의 동작원리
- 스프링이 jpa 인터페이스를 구현할 때, 그러니까 JpaRepository 과 그것을 상속한 인터페이스를 구현할 때, SimpleJpaRepository 로 구현한다. 
- SimpleJpaRepository의 코드를 보면 다음과 같다.

```java
@Repository
@Transactional(readOnly = true)
public class SimpleJpaRepository<T, ID> implements JpaRepositoryImplementation<T, ID> {
	private final EntityManager em;

	@Transactional
	@Override
	public <S extends T> S save(S entity) {

		Assert.notNull(entity, "Entity must not be null.");

		if (entityInformation.isNew(entity)) {
			em.persist(entity);
			return entity;
		} else {
			return em.merge(entity);
		}
	}
}
```

- 위의 구현체는 jpa를 구현하는 것과 크게 차이가 없는 것을 확인할 수 있다. @Repository 를 사용하며 @Transactional(readOnly = true)을 사용함을 확인할 수 있다.
- save()의 경우 @Transactional이 있다. 그러므로 해당 리포지토리에 데이터를 삽입하면 db에 저장이 된다. 트랜잭션이 없는 경우 insert가 되지 않음을 확인할 수 있다.


```java
@SpringBootTest
class MemberRepositoryNoTransactionalTest {
    
    @Autowired
    MemberRepository memberRepository;

    @Autowired
    EntityManager em;

    @Test
    void test(){
        // repository.save에서는 insert query가 발생한다.
        //insert into member (created_date, last_modified_date, create_by, last_modified_by, age, team_id, username, id) values (?, ?, ?, ?, ?, ?, ?, ?)
        final Member member = new Member("kim");
        memberRepository.save(member);
        
        // javax.persistence.TransactionRequiredException: No EntityManager with actual transaction available for current thread - cannot reliably process 'persist' call
        final Member member2 = new Member("lee");
        em.persist(member2);
    }
}
```

## isNew()
- 그런데 save()의 구현 코드를 보면 isNew()를 기반으로 insert를 할지 update를 할지 판별한다. insert는 persist로, update는 merge로 저장한다. 
- inNew()는 어떻게 판별할까? isNew는 기본적으로 @Id로 선언한 필드의 null의 여부로 판단한다. (기본타입은 0의 여부로 판단한다).
- 한편, @Id에 @GenerateValue가 없을 경우 어떻게 할까? 

- 엔티티

```java
@Entity
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class Item {
    @Id
    private String id;
}
```

- 테스트

```java
@Test
void test(){
    final Item item1 = new Item("item1");
    itemRepository.save(item1);
}
```

- sql 결과

```sql
    select
        item0_.id as id1_0_0_ 
    from
        item item0_ 
    where
        item0_.id=?

    insert 
    into
        item
        (id) 
    values
        (?)

```

- merge로 동작한다. merge는 select과 insert/update 두 개의 쿼리가 한 쌍이다. 처음으로 "item1"이란 id를 가진 값을 select으로 검색한다. 없으면 insert를 진행한다. 
- 쿼리를 한 번만 동작하게 하는 방법은 없을까? 

```java
@Entity
@Setter
@NoArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class Item implements Persistable<String> {
    @Id
    private String id;

    @CreatedDate
    private LocalDateTime createdDate;

    @Override
    public String getId() {
        return id;
    }

    @Override
    public boolean isNew() {
        return createdDate == null;
    }

    public Item(String id) {
        this.id = id;
    }
}
```

- Persistable을 상속하면 isNew를 재정의 한다. 이 때 insert의 기준이 되는 @CreatedDate의 존재 여부로 영속 상태에 있었던 객체인지 아니면 새로운 객체인지를 판별한다. 물론 이 상황에서는 createDate에 대하여 setter를 모두 닫아야 할 것이다.
- 동일한 쿼리를 할 경우 select - insert 가 아닌, 바로 insert를 함을 확인할 수 있다. 