---
layout: post
author: infoqoch
title: 로그백과 p6Spy 활용하여 JPA로깅 하기 + 로그백 필터링
categories: [spring]
tags: [spring, jpa]
---

# 들어가며
- 여러번 세팅을 하지만 항상 애를 먹었던 것 중 하나가 로그이다. 로그를 하나 하나 디테일하게 설정하는 것이 어렵다.
- 특히 특정 로그는 발생시키고 다른 로그는 제거하는 로직을 구현하는 것 또한 힘들었다. 
- 로깅이 원하는 방향대로 동작하지 않아 힘들었는데 ㅠ 이 글이 많은 분들께 도움이 되기를 바란다!

# 요구사항
- JPA의 쿼리를 예쁘게 만들고 싶다. 그러니까 JPA의 쿼리가 단 한 번만 발생하고, 파라미터는 ?가 아니라 바로 주입되었으면 좋겠다. 
- 쿼리를 발생시킨 메서드를 확인하고 싶다. mybatis의 경우 쿼리가 발생한 메서드의 이름이 로거에 바로 남는다. 하지만 jpa는 언제나 org.hibernate.SQL 로 나온다. 예를 들면 아래와 같다. 

```log
마이바티스 : 
2022-04-14 15:45:19.195 [main] DEBUG a.b.c.d.e.f.findById - ==>  Preparing: SELECT * FROM TABLE WHERE ID = ? 

JPA:
2022-07-23 04:53:22.887 [main] DEBUG org.hibernate.SQL - 
    /*  select
        max(s.no) 
    from
        Send s */ select
            max(send0_.no) as col_0_0_ 
        from
            send send0_
```

- 반복되는 쿼리는 필터링하고 싶다. 스케줄러를 통해 특정 상태를 가지는 레코드에 대한 이벤트 처리를 하고 싶을 수 있다. 이 때 쿼리가 계속 발생하는 것을 방지하고 싶을 수 있다.

```java
@Scheduled(fixedDelay = 100) 
public void run() {
    // 0.1초마다 아래의 쿼리가 로그에 남는다.
    List<Send> sendRequests = sendRunnerService.findByStatus(REQUEST);
    // 이하 생략
}
```

# 로깅을 사용하는 가장 간단한 방법
- 앞서의 요구사항을 수행하기 전에, 프로퍼티스를 활용한 최대한 간단한 로깅을 정리하였다.
- 스프링과 jpa를 활용한 가장 쉬운 로깅 방법은 application.yml 을 아래와 같이 설정하는 것이다. 로깅의 레벨과 파일의 저장, 롤링까지 세세하게 설정 가능하다.
- 이하 테스트는 `# 설정` 부분만을 건든다.

```yaml
spring:
  datasource:
    url: jdbc:h2:mem:test
    username: sa
    password:
    driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: create
    properties:
      hibernate:
       show_sql: true # 설정
       format_sql: true # 설정
       use_sql_comments: true # 설정

logging:
  level:
    root: INFO
    study.querydsl: DEBUG # 프로젝트 위치
    org.hibernate.SQL: DEBUG  # 설정
    org.hibernate.type.descriptor.sql: TRACE # 설정
  pattern:
    rolling-file-name: ${LOG_FILE}.%d{yyyy-MM-dd}-%i.log
  file:
    path: C://logs//study//querydsl
    max-size: 10MB
```

- 더 나아가 테스트를 진행할 로직은 아래와 같다. 동일한 로직을 계속 반복할 예정이다.

```java
package study.querydsl.entity;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.EntityManager;
import java.util.List;

@SpringBootTest
@Transactional
class TeamTest {
    @Autowired
    EntityManager em;

    @Test
    void test(){
        Team team = new Team("teamA"); 

        // insert into team (team_id, name) values (?, ?);
        em.persist(team); 

        em.flush();
        em.clear();

        // select * from team t where t.team_id =?; 
        em.find(Team.class, team.getId()); 
    }
}
```

