---
layout: post
author: infoqoch
title: 스프링의 로깅 + 마이바티스
categories: [spring]
tags: [spring]
---

## 들어가며
- 스프링 부트 2.0 이후로 로깅 인터페이스는 SLF4j 와 commons-logging 이 있다. (이전에 복잡한 전사가 존재하지만 일단 그러하다)
- 로깅 인터페이스의 구현체는 JUL, Log4J2, Logback 가 있다. 스프링 기본 값은 Logback이다. 
- 그러므로 특별한 설정 없이 SLF4j 을 로거로 사용한다면 Logback 을 실제로 사용한다.

## 로그 커스터마이즈
- logback-spring.xml 을 보통 사용하지만 properties 를 통해 사용 가능하다.
- 컬러 출력: spring.output.ansi.enabled
- 파일 출력: logging.file 또는 logging.path
- 로그 레벨 조정: logging.level.패지키 = 로그 레벨

## 마이바티스와 로그
- 여담인데, JPA 의 경우 스프링부트와 통합성이 좋아서 특별한 설정 없이 쉽게 할 수 있었다. 그러나  마이바티스의 로그 설정에서 정말로 어려움을 겪었다. 
- 나의 경우 아래와 같이 진행하며 큰 문제 없이 진행했다. 마이바티스 로그 설정에 어려움을 겪는 분들에게 큰 도움이 되기를 바란다 ㅠ 나의 경우 이 부분에서 시간을 너무 잡아먹어서 ㅠ 나같은 사람이 없길 진짜 바란다.

## 설정해야 하는 파일
- log4jdbc.log4j2.properties 와 logback-spring.xml 둘 다 반드시 설정해야 한다! 중요!

```properties
log4jdbc.drivers=com.mysql.cj.jdbc.Driver
log4jdbc.spylogdelegator.name=net.sf.log4jdbc.log.slf4j.Slf4jSpyLogDelegator
log4jdbc.auto.load.popular.drivers=false
log4jdbc.dump.sql.maxlinelength=0
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <!--
    1. 테스트 코드 작동 시 프로파일이 존재하지 않음. 메이븐에서 명령어를 할 때 VM에 코드를 주면 그때 들어감. 아마 package 때 줘야지 들어 갈 듯.
    2. 한편, 내가 주로 하는 테스트의 경우 프로파일이 없이 진행이 된다. 그러므로 아무것도 없는 default 상태에서는 윈도우이며 다른 폴더에 저장되도록 한다.
    -->
    <springProfile name="default">
        <property name="LOG_PATH" value="c:\\log\\default"/>
    </springProfile>
    <springProfile name="window">
        <property name="LOG_PATH" value="c:\\log"/>
    </springProfile>
    <springProfile name="linux">
        <property name="LOG_PATH" value="/home/ec2-user/app/step2/logs"/>
    </springProfile>

    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <filter class="com.example.dic.core.config.LogbackFilter"/>
        <file>${LOG_PATH}/logs.log</file>
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>${LOG_PATH}/logs_%d{yyyyMMdd}_%i.log</fileNamePattern>
            <maxFileSize>10MB</maxFileSize>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
    </appender>

    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <filter class="com.example.dic.core.config.LogbackFilter"/>        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <logger name="com.example.dic" level="INFO" additivity="true"/>

    <logger name="jdbc.sqltiming" level="OFF" additivity="false"/>
    <logger name="jdbc.resultsettable" level="OFF" additivity="false"/>
    <logger name="jdbc.sqlonly" level="INFO" additivity="true"/>
    <logger name="jdbc.audit" level="OFF" additivity="false"/>
    <logger name="jdbc.resultset" level="OFF" additivity="false"/>
    <logger name="jdbc.connection" level="OFF" additivity="false"/>
    <logger name="log4jdbc.debug" level="OFF" additivity="false"/>

    <root level="INFO">
        <appender-ref ref="CONSOLE" />
        <appender-ref ref="FILE" />
    </root>

</configuration>
```

