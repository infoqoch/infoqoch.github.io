---
layout: post
author: infoqoch
title: spring-data-jpa 페이징
categories: [jpa]
tags: [jpa, spring]
---

## spring-data-jpa 의 페이징 기능
- 페이징과 정렬 기능을 구현하였음
    - org.springframework.data.domain.Sort
    - org.springframework.data.domain.Pageable
- 반환타입도 편리하게 구현하였음
    - org.springframework.data.domain.Page : count를 포함하는 페이징
    - org.springframework.data.domain.Slice : count가 없는 다음 페이지 
    - List : 자바 컬렉션 리스트로 리턴할 경우 데이터만 출력함. 
- map 매서드를 통해 dto로 쉽게 변환 가능.


## page와 pagable

- Page를 리턴으로 하고 Pagable 을 매개변수로 한다. 
- Pagable에 Sort를 추가하여 정렬 기능을 넣을 수 있다. 
- page의 시작은 0이다.

```java
Page<Member> findByAge(int age, Pageable pageable);
```

- 테스트코드

```java
@Test
void 페이징_page(){
    memberRepository.save(new Member("member1", 10));
    memberRepository.save(new Member("member2", 10));
    memberRepository.save(new Member("member3", 10));
    memberRepository.save(new Member("member4", 10));
    memberRepository.save(new Member("member5", 10));


    int age = 10;

    // 페이지는 0부터 시작한다. 
    final PageRequest pageRequest = PageRequest.of(0, 3, Sort.by(Sort.Direction.DESC, "username"));

    final Page<Member> page = memberRepository.findByAge(age, pageRequest);

    // dto로 쉽게 반환한다.
    // json으로 변환 기능도 내부적으로 지원한다.
    final Page<MemberDto> dtos = page.map(member -> new MemberDto(member));

    for (MemberDto dto : dtos) {
        System.out.println("dto = " + dto);
    }

    final List<Member> content = page.getContent();

    final long totalCount = page.getTotalElements();
    System.out.println("totalCount = " + totalCount);

    for (Member member : content) {
        System.out.println("member = " + member);
    }

    assertThat(totalCount).isEqualTo(5);
    assertThat(content).size().isEqualTo(3);
    assertThat(page.getNumber()).isEqualTo(0);
    assertThat(page.getTotalPages()).isEqualTo(2);
    assertThat(page.isFirst()).isTrue();
    assertThat(page.hasNext()).isTrue();
}
```

- 인터페이스 메서드는 `findTop3ByAge` 등 메서드 자체에서 페이징 처리를 지원하기도 한다. 이 경우 Pagable을 무시한다.

## count query
- Page로 리턴을 받을 때, join이 많을 경우, count query를 계산 할 때의 성능 문제가 발생할 수 있다. 
- 그 경우 count를 위한 쿼리를 구현할 수 있다. 성능 상 문제가 있을 때 직접 쿼리를 짠다.

```java
@Query(
        value = "select m from Member m left join m.team t"
        ,countQuery = "select count(m) from Member m ")
Page<Member> findByAge(int age, Pageable pageable);
```

```sql
-- 엔티티를 추출할 때는 join을 사용한다.
select
    member0_.id as id1_0_,
    member0_.age as age2_0_,
    member0_.team_id as team_id4_0_,
    member0_.username as username3_0_ 
from
    member member0_ 
left outer join
    team team1_ 
        on member0_.team_id=team1_.id 
order by
    member0_.username desc limit ?

-- count를 추출할 때는 join이 없다.
select
    count(member0_.id) as col_0_0_ 
from
    member member0_
```

## slice
- 카운트가 없이 next 정도의 정보만을 가진 Slice 객체로 리턴한다.
- Page가 Slice를 상속하는 형태이기 때문에, page의 몇 가지 기능을 사용하지 못한다. 

```java
Slice<Member> findByAgeAndUsernameLike(int age, Pageable pageable, String username);
```

```sql
select
    member0_.id as id1_0_,
    member0_.age as age2_0_,
    member0_.team_id as team_id4_0_,
    member0_.username as username3_0_ 
from
    member member0_ 
where
    member0_.age=? 
    and (
        member0_.username like ? escape ?
    ) 
order by
    member0_.username desc limit ? offset ?

-- limit 4 offset 3
```
