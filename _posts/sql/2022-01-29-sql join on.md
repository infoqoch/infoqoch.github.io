---
layout: post
author: infoqoch
title: sql, join 할 때 비교를 잘 하기 위하여
categories: [sql]
tags: [sql, mysql]
---


## join 과 데이터의 뻥튀기
- sql이 데이터를 비교할 때 그것이 일치하는 최대의 값을 추출한다. 
- 아래의 예시를 살펴보자. 
- 아래의 코드는 과일 상품과 고객의 주문 테이블 두 개가 있다. 과일은 상품고유번호(goods_id)와 농장고유번호(farm_id)로 이뤄지고, 주문은 주문고유번호(order_id)가 추가된다.
- 쿼리는 주문을 기준으로 과일 테이블에 해당 데이터가 있는지를 추출하고자 한다. 

```sql
CREATE TABLE fruit (
	idx INT PRIMARY KEY AUTO_INCREMENT,
	goods_id INT,
	farm_id INT
);
		
CREATE TABLE ORDERS (
	idx INT PRIMARY KEY AUTO_INCREMENT,
	order_id INT,
	goods_id INT,
	farm_id INT
);

INSERT INTO fruit (goods_id, farm_id) VALUES 
(1,2),
(1,3),
(2,2);

INSERT INTO orders (order_id, goods_id, farm_id) VALUES
(1,1,2),
(2,2,2);

SELECT 
	O.order_id
	, O.goods_id
	, O.farm_id
	, if(f.goods_id IS NOT NULL, 'T','F') isExist
FROM ORDERS O
JOIN FRUIT F
ON F.GOODS_ID = O.GOODS_ID;
```

- 만약 위의 select 문으로 할 경우 결괏값은 아래와 같다.

|order_id|goods_id|farm_id|isExist|
|---|---|---|---|
|1|1|2|T|
|1|1|2|T|
|2|2|2|T|

- 결괏값의 경우 동일한 데이터(order_id 가 1)가 두 번 반복된다.
- 사실 이 이유는 당연하다. 왜냐하면 where절에서 goods_id 로만 비교하기 때문이다. 만약 fruit 에 goods_id가 1인 값이 두 개가 더 있으면 동일한 데이터가 여러번 반복된다.
- 이를 distinct 나 group by로 해소할 수 있다. 하지만 그보다는 더 정확한 방법으로 비교하는 것이 맞다. 그것은 아래와 같다.

```sql
SELECT 
	O.order_id
	, O.goods_id
	, O.farm_id
	, if(f.goods_id IS NOT NULL, 'Y','F') isExist
FROM ORDERS O
JOIN FRUIT F
ON F.GOODS_ID = O.GOODS_ID AND F.farm_id = O.FARM_ID ;
```

- 비교할 때 최대한 비교할 수 있는 값에 대하여 촘촘하게 비교해야함을 배울 수 있었다. 
- 아래의 문제는, 이러한 비교의 엄격함을 지키지 못해서 쉽게 풀지 못한 문제이다.


## 두 번째로 판매한 상품이, 선호하는 상품인가?
- https://leetcode.com/problems/market-analysis-ii/

### 요구사항
- orders 에는 seller_id 가 있다. 그가 상품을 판매하였다. 해당 셀러는 users 에 데이터를 가지고 있으며, 자신이 선호하는 브랜드 아이템이 있다. 셀러가 판매한 상품 중 두 번째로 판매한 것이, 셀러가 선호하는 브랜드인지를 판별한다. 

```text
Input: 
Users table:
+---------+------------+----------------+
| user_id | join_date  | favorite_brand |
+---------+------------+----------------+
| 1       | 2019-01-01 | Lenovo         |
| 2       | 2019-02-09 | Samsung        |
| 3       | 2019-01-19 | LG             |
| 4       | 2019-05-21 | HP             |
+---------+------------+----------------+
Orders table:
+----------+------------+---------+----------+-----------+
| order_id | order_date | item_id | buyer_id | seller_id |
+----------+------------+---------+----------+-----------+
| 1        | 2019-08-01 | 4       | 1        | 2         |
| 2        | 2019-08-02 | 2       | 1        | 3         |
| 3        | 2019-08-03 | 3       | 2        | 3         |
| 4        | 2019-08-04 | 1       | 4        | 2         |
| 5        | 2019-08-04 | 1       | 3        | 4         |
| 6        | 2019-08-05 | 2       | 2        | 4         |
+----------+------------+---------+----------+-----------+
Items table:
+---------+------------+
| item_id | item_brand |
+---------+------------+
| 1       | Samsung    |
| 2       | Lenovo     |
| 3       | LG         |
| 4       | HP         |
+---------+------------+
Output: 
+-----------+--------------------+
| seller_id | 2nd_item_fav_brand |
+-----------+--------------------+
| 1         | no                 |
| 2         | yes                |
| 3         | yes                |
| 4         | no                 |
+-----------+--------------------+
Explanation: 
The answer for the user with id 1 is no because they sold nothing.
The answer for the users with id 2 and 3 is yes because the brands of their second sold items are their favorite brands.
The answer for the user with id 4 is no because the brand of their second sold item is not their favorite brand.
```

