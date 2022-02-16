---
layout: post
author: infoqoch
title: spring-data-jpa 벌크연산
categories: [jpa]
tags: [jpa, spring]
---

## 벌크연산이란?
- 벌크연산은 update를 여러 개 날리는 쿼리를 의미한다. 
- `update member set age = age + 1 where username = 'kim';`
- 벌크연산을 위와 같은 쿼리로 jpql로 할 수 있으며, spring-data-jpa의 인터페이스 메서드를 통해서도 가능하다. 

```java
// jpql
public int bulkAgePlus(int age){
    return em.createQuery("update Member m set m.age = m.age + 1" +
                    " where m.age >= :age")
            .setParameter("age", age)
            .executeUpdate();
}

// spring-data-jpa
@Modifying(clearAutomatically = true)
@Query("update Member m set m.age = m.age + 1 where m.age >= :age")
int bulkAgePlus(@Param("age") int age);
```

```java
@Test
void 벌크_업데이트(){
    // given
    memberRepository.save(new Member("member1", 10));
    memberRepository.save(new Member("member2", 19));
    memberRepository.save(new Member("member3", 20));
    memberRepository.save(new Member("member4", 21));
    memberRepository.save(new Member("member5", 40));

    int resultCount = memberRepository.bulkAgePlus(20); // update 성공한 갯수만큼 리턴한다.

    Assertions.assertThat(resultCount).isEqualTo(3);

    // 하나의 트랜잭션에서 벌크연산의 결과값을 확인하려면 영속성 컨텍스트를 비워야 한다.
    // @Modifying(clearAutomatically = true) 으로 대체할 수 있다.
    // em.flush();
    // em.clear();

    // when
    final List<Member> findAll = memberRepository.findAll();
    Set<Integer> ages = new HashSet<>();
    ages.add(10);
    ages.add(19);
    ages.add(21);
    ages.add(22);
    ages.add(41);

    for (Member member : findAll) {
        ages.remove(member.getAge());
        System.out.println("member.getUsername() = " + member.getUsername());
        System.out.println("member.getAge() = " + member.getAge());
    }

    // then 
    Assertions.assertThat(ages).size().isEqualTo(0);

}
```

## 벌크연산의 주의점
- 수정을 위한 쿼리에는 @Modifying 을 붙여야 한다. 
- 위의 쿼리에서 em.flush() 혹은 (clearAutomatically = true) 를 사용한 것을 확인할 수 있다. 
- 벌크연산의 경우 자바 메모리까지 변경하지 못한다. 그러므로 데이터 간 차이가 발생할 수 있기 때문에 반드시 영속성 컨텍스트를 비워야 한다. 