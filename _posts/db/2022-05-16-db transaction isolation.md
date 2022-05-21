---
layout: post
author: infoqoch
title: 트랜잭션의 격리수준
categories: [db]
tags: [db, mysql]
---

# 격리수준?
- 하나의 트랜잭션이 DB를 조회(select) 함에 있어서 어느 수준으로 일관된 데이터를 보여주는지에 대한 수준이 격리 수준이다. 
- 격리수준은 아래와 같은 종류가 있다. 
    - READ UNCOMMITTED
    - READ COMMITTED
    - REPEATABLE READ
    - SERIALIZABLE

## READ UNCOMMITTED
- dirty read : 트랜잭션 B가 DB를 갱신하였고 이를 커밋하지 않았는데, A 트랜잭션이 갱신한 내용을 읽을 수 있다. 
- READ UNCOMMITTED란 이름처럼, 커밋여부와 관계 없이 항상 최신의 상태를 읽는다. 
- RDB 표준에서는 격리수준으로조차 인정하지 않는다.

## READ COMMITTED
- dirty read 해소 : 커밋된 데이터만 읽는다.

### NON-REPEATABLE READ 
- REPEATABLE READ란 한 트랜잭션이 같은 쿼리를 할 때 동일한 결과를 보여줘야 한다는 원칙. READ COMMITTED은 REPEATABLE READ를 보장하지 않는다.
- 트랜잭션 A가 레코드 X를 읽고, 트랜잭션 B가 레코드 X를 수정하고 커밋하면, 트랜잭션 A가 다시 레코드 X를 읽을 때 첫 번째로 읽었을 때와 다른 데이터를 보여준다.
- (트랜잭션 A의 입장에서) 하나의 트랜잭션이 동일한 쿼리를 할 때(레코드 X를 읽을 때) 동일한 결과를 만들어내지 못한다(트랜잭션 B가 X를 수정해서). 그러니까 REPEATABLE READ 원칙을 지키지 못한다

## REPEATABLE READ
- REPEATABLE READ를 준수한다.
- rdb, 엔진마다 이를 구현하는 방식은 차이를 가진다. mysql의 innoDB를 기준으로 보면, 
- 트랜잭션이 시작되는 그 순간 이전에 커밋된 내용만을 보여준다. 이를 스냅샷이라 한다. 그러므로 트랜잭션이 시작한 이후 변경된 사항을 무시할 수 있다. 과거의 것만 보여준다.
- 이로 인하여 insert 및 update의 정합성 문제가 발생할 수 있다.

### phantom read 
- 한편 격리수준 REPEATABLE READ은 select에 대해서는 동일한 레코드를 보장한다.
- 하지만 갱신(INSERT, UPDATE, DELETE)을 한 레코드에 대해서는 그것의 결과를 보여줘야 한다. 그러니까 최신의 상태를 리턴한다. 이로 인한 정합성 문제가 발생할 수 있다. 이러한 문제로, 트랜잭션이 갱신을 한 경우 REPEATABLE READ가 깨지는 것처럼 보이는 현상이 나타난다. 이를 팬텀 리드라 한다. 
- 아래의 코드는 그 예시이다. 트랜잭션 1과 2가 동시에 동작한다. 1은 정상 쿼리이며 2는 주석처리(--)된 쿼리이다. 트랜잭션 1은 이름만 'kim-li'로 변경하였는데, 해당 레코드를 읽었을 때 age 또한 변경된 것을 알 수 있다. 

```sql
select * from test where seq = 1 and name = 'kim' and age = 10;
-- select * from test where seq = 1 and name = 'kim' and age = 10;
-- update test set age = 11, name ='kim-kong' where seq = 1; -- 1 row(s) affected 
-- commit;
update test set name ='kim-li' where seq = 1; -- 1 row(s) affected
select * from test where seq = 1 and name = 'kim-li' and age = 10; -- 없음
select * from test where seq = 1 and name = 'kim-li'; -- age가 11이 되어 있음.
```

- innoDB에서는 이러한 **팬텀리드를 방지하기 위하여 락을 제공한**다. x lock(for update), s lock(for share), 범위나 인덱스에 따른 gap lock 및 next key lock을 제공한다.

- 그외 insert 및 update의 쿼리는 아래와 같다. 

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
update test set age = 12 where seq = 9;
select count(*) from test; -- 2개
```

## SERIALIZABLE
- REPEATABLE READ가 사용자의 제한에 따라 락을 제어하였다면, SERIALIZABLE은 트랜잭션이 모든 SELECT 쿼리에 for share를 넣은 효과를 준다. 그러니까 s lock을 소유한다.
- 락을 통해 팬텀리드를 완전하게 방지한다. 데이터에 대한 확실한 정합성을 보장한다. 
- 다만 데드락으로 인한 일종의 예외, 동시성 문제로 인한 성능 문제가 발생한다.

> https://www.letmecompile.com/mysql-innodb-transaction-model/