## SQL 로깅 생략
- 위의 내용을 확인하기에 앞서, 다음과 같은 형태로 로깅을 해보자. 
- 아래와 같이 진행하면 콘솔과 파일은 생성되고 로그가 정상 동작한다. 하지만 SQL로그는 발생하지 않음을 확인할 수 있다.

```yaml 
spring:
  jpa:
    properties:
      hibernate:
       show_sql: false
       format_sql: false
       use_sql_comments: false

logging:
  level:
    org.hibernate.SQL: INFO
    org.hibernate.type.descriptor.sql: INFO
```

## SQL의 콘솔과 로그에서의 출력
- 아래와 같이 레벨을 DEBUG와 TRACE로 각각 설정하면 아래와 같이 SQL로그가 발생한다.

```yaml
logging:
  level:
    org.hibernate.SQL: DEBUG
    org.hibernate.type.descriptor.sql: TRACE
```

```log
2022-07-23 08:52:52.404 DEBUG 13188 --- [Test worker] org.hibernate.SQL                        : insert into team (name, team_id) values (?, ?)
2022-07-23 08:52:52.409 TRACE 13188 --- [Test worker] o.h.type.descriptor.sql.BasicBinder      : binding parameter [1] as [VARCHAR] - [teamA]
2022-07-23 08:52:52.410 TRACE 13188 --- [Test worker] o.h.type.descriptor.sql.BasicBinder      : binding parameter [2] as [BIGINT] - [1]
2022-07-23 08:52:52.437 DEBUG 13188 --- [Test worker] org.hibernate.SQL                        : select team0_.team_id as team_id1_2_0_, team0_.name as name2_2_0_ from team team0_ where team0_.team_id=?
2022-07-23 08:52:52.439 TRACE 13188 --- [Test worker] o.h.type.descriptor.sql.BasicBinder      : binding parameter [1] as [BIGINT] - [1]
2022-07-23 08:52:52.449 TRACE 13188 --- [Test worker] o.h.type.descriptor.sql.BasicExtractor   : extracted value ([name2_2_0_] : [VARCHAR]) - [teamA]
```

- org.hibernate.SQL 은 PreparedStatement 를 출력한다.
- org.hibernate.type.descriptor.sql은 바인딩되는 파라미터를 출력한다.
- 로깅과 콘솔을 위한 가장 간단한 세팅이다.

## 콘솔에서만 출력한다면?
- 이번에는 다음과 같이 설정하자.

```yaml 
spring:
  jpa:
    properties:
      hibernate:
       show_sql: true
       format_sql: false
       use_sql_comments: false

logging:
  level:
    org.hibernate.SQL: INFO
    org.hibernate.type.descriptor.sql: INFO
```

```log
Hibernate: call next value for hibernate_sequence
Hibernate: insert into team (name, team_id) values (?, ?)
Hibernate: select team0_.team_id as team_id1_2_0_, team0_.name as name2_2_0_ from team team0_ where team0_.team_id=?
```

- 위는 **콘솔**에 찍힌 로그이다. 아까와 달리 로그가 다소 달라짐을 확인할 수 있다. 
- 그리고 path에 저장된 **로그 파일**을 열면, 어떤 sql로 없는 것을 확인할 수 있다. 
- 내가 가장 헤맸던 부분이 바로 이 부분이다! 로그백의 필터링을 먹이고 해당 필터가 동작함을 분명하게 확인하였는데도 불구하고 위의 로그가 찍혔다.
- 사실 이러한 이유는 단순했다. show_sql은 콘솔에 출력하는 System.out이었고, org.hibernate.SQL은 로거를 사용한 로깅이었기 때문이다. 이 개념이 없었던 나는 많은 시간을 헤맸다🥶🥶🥶. 
- 개인적으로 로그파일과 콘솔에 출력되는 내용은 동일한게 보기 좋다고 생각했다. 특히 로그백 필터 등을 콘솔에 적용하고 싶을 경우 그러하다. 개인적으로 show_sql은 false가 낫다고 생각한다.

## format_sql

```yaml 
spring:
  jpa:
    properties:
      hibernate:
       show_sql: false
       format_sql: true
       use_sql_comments: false

logging:
  level:
    org.hibernate.SQL: DEBUG
    org.hibernate.type.descriptor.sql: TRACE
```

