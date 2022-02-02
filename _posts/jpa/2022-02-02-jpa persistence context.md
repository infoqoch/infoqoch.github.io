---
layout: post
author: infoqoch
title: jpa 와 영속성 컨텍스트
categories: [jpa]
tags: [jpa, spring]
---

## 영속성 컨텍스트란?
- 영속성 컨텍스트는 1차 캐시라고 하며, DB와 객체 사이의 중간 단계이다. 
- 엔티티 매니저를 통해 영속성 컨텍스트에 접근한다. 
- 자바 환경에서는 EntityManager 와 persistance context 는 1:1 관계이며, EntityManager에 종속된다. 
- 영속성 컨텍스트를 통해 다양한 장점을 가진다.

## 영속성 컨텍스트와 객체의 상태
- 객체는 영속 상태, 비영속 상태, 준영속 상태, 삭제 상태를 가진다.
- 영속 상태는 영속성 컨텍스트에 객체가 있는 상태를 의미한다. 이 때 영속성 컨텍스트의 다양한 장점(1차 캐시, 더티 채킹, 쓰기 지연 등)을 가진다.
- 비영속 상태는 새로운 객체(new Member())가 영속 상태(em.persist(member))로 들어가지 않은 상태를 의미한다. 
- 준영속 상태는 영속상태로부터 이탈한 상태를 의미한다. 영속성 컨텍스트의 기능을 사용할 수 없다. 특정 객체를 영속성으로부터 분리(detach)하거나, 영속성 컨텍스트를 청소(em.clear())하거나 엔티티 매니저를 종료(em.close())하여 그 상태를 만들 수 있다. 
- 삭제 상태는 해당 객체가 삭제된 상태를 말한다. 

```java
public class JpaMain2 {
    public static void main(String[] args) {
        EntityManagerFactory emf = Persistence.createEntityManagerFactory("hello");

        final EntityManager em = emf.createEntityManager();

        final EntityTransaction tx = em.getTransaction();

        tx.begin();

        try{
            // 비영속 상태
            final Member member = new Member();
            member.setId(1L);
            member.setName("kim");
            
            // 영속 상태
            // DB에 저장되지 않고 영속성 컨텍스트에 저장된 상태이다.
            System.out.println("===before===");
            em.persist(member);
            System.out.println("===after===");

            // 준영속
            // 해당 엔티티를 영속성 컨텍스트로부터 분리
            // em.detach(member);

            // 삭제
            // 객체를 삭제함
            // em.remove(member);

            tx.commit();
            
        }catch (Exception e){
            tx.rollback();
        }finally {
            em.close();
        }
        emf.close();
    }
}
```

- 준영속 상태로 변경할 경우, 이전에 아무리 해당 값을 1차 캐시에 넣었다 하더라도, 다시 select 쿼리를 한다. 

```java
public class JpaMain4 {
    public static void main(String[] args) {
        EntityManagerFactory emf = Persistence.createEntityManagerFactory("hello");
        final EntityManager em = emf.createEntityManager();
        final EntityTransaction tx = em.getTransaction();
        tx.begin();

        try{
            // 영속성 상태. find할 경우 영속성 컨텍스트(1차캐시)에 저장한다.
            final Member result = em.find(Member.class, 1L);
            result.setName("kkk");

            // 영속성 상태로부터 빼기 위해서, 준영속 상태로 만든다.
            // 이를 통해 영속성 컨텍스트의 어떤 기능도 사용하지 않는다. 더티 체킹하지 않아 db의 값을 변경할 수 없다.

            em.detach(result); // 해당 객체를 영속성 컨텍스토부터 이탈시킨다.
            em.clear(); // 영속성 컨텍스트를 지운다.
            // em.close(); // 영속성 컨텍스트를 종료한다.
            System.out.println("===== after clear ===== ");
            final Member result2 = em.find(Member.class, 1L);

            tx.commit();
            
        }catch (Exception e){
            tx.rollback();
        }finally {
            em.close();
        }
        emf.close();
    }
}
```

## 영속성 컨텍스트의 특징과 기능

