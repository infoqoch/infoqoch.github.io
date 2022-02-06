---
layout: post
author: infoqoch
title: jpa의 기본적인 활용과 JPQL 
categories: [jpa]
tags: [jpa, java]
---

## 들어가며
- 가장 기본적인 형태의 JPA의 활용은 아래와 같다.
- SQL을 사용하여 쿼리를 할 수 있으며 이를 JPQL이라 한다. JPQ를 통하여 쿼리를 날려도, 객체지향적 개발이 가능하고 다양한 메서드를 사용하며 방언에 자유롭기 때문에 활용도가 아주 높다.

## 실습
- 자바 프로젝트로 진행한다.
- maven

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>jpa-basic</groupId>
    <artifactId>ex1-hello-jpa</artifactId>
    <version>1.0.0</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
    </properties>

    <dependencies>
        <!-- JPA 하이버네이트 -->
        <dependency>
            <groupId>org.hibernate</groupId>
            <artifactId>hibernate-entitymanager</artifactId>
            <version>5.4.13.Final</version>
        </dependency>

        <!-- H2 데이터베이스 -->
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <version>1.4.200</version>
        </dependency>

        <dependency>
            <groupId>javax.xml.bind</groupId>
            <artifactId>jaxb-api</artifactId>
            <version>2.3.1</version>
        </dependency>

        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <version>1.18.22</version>
        </dependency>

    </dependencies>

</project>
```

- META-INF/persistance.xml 에 아래의 데이터를 추가한다.

```xml
<persistence version="2.2"
             xmlns="http://xmlns.jcp.org/xml/ns/persistence" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/persistence http://xmlns.jcp.org/xml/ns/persistence/persistence_2_2.xsd">
    <persistence-unit name="hello">
        <properties>
            <!-- 필수 속성 -->
            <property name="javax.persistence.jdbc.driver" value="org.h2.Driver"/>
            <property name="javax.persistence.jdbc.user" value="sa"/>
            <property name="javax.persistence.jdbc.password" value=""/>
            <property name="javax.persistence.jdbc.url" value="jdbc:h2:tcp://localhost/~/test"/>
            <property name="hibernate.dialect" value="org.hibernate.dialect.H2Dialect"/>
            <!--jpa는 데이터베이스에 종속적이지 않다. 데이터베이스 마다 sql이 차이를 가짐. 특히 페이징이 그러함. 이러한 부분을 방언(dialect)이라 함.-->
            <!--javax는 표준을 의미하며 다른 구현체로 교체 가능하다. hibernate로 시작하는 것들은 해당 라이브러리에 의존함-->

            <!-- 옵션 -->
            <!--SQL 출력-->
            <property name="hibernate.show_sql" value="true"/>
            <!--포맷에 따라 예쁘게 출력-->
            <property name="hibernate.format_sql" value="true"/>
            <!--출력에 대한 정보-->
            <property name="hibernate.use_sql_comments" value="true"/>
            <!--<property name="hibernate.hbm2ddl.auto" value="create" />-->
        </properties>
    </persistence-unit>
</persistence>
```


```java
import lombok.Getter;
import lombok.Setter;

import javax.persistence.Entity;
import javax.persistence.Id;

@Entity
@Getter
@Setter
public class Member {
    @Id
    private Long id;
    private String name;
}

// -----------------------------


import javax.persistence.*;
import java.util.List;

public class JpaMain {
    public static void main(String[] args) {
        EntityManagerFactory emf = Persistence.createEntityManagerFactory("hello");
        // 엔티티매니저팩토리는 하나만 생성하여 어플리케이션 전체에서 공유한다.

        final EntityManager em = emf.createEntityManager();
        // 엔티티 매니저는 쓰레드간 공유하며 안된다. 사용하고 버린다. 데이타베이스 커넥션과 사용 방법이 유사하다. 바로 반납한다.

        final EntityTransaction tx = em.getTransaction();
        // JPA의 모든 데이터 변경은 반드시 트랜잭션 안에서 실행해야 한다.
        
        tx.begin();

        try{
//            입력
//            final Member member = new Member();
//            member.setId(2L);
//            member.setName("kim");
//            em.persist(member);

//            조회
//            final Member member = em.find(Member.class, 1L);
//            System.out.println("member name : "+member.getName());

//            수정
//            final Member member = em.find(Member.class, 1L);
//            member.setName("lee");
//            System.out.println("member name : "+member.getName());

//            삭제
//            final Member member = em.find(Member.class, 1L);
//            member.setName("lee");
//            em.remove(member);

            // JPQL을 통해 쿼리를 사용할 수 있다.
            // 엔티티 객체를 대상으로 데이터를 호출할 수 있다. 그러니까 sql을 쿼리한다 하더라도 엔티티 대상을 객체로 하기 때문에, 객체 지향적인 개발을 할 수 있다.
            // JPQL은 객체 지향 SQL이다.
            // 단순한 쿼리를 넘어서 다양한 기능을 매서드를 통해 사용 가능하다. 특히 방언에 따라 쿼리를 짠다.
            final List<Member> result = em.createQuery("select m from Member as m", Member.class)
                    .setFirstResult(5)
                    .setMaxResults(10)
                    .getResultList();

            for(Member member : result){
                System.out.println("member.name : "+member.getName());
            }

            tx.commit(); // 트랜잭션이 종료 될 때, 입력, 수정, 삭제할 내용이 있는지를 확인하고, 쿼리를 보내 마무리한다.
        }catch (Exception e){
            tx.rollback();
        }finally {
            em.close();
        }
        emf.close();
    }
}

```

## 정리
- JPA를 통하여 단순한 매서드를 통해 sql을 자동생성하여 DB에 사용가능하다. 
- JPQL을 활용하여 단순하게 쿼리를 사용한다 하더라도, JPQL을 통해 필요로한 절을 메서드 형태로 추가 가능하다. 
- RDB에서 가지고 온 데이터를, 해당 데이터의 컬럼에 맞춰 객체를 만들고 그 객체에 데이터를 넣는 방식으로부터 탈피한다. Member 라는 객체지향적인 객체를 자동으로 주입 및 생성한다. 어떤 측면으로든 개발이 편해지고 빨라 진다.


> 김영한 선생님의 인프런 JPA 수업을 정리 중입니다. 