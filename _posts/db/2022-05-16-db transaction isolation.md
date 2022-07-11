---
layout: post
author: infoqoch
title: 트랜잭션의 격리수준
categories: [db]
tags: [db, sql]
---

# 격리수준?
- 하나의 트랜잭션이 DB를 조회(select) 함에 있어서 어느 수준으로 데이터의 일관성을 보장하는지에 대한 수준이다.
- 격리수준이 높을 수록 일관성이 확보되지만 성능이나 락 문제가 발생할 수 있다. 
- 격리수준은 아래와 같은 종류가 있다. 
    - READ UNCOMMITTED
    - READ COMMITTED
    - REPEATABLE READ
    - SERIALIZABLE

## READ UNCOMMITTED
- dirty read : 트랜잭션 B가 DB를 갱신하였고 이를 커밋하지 않았는데, A 트랜잭션이 갱신한 내용을 읽을 수 있다. 
- READ UNCOMMITTED란 이름처럼, 커밋여부와 관계 없이 항상 최신의 상태를 읽는다. 
- RDB 표준에서는 READ UNCOMMITTED을 격리수준으로 인정하지 않는다.

## READ COMMITTED
- dirty read 해소 : 커밋된 데이터만 읽는다. 

### NON-REPEATABLE READ 
- REPEATABLE READ : 한 트랜잭션이 같은 쿼리를 할 때 동일한 결과를 보여줘야 한다는 원칙.
- 격리수준 READ COMMITTED의 경우 트랜잭션 A가 레코드 X를 읽은 후, 트랜잭션 B가 레코드 X를 수정하고 커밋하면, 트랜잭션 A가 다시 레코드 X를 읽을 때 첫 번째로 읽었을 때와 다른, 트랜잭션 B가 수정한 데이터를 보여준다. 

## REPEATABLE READ
- REPEATABLE READ를 준수한다.
- rdb, 엔진마다 이를 구현하는 방식은 차이를 가진다.
- mysql의 innoDB의 경우, 트랜잭션이 시작되는 그 순간, 그 이전에 커밋된 내용만을 보여준다. 이를 스냅샷이라 한다. 트랜잭션이 시작한 이후 다른 트랜잭션이 아무리 커밋하고 수정한다 하더라도 과거의 것만 보여준다.
- 이전의 내용만을 알기 때문에, insert 및 update의 정합성 문제가 발생할 수 있다.

### phantom read 
- REPEATABLE READ는 동일한 쿼리에 대하여 동일한 데이터를 보장한다.
- 이와 달리, 갱신(INSERT, UPDATE, DELETE)을 한 레코드에 대해서는 그것에 대한 최신의 결과를 보여줘야 한다. 스냅샷을 보여준다는 원칙과 갱신한 레코드는 최신의 상태를 보여줘야 한다는 원칙이 충돌한다. 이때 발생하는 현상 중 하나가 팬텀 리드라 한다.  
- 아래는 팬텀리드의 예시이다. 트랜잭션 A과 B가 동시에 동작한다. 주석처리(--)된 쿼리가 트랜잭션 B이다.
- 트랜잭션 A의 입장에서는 seq = 1인 이름을 kim-li로만 변경하였다. 하지만 실제로 해당 레코드는 다른 트랜잭션에 의하여 age가 변경되었다. 엄밀한 의미에서 REPEATABLE READ가 적용되었다면 age는 10이 유지되어야 하지만 11로 변경됨을 확인할 수 있다. 

```sql
select * from test where seq = 1 and name = 'kim' and age = 10;
-- select * from test where seq = 1 and name = 'kim' and age = 10;
-- update test set age = 11, name ='kim-kong' where seq = 1; -- 1 row(s) affected 
-- commit;
update test set name ='kim-li' where seq = 1; -- 1 row(s) affected
select * from test where seq = 1 and name = 'kim-li' and age = 10; -- 없음
select * from test where seq = 1 and name = 'kim-li'; -- age가 11이 되어 있음.
```

- innoDB에서는 이러한 **팬텀리드를 방지하기 위하여 락을 제공**한다. x lock(for update), s lock(for share), 범위나 인덱스에 따른 gap lock 및 next key lock을 제공한다.

## 기타 쿼리들
- 그 외 REPEATABLE READ의 테스트를 위해 작성한 쿼리는 아래와 같다. 

```sql
-- update 
select * from test where seq = 1 and age = 10 and name = 'kim';
-- select * from test where seq = 1 and age = 10 and name = 'kim';
-- update test set age = 11 where seq = 1 and age = 10 and name = 'kim'; -- 1 row(s) affected 
-- commit;
update test set age = 11 where seq = 1 and age = 10 and name = 'kim'; -- 0 row(s) affected 

-- insert 
select count(*) from test; -- 1개
-- insert into test(seq, name, age) values (2, 'lee', 15);
-- commit;
select count(*) from test; -- 1개
update test set age = 12 where seq = 2;
select count(*) from test; -- 2개
```

## SERIALIZABLE
- REPEATABLE READ가 사용자의 쿼리 작성에 따라 락을 제어하였다면, SERIALIZABLE은 모든 SELECT 쿼리에 for share를 넣은 효과를 준다. 그러니까 s lock을 소유한다.
- 락을 통해 팬텀리드를 완전하게 방지한다. 데이터에 대한 확실한 정합성을 보장한다. 조회한 레코드에 대해서는 그 누구도 갱신할 수 없다.
- 다만 데드락으로 인한 일종의 예외, 동시성 문제로 인한 성능 문제가 발생한다.

> https://www.letmecompile.com/mysql-innodb-transaction-model/