```java
import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.EntityTransaction;
import javax.persistence.Persistence;

public class JpaMain3 {
    public static void main(String[] args) {
        EntityManagerFactory emf = Persistence.createEntityManagerFactory("hello");

        final EntityManager em = emf.createEntityManager();

        final EntityTransaction tx = em.getTransaction();

        tx.begin();

        try{
            // 비영속 상태
            final Member member = new Member();
            member.setId(10000L);
            member.setName("kim");
            
            // 영속 상태
            // DB에 저장되지 않고 영속성 컨텍스트에 저장된 상태이다.
            System.out.println("===before===");
            em.persist(member);
            System.out.println("===after===");

            // 이 경우, print가 먼저 실행된 다음 insert가 수행된다.
            // 영속성 컨텍스트에 해당 객체가 저장(persist)되고, 그것을 찾은 다음(find), 트랜잭션이 종료 될 때 db에 저장(insert into..)한다. 쓰기 지연.
            // 쓰기 지연 자체를 JPA에서 지원하기 때문에 최적화의 여지가 많음.
            final Member result = em.find(Member.class, 10000L);
            System.out.println("result name : "+result.getName());

            // 1차 캐시로 반복 가능한 읽기(REPEATABLE READ) 등급의 트랜잭션 격리 수준을 데이타베이스가 아닌 애플리케이션 차원에서 제공.
            // 동일성을 보장한다.
            final Member result2 = em.find(Member.class, 10000L);
            System.out.println("result1 == result2 : "+(result==result2));

            // dirty checking.
            // em.update(member); 를 넣거나 em.persist(member); 넣어야 변경할 수 있냐고 할 수 있음. 하지만 컬랙션을 다루는 것처럼 jpa를 다룬다.
            // 해당 객체를 변경하면 그냥 무조건 jpa는 update를 반영한다는 생각으로 코드를 짜야 한다.
            // 영속성 컨텍스트는 @id와 entity와 더불어, 스냅샷이 존재한다.
            // 스냅샷(DB의 원본 값)과 entity를 비교하여, 그것의 변경값이 존재할 경우, 쓰기지연 저장소에 update 쿼리를 저장해놓고, 마지막에 쓰기한다.
            final Member result3 = em.find(Member.class, 1L);
            result3.setName("kkk");

            // flush가 동작한다. 트랜잭션 커밋 혹은 JPQL 쿼리 실행 시 자동으로 호출된다.
            // em.flush를 할 경우, commit의 위치와 상관없이 즉시 동작한다.
            // 더티체킹 -> 쓰기 지연 SQL 저장소에 수정된 엔티티 저장 -> 쓰기지연 SQL 저장소의 쿼리를 데이타베이스에 전송(입력, 수정, 삭제)
            // 플러시가 동작하더라도 영속성 컨텍스트는 유지된다. 데이타베이스에 동기화할 뿐이다.
            // 어찌 됐든 커밋 직전에만 동기화를 하면 된다. 사실상 대부분의 업무는 영속성 엔티티에 위임한다.
            System.out.println("====== before flush ========");
            em.flush();
            System.out.println("====== after flush ========");
            tx.commit();
            
        }catch (Exception e){
            tx.rollback();
        }finally {
            em.close();
        }
        emf.close();
    }
}
```

### 1차 캐싱
- 영속성 컨텍스트는 일종의 맵처럼 동작한다. @Id를 key로 entity를 value로 한다. 영속성 컨텍스트에 캐시로서 저장한다. 동일한 데이터를 호출할 때, DB가 아닌 캐시에서 바로 꺼낸다. 1차 캐시에 없을 경우 DB에서 조회 하며, DB에서 조회한 객체를 1차 캐시에 저장한 다음, 1차 캐시에서 해당 값을 전달한다. 
- 객체 간 동일성을 보장한다.  
- 반복 가능한 읽기(REPEATABLE READ) 등급의 트랜잭션 격리 수준을 데이타베이스가 아닌 애플리케이션 차원에서 제공한다.
- 한편, 트랜잭션의 시작과 종료에 의존하여 엔티티매니저(영속성 컨텍스트)가 생명주기를 가진다. 아주 짧은 순간에 트랜잭션의 시작과 종료가 끝나므로, 매우 복잡한 비니지스 로직이 아닌 한 큰 이득은 없다. 

### 쓰기 지연
- 영속성 컨텍스트는 트랜잭션이 선행되어야지만 동작한다. 엔티티 매니저 팩토리 -> 엔티티 매니저 -> 트랜잭션 순으로 코드를 구현한다. 
- 트랜잭션의 종료 때 쓰기(insert, update, delete)가 동작한다. 삽입, 수정과 삭제에 관련한 요청이 쓰기 지연 저장소게 저장되고, 트랜잭션의 커밋 때, 쓰기 지연 저장소에 있던 쿼리가 flush를 통해 동작한 후, commit 이 실행된다. 
- 쓰기 지연을 할 때 쿼리의 갯수는 배치의 설정에 따른다(hibernate.jdbc.batch_size). 배치를 통해 성능 향상이 가능하다. 

### 더티 체킹 
- 수정을 할 때 `member.setName("변경한 이름");` 으로 마치 자바의 컬랙션이나 객체를 다루는 것처럼 동일한 방식으로 간단하게 정리한다. 
- 더티 체킹 역시 쓰기와 동일하게 쓰기 지연을 통해 함께 처리된다. 
- 영속성 컨텍스에는 @Id, entity와 더불어 스냅샷이 있다. DB의 원래 값이었던 스냅샷과 변경된 entity의 데이터를 비교하여, 변경된 경우 update 쿼리를 날린다. 


## 나아가며
- 영속성 컨텍스트의 다양한 기능을 확인할 수 있었다. 놀라웠던 기능은 더티 체킹과 쓰기지연이었다. 
- 더티체킹의 동작을 보면 정말로 객체를 다루는 것과 전혀 다름이 없었다. 객체지향이 정말로 가능했다는 점이 놀라웠다.
- 쓰기지연은 무척 매력적이었다. 테이블 여러 개를 삽입할 때, 부모가 되는 레코드의 auto_increment 된 primary key 값을 가져오고, 그 값을 공통으로 사용하여 insert를 하는 경우가 많다. 이런 경우 insert를 여러 번 복잡하게 진행하고, 또 사용 도중에 update 하는 경우도 많다. 이 경우 insert의 순서를 통제한다는 것은 무척 어려울 테다. 이런 다양한 상황에서 특별한 고민 없이 처리해준다는 것은 매력적이다. 
- 더 나아가 하나의 비지니스 로직에서, 특정 객체의 상태가 자주 변경되는 경우가 있을 때가 있다. 예를 들면, READY 상태로 특정 객체를 만들고, 그것이 마지막에 SUCCESS 나 ERROR 등의 상태로 변경하는 경우도 있을 테다. 이런 경우 유용하게 쓰일 것 같다. 

> 김영한 선생님의 jpa 강의를 학습하고 정리 중에 있습니다. 