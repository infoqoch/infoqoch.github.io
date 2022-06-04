---
layout: post
author: infoqoch
title: 데이터의 정합성을 고려한 개발을 위하여 
categories: [db]
tags: [db]
---

## 들어가며
- 최근 데이터 정합성과 관련한 문제가 있었다. 이에 대한 문제를 분석하고 좋은 설계를 위한 고민이 많았다.
- 최범균 개발자님의 유튜브를 통해 정리하였다. 

## 커넥션, 트랜잭션은 롤백을 공유하지 않는다.
- 예외 상황에서 트랜잭션은 롤백을 통하여 문제를 해소한다. all or nothing.
- 하지만 다른 커넥션이나 이미 커밋된 트랜잭션에 대하여 롤백을 제공하지는 않는다. 
- 외부 API 역시 마찬가지이다. 외부 API에게 메시지를 전달하였는데, 내부 로직 동작 과정에서 갑자기 실패했다고 하여, 이미 보낸 통신을 되돌려 받을 수 없다. 
- 하나의 DB 트랜잭션의 롤백과 다른 트랜잭션, 커넥션, 외부 API 통신 과정의 트랜잭션은 분리해서 생각해야 한다. 그리고 이러한 롤백을 고려한 코드를 작성해야 한다. 대체로 catch 블럭에 롤백의 역할을 하는 코드나 api 통신 코드를 작성한다. 
- 이렇게 롤백이 어려운 작업에 대해서는 가능한 마지막에 배치하는 것이 낫다. 

## 명시적 잠금
- `select .... for update` 등을 사용하여 락을 획득한다.

## 원자적 연산 사용
- update를 할 때 원자적 연산(+=)을 사용하는 것이 무결성에 더 낫다.

```sql
select hit from test; -- hit : 1
update TEST set hit = 2 where ....; 
update TEST set hit += 1 where ....; 
```

## CAS ( compare and set)
- 레코드에 버전을 부여하고, 갱신할 때 해당 버전을 항상 사용한다.

```sql
select * from test where no = '1'; -- ver가 1임을 확인했다.

update test
set ver = 2, name = 'kim' 
where no = '1' and ver='1'
```

> https://www.youtube.com/watch?v=poyjLx-LOEU