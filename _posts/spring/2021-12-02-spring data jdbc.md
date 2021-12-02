---
layout: post
author: infoqoch
title: 스프링 jdbc
categories: [spring]
tags: [spring]
---

## 스프링 JDBC 와 in memory db
- 스프링은 메모리 내부에 인메모리데이타베이스를 제공한다. 외부 DB와 연결하지 않고 Spring-Data를 사용 가능하다.
- 인메모리데이타베이스는 보통 H2를 사용한다. 콘솔을 사용 가능하기 때문이다.

## H2 구현

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jdbc</artifactId>
</dependency>
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

```properties
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console
spring.datasource.url= jdbc:h2:mem:testdb
```

- h2 의 경우 위의 의존성을 추가하고 프로퍼티스에 위의 내용을 추가한다. 이를 통해 DB URL 을 설정할 수 있다. 그 외 console.path 를 사용하여 웹 브라우저에서 콘솔을 사용 가능하다.  

```java
@Component
@Slf4j
public class H2Runner implements ApplicationRunner {

    @Autowired
    private DataSource dataSource; // Data-JDBC 를 호출

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(ApplicationArguments args) throws Exception {
        try(Connection connection = dataSource.getConnection();){ // 예외가 발생하든 아니면 종료가 되든 close() 를 자동으로 한다.

            System.out.println(connection.getMetaData().getURL()); // properties 에서 설정한 값이 나온다. 
            System.out.println(connection.getMetaData().getUserName());

            Statement statement = connection.createStatement();
            String sql = "CREATE TABLE USER(ID INTEGER NOT NULL, name VARCHAR, PRIMARY KEY(id))";
            statement.executeUpdate(sql);
        }
        jdbcTemplate.execute("INSERT INTO USER VALUES(1,'hi')");

    }
}
```

- 오랜만에 스프링 레거시와 JSP model1 으로 돌아간 기분이었다. 실제로 Connection 을 따와서 쿼리를 짜고 commit 을 하거나 catch 를 통해 rollback 을 했던 기억이 남는다. 
- JDBCTemplate 은 위의 방법보다 발전된 방법으로 예외처리, 커넥션 연결 등 다양한 것을 쉽게 해준다. 
  
## 스프링부트와 DBCP
- DBCP란 Database Connection Pool 의 약자이다.
- 스프링부트는 HikariCP 를 기본으로 사용한다.
- 어플리케이션의 리소스와 성능을 커넥션풀이 좌우한다. 그러므로 안정적인 커넥션풀을 선택하는 것이 중요하다.
- 동시에 커넥션풀에 대한 세팅 또한 성능에 중요하다. 커넥션풀의 갯수 등 다양한 부분에 대해서 신중하게 선택해야 한다. 

## 관계형 데이타베이스의 선택
- (약간은 뜬금 없지만) 관계형 데이타베이스 중 무료로 사용 가능한 데이타베이스를 선택하여 사용한다. 
- 라이센스와 비용의 측면에서 선호되는 순서는 Oracle -> Mysql -> MariaDB -> PostgreSQL 이다. 
- Mysql 의 경우 엔터프라이즈를 사용하려면 오라클에 비용을 내야 한다.
- MariaDB의 경우 무료이지만 GPL2 에 따라 해당 DB를 사용하는 어플리케이션에 대한 소스코드를 공개해야 할 수 있다.
- PostgreSQL의 경우 무료에 특별한 의무사항이 없어서 무료 관계형 데이타베이스로 법적인 특별한 문제 없이 선택하기에 좋다. 