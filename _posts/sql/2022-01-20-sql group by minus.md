---
layout: post
author: infoqoch
title: sql minus 와 함께 group by 하기
categories: [sql]
tags: [sql, mysql]
---

## 연속된 숫자를 그룹핑하여 그룹간 첫 번째와 마지막을 구하기 1285. Find the Start and End Number of Continuous Ranges
- https://leetcode.com/problems/find-the-start-and-end-number-of-continuous-ranges/
- 칼럼이 하나인 테이블이 있다. 값은 숫자가 증가하는 레코드로 구성되어 있다. 값이 1씩 증가할 경우 하나의 그룹이 되어 처음 값과 마지막 값을 구한다. 

```text
Input: 
Logs table:
+------------+
| log_id     |
+------------+
| 1          |
| 2          |
| 3          |
| 7          |
| 8          |
| 10         |
+------------+
Output: 
+------------+--------------+
| start_id   | end_id       |
+------------+--------------+
| 1          | 3            |
| 7          | 8            |
| 10         | 10           |
+------------+--------------+
```

## 문제의 해소
- 시작하는 숫자는 앞에는 자신을 하나 뺀 값이 없다. 종료되는 숫자는 뒤에는 자신을 하나 더한 값이 없다. 이를 통해 처음 시작과 끝이 무엇인지를 판별했다. 
- 아래는 with절을 통해 테이블을 생성했고 칼럼은 세 개이다. 첫 번째는 원래 값, 두 번째는 그 전에 값이 있는지, 세 번째는 다음에 값이 있는지를 보여준다. 

```sql
with tb(id, s, e) as(
select 
        *   
    from logs l
    left join logs s
    on l.log_id = s.log_id + 1
    left join logs e
    on l.log_id = e.log_id - 1
)
select * from tb;
```

- 결과 : 
  
```json
{"headers": 
    ["id", "s", "e"],
 "values": 
    [[1, null, 2],
    [2, 1, 3],
    [3, 2, null],
    [7, null, 8],
    [8, 7, null],
    [10, null, null]]
}
```

- 자신의 앞에 값이 연결되는 값이 없는 것(s)과 자신의 뒤에 연결되는 값이 없는 것(e)을 합치면 결과가 나온다. 

```sql
with tb(id, s, e) as(
select 
        *   
    from logs l
    left join logs s
    on l.log_id = s.log_id + 1
    left join logs e
    on l.log_id = e.log_id - 1
)
select
    s.id 'start_id'
    , e.id 'end_id'
from (
    select 
        (@idx1:=@idx1+1) idx
        , t.id
    from tb t
        ,(select @idx1:=0) i
    where t.s is null 
) s
join (
    select 
        (@idx2:=@idx2+1) idx
        , t.id
    from tb t
        ,(select @idx2:=0) i
    where t.e is null 
) e
on s.idx = e.idx
```

## 더 쉬운 방법
- 성능은 나쁘지 않았으나 쿼리가 다소 길고 복잡했다. 그래서 다른 사람이 쿼리를 살펴봤다.
- 더 쉬운 방법이 있었다. 
  
```text
+------------+-----+-------------+
| log_id     | idx |log_id - idx |
+------------+-----+-------------+
| 1          |1    |0            |
| 2          |2    |0            |
| 3          |3    |0            |
| 7          |4    |3            |
| 8          |5    |3            |
| 10         |6    |4            |
+------------+-----+-------------+
```

- 숫자의 순서대로 인덱스를 부여한다. 그리고 그 값과 인덱스를 뺀다. 그리고 그 결괏값이 동일한 레코드가 바로 같은 그룹이 된다. 차이가 동일하다는 것은 숫자가 연속됨을 보장하기 때문이다. 
- 각각의 그룹(위에서는 0, 3, 4)에서 log_id의 최댓값과 최솟값을 구한다. 
- 그룹핑에 대한 완전 새로운 접근이었다. 많이 놀랐다. 

## group by with minus operation
- 더 놀란 것은, 이러한 그룹핑을 group by 를 통해 매우 간단하게 해결 가능했다. 

```sql
select 
    min(log_id) as start_id
    , max(log_id) as end_id
FROM(
    SELECT 
        log_id
        , ROW_NUMBER() OVER(ORDER BY log_id) as num 
        FROM Logs
) a
GROUP BY log_id - num
```

- 위의 코드에서 `log_id - num` 을 할 경우 000,33,4가 나온다. 이 값으로 바로 그룹핑이 가능하다. 


