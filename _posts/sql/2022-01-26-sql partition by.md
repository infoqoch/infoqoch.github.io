---
layout: post
author: infoqoch
title: sql partition by  활용하기
categories: [sql]
tags: [sql, mysql]
---

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


## 각 통장 별 잔액 구하기 Account Balance
- 아래의 테이블은 거래내역을 보여준다. 각 account_id는 0원으로부터 시작함을 가정한다. 거래는 입금과 출금으로 이뤄지고 해당 금액을 가진다. 각 거래마다의 잔액(balance)를 구하는 것이 과제이다. 

```text
Input: 
Transactions table:
+------------+------------+----------+--------+
| account_id | day        | type     | amount |
+------------+------------+----------+--------+
| 1          | 2021-11-07 | Deposit  | 2000   |
| 1          | 2021-11-09 | Withdraw | 1000   |
| 1          | 2021-11-11 | Deposit  | 3000   |
| 2          | 2021-12-07 | Deposit  | 7000   |
| 2          | 2021-12-12 | Withdraw | 7000   |
+------------+------------+----------+--------+
Output: 
+------------+------------+---------+
| account_id | day        | balance |
+------------+------------+---------+
| 1          | 2021-11-07 | 2000    |
| 1          | 2021-11-09 | 1000    |
| 1          | 2021-11-11 | 4000    |
| 2          | 2021-12-07 | 7000    |
| 2          | 2021-12-12 | 0       |
+------------+------------+---------+
Explanation: 
Account 1:
- Initial balance is 0.
- 2021-11-07 --> deposit 2000. Balance is 0 + 2000 = 2000.
- 2021-11-09 --> withdraw 1000. Balance is 2000 - 1000 = 1000.
- 2021-11-11 --> deposit 3000. Balance is 1000 + 3000 = 4000.
Account 2:
- Initial balance is 0.
- 2021-12-07 --> deposit 7000. Balance is 0 + 7000 = 7000.
- 2021-12-12 --> withdraw 7000. Balance is 7000 - 7000 = 0.
```

### 해결 방안
- 입금은 금액을 양으로, 출금은 음으로 만든다. 
- 해당 금액을 partition by를 사용하여 시간의 흐름에 따라 값을 누적한다. 이 때 sum over를 사용한다. 

```sql
with this as (
    select 
        account_id
        , day
        , case 
            when type = 'Deposit' then amount 
            else -amount
            end 'amt'    
    from transactions
)
select 
    account_id
    , day
    , sum(amt) over(partition by account_id order by day asc) balance
from this
```

## 순서에 따른 누적값 구하기 
- https://leetcode.com/problems/game-play-analysis-iii/

### 요구 사항
- 각 회원별로 로그인 한 각각의 날을 기준으로 해당 날까지 게임을 한 횟수의 누적값을 구한다. 

```text
Input: 
Activity table:
+-----------+-----------+------------+--------------+
| player_id | device_id | event_date | games_played |
+-----------+-----------+------------+--------------+
| 1         | 2         | 2016-03-01 | 5            |
| 1         | 2         | 2016-05-02 | 6            |
| 1         | 3         | 2017-06-25 | 1            |
| 3         | 1         | 2016-03-02 | 0            |
| 3         | 4         | 2018-07-03 | 5            |
+-----------+-----------+------------+--------------+
Output: 
+-----------+------------+---------------------+
| player_id | event_date | games_played_so_far |
+-----------+------------+---------------------+
| 1         | 2016-03-01 | 5                   |
| 1         | 2016-05-02 | 11                  |
| 1         | 2017-06-25 | 12                  |
| 3         | 2016-03-02 | 0                   |
| 3         | 2018-07-03 | 5                   |
+-----------+------------+---------------------+
Explanation: 
For the player with id 1, 5 + 6 = 11 games played by 2016-05-02, and 5 + 6 + 1 = 12 games played by 2017-06-25.
For the player with id 3, 0 + 5 = 5 games played by 2018-07-03.
Note that for each player we only care about the days when the player logged in.
```

### 해소
- sum() over 를 통하여 누적값을 구한다. row_number() 가 1씩 더하는 인덱스를 구하는 것처럼, sum의 경우 그것의 인자를 누적한다. 

```sql
select 
    player_id 
    , event_date 
    , sum(games_played) over(partition by player_id order by  event_date asc) games_played_so_far
from activity
```

## partition by...
- leetcode의 sql 문제를 풀며 partition by 를 자주 활용하였다. 사실은 문제의 반절은 partition by를 활용해야 쉽게 풀 수 있는 문제로 이뤄져 있다. 코테를 위한 코딩처럼, 쿼리 테스트를 위한 쿼리절이 있는건가...!?
- partition by는 group by와 같이 데이터를 분리하는데 사용하며, order by 는 순서를 정한다. sum, rank, row_number() 이외에 count() 등 다양한 함수를 지원한다.  
- 이번에 공부하면서 쿼리에 대하여 단순한 절은 잘 사용하지만 복잡한 내용은 잘 모르고 사용한다는 것을 많이 느꼈다. 더 공부하자! 