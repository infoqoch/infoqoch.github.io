---
layout: post
author: infoqoch
title: sql sum 과 case 사용하기
categories: [sql]
tags: [sql, mysql]
---

## 조건에 맞는 값을 합친다. sum 과 case
- sum과 case를 같이 사용하여 정말로 많은 요구사항을 수행할 수 있다. where 문이 select 문에 있는 것과 유사한데, 그것의 조건을 거는 방식이 매우 자유롭고 강력하기 때문이다. 
- 특정 칼럼에서의 조건에 따라 해당 값을 더하거나 뺄 수 있고 곱하는 등 매우 자유롭게 사용 가능하다. 
- group by를 통해 각 그룹마다의 합계를 생성할 수 있어서 무척 편하다. 

### 문제 Capital Gain/Loss
- https://leetcode.com/problems/capital-gainloss/
- Stocks 테이블에는 주식의 이름, 구매 및 판매 여부, 값이 있다. 주식 종류 마다 구매와 판매의 가격을 비교하여 최종적인 수익을 구한다. 

```text
Input: 
Stocks table:
+---------------+-----------+---------------+--------+
| stock_name    | operation | operation_day | price  |
+---------------+-----------+---------------+--------+
| Leetcode      | Buy       | 1             | 1000   |
| Corona Masks  | Buy       | 2             | 10     |
| Leetcode      | Sell      | 5             | 9000   |
| Handbags      | Buy       | 17            | 30000  |
| Corona Masks  | Sell      | 3             | 1010   |
| Corona Masks  | Buy       | 4             | 1000   |
| Corona Masks  | Sell      | 5             | 500    |
| Corona Masks  | Buy       | 6             | 1000   |
| Handbags      | Sell      | 29            | 7000   |
| Corona Masks  | Sell      | 10            | 10000  |
+---------------+-----------+---------------+--------+
Output: 
+---------------+-------------------+
| stock_name    | capital_gain_loss |
+---------------+-------------------+
| Corona Masks  | 9500              |
| Leetcode      | 8000              |
| Handbags      | -23000            |
+---------------+-------------------+
```

### 문제의 해소
- 주식의 종류를 기준으로 group by 를 한다. 
- 주식을 구매했을 때 빼기를 하고 주식을 팔 때 더하기를 한다. 그 합을 구한다. 

### 쿼리
```sql
select 
    stock_name
    , sum(case when operation='buy' then -price
         else price
          end) as 'capital_gain_loss'
from stocks
group by stock_name
```

### 가장 높은 비율을 가진 데이터 뽑기 Get Highest Answer Rate Question
- https://leetcode.com/problems/get-highest-answer-rate-question/
- 특정 문제가 있고 그것을 보여(show)준다. 상대방은 대답(answer)하거나 무시(skip)한다. 각 문제마다 대답의 비율을 구하고 가장 대답의 비율이 높은 문제를 출력한다. 대답의 비율이 동일하면 그 중 가장 빠른 id를 출력한다.

```text
Input: 
SurveyLog table:
+----+--------+-------------+-----------+-------+-----------+
| id | action | question_id | answer_id | q_num | timestamp |
+----+--------+-------------+-----------+-------+-----------+
| 5  | show   | 285         | null      | 1     | 123       |
| 5  | answer | 285         | 124124    | 1     | 124       |
| 5  | show   | 369         | null      | 2     | 125       |
| 5  | skip   | 369         | null      | 2     | 126       |
+----+--------+-------------+-----------+-------+-----------+
Output: 
+------------+
| survey_log |
+------------+
| 285        |
+------------+
```

### 문제의 해소
- 이 문제는 사실상 answer / show를 구하는 문제이다. 

### 쿼리

```sql
select 
  question_id survey_log
from (
  select 
    question_id
    , sum(case when action = 'answer' then 1 else 0 end)/ sum(case when action = 'show' then 1 else 0 end) rt
  from surveylog 
  group by question_id 
    ) tb 
order by tb.rt desc, tb.question_id asc 
limit 1
```