```log
2022-07-23 09:03:13.434 DEBUG 13852 --- [Test worker] org.hibernate.SQL                        : 
    insert 
    into
        team
        (name, team_id) 
    values
        (?, ?)
2022-07-23 09:03:13.439 TRACE 13852 --- [Test worker] o.h.type.descriptor.sql.BasicBinder      : binding parameter [1] as [VARCHAR] - [teamA]
2022-07-23 09:03:13.440 TRACE 13852 --- [Test worker] o.h.type.descriptor.sql.BasicBinder      : binding parameter [2] as [BIGINT] - [1]
2022-07-23 09:03:13.467 DEBUG 13852 --- [Test worker] org.hibernate.SQL                        : 
    select
        team0_.team_id as team_id1_2_0_,
        team0_.name as name2_2_0_ 
    from
        team team0_ 
    where
        team0_.team_id=?
2022-07-23 09:03:13.471 TRACE 13852 --- [Test worker] o.h.type.descriptor.sql.BasicBinder      : binding parameter [1] as [BIGINT] - [1]
2022-07-23 09:03:13.480 TRACE 13852 --- [Test worker] o.h.type.descriptor.sql.BasicExtractor   : extracted value ([name2_2_0_] : [VARCHAR]) - [teamA]
```

- preparedStatement가 예쁘게 찍힌다!

## use_sql_comments
- `use_sql_comments : true` 로 변경한다. 
- Spring-data-jpa를 사용할 경우 아래와 같은 형태로 사용하면, 작성한 주석이 발생한다.

```java
    @Test
    void test2() {
        String query = "select t from Team t";
        final List<Team> result = em
                .createQuery(query, Team.class)
                .setHint(QueryHints.HINT_COMMENT, "This is my comment")
                .getResultList();
    }
```

```log
2022-07-23 10:23:59.699 DEBUG 17752 --- [    Test worker] org.hibernate.SQL                        : 
    /* This is my comment */ select
        team0_.team_id as team_id1_2_,
        team0_.name as name2_2_ 
    from
        team team0_
```

- spring-data-jpa에서는 아래와 같이 설정한다.

```java
public interface TeamRepository extends JpaRepository<Team, Long> {
    @QueryHints({
            @QueryHint(name = org.hibernate.annotations.QueryHints.COMMENT, value = "add comment!")
    })
    @Query("select t from Team t")
    List<Team> findAll();
}
```

- 원하지 않는 쿼리에 대해서 누락시켰을 때, 원래 이러한 방식으로 진행하였다.
- p6spy를 통해 처리하는 것이 좋았다.

# logback-spring.xml 
- 로그백은 앞서의 프로퍼티스에서 설정할 수 있지만 xml을 통해 설정할 수 있다.
- 마이바티스와 달리 logback-spring.xml  하나로 간편하게 설정할 수 있다.

- 먼저 아래의 의존성을 받는다. 필터를 사용하는 방식 중 하나인 EvaluatorFilter 을 사용하려면 아래의 의존성이 필요하다.

```groovy
// build.gradle
implementation 'org.codehaus.janino:janino'
```

- xml 설정을 통해 properties에서 로거와 관련한 내용을 뺄 수 있다. 
- 다만, hibernate의 포맷 등 기능을 사용하려면 아래와 같이 설정해야 한다.

```yaml
spring:
  datasource:
    url: jdbc:h2:mem:test
    username: sa
    password:
    driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: create
    properties:
      hibernate:
        show_sql: false
        format_sql: false
        use_sql_comments: false

#logging:
#  level:
#    root: INFO
#    study.querydsl: DEBUG # 프로젝트 위치
#    org.hibernate.SQL: DEBUG
#    org.hibernate.type.descriptor.sql: TRACE
#  pattern:
#    rolling-file-name: ${LOG_FILE}.%d{yyyy-MM-dd}-%i.log
#  file:
#    path: C://logs//study//querydsl
#    max-size: 10MB
```

