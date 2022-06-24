---
layout: post
author: infoqoch
title: db, x lock은 select에 대한 배타적 락을 보장하는가?
categories: [db]
tags: [db, sql]
---

## x 락은 동일한 select 쿼리에 대하여 배타적인 권한을 주는 것은 아니다.
- x 락은 조회에 대하여 배타적인 권리를 가진다. 
- 어플리케이션은 다수이며 DB는 하나이다. 하나의 어플리케이션은 또한 여러 개의 쓰레드로 이뤄져 있다. 
- 나는 트랜잭션으로 묶인 특정 메서드가 단 하나의 스레드만 사용하도록 만들고 싶었다. DB 차원에서 동기적 작업을 보장할 방법을 고민하였고, x 락이 이러한 역할을 할 것이라 기대하였다. 예를 들면 아래와 같다.

```java
@Transactional(REFEATABLE_READ)
void save(SomeRequest req){
    // select * from some_table where no = #{no} for update;
    // for update로 인하여 단 하나의 스레드만 접근 가능하고 나머지 스레드는 대기한다.
    Something something = repository.findSomethingByNoForUpdate(req.getNo()); 
    something.valid();
    repository.save(req);    
}
```

- 하지만 기대한 것처럼 동작하지 않았다. 

## for update는 select에 대한 락에 대하여 배타적이지 않았다. 
- 아래의 쿼리로 for update를 테스트하였다.
- 주석(--)이 없는 것은 트랜잭션 A, 있는 것은 트랜잭션 B이다.
- 격리수준은 REPEATABLE READ 이다.

### 전체 탐색 혹은 존재하는 레코드 검색

```sql
-- 테스트 1.1. 전체 검색
SELECT * FROM TESTS FOR update; 
-- SELECT * FROM TESTS FOR update; -- 교착

-- 테스트 1.2. 전체 카운트
SELECT count(*) FROM TESTS FOR update;
-- SELECT count(*) FROM TESTS FOR update; -- 교착
```

- 위의 테스트를 진행하면 전체 탐색에 대해서는 교착이 발생함을 확인할 수 있다. 
- 아래의 코드 중 seq는 auto increment가 되는 pk 이다. index가 있다. 100까지 데이터가 있다.

```sql
-- 테스트 2. 
EXPLAIN SELECT count(1) FROM TESTS WHERE SEQ  = 1 ; -- index
EXPLAIN SELECT count(1) FROM TESTS WHERE SEQ  = 130 ; -- no matching row in const table
EXPLAIN SELECT count(1) FROM TESTS WHERE SEQ  = 150 ; -- no matching row in const table

-- 테스트 2.1. index가 걸린 칼럼의 레코드를 검색했고 그 레코드가 존재한다. 
SELECT count(1) FROM TESTS WHERE SEQ  = 1 FOR UPDATE; -- 존재한다.

-- SELECT count(1) FROM TESTS WHERE SEQ  = 1 FOR UPDATE; -- 교착
-- SELECT count(1) FROM TESTS WHERE SEQ  = 2 FOR UPDATE; -- 정상

-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('1', '130 ID', '130 name') -- 교착
-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('2', '130 ID', '130 name') -- 정상. 그러나 duplicate entry로 예외 발생
-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('130', '130 ID', '130 name') -- 정상
-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('150', '150 ID', '130 name') -- 정상 
```

- 인덱스가 있고, 그 값이 존재하면, 그 이외의 레코드에는 락이 걸리지 않는다. 현 상황에서는 seq = 1에 대해서만 record lock이 걸린다.


### 레코드가 없는 탐색의 경우

```sql
-- 테스트 2.2. index가 걸린 칼럼의 레코드를 검색했고, 그 레코드는 없다. 
SELECT count(1) FROM TESTS WHERE SEQ = 150 FOR UPDATE; -- 150은 없음.

-- SELECT count(1) FROM TESTS WHERE SEQ  = 1 FOR UPDATE; -- 정상
-- SELECT count(1) FROM TESTS WHERE SEQ  = 150 FOR UPDATE; -- 정상
-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('130', '130 ID', '234982374 name') -- 교착 : 130은 없음
-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('150', '150 ID', '234982374 name') -- 교착 : 150은 없음
```

- 앞서의 내용과 달리, 레코드가 없을 경우, 기대하는 것처럼 select에 대하여 배타적인 권한을 얻지 못했다. 
- 그러므로 동일한 select 쿼리 `SELECT count(1) FROM TESTS WHERE SEQ = 150 FOR UPDATE;` 를 두 개의 트랜잭션에서 할 수 있었다. 
- 결과적으로 x 락을 통해 select 자체에 대한 유일한 트랜잭션의 락을 완전하기 기대할 수 없게 된다. 
- 결국 s 락을 가지는 것과 동일하게 insert에서 교착상태가 되어 버린다. 

## 나아가며
- 레코드가 없는 경우에 대해서 왜 이런 문제가 발생하는지 찾아보려 하였지만 찾지 못했다ㅠ. 이유가 무척 궁금하다ㅠ. 
- 결과적으로 나는 x 락을 통한 동기적 처리를 포기하였다. 쿼리나 어플리케이션 로직을 잘 짜는 방법을 고민해볼 수 있지만 이런 경우 코드를 읽는 입장에서 무척 복잡해질 것 같다는 느낌이 들었기 때문이다. 
