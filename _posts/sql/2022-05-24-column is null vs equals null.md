---
layout: post
author: infoqoch
title: sql에서 column is null 과 column = null
categories: [sql]
tags: [sql]
---

- sql을 사용하면서 `column is null` 과 `column = null` 의 차이가 궁금했다. 
- 특히 sql mapper를 사용할 때 걱정되었다. 아래와 같은 코드가 있다고 가정하자.

```java
void updateName(){
    Test test = new Test();
    test.setName("kim");
    test.setId(null);
    mapper.update(test); // update tests set name = ? where id = ?; 
}
```
- 위의 코드를 보면 id에 null이 들어가는데, id가 의도치 않게 어떤 값도 들어가지 않은 상황이다. 
- tests 테이블에 id가 null인 데이터가 5개가 있다고 가정하자. 위의 쿼리가 동작할 때 5개의 레코드가 영향을 받는 것일까? 아니면 아무런 영향을 받지 않을까? 이 부분이 걱정되었다. 사이드 이펙트를 최소화 하고 싶었다. 

- 실제로 아래와 같이 is null과 = null을 비교하였다. 
- 결과적으로 `id = null`은 칼럼에 null인 레코드가 여러 개 있더라도 어떤 영향을 주지 못했다. 
- 실제 값이 null 인 레코드를 수정하려면 `id is null` 로 해야 한다.

```sql
-- 아래의 쿼리와 같이 id가 null인 레코드 몇 개를 삽입한다. 
INSERT INTO tests (id, name) VALUES (NULL, 'name'); 

-- 동작 안함
UPDATE TESTS 
SET name = 'new name'
WHERE id = NULL 

-- 동작 안함
UPDATE TESTS 
SET name = 'new name'
WHERE id != NULL

-- 동작함
UPDATE TESTS 
SET name = 'new name'
WHERE id is NULL 
```

- 예전에는 `column is null`이 매우 불편하다고 생각했다. 이제 와서 보면, 이 방식은 매우 안전하고 좋은 방법이다. 동적 쿼리 생성 과정에서 사이드이펙트를 없앤다. 