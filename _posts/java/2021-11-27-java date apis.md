---
layout: post
title: 자바의 date api
author: infoqoch
# last_modified_at: 2021-11-27 09:40:46
categories: [java]
tags: [java]
---

## java 8 이전의 date api 의 문제
### 가변성과 비일관성
- Date 객체의 경우 getTime() 메서드에서 기계를 위한 시간 EPOCK 이 출력된다. 
- Date 인데 Date 와 Time 을 다룬다.
- Date 객체가 변한다. 쓰레드의 안정성 문제가 존재한다. 

```java
@Test
void legacyDateApi_threadSafety(){
    Date date = new Date();
    long time = date.getTime();
    System.out.println(time); // Date 인데  time 이 나오고 time 은 이상한 long 이...

    Date now = new Date();
    now.setTime(335983742343245l); // mutable 함. 그러니까 인스턴스의 값이 가변적임. Thread Safety 하지 아니함.
    System.out.println(now);
}
```

### 월이 숫자이며 0부터 시작한다.
- 1월이 0이다. 
- 99월을 할 수 있다.....
```java
@Test
void legacyDateApi_DateTypeSafety(){
    GregorianCalendar calendar = new GregorianCalendar(2021, 99, 23); // month 가 5를 넣지만 6월이다. int를 99 로 넣을 수 있다.
    System.out.println(calendar.getTime());
}
```

## LocalDate 와 LocalDateTime
- 자바 8부터 사용되는 시간 api 이다.
- 컴퓨터 용 시간 Instant 와 사랑을 위한 시간 LocalDateTime 으로 분리된다.
  - 서버의 실제 지역과 세팅에 따라 시간이 달라질 수 있으므로, LocalDateTime 을 사용할 때 주의해야 한다. 
- 원하는 지역에 대한 시간을 구하기 위한 ZoneDateTime 을 지원한다. 

```java
@Test
void java8_date_api(){
    Instant instant = Instant.now(); // 컴퓨터용 시간
    LocalDate localDate = LocalDate.now(); // 이하 사람 용
    LocalDateTime localDateTime = LocalDateTime.now(); // OS의 기준에 따라... 만약 AWS 등 해외 서버를 사용한다면 위험할수도?
    ZonedDateTime zonedDateTime = ZonedDateTime.now(); // 설정에 따라... 
}

@Test
void java8_date_api2(){
    LocalDateTime localDateTime = LocalDateTime.of(2021, Month.JULY,7, 10,15);
    System.out.println(localDateTime);
    System.out.println(localDateTime.atZone(ZoneId.of("Asia/Seoul")));

    LocalDateTime now = LocalDateTime.now();

    Duration between = Duration.between(now, localDateTime);
    System.out.println(between.toDays());

    Period period = LocalDate.now().until(LocalDate.of(2022, Month.JULY, 5));
    System.out.println(period.get(ChronoUnit.DAYS));
}

@Test
void formatter(){
    DateTimeFormatter MMddyyyy = DateTimeFormatter.ofPattern("MM-dd-yyyy");
    String format = LocalDate.now().format(MMddyyyy);
    System.out.println(format);
}
```