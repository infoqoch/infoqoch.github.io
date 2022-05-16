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
- dirty read : 트랜잭션 B가 DB를 갱신하였고 이를 커밋하지 않았는데, A 트랜잭션이 갱신한 내용을 읽을 수 있다. READ UNCOMMITTED란 이름처럼, 다른 트랜잭션의 커밋여부와 관계 없이 최신의 상태를 읽는다. 
- RDB 표준에서는 격리수준으로조차 인정하지 않는다.

## READ COMMITTED
- dirty read 해소 : 커밋된 데이터만 읽는다.
- NON-REPETABLE READ 
    - REPETABLE READ란 한 트랜잭션이 DB를 읽을 때는 언제나 동일한 결과를 보여줘야 한다는 원칙. 
    - 트랜잭션 A가 특정 데이터를 읽고 나서 트랜잭션 B가 해당 데이터를 수정하면, 트랜잭션 A가 다시 그 데이터를 읽을 때 데이터가 변경되어 버린다. 하나의 트랜잭션에서 동일한 쿼리를 할 때 동일한 결과를 만들어내지 못한다. 그러니까 REPETABLE READ 원칙을 지키지 못한다

## REPEATABLE READ
- REPETABLE READ : 트랜잭션이 시작한 직전의 데이터만 읽는다. 이후 발생한 트랜잭션의 갱신 내용을 무시하기 때문에, REPETABLE READ 원칙을 지킨다. 

### UPDATE의 부정합
- 다만, 특정 기간 이전의 데이터만 읽기 때문에, 실제 DB의 데이터를 읽지 못한다는 치명적인 문제를 가진다. 특정 스냅샷을 기준으로 update를 할 경우, 실제 DB에서는 비정상적인 작업이 수행될 수 있다. 

```sql
select * from tb where name = "kim";
-- 중간에 다른 트랜잭션에 의하여 name = "kim" 인 레코드의 name이 "lee"가 되었다. 
update tb set age = 15 where name = 'kim';  -- 0 row(s) affected 
```

### INSERT의 부정합 : Phantom READ
- update 등으로 db를 갱신할 경우, 다른 트랜잭션에 의하여 insert가 된 레코드를 출력한다. 

```sql
select * from test;
select count(*) from test; -- 1개
    -- begin; insert into test(name, age) values ('lee', 15); commit; -- 다른 트랜잭션에서 insert를 한다.
select count(*) from test; -- 1개 
update test set age = 12 where name = 'kim'; -- 실제하는 데이터를 수정한다. 
select count(*) from test; -- 2개 
```

- 다만 innoDB의 경우, insert 된 데이터를 대상으로 갱신하지 않는 한, 팬텀 리드가 발생하지 않는다. 

```sql
select * from test;
select count(*) from test; -- 1개
    -- begin; insert into test(name, age) values ('lee', 15); commit; -- 다른 트랜잭션에서 insert를 한다.
select count(*) from test; -- 1개 
update test set age = 12 where name = 'lee'; -- 다른 트랜잭션에서 삽입한 'lee'를 수정해야지 팬텀리드가 발생한다.
select count(*) from test; -- 2개 
```

## SERIALIZABLE
- SELECT 쿼리를 사용할 때, SELECT ... FOR SHARE 의 형태로 변환된다. s lock이 발생한다. 
- s lock은 record lock, gap lock, next key lock 등을 발생시키므로, 해당 select 절에 대한 완전한 정합성을 보장한다.