- 실제 xml 파일은 아래와 같다.
- resources/logback-spring.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property name="LOG_PREFIX" value="study-querydsl"></property>
    <property name="LOG_PATH" value="c:/logs/study/querydsl"/>
  
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <filter class="ch.qos.logback.core.filter.EvaluatorFilter">
            <evaluator>
                <expression>if (message.contains("insert")){ return true; } return false;</expression>
            </evaluator>
            <OnMismatch>ACCEPT</OnMismatch>
            <OnMatch>DENY</OnMatch>
        </filter>

        <file>${LOG_PATH}/${LOG_PREFIX}.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>${LOG_PATH}/${LOG_PREFIX}.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <maxFileSize>10MB</maxFileSize>
        </rollingPolicy>
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <filter class="ch.qos.logback.core.filter.EvaluatorFilter">
            <evaluator>
                <expression>if (message.contains("insert")){ return true; } return false;</expression>
            </evaluator>
            <OnMismatch>ACCEPT</OnMismatch>
            <OnMatch>DENY</OnMatch>
        </filter>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>


    <root level="INFO">
        <appender-ref ref="CONSOLE" />
        <appender-ref ref="FILE" />
    </root>

    <logger name="study.querydsl" level="DEBUG" additivity="true"/> <!--프로젝트 로그-->
    <logger name="org.hibernate.SQL" level="DEBUG" additivity="true" /> <!--sql 로그-->
    <logger name="org.hibernate.type.descriptor.sql" level="TRACE" additivity="true" /> <!--파라미터 로그-->
</configuration>
```

- 위의 내용 중 특이한 부분은 필터 부분이다. 자바 문법을 사용하여 `<expression>` 태그에 boolean을 리턴하는 필터를 구현한다.
- true일 경우 `<OnMatch>`의 동작을 수행하며 그렇지 않을 경우 `<OnMismatch>`을 수행한다.
- ACCEPT은 해당 로그를 실제로 작성한다는 의미이며 DENY일 경우 로그를 제거한다. 
- 위의 필터는 insert가 들어간 로그를 제거한다는 의미이며 가장 먼저 예로 든 테스트를 동작하면 아래와 같은 로그가 발생한다.

```log
2022-07-23 10:44:37.661 [Test worker] DEBUG org.hibernate.SQL - call next value for hibernate_sequence
2022-07-23 10:44:37.767 [Test worker] TRACE o.h.type.descriptor.sql.BasicBinder - binding parameter [1] as [VARCHAR] - [teamA]
2022-07-23 10:44:37.768 [Test worker] TRACE o.h.type.descriptor.sql.BasicBinder - binding parameter [2] as [BIGINT] - [1]
2022-07-23 10:44:37.793 [Test worker] DEBUG org.hibernate.SQL - select team0_.team_id as team_id1_2_0_, team0_.name as name2_2_0_ from team team0_ where team0_.team_id=?
2022-07-23 10:44:37.795 [Test worker] TRACE o.h.type.descriptor.sql.BasicBinder - binding parameter [1] as [BIGINT] - [1]
2022-07-23 10:44:37.804 [Test worker] TRACE o.h.t.descriptor.sql.BasicExtractor - extracted value ([name2_2_0_] : [VARCHAR]) - [teamA]
```

- 두 번째와 세 번째 로그에는 insert에 사용하는 파라미터가  있음을 확인할 수 있다. 그러니까 두 번재 로그에 원래는  `insert into ...` 의 형태의 로그가 발생해야 하는데 발생하지 않는다.
- 이하 select 쿼리는 로그가 잘 찍힘을 확인할 수 있다.
- 단순한 preparedStatement만 로그를 작성할 경우 이 기능으로 충분하다. 하지만 좀 더 복잡한 로직을 수행하려면 logback으로만 필터링을 하기에는 다소 어렵다.
- 좀 더 쿼리를 세세하게 짤 수 있는 p6spy를 활용하여 요구사항에 따라 로그를 작성할 수 있었다.

## 추가... ILoggingEvent 활용하기
- 필터를 자바 파일로 추출할 수 있다. 컴파일 시점에서 문법오류를 잡기 때문에 xml보다 나은 방식이다.
- xml 파일이 장황해지는 것을 방지한다.
- 의존성 janino가 필요 없다.

```xml
<filter class="study.querydsl.log.IgnoreLogFilter"/>
<!-- 이하 주석 처리한다.
<filter class="ch.qos.logback.core.filter.EvaluatorFilter">
  <evaluator>
      <expression>if (message.contains("insert")){ return true; } return false;</expression>
  </evaluator>
  <OnMismatch>ACCEPT</OnMismatch>
  <OnMatch>DENY</OnMatch>
