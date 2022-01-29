---
layout: post
author: infoqoch
title: sql의 데이터 타입 중 하나인 date 다루기  
categories: [sql]
tags: [sql, mysql]
---

## sql의 데이터 타입
- sql에는 다양한 데이터 타입이 있다.
- 나에게는 varchar 와 char의 차이가 인상적이었다. varchar 는 그것의 초기값이 얼마이든, 실제 레코드가 들어갈 때 그것의 실제 점유 공간의 길이가 결정되는데 반해, char의 경우 레코드가 생성될 때 무조건 그것이 초기화한 양 만큼 점유한다고 한다. 
- char varchar 이외에 int, date, datetime 등 다양한 데이터 타입이 있다. 더 나아가 인텔리제이는 boolean 등을 지원하고 0과 1을 true와 false로 변환해주는 등 매우 편리한 기능도 지원한다. 
- 이번에 이야기할 데이터타입은 date 와 datetime 이다.

## date 
- date type 은 date, datetime 으로 나뉜다. 앞은 년-월-일, 후자는 시분초를 포함한다.
- string 에 대하여 특별한 타입 변환 없이 date로 변환이 된다. 
- now() 와 sysdate()의 차이는, 하나의 명령에서의 now()는 동일한 값을 보장하고, sysdate()는 각각의 쿼리마다 새로운 시간을 부여한다. 메모리와 데이터 동일성 입장에서 now()를 보통 사용한다. 
- 기타 date와 관련한 함수는 아래의 코드를 참고하자. 

```sql
CREATE TABLE datetest (
	idx INT UNSIGNED PRIMARY KEY AUTO_INCREMENT ,
	name VARCHAR(100),
	birthday DATE,
	regDt DATETIME 
) ;

INSERT INTO datetest(NAME, birthday, regdt)
VALUES 
	('kim', '2000-01-01', NOW()),
	('lee', '2005-06-05', NOW());

SELECT * FROM datetest;

SELECT 
	TIMESTAMPDIFF(DAY, '2021-01-01', '2021-02-05')
	, TIMESTAMPDIFF(MONTH, '2021-01-01', '2021-02-05')
	, DATE_FORMAT(NOW(), '%Y-%m-%d')
	, MONTH(NOW()) 
	, YEAR(NOW())
	, HOUR(NOW())
	, YEAR('2020-01-01')
	, YEAR('2020-1-1')
	, NOW()
	, SYSDATE()
```

## 같은 날에 주문하였는가? 
- https://leetcode.com/problems/immediate-food-delivery-i/

### 요구사항
- 고객이 주문을 할 때 선호하는 발송일을 선택할 수 있다. 
- 고객이 주문한 날에 발송한 비율을 추출한다.

```sql
Input: 
Delivery table:
+-------------+-------------+------------+-----------------------------+
| delivery_id | customer_id | order_date | customer_pref_delivery_date |
+-------------+-------------+------------+-----------------------------+
| 1           | 1           | 2019-08-01 | 2019-08-02                  |
| 2           | 5           | 2019-08-02 | 2019-08-02                  |
| 3           | 1           | 2019-08-11 | 2019-08-11                  |
| 4           | 3           | 2019-08-24 | 2019-08-26                  |
| 5           | 4           | 2019-08-21 | 2019-08-22                  |
| 6           | 2           | 2019-08-11 | 2019-08-13                  |
+-------------+-------------+------------+-----------------------------+
Output: 
+----------------------+
| immediate_percentage |
+----------------------+
| 33.33                |
+----------------------+
Explanation: The orders with delivery id 2 and 3 are immediate while the others are scheduled.
```

### 해소
- 주문한 날과 발송한 날을 비교한다. 그 날의 차이가 0 인 값을 추출한다. 

```sql
select round(tb1.cnt/tb2.cnt, 4) * 100 immediate_percentage
from (
    select count(1) cnt
    from delivery 
    where timestampdiff(DAY, order_date, customer_pref_delivery_date) = 0
) tb1
join (
    select count(1) cnt
    from delivery 
) tb2
```
