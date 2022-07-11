---
layout: post
author: infoqoch
title: DB의 데이터 정합성을 고려한 개발 팁
categories: [db]
tags: [db, sql]
---

# 트랜잭션의 편리한 롤백 기능은 사실 제한적인 기능이다
- 트랜잭션은 예외 상황이 발생할 경우 롤백을 통해 해소한다. 수행했던 작업을 취소한다. all or nothing.
- 모든 작업이 트랜잭션과 같이 동작할 경우, 쉽게 데이터의 정합성을 보장할 수 있다. 하지만 트랜잭션 롤백은 사실 제한적인 상황이다.
- 다른 트랜잭션, 다른 커넥션, 이미 커멧된 트랜잭션에 대해서 DB는 롤백을 보장하지 않는다. 
- 외부 API 또한 데이터 정합성과 관련한 중요한 요소이다. 컨펌 메일을 보냈는데, 내부 사정으로 사업을 취소하고 싶다고 하여, 이미 보낸 메일을 되돌려 받을 수 없다. 외부 API를 롤백할 대응책이 필요하다. 
- 각각의 상황에서 데이터 정합성을 어떻게 확보할지에 대하여 고민해야 한다. 대체로 catch 블럭을 활용하여, 롤백을 위한 기능을 마련한다.
- 롤백은 쉬운 작업이 아니다. 그러므로 수정이 어려운 작업을 가능한 마지막에 배치해야 한다. 

# 다수의 트랜잭션이 동작할 때
## 명시적 잠금을 통한 락 획득
- `select .... for update` 등을 사용하여 락을 획득한다.

## 원자적 연산 사용
- update를 할 때 원자적 연산(+=)을 사용하는 것이 무결성에 더 낫다.

```sql
select hit from test; -- hit : 1
update TEST set hit = 2 where ....; -- 트랜잭션 A가 조회수 1을 늘리는 의도로 2를 갱신한다. 
-- update TEST set hit = 2 where ....; -- 트랜잭션 B가 조회수 1을 늘리는 의도로 2를 갱신한다. 3이어야 하는데....

update TEST set hit += 1 where ....;  -- 원자적 연산을 하는 것이 낫다.
```

## CAS (compare and set)
- 레코드에 버전을 부여하고, 갱신할 때 해당 버전을 항상 사용한다.

```sql
select * from test where no = '1'; -- ver가 1임을 확인했다.

update test
set ver = 2, name = 'kim' 
where no = '1' and ver='1'
```

> 참고
>
> https://www.youtube.com/watch?v=poyjLx-LOEU