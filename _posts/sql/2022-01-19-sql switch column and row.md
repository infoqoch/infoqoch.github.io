---
layout: post
author: infoqoch
title: sql column과 row를 유연하게 전환하기
categories: [sql]
tags: [sql, mysql]
---

## column 과 row 를 잘 전환하기
- sql은 일종의 x축과 y축을 가진 2차원과 유사하다는 느낌을 받는다. 칼럼과 로우로 이뤄진 관계형 데이타베이스는 사실 2차원이 맞다.
- 한편, 관계형 데이타베이스는 x축과 y축을 join이나 union 등을 사용하여 자유롭게 변형 가능하며 이를 통해 요구사항을 쉽게 풀 수 있다. 
- column 과 row 를 염두하여 쿼리를 짜는 방식으로 문제를 효과적으로 해소한 경험을 공유코자 한다. 

## column 을 추가하여 비교하기.

### 문제 
- https://leetcode.com/problems/drop-type-1-orders-for-customers-with-type-0-orders/
- Orders 테이블이 있다. customer_id는 order_type을 0이나 1을 가질 수 있다. 만약 0을 가진다면 1을 출력해서는 안된다. 

``` text
Input: 
Orders table:
+----------+-------------+------------+
| order_id | customer_id | order_type |
+----------+-------------+------------+
| 1        | 1           | 0          |
| 2        | 1           | 0          |
| 11       | 2           | 0          |
| 12       | 2           | 1          |
| 21       | 3           | 1          |
| 22       | 3           | 0          |
| 31       | 4           | 1          |
| 32       | 4           | 1          |
+----------+-------------+------------+
Output: 
+----------+-------------+------------+
| order_id | customer_id | order_type |
+----------+-------------+------------+
| 31       | 4           | 1          |
| 32       | 4           | 1          |
| 1        | 1           | 0          |
| 2        | 1           | 0          |
| 11       | 2           | 0          |
| 22       | 3           | 0          |
+----------+-------------+------------+
```

### 문제 해소의 방향
- order_type 이 0인 경우는 모두 출력을 하면 된다. 핵심적인 문제는 order_type이 1인 경우 출력하거나 하지 않으며 이를 판별해야 한다. 
- order_type이 1일 때, 출력할지 말지를 판별하는 방식을 나는 기존 테이블에 하나의 칼럼을 추가하는 방식으로 문제를 해소하였다. 그러니까 각 레코드 마다 해당 회원이 order_type을 1을 가지고 있는지의 여부를 보여주면 된다. 그러니까 테이블을 아래와 같이 만든다. 

```text
+----------+-------------+------------+-------------------+
| order_id | customer_id | order_type |isExistOrderType0  |
+----------+-------------+------------+-------------------+
| 1        | 1           | 0          |true               |
| 2        | 1           | 0          |true               |
| 11       | 2           | 0          |true               |
| 12       | 2           | 1          |true               |
| 21       | 3           | 1          |true               |
| 22       | 3           | 0          |true               |
| 31       | 4           | 1          |false              |
| 32       | 4           | 1          |false              |
+----------+-------------+------------+-------------------+
```

### 쿼리
- 위의 레코드 추가는 join으로 하였다. 
- `o2.order_type`는 사실 어떤 값이 오더라도 상관 없다. left join의 특성 상 그곳에 데이타 있거나(not null), 데이터가 있거나(null)를 판별하면 되기 때문이다. 

```sql
select distinct
    tb.order_id 
    , tb.customer_id 
    , tb.order_type
from(
    select 
        o1.order_id 
        , o1.customer_id
        , o1.order_type
        , o2.order_type isExist
    from orders o1
    left join orders o2
    on o2.customer_id = o1.customer_id and o2.order_type = 0
) tb 
where tb.order_type = 0
      or (tb.order_type = 1 and tb.isExist is null)
```


## column 을 row로 변경한다. union

### 승리한 횟수를 구한다. Grand Slam Titles
- https://leetcode.com/problems/grand-slam-titles/
- Championships 테이블에는 년도와 4개의 메이저 대회가 있다. 년도는 년도가 들어가고 대회에는 승리자의 고유번호가 들어간다. 
- 문제는 승리자의 고유번호가 모든 연도에 모든 게임에서 총 몇 회를 승리를 했는지 판단하는 일이다. 

```test
Input: 
Players table:
+-----------+-------------+
| player_id | player_name |
+-----------+-------------+
| 1         | Nadal       |
| 2         | Federer     |
| 3         | Novak       |
+-----------+-------------+
Championships table:
+------+-----------+---------+---------+---------+
| year | Wimbledon | Fr_open | US_open | Au_open |
+------+-----------+---------+---------+---------+
| 2018 | 1         | 1       | 1       | 1       |
| 2019 | 1         | 1       | 2       | 2       |
| 2020 | 2         | 1       | 2       | 2       |
+------+-----------+---------+---------+---------+
Output: 
+-----------+-------------+-------------------+
| player_id | player_name | grand_slams_count |
+-----------+-------------+-------------------+
| 2         | Federer     | 5                 |
| 1         | Nadal       | 7                 |
+-----------+-------------+-------------------+
```

### 문제의 해소
- 위의 문제는 어떤 게임에서 어떤 해에 이겼나가 중요하지 않다. 그냥 몇 번 이겼나가 중요하다. 
- 이 경우 모든 column을 row로 변경하여 쉽게 해소 가능하다. 다음과 같이 변경된다. 

```text
before
+------+-----------+---------+---------+---------+
| year | Wimbledon | Fr_open | US_open | Au_open |
+------+-----------+---------+---------+---------+
| 2018 | 1         | 1       | 1       | 1       |
| 2019 | 1         | 1       | 2       | 2       |
| 2020 | 2         | 1       | 2       | 2       |
+------+-----------+---------+---------+---------+

after
+-----------
| Wimbledon 
+-----------
| 1         
| 1         
| 2         
+-----------
+---------
| Fr_open 
+---------
| 1       
| 1       
| 1       
+---------
| US_open 
| 1       
| 2       
| 2       
+---------+
| Au_open 
| 1       
| 2       
| 2       
```

## 쿼리
- column을 row로 만들 때 union 을 사용했다. 

```sql
select 
    tb.player_id
    , player_name
    , count(tb.player_id) grand_slams_count
from (
    select Wimbledon player_id
    from Championships 
    union all
    select Fr_open player_id
    from Championships 
    union all
    select US_open player_id
    from Championships 
    union all
    select Au_open player_id
    from Championships 
) tb
join players p
    on tb.player_id = p.player_id
group by player_id
```