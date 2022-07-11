---
layout: post
author: infoqoch
title: x lock은 정말로 select에 대한 배타적 락을 보장하는가?
categories: [db]
tags: [db, sql]
---

## x 락은 동일한 쿼리에 대한 배타적인 권한을 줄 것이라 기대하였다. 
- x 락은 조회에 대하여 배타적인 권리를 가진다. 
- DB는 하나이다. 하나의 DB에 여러 개의 어플리케이션과 여러 개의 스레드가 붙어 있다. DB를 다루는 것에 있어 동시성 문제는 무척 중요하다.
- 나는 x락을 자바의 synchronized와 같다고 이해했다. 멀티스레드 상황에서 유일한 스레드만 해당 코드블럭에 접근할 수 있다고 생각했다.

```java
@Transactional(REFEATABLE_READ)
void save(SomeRequest req){
    Something something = repository.findByNo(req.getNo());  // select * from some_table where no = #{no} for update;
    something.valid();
    repository.save(req);    
}
```

- 나는 위의 `for update`를 통하여 해당 트랜잭션이 시작하고 종료되는 save()메서드의 시작과 끝을 단 하나의 트랜잭션만 접근 가능할 것이라 기대했다. 
- 하지만 기대한 것처럼 동작하지 않았다. 

## for update는 select 쿼리에 대하여 배타적일 때도 있지만 아닐 때도 있었다. 
- for update를 아래의 sql과 같이 테스트하였다.
- 주석(--)이 없는 것은 트랜잭션 A, 있는 것은 트랜잭션 B이다.
- 격리수준은 REPEATABLE READ 이다.

### 전체 탐색 혹은 존재하는 레코드 검색

- 아래의 테스트를 진행하면 전체 탐색에 대해서는 교착이 발생함을 확인할 수 있다. 

```sql
-- 테스트 1.1. 전체 검색
SELECT * FROM TESTS FOR update; 
-- SELECT * FROM TESTS FOR update; -- 교착

-- 테스트 1.2. 전체 카운트
SELECT count(*) FROM TESTS FOR update;
-- SELECT count(*) FROM TESTS FOR update; -- 교착
```

- 아래의 코드 중, 칼럼 seq는 auto increment가 되는 pk 이다. index가 있다. 100까지 데이터가 있다.

```sql
-- 테스트 2.1. index가 걸린 칼럼의 레코드를 검색했고 그 레코드가 존재한다. 
SELECT count(1) FROM TESTS WHERE SEQ  = 1 FOR UPDATE; -- 존재한다.

-- SELECT count(1) FROM TESTS WHERE SEQ  = 1 FOR UPDATE; -- 교착
-- SELECT count(1) FROM TESTS WHERE SEQ  = 2 FOR UPDATE; -- 정상

-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('1', '130 ID', '130 name') -- 교착
-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('2', '130 ID', '130 name') -- 정상. 그러나 duplicate entry로 예외 발생
-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('130', '130 ID', '130 name') -- 정상
-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('150', '150 ID', '130 name') -- 정상 
```

- seq = 1에 대해서만 record lock이 걸린다.

### 레코드가 없는 탐색을 할 때

```sql
-- 테스트 2.2. index가 걸린 칼럼의 레코드를 검색했고, 그 레코드는 없다. 
SELECT count(1) FROM TESTS WHERE SEQ = 150 FOR UPDATE; -- 150은 없음.

-- SELECT count(1) FROM TESTS WHERE SEQ  = 1 FOR UPDATE; -- 정상
-- SELECT count(1) FROM TESTS WHERE SEQ  = 150 FOR UPDATE; -- 정상
-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('130', '130 ID', '234982374 name') -- 교착 : 130은 없음
-- INSERT INTO TESTS (SEQ , ID, NAME) VALUES ('150', '150 ID', '234982374 name') -- 교착 : 150은 없음
```

- 테스트 2.1과 달리, 검색 결과 레코드가 없을 경우, 기대하는 것처럼 select에 대하여 배타적인 권한을 얻지 못했다. 
- `SELECT count(1) FROM TESTS WHERE SEQ = 150 FOR UPDATE; ` 이 두 개의 트랜잭션에서 반복적으로 수행됨을 확인할 수 있다.
- 결과적으로 레코드의 존재 유무에 따라 select 쿼리리에 대한 배타적인 권한을 가질 수 없음을 확인할 수 있었다. 이 때 사실상 s lock을 획득하는 것과 동일한 상태가 되며, insert에서 교착상태가 되어 버린다. 

## 나아가며
- 레코드가 없는 경우에 대해서 왜 이런 문제가 발생하는지 확인해보고자 하였지만 찾을 수 없었다. 
- x락을 신뢰할 수 없다고 판단한 이유 중 하나가 여기에 있다. DB의 입장에서는 레코드가 없으니까 배타적 락을 얻을 수 없다고 볼 수 있다. 하지만 비지니스 로직을 다루는 입장에서, 해당 로직이 동작하는 어플리케이션 차원에서는 배타적 락을 기대했다면 어떤 상황이 되더라도 락을 보장해야 한다. 하지만 x 락은 이러한 기대를 하기 어렵다는 직감이 들었다. 