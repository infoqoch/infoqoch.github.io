---
layout: post
author: infoqoch
title: sql, insert와 select을 동시에 하기 
categories: [sql]
tags: [sql, mysql]
---

## insert 의 값을 select으로부터 호출한다.
- 특정 데이터를 거의 대부분 복사하되 몇 가지 부분만 수정해야 할 일이 생겼다. 
- 이때 사용하면 좋은 쿼리가 insert into.... select.... 패턴이다. 
- 아래의 쿼리는 TABLE_TEST의 USER_ID가 'kim'인 값을 호출하고, ADDRESS 만 변경하는 쿼리이다.

```sql
INSERT INTO TABLE_TEST
    (NAME, AGE, ADDRESS)
SELECT 
    NAME, AGE, '서울시 서울구 서울동'
FROM     
    TABLE_TEST
WHERE 
    USER_ID = 'kim';
```
