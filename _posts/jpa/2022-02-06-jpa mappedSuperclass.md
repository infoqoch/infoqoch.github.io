---
layout: post
author: infoqoch
title: jpa mappedSuperclass 공통 필드 칼럼 관리하기
categories: [jpa]
tags: [jpa, java]
---

## mappedSuperclass 공통 맵핑
- regId, regDt 등 모든 객체(테이블)의 공통 정보가 존재함.
- 이러한 공통 정보를 하나의 엔티티로 묶음.
- MappedSuperclass 를 어너테이션으로 한다. 단독으로 사용할 일이 없으므로 추상 클래스(abstract class)로 한다. 
- 매우 자주 사용한다.

## 구현

```java
@MappedSuperclass
@Setter
@Getter
public abstract class BaseEntity {

    private String createdBy;
    private String lastModifiedBy;
    private LocalDateTime createDate;
    private LocalDateTime lastModifyDate;
}

@Entity
@Setter
@Getter
public class Member extends BaseEntity{
    @Id
    @GeneratedValue
    private Long id;
    private String name;
}


@Entity
@Setter
@Getter
public class Team extends BaseEntity{
    @Id
    @GeneratedValue
    private Long id;
    private String name;
}
```