### 해소
- 1) 각 셀러별로 선호하는 상품을 orders 테이블에서 사용하는 item_id로 정리한다.
- 2) orders 에서 각 셀러 당 두 번째로 판매한 레코드를 찾고, 두 번째 레코드가 없는 경우를 찾는다.
- 1)과 2)를 비교하여, 두 번째로 판매한 상품이 선호하는 상품인지를 판별한다.

```sql
-- 선호하는 상품을 정리한다
# with fav as(
#     select 
#         u.user_id
#         , i.item_id
#     from users u
#     join items i
#     on u.favorite_brand = i.item_brand
# )
# select *
# from orders o
# join fav f
# on o.seller_id = f.user_id

-- 두 번째 판매 상품이 무엇인지 확인한다. 
# with 2ndOrd as(
#     select 
#         seller_id
#         , item_id
#     from (
#         select 
#             seller_id
#             , item_id
#             , row_number() over (partition by seller_id order by order_date asc) ranks
#         from orders 
#     )tb
#     where ranks = 2
# )
# select * from 2ndOrd


# with fav as(
#     select 
#         u.user_id
#         , i.item_id
#     from users u
#     join items i
#     on u.favorite_brand = i.item_brand
# )
# , 2ndOrd as(
#     select 
#         seller_id
#         , item_id
#     from (
#         select 
#             seller_id
#             , item_id
#             , row_number() over (partition by seller_id order by order_date asc) ranks
#         from orders 
#     )tb
#     where ranks = 2
# )
# select
#     f.user_id seller_id
#     , case 
#         when f.item_id = s.item_id then 'yes'
#         else 'no'
#       end '2nd_item_fav_brand'
# from fav f
# left join 2ndOrd s
# on f.user_id = s.seller_id
```

- 위의 쿼리를 한 결과 실패했다.
- 실패한 이유는 fav 테이블과 2ndOrd 에서 같은 user_id 임에도 중복되는 값이 발생했기 때문이다. 그리고 주문 상품과 선호상품의 일치 여부가 yes와 no를 각 각 가졌다. 그렇기 때문에 distinct 로 해소할 수 없었다.
- 사실 위의 문제는 선호하는 상품이 한 명의 셀러에게 여러 개일 수 있다는 가정을 하지 못한채 짰기 때문이다. 
- 그래서 아래와 같이 쿼리를 생성하고, 테스트에 성공할 수 있었다. 

```sql
-- 1) 유일함을 보장하는 것 : 두 번째로 판매한 상품, 두 번째로 판매한 상품이 없는 사람
-- 2) 유일함을 보장하지 않는 것 : 선호 상품

-- 1)과 2)를 어떤 식으로든 join 할 경우 선호 상품을 중복으로 가진 회원이 생길 경우 갯수가 늘어남. 

-- 모든 유저를 두 번째를 판매한 유저와 하지 아니한 유저를 분류한다.
-- 판매한 유저의 경우 판매한 상품과 선호상품의 일치여부를 비교한다. 

with fav as(
    select 
        u.user_id
        , i.item_id
    from users u
    join items i
    on u.favorite_brand = i.item_brand
)
, 2ndOrd as(
    select 
        seller_id
        , item_id
    from (
        select 
            seller_id
            , item_id
            , row_number() over (partition by seller_id order by order_date asc) ranks
        from orders 
    )tb
    where ranks = 2
)
select 
    u.user_id seller_id
    , case when tb.isExist is not null then 'yes'
        else 'no'
        end '2nd_item_fav_brand'
from users u
left join (
    select 
        user_id
        , 'yes' isExist
    from 2ndOrd s
    join fav f
    on s.seller_id = f.user_id and s.item_id = f.item_id
) tb
on u.user_id = tb.user_id
```

- `on s.seller_id = f.user_id and s.item_id = f.item_id` 의 코드를 통해 문제를 해소할 수 있었다.