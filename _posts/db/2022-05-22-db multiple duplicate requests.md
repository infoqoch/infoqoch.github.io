---
layout: post
author: infoqoch
title: uk가 없는 상태에서 중복되지 않은 레코드를 삽입하려면 어떻게 해야할까? x 락, update affected rows 검토
categories: [db]
tags: [db, sql]
---

## 들어가며
- 격리, 락, 데이터 정합성 등 정리를 했던 이유는 사실 현 블로그의 문제를 해소하기 위해서였다. 
- 문제가 발생했을 때, mariadb와 mybatis를 사용했고, 격리수준은 Repeatable Read였다.
- 해당 소스는 대략 아래와 같다. 

```java
// controller
void doSomething(DoSomethingRequest req){
    service.save(req);
}

// service
void save(DoSomethingRequest req){
    if(!firstMapper.isNew(req)) // select count(*) from second where seq = #{seq} and status = 'NEW';
        throw new IllegalArgumentException("해당 레코드의 상태가 'NEW'가 아닙니다.");
    if(secondMapper.countDuplicateRecords(req)>0) // select count(*) from second where seq = #{seq};
        throw new IllegalArgumentException("second 테이블에 이미 존재하는 레코드가 있습니다.");
    secondMapper.save(req); // insert into second (....) values (.....);
    firstMapper.updateState(req, First.Done); // update first set state = 'DONE' where id = #{id} and state = 'NEW';
}
```

- 테이블은 두 개가 있다. first, second. first의 'NEW'인 레코드만 second에 insert를 할 수 있다. 모든 로직이 종료되면 first 레코드의 작업이 끝나며 'DONE'의 상태가 된다. 
- 만약 save 메서드에 두 개의 동일한 요청이 들어왔다면 어떻게 될까? 더 정확하게, `secondMapper.countDuplicateRecords(req)>0`를 통과한 동일한 내용의 요청 2개가 `save()` 를 앞두고 있다면 어떻게 될까?
    - second 테이블 내부에 uk가 존재하고 동일한 요청이 uk로 인하여 예외가 발생하는 것이 사실 가장 이상적인 상태이다. 
    - 안타깝게도 uk로 인한 예외가 발생하지 않았다. 완전 동일한 레코드 두 개가 insert가 될 수 있는 조건이었다. 
    - 테이블 변경은 부담스런 상황이었다. 가능한 현 조건에서 수정하고자 하였다. 

- insert가 계속 들어오는 상황을 일단 막아야 했다. 그때 선택한 것은 격리수준을 SERIALIZABLE으로 변경하는 것이었다. 

```java
@Transactional(isolation = Isolation.SERIALIZABLE)
void save(DoSomethingRequest req){
    // 상동
}
```

- 당장은 기대하는 방향대로 동작하였다. `countDuplicateRecords()` 메서드가 동작할 때, s lock을 얻게 된다. count가 0을 호출한다는 의미는, 해당 테이블 전체를 탐색했다는 의미이며, 모든 레코드에 대하여 갭락이 생긴다. 
- 한편, 이로 인한 부정적인 사이드 이펙트가 발생하였다. 데드락이 발생했다.
    - 만약 동일한 요청이 들어왔다면? `countDuplicateRecords()` 를 호출하여 s lock을 가진 트랜잭션이 두 개가 되기 때문에, 둘 중 하나는 죽여야 한다. 데드락은 적절한 대응이다. 
    - 하지만 다른 요청이 동시에 들어왔다면? 다른 요청일 경우 정상적인 상황이므로 save가 각각 되어야 한다. 하지만 `countDuplicateRecords()`으로 인한 갭락은 요청에 따라 부여되는 것이 아니다. 검색을 위한 where문이 다르더라도 두 트랜잭션 모두 전체 레코드에 대한 갭락을 가진다. 누구도 insert를 하지 못하게 된다. 
- 클라이언트 입장에서는 사용성이 떨어지며, 서버 입장에서는 굳이 필요 없는 락으로 인한 성능 문제가 발생하기 시작했다.

## 1차 시도 : 메서드는 무조건 한 스레드만 접근할 수 있게 with for update
- 최초에 나는 x 락으로 이 문제를 해결하려고 하였다. 왜냐하면 x lock은 select에 대한 배타적 락을 가진다고 이해했기 때문이다. 더 나아가 insert는 자원을 많이 소비하지 않고 빠르게 처리하는 작업이기 때문에, 동기적으로 동작하더라도 전혀 문제가 없다고 생각했다.

