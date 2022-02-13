---
layout: post
author: infoqoch
title: sql limit 을 over에서 사용하기. row proceding
last_modified_at: 
categories: [sql]
tags: [sql, mysql]
---

## 7일까지의 통계를 매일마다 분석하기
- https://leetcode.com/problems/restaurant-growth/

```text
Input: 
Customer table:
+-------------+--------------+--------------+-------------+
| customer_id | name         | visited_on   | amount      |
+-------------+--------------+--------------+-------------+
| 1           | Jhon         | 2019-01-01   | 100         |
| 2           | Daniel       | 2019-01-02   | 110         |
| 3           | Jade         | 2019-01-03   | 120         |
| 4           | Khaled       | 2019-01-04   | 130         |
| 5           | Winston      | 2019-01-05   | 110         | 
| 6           | Elvis        | 2019-01-06   | 140         | 
| 7           | Anna         | 2019-01-07   | 150         |
| 8           | Maria        | 2019-01-08   | 80          |
| 9           | Jaze         | 2019-01-09   | 110         | 
| 1           | Jhon         | 2019-01-10   | 130         | 
| 3           | Jade         | 2019-01-10   | 150         | 
+-------------+--------------+--------------+-------------+
Output: 
+--------------+--------------+----------------+
| visited_on   | amount       | average_amount |
+--------------+--------------+----------------+
| 2019-01-07   | 860          | 122.86         |
| 2019-01-08   | 840          | 120            |
| 2019-01-09   | 840          | 120            |
| 2019-01-10   | 1000         | 142.86         |
+--------------+--------------+----------------+
Explanation: 
1st moving average from 2019-01-01 to 2019-01-07 has an average_amount of (100 + 110 + 120 + 130 + 110 + 140 + 150)/7 = 122.86
2nd moving average from 2019-01-02 to 2019-01-08 has an average_amount of (110 + 120 + 130 + 110 + 140 + 150 + 80)/7 = 120
3rd moving average from 2019-01-03 to 2019-01-09 has an average_amount of (120 + 130 + 110 + 140 + 150 + 80 + 110)/7 = 120
4th moving average from 2019-01-04 to 2019-01-10 has an average_amount of (130 + 110 + 140 + 150 + 80 + 110 + 130 + 150)/7 = 142.86
```

- 위의 문제를 보면 Customer 테이블이 있다. 요구사항은 매일마다 해당일을 기준으로 7일 전까지의 통계를 내고 싶다. 해당 통계는 총 판매량과 그것을 7로 나눈 평균값이다. 

## 해소
- 보통 이러한 문제는 2일 3일 정도로 단순하다. 그러니까 하루 전날과 그 날을 기준을 어긋나게 하여 `(on a.date = DATE_ADD(b.date, interval -1 day)` 할 수 있다. 그러나 이번의 기준은 7일이며 join 테이블을 7개 만들 수는 없었다. 
- 생각해 낸 방법은 서브쿼리였다. 각각의 판매일을 group by 하고, 해당일로부터 7일 전까지 limit 으로 추출하는 방식이다.

```sql
with tb as(
    select 
        visited_on
        , sum(amount) amount
        , row_number() over(order by visited_on asc) ranks
    from customer 
    group by visited_on
)
select
    visited_on
    , (select sum(amount) from (select t.amount from tb t where t.ranks <= tb.ranks order by t.ranks desc limit 7) tt) amount
    , round((select sum(amount) from (select t.amount from tb t where t.ranks <= tb.ranks order by t.ranks desc limit 7) tt) / 7, 2) average_amount
from tb
where tb.ranks>6;
```
- 더 쉬운 방법이 없을까 찾아봤다. 
- row [int] preceding 이 위의 limit [int] 와 동일하게 동작한다. 
  
```sql
  with tb as(
    select 
        visited_on
        , sum(sum(amount)) over(order by visited_on rows 6 preceding) amount
        , row_number() over(order by visited_on asc) ranks
    from customer 
    group by visited_on
)
select 
    visited_on
    , amount
    , round(amount/7, 2) average_amount
from tb
where ranks > 6
```

## 나아가며
- sql 문제 여러개를 풀었다. 덕분에 with, over() 등 좀 더 고급 쿼리 절을 알 수 있게 됐다.
- 그러나 문제를 푸는 형태로 접근하니까 그것에 대한 일종의 풍부한 지식을 얻기에는 부족했다. 
- 뭔가 쿼리에 대하여 좀 더 이론적으로 접근할 만한 방식이 없을까 고민이 든다. DBA분들은 도대체 어떤 방식으로 공부하는 것일까?