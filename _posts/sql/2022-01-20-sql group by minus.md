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
- 시작하는 숫자는 앞에 값이 없다. 종료되는 숫자는 뒤에 값이 없다. 
- 그러므로 나는 각 레코드에서 시작하는 값과 종료하는 값의 여부를 판별하고 합치는 방식으로 했다. 
- 그러니까, 아래의 쿼리를 생성할 경우 칼럼은 세 개이며 첫 번째는 원래 값, 두 번째는 그 전에 값이 있는지, 세 번째는 다음에 값이 있는지를 보여준다. 

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

- 그리고 그 전의 값이 없는 것(s)과 그 이후의 값이 없는 것(e)를 join 하면 결괏값이 나온다. 

## 더 쉬운 방법
- 쿼리가 다소 길어서 다른 사람이 한 방식들을 살펴봤다. 
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

- 위와 같이 위에서부터 아래로 인덱스를 부여한다. 그리고 그 값과 인덱스를 뺀다. 그리고 그 결괏값이 동일한 레코드가 바로 같은 그룹이 된다. 
- 이러한 해결 방법을 보고 사실 많이 놀랐다. 

## group by with minus operation
- 더 놀란 것은, 이러한 그룹핑을 group by 를 통해 가능하다.
