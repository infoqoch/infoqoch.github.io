---
layout: post
author: infoqoch
title: sql, outer join 과 집계함수의 활용
categories: [sql]
tags: [sql, mysql]
---

## join 과 집계 함수
- inner join 의 경우 두 개의 테이블을 특정 기준으로 비교하여, 두 테이블에 레코드가 모두 존재하는 경우만 출력한다.
- outer join 의 경우 기준이 되는 테이블 전체의 출력을 보장한다. left join을 할 경우 왼쪽 테이블 전체의 출력을 보장하는데, 왼쪽의 어떤 레코드가 오른쪽의 레코드와 연결되는 값이 없으면, 오른쪽 레코드가 들어갈 칼럼에 null을 채운다. 
- null의 존재유무는 테이블 간 연결되는 레코드의 존재유무를 의미하기 때문에, null을 통해 테이블 간 비교를 다채롭게 할 수 있다. 
- 한편, sum 등 집계함수와 outer join을 동시에 할 경우 어떻게 처리해야 할까?

## 종이박스와 상자에 있는 상품의 갯수를 합치기
- https://leetcode.com/problems/count-apples-and-oranges/
  
### 요구사항
- 오렌지와 사과를 담는 상자chests와 종이박스boxes가 있다. 
- boxes 에는 chest_id가 있으며, chests의 chest_id와 fk관계이며, chests 에 있는 값을 더해야 한다. 그러니까 boxes의 chest_id 가 3개 있으면, chests의 fk 레코드의 오렌지와 사과를 3번 더 더해야 한다. 

```text
Input: 
Boxes table:
+--------+----------+-------------+--------------+
| box_id | chest_id | apple_count | orange_count |
+--------+----------+-------------+--------------+
| 2      | null     | 6           | 15           |
| 18     | 14       | 4           | 15           |
| 19     | 3        | 8           | 4            |
| 12     | 2        | 19          | 20           |
| 20     | 6        | 12          | 9            |
| 8      | 6        | 9           | 9            |
| 3      | 14       | 16          | 7            |
+--------+----------+-------------+--------------+
Chests table:
+----------+-------------+--------------+
| chest_id | apple_count | orange_count |
+----------+-------------+--------------+
| 6        | 5           | 6            |
| 14       | 20          | 10           |
| 2        | 8           | 8            |
| 3        | 19          | 4            |
| 16       | 19          | 19           |
+----------+-------------+--------------+
Output: 
+-------------+--------------+
| apple_count | orange_count |
+-------------+--------------+
| 151         | 123          |
+-------------+--------------+
Explanation: 
box 2 has 6 apples and 15 oranges.
box 18 has 4 + 20 (from the chest) = 24 apples and 15 + 10 (from the chest) = 25 oranges.
box 19 has 8 + 19 (from the chest) = 27 apples and 4 + 4 (from the chest) = 8 oranges.
box 12 has 19 + 8 (from the chest) = 27 apples and 20 + 8 (from the chest) = 28 oranges.
box 20 has 12 + 5 (from the chest) = 17 apples and 9 + 6 (from the chest) = 15 oranges.
box 8 has 9 + 5 (from the chest) = 14 apples and 9 + 6 (from the chest) = 15 oranges.
box 3 has 16 + 20 (from the chest) = 36 apples and 7 + 10 (from the chest) = 17 oranges.
Total number of apples = 6 + 24 + 27 + 27 + 17 + 14 + 36 = 151
Total number of oranges = 15 + 25 + 8 + 28 + 15 + 15 + 17 = 123
```

### 해소방안
#### outer join 과 집계함수 실패
- chests 와 boxes 를 left join 하여 집계함수를 활용한다.

```sql
select 
    sum(b.apple_count+c.apple_count) apple_count
    , sum(b.orange_count+c.orange_count) orange_count
from boxes b
left join chests c
on b.chest_id = c.chest_id
```

- 위의 방식으로 할 경우 문제가 발생한다. chest가 null인 경우를 더해주지 못한다. 
- 그래서 복잡하지만 아래의 방법을 선택하였고 성공했다.


#### join과 null의 union
- chests 와 boxes를 join 한다.
- join을 하더라도 chest에 null인 경우 boxes 의 레코드를 잃어버린다.
- 그러므로 boxes 에서 chest_id 가 null 인 값을 추출하여 join 한 값과 합친다.

```sql
select 
    sum(apple_count) apple_count 
    , sum(orange_count) orange_count
from (
    select 
        sum(c.apple_count+b.apple_count) apple_count
        , sum(c.orange_count+b.orange_count) orange_count
    from boxes b
    join chests c
    on b.chest_id = c.chest_id 
    union 
    select 
        sum(apple_count) apple_count
        , sum(orange_count) orange_count
    from boxes
    where chest_id is null 
)tb
```

#### outer join 과 집계함수 성곧
- 아래의 방법을 통해 더 간단하게 성공했다. 첫 번째 방법이 실패한 이유는 null 과 숫자를 합치면 null을 반환하기 때문이다.

``` sql
select 
    b.apple_count a 
    , c.apple_count b
    , b.apple_count +  c.apple_count
from boxes b
left join chests c
on b.chest_id = c.chest_id
```

- 6과 null 을 더하면 null을 반환함을 확인할 수 있다. 

```text
[6, null, null]
[4, 20, 24]
[8, 19, 27]
[19, 8, 27]
[12, 5, 17]
[9, 5, 14]
[16, 20, 36]
```

- 그러므로 null일 경우 0으로 대체하여 더해야 한다. ifnull을 사용한다. 그 쿼리는 아래와 같다. 

```sql
SELECT 
    IFNULL(SUM(BOXES.APPLE_COUNT), 0) + IFNULL(SUM(CHESTS.APPLE_COUNT), 0) AS APPLE_COUNT
    , IFNULL(SUM(BOXES.ORANGE_COUNT), 0) + IFNULL(SUM(CHESTS.ORANGE_COUNT), 0) AS ORANGE_COUNT
FROM BOXES
LEFT JOIN CHESTS ON CHESTS.CHEST_ID = BOXES.CHEST_ID
```