</filter>
-->
```

```java
package study.querydsl.log;

import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.filter.Filter;
import ch.qos.logback.core.spi.FilterReply;

public class IgnoreLogFilter extends Filter<ILoggingEvent> {
    @Override
    public FilterReply decide(ILoggingEvent event) {
        if (event.getMessage().contains("insert") ) {
            return FilterReply.DENY;
        } else {
            return FilterReply.ACCEPT;
        }
    }
}
```


# p6spy의 활용
- 다음의 의존성을 추가한다.
- `implementation 'com.github.gavlyukovskiy:p6spy-spring-boot-starter:1.8.0'`

- logback-spring.xml에서 아래의 로깅 레벨을 INFO로 변경한다.  p6spy는 데이타소스를 데코레이션 패턴으로 감싸기 때문에, 로깅 레벨이 필요 없다. (이로 인하여 성능 문제가 있다. 운영에서 쓰면 안된다.)

```xml
<logger name="org.hibernate.SQL" level="INFO" additivity="true" /> <!--sql 로그-->
<logger name="org.hibernate.type.descriptor.sql" level="INFO" additivity="true" /> <!--파라미터 로그-->
```

- 로그백의 필터를 주석처리한다. insert 쿼리가 발생하도록 한다.

```xml
<!--<filter class="study.querydsl.log.IgnoreLogFilter"/>-->
````

- 프로퍼티스에서 아래와 같이 p6spy의 사용 여부를 true로 한다. default가 true 이므로 생략해도 된다.

```yaml
decorator:
  datasource:
    p6spy:
      enable-logging: true
```

- 이렇게 설정하면 아래와 같이 로그가 발생한다. 좀 더 구체적인 정보가 노출된다. 파라미터가 입력된 상태로 노출되어 보기 더 편해졌다. 

```log
2022-07-23 11:02:52.015 [Test worker] INFO  p6spy - #1658541772015 | took 1ms | statement | connection 3| url jdbc:h2:mem:test
insert into team (name, team_id) values (?, ?)
insert into team (name, team_id) values ('teamA', 1);
2022-07-23 11:02:52.040 [Test worker] INFO  p6spy - #1658541772040 | took 0ms | statement | connection 3| url jdbc:h2:mem:test
select team0_.team_id as team_id1_2_0_, team0_.name as name2_2_0_ from team team0_ where team0_.team_id=?
select team0_.team_id as team_id1_2_0_, team0_.name as name2_2_0_ from team team0_ where team0_.team_id=1;
2022-07-23 11:02:52.070 [Test worker] INFO  p6spy - #1658541772070 | took 0ms | rollback | connection 3| url jdbc:h2:mem:test
```

- 만약 필터를 로그백에서 추가하면 어떨까? 그럼 아래와 같이 로그가 발생한다. insert 로그가 발생하지 않음을 확인할 수 있다.

```xml
<!-- 필터를 사용한다 -->
<filter class="study.querydsl.log.IgnoreLogFilter"/> 
```

```log
call next value for hibernate_sequence;
2022-07-23 11:05:28.892 [Test worker] INFO  p6spy - #1658541928892 | took 0ms | statement | connection 3| url jdbc:h2:mem:test
select team0_.team_id as team_id1_2_0_, team0_.name as name2_2_0_ from team team0_ where team0_.team_id=?
select team0_.team_id as team_id1_2_0_, team0_.name as name2_2_0_ from team team0_ where team0_.team_id=1;
2022-07-23 11:05:28.936 [Test worker] INFO  p6spy - #1658541928936 | took 0ms | rollback | connection 3| url jdbc:h2:mem:test
```

