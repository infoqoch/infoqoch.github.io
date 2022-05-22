---
layout: post
author: infoqoch
title: db, uk가 없는 상태에서 중복되지 않은 레코드를 삽입하려면 어떻게 해야할까? x 락, update affected 검토
categories: [db]
tags: [db, sql, java]
---

## 들어가며
- 이전에는 와닿지 않았던 트랜잭션, 격리수준, 락 등에 대하여 공부하고 고민하고 정리하였던 이유는 현재 정리한 실무에서의 문제 때문이었다. 
- 클라이언트에서 고의로든 실수로든 동일한 요청 여러 개가 발생하고 이것이 모두 insert가 되는 형태였다. 그러니까 중복된 데이터가 insert 되었다. 
- 그 형태는 대략 아래와 같다. mybatis를 사용 중이다. default 격리수준은 Repeatable Read이다.

```java
// controller
void doSomething(DoSomethingRequest req){
    valid1(req);
    valid2(req);
    valid3(req);
    service.save(req);
}

// service
void save(DoSomethingRequest req){
    if(!firstMapper.isNew(req)) // select count(*) from second where seq = #{seq};
        throw new IllegalArgumentException("해당 레코드의 상태가 'NEW'가 아닙니다.");
    if(secondMapper.countDuplicateRecords(req)>0) // select count(*) from second where seq = #{seq};
        throw new IllegalArgumentException("second 테이블에 이미 존재하는 레코드가 있습니다.");
    secondMapper.save(reqToEntity(req)); // insert into second (....) values (.....);
    firstMapper.updateState(req, First.Done); // update first set state = 'DONE' where id = #{id} and state = 'NEW';
}
```

- 테이블은 두 개가 있다. first, second. first의 'NEW'인 레코드만 second에 insert를 할 수 있다. 모든 로직이 종료되면 first 레코드의 작업이 끝나며 'DONE'의 상태가 된다. 
- 위의 로직에서 만약 save 메서드에 두 개의 동일한 요청이 들어왔다면 어떻게 될까? 더 정확하게, `secondMapper.countDuplicateRecords(req)>0`를 통과한 요청 2개가 `save()` 를 앞두고 있다면 어떻게 될까?
    - uk가 있고, `reqToEntity()` 메서드가 동일한 요청에 대하여 uk 칼럼에 대응되는 필드를 동일한 값으로 만들었다고 가정하자. 그럼 문제가 없다. 왜냐하면 DB차원에서 뒤에 온 요청에 대하여 중복으로 인한 예외처리를 하기 때문이다. 사실은 가장 이상적이고 간단하고 빠른 방법이다.
    - 하지만 insert 때 삽입되는 어떤 데이터도 uk로 예외처리할 수 없다면 어떻게 할까? 어플리케이션이 너무 레거시라 테이블을 재정비하여 uk로 만들기에 버거운 상황일 수 있다. 혹은 DB 자체를 건들기에 너무 부담스러운 상황일 수 있다. 

- 실제로 이러한 문제에 나는 봉착하였고, 그때 나는 가장 간단한 해결책을 사용했다. 

```java
@Transactional(isolation = Isolation.SERIALIZABLE)
void save(DoSomethingRequest req){
    // 상동
}
```

- 위의 코드는 기대하는 방향대로 동작하였다. `countDuplicateRecords()` 메서드가 동작할 때, s lock을 얻게 된다. count가 0을 호출한다는 의미는, 해당 테이블 전체를 탐색했다는 의미이며, 모든 레코드에 대하여 갭락이 생긴다. 그러니까 트랜잭션 두 개 이상이 해당 countDuplicateRecords을 호출하였다면, 단 하나의 트랜잭션만 save()가 가능하며 나머지 트랜잭션은 데드락으로 받아드려 예외처리가 된다. 
- 다만 데드락으로 인한 문제가 발생한다.
    - 만약 동일한 요청이 들어왔으며 `countDuplicateRecords()` 를 호출하여 s lock을 가진 트랜잭션이 두 개가 된다면, 데드락은 적절한 대응이다. 
    - 하지만 다른 요청이 동시에 들어왔다면? `countDuplicateRecords()>0` 이기 때문에 실제 검색한 데이터가 서로 다르더라도 두 트랜잭션 모두 전체 레코드에 대한 갭락을 가진다. 누구도 insert를 하지 못하는 데드락이 발생한다. 클라이언트 입장에서는 사용성이 떨어지며, 서버 입장에서는 굳이 필요 없는 락으로 인한 성능 문제가 발생한다. 

## 1차 시도 : 메서드는 무조건 한 스레드만 접근할 수 있게 with for update
- 최초에 나는 x 락으로 이 문제를 해결하려고 하였다. 왜냐하면 s lock은 select에 대한 배타적 락을 가진다고 이해했기 때문이다. 더 나아가 insert는 자원을 많이 소비하지 않고 빠르게 처리하는 작업이기 때문에, 동기적으로 동작하더라도 전혀 문제가 없다고 생각했다.