```java
@Transactional(isolation = Isolation.SERIALIZABLE)
void save(DoSomethingRequest req){    
    if(!firstMapper.isNew(req)) // select count(*) from second where seq = #{seq} and status = 'NEW';
        throw new IllegalArgumentException("해당 레코드의 상태가 'NEW'가 아닙니다.");

    // 쿼리 : select count(*) from second where seq = #{seq} for update;
    // 기대 : for update가 있으므로 어플리케이션이나 스레드의 갯수와 관계 없이 단 하나의 요청만 아래의 select을 할 수 있다. 나머지는 대기한다.
    if(secondMapper.countDuplicateRecords(req)>0)
        throw new IllegalArgumentException("second 테이블에 이미 존재하는 레코드가 있습니다.");

    secondMapper.save(reqToEntity(req)); // insert into second (....) values (.....);

    firstMapper.updateState(req, First.Done); // update first set state = 'DONE' where id = #{id} and state = 'NEW';
}
```

- 하지만 이것은 착각이었다. 검색 결과가 없는 `select ... for update`는 마치 s 락과 같이 동작했다. 그러니까 여러 트랜잭션이 동시에 select을 할 수 있었으며 락까지 획득하였다. 그 누구도 갱신할 수 없는 데드락 상태에 다시 놓이게 되었다. 이에 대한 구체적인 내용은 이전에 정리한 블로그를 참고바란다. 

### sql에 의존적인 코드
- 추가적으로 `for update`를 통한 동시성 문제를 해소하는 것이 좋은 방식인지에 대한 의문이 들었다. 도메인과 비지니스로직을 개발할 때, 인프라스트럭처에 영향을 받지 않을 수 없다. 하지만 x 락을 이해하고 이를 기반으로 개발한다는 것은 사실 db와 sql에 대한 높은 이해를 필요로 하며, 이에 따라 인프라스트럭처에 과도하게 의존적인 방식으로 개발한다고 생각했다. 예를 들면 `select count(*) from seconds for update` 등 비지니스 로직에는 필요 없지만, 락을 위한 쿼리를 만들어 호출할 수도 있을 것이다. 하지만 락에 대해 잘 이해하지 못하는 개발자가 읽을 수도 있다. 나중에 내가 그 코드의 의도를 이해하지 못해 잘못 수정할 수도 있다. 깨지기 쉬운 코드가 될 것 같다는 직감이 들었다. 
- 그러므로 나는 다른 방법을 선택해야 했다.

## 2차 시도 : UPDATE... affected rows 0
- update는 격리수준에 관계 없이 실제 DB에서 해당 쿼리가 성공했는지의 여부를 반환한다. affcted rows 0 혹은 1이라는 형태로 반환한다.
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
// service
void save(DoSomethingRequest req){
    if(firstMapper.updateState(req, 'DONE')==0) // update first set status = #{status} where status = 'NEW';
        throw new IllegalArgumentException("해당 레코드의 상태가 'NEW'가 아닙니다.");
    secondMapper.save(reqToEntity(req)); // insert into second (....) values (.....);
}
```

- 더 단순하고 명확한 방식으로 문제를 해소할 수 있었다. first 테이블의 update가 정상 수행 될 때,  second 테이블을 insert하는 행위는, 합리적인 흐름이다. 다른 개발자가 보더라도 직관적인 코드가 되었다. 
- first table에 대하여 select 후 update를 하던 로직을, update 한 차례로 줄였다. 
- 격리수준이 REPEATABLE READ이기 때문에 여러 트랜잭션이 동시에 update 및  insert를 할 수 있어서 성능상 좋다. 

## 나아가며
- DB에 잘 알지 못하는 상황에서 혼자 머리 싸매고 끙끙거려서 힘들었다. 하지만 트랜잭션이나 락 등에 대하여 잘 이해할 수 있는 기회가 되었다. 문제 발생을 해결하는 과정에서 학습해서 그럴까? 이전에는 와닿지 않았던 트랜잭션, 격리수준, 락에 대한 이해가 깊어짐을 느낀다. 해결해서 기분도 무척 좋았다. 
- insert할 때 신중한 방식으로 DDL을 작성해야 함을 깨달았다. 어떤 이유로든 중복 요청이 들어갈 수 있음을 상정해야 한다. 처음부터 uk를 적절하게 활용하여 중복 insert를 방지하는 것이 가장 쉽고 단순하며 확실한 방법임을 배웠다. 설계 차원에서 DDL을 잘 구현해야 함을 깨달았다. 나중에 가서 uk를 설정하는 것은 무척 부담스러운 일이다.
- 데이터 정합성 측면에서 데드락이 오히려 고마운 존재(?)임을 느끼게 된 계기가 되었다. 물론 결과적으로 없애야 할 에러이긴 하지만.