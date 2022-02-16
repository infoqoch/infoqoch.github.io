---
layout: post
author: infoqoch
title: spring-data-jpa auditing 과 엔티티의 수정일, 등록일의 자동 생성
categories: [jpa]
tags: [jpa, spring]
---

## 등록일과 수정일 등에 대한 자동 등록 기능
- 등록일과 수정일에 대하여 자동 등록이 가능하다. 
- 해당 기능을 jpa로 구현하면 다음과 같다. 

## jpa로 구현 
- 부모 클래스(@MappedSuperclass)
- 부모 클래스를 @MappedSuperclass로 생성한다. 
- @PrePersist 와 @PreUpdate 등을 활용하여 엔티티의 이벤트에 의해 동작할 메서드를 선언한다. 전자는 insert 때, 후자는 update 때 동작할 이벤트 메서드임을 가리킨다. 이를 통하여 `createDate = now;` 를 자동으로 동작하게 만든다. 

```java
@MappedSuperclass
@Getter
public class JpaBaseEntity {

    @Column(updatable = false)
    private LocalDateTime createDate;
    private LocalDateTime updateDate;

    @PrePersist
    public void prePersist(){
        LocalDateTime now = LocalDateTime.now();
        createDate = now;
        updateDate = now;
    }

    @PreUpdate
    public void preUpdate() {
        updateDate = LocalDateTime.now();
    }
}
```

- 엔티티

```java
public class Member extends JpaBaseEntity {
}
```

- 테스트

```java
@Test
void JpaEventBaseEntity() throws InterruptedException {
    // given
    final Member member = new Member("member");
    memberRepository.save(member);

    Thread.sleep(100);

    member.setUsername("changedName");

    em.flush();
    em.clear();

    //when
    final Member findMember = memberRepository.findById(member.getId()).get();

    //then
    Assertions.assertThat(findMember.getUpdateDate()).isAfter(findMember.getCreateDate());
}
```

- 엔티티의 이벤트는 아래와 같다.
    - @PrePersist, @PostPersist
    - @PreUpdate, @PostUpdate

## 스프링데이터jpa로 구현 @Auditing
- 스프링데이터jpa의 경우 좀 더 편리한 방식으로 제공한다.

- `@MappedSuperclass` 클래스를 구현한다. 
- `@EntityListeners(AuditingEntityListener.class)`를 반드시 입력한다. 
- 아래의 코드는 생성/수정일과 생성/수정자 클래스를 분리하였다. 특정 테이블은 등록/수정일만 필요하기 때문이다. 대체로 분리하여 사용하면 편하다. 

```java 
@EntityListeners(AuditingEntityListener.class)
@MappedSuperclass
@Getter
public abstract class BaseTimeEntity {

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdDate;

    @LastModifiedDate 
    private LocalDateTime lastModifiedDate;
}

@EntityListeners(AuditingEntityListener.class)
@MappedSuperclass
@Getter
public abstract class BaseEntity extends BaseTimeEntity{

    @CreatedBy
    @Column(updatable = false)
    private String createBy;

    @LastModifiedBy
    private String lastModifiedBy;
}
```

- SpringBootApplication
- 스프링부트어플리케이션에 `@EnableJpaAuditing`을 반드시 선언해야 한다.
- `@CreatedBy` 등에 사용하는 이름은 `AuditorAware<String>` 빈을 통해 정의한다. 아래는 uuid로 하였지만, 보통 스프링 시큐리티나 세션 등에서 수정자의 아이디나 이름을 꺼내온다. 

```java
@SpringBootApplication
@EnableJpaAuditing
public class DataJpaApplication {

    public static void main(String[] args) {
        SpringApplication.run(DataJpaApplication.class, args);
    }

    @Bean
    public AuditorAware<String> auditorAware(){
        // 원래의 경우 스프링시큐리티이나 세션에서 이름을 꺼내는 방식으로 활용한다.
        return ()-> Optional.of(UUID.randomUUID().toString());
    }
}
```

- 수정자와 수정일은 insert 할 때 입력해야 하는가? 검색을 할 때 last_modified_by 로 검색한다고 가정한다. 이때 만약 null 일 경우 create_by 로 다시 검색해야 한다. 이러한 경우를 없애기 위하여 insert 할 때 같이 삽입한다. 
- 기본 세팅은 insert 할 때 lastModifiedBy 가 함께 입력된다. 