```java
@Transactional(isolation = Isolation.SERIALIZABLE)
void save(DoSomethingRequest req){    
    if(!firstMapper.isNew(req)) // select count(*) from second where seq = #{seq};
        throw new IllegalArgumentException("해당 레코드의 상태가 'NEW'가 아닙니다.");

    // 쿼리 : select count(*) from second where seq = #{seq} for update;
    // 기대 : for update가 있으므로 어플리케이션이나 스레드의 갯수와 관계 없이 단 하나의 요청만 아래의 select을 할 수 있다. 나머지는 대기한다.
    if(secondMapper.countDuplicateRecords(req)>0) // select count(*) from second where seq = #{seq};
        throw new IllegalArgumentException("second 테이블에 이미 존재하는 레코드가 있습니다.");
    secondMapper.save(reqToEntity(req)); // insert into second (....) values (.....);
    firstMapper.updateState(req, First.Done); // update first set state = 'DONE' where id = #{id} and state = 'NEW';
}
```

- 하지만 이것은 착각이었다. 앞서 블로그에서 정리한 바와 같이, 검색 결과가 없는 `select ... for update`는 마치 s 락과 같이 동작했다. 그러니까 여러 트랜잭션이 select을 할 수 있었다. 하지만 갱신에 대해서는 모든 위치에 대하여 데드락을 걸었다. (구체적인 내용은 앞의 블로그 참고). 

- 두 번째의 고민지점은, 어플리케이션 개발을 할 때, sql에 의존적인 방식으로 개발하는 것이 좋지 않다고 생각했다. 예를 들면 `select count(*) from seconds for update` 등 어떻게든 쿼리를 변경하여 select을 단 하나의 요청만 수 있도록 고민할 수 있다. 하지만 락에 대해 잘 이해하지 못하는 개발자가 수정할 수도 있지 않을까? 깨지기 쉬운 코드가 될 것 같다는 직감이 들었다. 
- 그러므로 나는 다른 방법을 선택해야 했다.

## 2차 시도 : UPDATE... affected rows 0
- update는 격리수준에 관계 없이 실제 DB에서 해당 쿼리가 성공했는지의 여부를 반환한다. 이를 affcted rows 0 혹은 1이라는 형태로 반환한다.
- 이에 대한 테스트는 아래와 같다. 트랜잭션 A, B가 동시에 동작한다. 주석(--) 처리된 것이 트랜잭션 B이다.

```sql
select * from test where seq = 1 and age = 10 and name = 'kim';
-- select * from test where seq = 1 and age = 10 and name = 'kim';
-- update test set age = 11 where seq = 1 and age = 10 and name = 'kim'; -- 1 row(s) affected 
-- commit;
update test set age = 11 where seq = 1 and age = 10 and name = 'kim'; -- 0 row(s) affected 
```

- 위의 쿼리를 보면 요청은 동일하다. `update test set age = 11 where seq = 1 and age = 10 and name = 'kim';` 하지만 먼저 처리한 트랜잭션은 1 row가 영향을 받았지만, 다음 트랜잭션은 0 row가 영향을 받는다. 
- 이러한 원리를 통해 아래와 같은 로직을 만들 수 있다. 

```java
// mapper, first table, void 에서 int로 리턴 타입을 변경한다.
int updateState(...); // affected row의 갯수를 리턴한다.

// service
void save(DoSomethingRequest req){
    if(firstMapper.updateState(req, First.Done)==0)
        throw new IllegalArgumentException("해당 레코드의 상태가 'NEW'가 아닙니다.");
    secondMapper.save(reqToEntity(req)); // insert into second (....) values (.....);
}
```

- 이를 통해 더 단순하고 명확한 방식으로 문제를 해소할 수 있었다. 
- first table에 대하여 select 후 update를 하던 로직을, update 한 차례로 줄였다. 격리수준이 REPEATABLE READ이기 때문에 여러 트랜잭션이 동시에 update 및  insert를 할 수 있어서 성능상 좋아졌다. 
- first 테이블에서 update가 성공한 갯수를 기준으로 second 테이블에 insert를 하기 때문에, 다른 개발자가 보기에 직관적인 로직이 되었다. 

## 나아가며
- DB에 잘 알지 못하는 상황에서 혼자 머리 싸매고 끙끙거려서 힘들었다. 하지만 트랜잭션이나 락 등에 대하여 잘 이해할 수 있는 기회가 되었다. 해결해서 기분도 무척 좋았다.
- insert할 때 신중한 방식으로 DDL을 작성해야 함을 깨달았다. 어떤 이유로든 중복 요청이 들어갈 수 있으며, insert를 할 때 DB 차원에서 이를 잘 방어하는 형태로 구현해야 한다. 이런 상황에서 uk가 가장 구현하기 쉽고 단순한 방법이다. 이를 잘 활용해야 함을 느꼈다. 나중에 uk를 만드는 것은 무척 부담스러운 일이다.
- 데이터 정합성 측면에서 데드락이 오히려 고마운 존재(?)임을 느끼게 된 계기가 되었다. 물론 결과적으로 없애야 할 에러이긴 하지만.