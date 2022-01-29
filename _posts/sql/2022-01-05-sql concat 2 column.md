---
layout: post
author: infoqoch
title: mysql 칼럼 두 개를 합쳐서 where 를 사용하기
categories: [sql]
tags: [sql, mysql]
---

## 들어가며
- 칼럼이 address 와 address_detail 이 있다. 그리고 주소를 검색하는 기능을 마련한다. 이 경우 address 와 address_detail 두 개에 대한 검색 기능을 넣는 것은 어색하다. 
- '홍은동'으로 검색하거나 '현대아파트'로 검색할 경우 `address like #{adress} or address_detail #{addressDetail}` 로 검색하면 잘 나오겠지만 '홍은동 현대아파트'라고 검색하면 위의 방법으로는 동작하지 않는다. 하나의 문자열을 address 와 address detail 을 어떤 기준으로 나눌지 판단하기 어렵다. 그렇다고 클라이언트에게 adress 와 adress detail 을 분리해서 입력하라는 요청도 좋아 보이지 않는다.   
- 이를 해소하는 방법은 아래와 같다.

## 쿼리
- concat으로 해결한다.
- 두 칼럼 사이에 스페이스 하나를 뒀다. 필요에 따라 다른 값을 넣을 수 있다. 

```sql
SELECT *
FROM STUDENT
WHERE CONCAT(ADDRESS,' ', ADDRESS_DETAIL) LIKE '%홍은동 현대아파트%';
```
  
