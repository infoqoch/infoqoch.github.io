---
layout: post
author: infoqoch
title: 마이바티스의 로그백을 통한 로그 설정
categories: [spring]
tags: [spring]
---

## 들어가며
- 스프링 부트는 보통 SLF4j을 인터페이스로 하여, 기본 로그 라이브러이인 Logback을 사용한다.
- 특별한 설정 없이 SLF4j 을 로거로 사용한다면 Logback 을 실제로 사용한다.
- Mybatis의 쿼리를 로그백으로 로깅할 수 있지만 다소 복잡한 세팅을 필요로 한다.

## 설정해야 하는 파일
- 보통은 logback-spring.xml 혹은 application.properties 에서 설정한다. 
- 마이바티스의 경우 log4jdbc.log4j2.properties 와 logback-spring.xml 둘 다 반드시 설정해야 한다! 중요!

- log4jdbc.log4j2.properties

```properties
log4jdbc.drivers=com.mysql.cj.jdbc.Driver
log4jdbc.spylogdelegator.name=net.sf.log4jdbc.log.slf4j.Slf4jSpyLogDelegator
log4jdbc.auto.load.popular.drivers=false
log4jdbc.dump.sql.maxlinelength=0
```
- logback-spring.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
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