## p6spy의 포매터
- p6spy은 데이터를 로그로 변환할 때 MessageFormattingStrategy을 기준으로 한다. 위의 로깅 방식을 수정하려면 MessageFormattingStrategy 을 상속한 객체를 구현한 후, 해당 포매터를 바꿔야 한다. 구체적인 내용은 다음의 링크를 참고 바란다. 이번 p6spy를 설정하는데 절대적인 도움을 받았다!!   https://github.com/shirohoo/p6spy-custom-formatter
- 위의 블로그를 참고하여 작성한, 특정 쿼리의 로그를 누락하기 위한 코드는 아래와 같다.

```java
package study.querydsl.log;

import com.p6spy.engine.logging.Category;
import com.p6spy.engine.spy.appender.MessageFormattingStrategy;
import org.hibernate.engine.jdbc.internal.FormatStyle;

import java.text.MessageFormat;
import java.util.Locale;
import java.util.Objects;
import java.util.Stack;
import java.util.function.Predicate;

import static java.util.Arrays.stream;

// 출처 :
// https://github.com/shirohoo/p6spy-custom-formatter
public class MyP6spyFormattingStrategy implements MessageFormattingStrategy {
    private static final String NEW_LINE = System.lineSeparator();
    private static final String P6SPY_FORMATTER = "MyP6spyFormattingStrategy";
    private static final String PACKAGE = "study.querydsl";  // 패키지를 설정해야 메서드 스택을 확인할 수 있다. 
    private static final String CREATE = "create";
    private static final String ALTER = "alter";
    private static final String COMMENT = "comment";


    @Override
    public String formatMessage(final int connectionId, final String now, final long elapsed, final String category, final String prepared, final String sql, final String url) {
        return sqlFormatToUpper(sql, category, getMessage(connectionId, elapsed, getStackBuilder()));
    }

    private String sqlFormatToUpper(final String sql, final String category, final String message) {
        if (Objects.isNull(sql.trim()) || sql.trim().isEmpty()) {
            return "";
        }

        return new StringBuilder()
                // .append(NEW_LINE)
                .append(sqlFormatToUpper(sql, category))
                .append(message)
                .toString();
    }

    private String sqlFormatToUpper(final String sql, final String category) {
        if (isStatementDDL(sql, category)) {
            return FormatStyle.DDL
                    .getFormatter()
                    .format(sql)
                    .toUpperCase(Locale.ROOT)
                    .replace("+0900", "");
        }
        return FormatStyle.BASIC
                .getFormatter()
                .format(sql)
                .toUpperCase(Locale.ROOT)
                .replace("+0900", "");
    }

    private boolean isStatementDDL(final String sql, final String category) {
        return isStatement(category) && isDDL(sql.trim().toLowerCase(Locale.ROOT));
    }

    private boolean isStatement(final String category) {
        return Category.STATEMENT.getName().equals(category);
    }

    private boolean isDDL(final String lowerSql) {
        return lowerSql.startsWith(CREATE) || lowerSql.startsWith(ALTER) || lowerSql.startsWith(COMMENT);
    }

    private String getMessage(final int connectionId, final long elapsed, final StringBuilder callStackBuilder) {
        return new StringBuilder()
                .append(NEW_LINE)
                .append(NEW_LINE)
                .append("\t").append(String.format("Connection ID: %s", connectionId))
                .append(NEW_LINE)
                .append("\t").append(String.format("Execution Time: %s ms", elapsed))
                .append(NEW_LINE)
                .append(NEW_LINE)
                .append("\t").append(String.format("Call Stack (number 1 is entry point): %s", callStackBuilder))
                .append(NEW_LINE)
                .append(NEW_LINE)
                .append("----------------------------------------------------------------------------------------------------")
                .toString();
    }

    private StringBuilder getStackBuilder() {
        final Stack<String> callStack = new Stack<>();
        stream(new Throwable().getStackTrace())
                .map(StackTraceElement::toString)
                .filter(isExcludeWords())
                .forEach(callStack::push);

        int order = 1;
        final StringBuilder callStackBuilder = new StringBuilder();
        while (!callStack.empty()) {
            callStackBuilder.append(MessageFormat.format("{0}\t\t{1}. {2}", NEW_LINE, order++, callStack.pop()));
        }
        return callStackBuilder;
    }

    private Predicate<String> isExcludeWords() {
        return charSequence -> charSequence.startsWith(PACKAGE) && !charSequence.contains(P6SPY_FORMATTER);
    }
}
```

