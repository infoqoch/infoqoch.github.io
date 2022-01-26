---
layout: post
author: infoqoch
title: sql partition by  활용하기
categories: [sql]
tags: [sql, mysql]
---

## 들어가며
- leetcode의 sql 문제를 풀며 partition by 를 자주 활용하였다. 

## 각 회원 별 가장 많이 구매한 물건은?  https://leetcode.com/problems/the-most-frequently-ordered-products-for-each-customer/
- 각 회원이 있고, 각 회원이 구매한 상품이 있다. 
- 각 회원이 가장 많이 구매한 물품을 구한다. 

```text
Input: 
Customers table:
+-------------+-------+
| customer_id | name  |
+-------------+-------+
| 1           | Alice |
| 2           | Bob   |
| 3           | Tom   |
| 4           | Jerry |
| 5           | John  |
+-------------+-------+
Orders table:
+----------+------------+-------------+------------+
| order_id | order_date | customer_id | product_id |
+----------+------------+-------------+------------+
| 1        | 2020-07-31 | 1           | 1          |
| 2        | 2020-07-30 | 2           | 2          |
| 3        | 2020-08-29 | 3           | 3          |
| 4        | 2020-07-29 | 4           | 1          |
| 5        | 2020-06-10 | 1           | 2          |
| 6        | 2020-08-01 | 2           | 1          |
| 7        | 2020-08-01 | 3           | 3          |
| 8        | 2020-08-03 | 1           | 2          |
| 9        | 2020-08-07 | 2           | 3          |
| 10       | 2020-07-15 | 1           | 2          |
+----------+------------+-------------+------------+
Products table:
+------------+--------------+-------+
| product_id | product_name | price |
+------------+--------------+-------+
| 1          | keyboard     | 120   |
| 2          | mouse        | 80    |
| 3          | screen       | 600   |
| 4          | hard disk    | 450   |
+------------+--------------+-------+
Output: 
+-------------+------------+--------------+
| customer_id | product_id | product_name |
+-------------+------------+--------------+
| 1           | 2          | mouse        |
| 2           | 1          | keyboard     |
| 2           | 2          | mouse        |
| 2           | 3          | screen       |
| 3           | 3          | screen       |
| 4           | 1          | keyboard     |
+-------------+------------+--------------+
```

### 해결 방안
- 각 회원마다 처리해야할 부분은 두 개이다.
  - 첫 번째는 각 회원별로 구매한 상품을 그룹핑하고 그것의 빈도를 구한다. 
  - 두 번째로 해당 빈도가 가장 많은 상품을 추출한다.
- 빈도를 구하는 것은 group by customer_id 와 count(product_id) 로 구할 수 있다. 하지만 count(product_id)의 max값을 구하는 것은 쉽지 않았다. 도저히 구할 수가 없어서 max(count(product_id)) 나 having max(count(product_id)) 등 요상한 방법으로 찾아봤지만 성공할 수 없었다. 
- 결국 partition by를 사용하여 해결하였다. partition by를 통해 그룹핑을 하고 order by를 기준으로 랭크를 매긴다. 그리고 랭크가 1인 값 전체를 추출한다. 

### 쿼리

```sql
select 
    tb.customer_id
    , tb.product_id
    , p.product_name
from (
    select 
        customer_id
        , product_id
        , rank() over(partition by customer_id  order by count(product_id) desc ) ranks
    from orders
    group by customer_id, product_id
)tb
join Products p
on p.product_id = tb.product_id
where tb.ranks = 1 
```


##