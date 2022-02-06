---
layout: post
author: infoqoch
title: jpa 영속성 전이 cascase와 고아 객체 orphan
categories: [jpa]
tags: [jpa, java]
---

## 영속성을 한 번에 관리한다. 영속성 전이 cascade
- 기본적으로 영속성은 아래와 같이 관리한다.

```java
@Entity
@Setter
@Getter
public class Parent {
    @Id
    @GeneratedValue
    private Long id;

    private String name;

    @OneToMany(mappedBy = "parent")
    private List<Child> children = new ArrayList<>();

    public void addChild(Child child){
        children.add(child);
        child.setParent(this);
    }
}

@Entity
@Setter
@Getter
public class Child {
    @Id
    @GeneratedValue
    private Long id;

    private String name;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "PARENT_ID")
    private Parent parent;
}
```

```java
Child child1 = new Child();
Child child2 = new Child();
child1.setName("chi1");
child2.setName("chi2");

Parent parent = new Parent();
parent.addChild(child1);
parent.addChild(child2);

em.persist(parent);
em.persist(child1);
em.persist(child2);
```

- 위의 메서드를 수행하면 insert 쿼리가 세 번 나간다. 만약 Parent 엔티티의 값을 아래와 바꾸면, 영속성을 주인 객체 하나만 수행하면 대상 객체는 자동으로 수행된다.

```java
public class Parent {
    // ...중략...
    @OneToMany(mappedBy = "parent", cascade = CascadeType.ALL)
    private List<Child> children = new ArrayList<>();
    // ...중략...
}
```

```java
em.persist(parent);
// em.persist(child1);
// em.persist(child2);
```

- 이는 프록시나 연관관계 맵핑 등 다른 기법과 전혀 관계 없다. 

## cascade의 옵션
- ALL, PERSIST, REMOVE 등 주로 사용한다.
- 사용할 때의 팁은, 
- **부모가 자식을 완전하게 관리하는 경우만 사용한다**. 자식이 다른 객체와 연관관계를 가질 경우 절대로 사용해서는 안된다. 
- 라이브사이클이 거의 일치할 때만 사용한다. 

## 고아 객체, 영속성이 끊어진 데이터를 자동 삭제한다. orphanRemoval

```java
@OneToMany(mappedBy = "parent", cascade = CascadeType.PERSIST, orphanRemoval = true)
private List<Child> children = new ArrayList<>();
```

```java
Child child1 = new Child();
Child child2 = new Child();
child1.setName("chi1");
child2.setName("chi2");

Parent parent = new Parent();
parent.addChild(child1);
parent.addChild(child2);

em.persist(parent);

em.flush();
em.clear();

final Parent findParent = em.find(Parent.class, parent.getId());

em.remove(findParent);

tx.commit();
```

```sql
Hibernate: 
    /* delete jpa6_proxy.e_orphan.Child */ delete 
        from
            Child 
        where
            id=?
Hibernate: 
    /* delete jpa6_proxy.e_orphan.Child */ delete 
        from
            Child 
        where
            id=?
Hibernate: 
    /* delete jpa6_proxy.e_orphan.Parent */ delete 
        from
            Parent 
        where
            id=?
```

- 참조(부모 객체)가 사라진 경우, 고아 객체로 보고 삭제한다. cascade의 REMOVAL 혹은 ALL과 동일하게 동작한다. 
- 위의 코드는 영속성 전이를 persist로만 한다. 고아 객체 삭제를 없앨 경우, fk 제약조건으로 인하여 부모 객체의 삭제가 정상 진행되지 않는다. `ERROR: Referential integrity constraint violation: "FKQTRFKXTU92RLLEPI09F1MWVLS: PUBLIC.CHILD FOREIGN KEY(PARENT_ID) REFERENCES PUBLIC.PARENT(ID) (1)";`
- 영속성 전이와 동일한 위험성을 가진다. 

## 자식의 생명주기
- 영속성 전이와 고아 객체를 통해 자식의 생명주기를 부모의 생명주기를 통제할 수 있다. 
- 도메인주도설계(DDD)의 Aggregate Root 개념을 구현할 때 유용하다. 자식에 대한 DAO나 Repository가 필요로 하지 않는다.