- 위의 코드를 설정하기 위한 설정 코드는 아래와 같다.

```java
package study.querydsl.log;

import com.p6spy.engine.spy.P6SpyOptions;
import org.springframework.context.annotation.Configuration;

import javax.annotation.PostConstruct;

@Configuration
public class LogConfiguration {
    @PostConstruct
    public void setLogMessageFormat() {
        P6SpyOptions.getActiveInstance().setLogMessageFormat(MyP6spyFormattingStrategy.class.getName());
    }
}
```

- 로그백 필터는 아래와 같이 수정한다. SQL을 대문자로 변경하여, 이에 대응하도록 수정하였다.

```java
package study.querydsl.log;

import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.filter.Filter;
import ch.qos.logback.core.spi.FilterReply;

public class IgnoreLogFilter extends Filter<ILoggingEvent> {
    @Override
    public FilterReply decide(ILoggingEvent event) {
        if (event.getMessage().contains("INSERT") || event.getMessage().length()==0 ) {
            return FilterReply.DENY;
        } else {
            return FilterReply.ACCEPT;
        }
    }
}
```

- 그럼 아래와 같이 로그가 발생하며, insert 쿼리가 깔끔하게 제거됨을 확인할 수 있다.

```log
2022-07-23 11:21:51.246 [Test worker] INFO  p6spy - 
    CALL NEXT VALUE FOR HIBERNATE_SEQUENCE

	Connection ID: 3
	Execution Time: 17 ms

	Call Stack (number 1 is entry point): 
		1. study.querydsl.entity.TeamTest.test(TeamTest.java:26)

----------------------------------------------------------------------------------------------------
2022-07-23 11:21:51.406 [Test worker] INFO  p6spy - 
    SELECT
        TEAM0_.TEAM_ID AS TEAM_ID1_2_0_,
        TEAM0_.NAME AS NAME2_2_0_ 
    FROM
        TEAM TEAM0_ 
    WHERE
        TEAM0_.TEAM_ID=1

	Connection ID: 3
	Execution Time: 0 ms

	Call Stack (number 1 is entry point): 
		1. study.querydsl.entity.TeamTest.test(TeamTest.java:32)

----------------------------------------------------------------------------------------------------
```

- 위 로그의 특징은, 파라미터가 붙은 쿼리를 생성하기 때문에, 필터링에 유리하다.
-  `study.querydsl.entity.TeamTest.test(TeamTest.java:32)` 을 통해 마이바티스에서 한 것처럼 어떤 메서드가 sql을 호출했는지 알 수 있다.  Throwable을 통해 스택으로 쌓인 메서드 목록을 추출함을 확인할 수 있다.
- 이러한 조건에서 필터링의 기준을 다양하게 잡을 수 있다. Queryhints를 사용하여 주석을 달아서 필터링 여부를 결정할 수 있다. 패키지와 매서드명을 기준으로 할 수 있다. 여러 응용이 가능하다.

# 나아가며
- JPA, 로그백, p6spy까지 다양한 라이브러리의 로깅에 대하여 정리하였다. 
- System.out, 로거, 데코레이션 패턴 등 매우 다양한 방식으로 로깅을 할 수 있다. 처음 내가 로그를 세팅할 때,  각각 분리하여 생각하지 않아 많은 어려움을 느꼈다. 나같은 삽질을 안하기를 바라며 글을 남긴다.
- 기타 이 문제를 해소하는데 도움을 준 글은 아래와 같다.
- https://github.com/shirohoo/p6spy-custom-formatter
- https://logback.qos.ch/