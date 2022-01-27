---
layout: post
author: infoqoch
title: sql 테이블 자기 자신과 조인하기
categories: [sql]
tags: [sql, mysql]
---

## 테이블 자기 자신과 조인?
- leetcode에서 sql 코딩 테스트를 하였다. 보통 업무를 할 때 나는 테이블 간 join을 하였다. 테이블이 자기 자신과 조인을 하는 경우는 사실 없었다. 하지만 리트코드의 수많은 문제는 테이블 자신과 join을 하는 경우가 많았다. 이러한 과정이 나에게는 놀라웠고, 쿼리를 짜는 방법에 있어서 새로운 시야를 얻을 수 있었다. 그 내용을 정리코자 한다. 

## 어제보다 더운 날은?
### 요구사항
- https://leetcode.com/problems/rising-temperature
  
```text
Input: 
Weather table:
+----+------------+-------------+
| id | recordDate | temperature |
+----+------------+-------------+
| 1  | 2015-01-01 | 10          |
| 2  | 2015-01-02 | 25          |
| 3  | 2015-01-03 | 20          |
| 4  | 2015-01-04 | 30          |
+----+------------+-------------+
Output: 
+----+
| id |
+----+
| 2  |
| 4  |
+----+
Explanation: 
In 2015-01-02, the temperature was higher than the previous day (10 -> 25).
In 2015-01-04, the temperature was higher than the previous day (20 -> 30).
```

### 해소
- Weather 테이블 두 개를 join 하며, 조인의 기준은 날짜로 한다. 첫 번째 테이블과 두 번째 테이블의 날짜를 한 레코드씩 어긋나게 조인하여, 온도를 뺀다. 

```sql
select w2.id
from weather w1
join weather w2
on date_add(w1.recordDate, interval +1 day) = w2.recordDate
where w1.temperature < w2.temperature;
```

## 짝수와 홀수 순서 바꾸기
- https://leetcode.com/problems/exchange-seats/

### 요구사항

```text
Input: 
Seat table:
+----+---------+
| id | student |
+----+---------+
| 1  | Abbot   |
| 2  | Doris   |
| 3  | Emerson |
| 4  | Green   |
| 5  | Jeames  |
+----+---------+
Output: 
+----+---------+
| id | student |
+----+---------+
| 1  | Doris   |
| 2  | Abbot   |
| 3  | Green   |
| 4  | Emerson |
| 5  | Jeames  |
+----+---------+
Explanation: 
Note that if the number of students is odd, there is no need to change the last one's seat.
```

### 해소
- 짝수를 가진 사람과 홀수를 가진 사람으로 테이블을 분리했다. 그리고 그것을 합치는 방식으로 해소했다. 
- 이 때 사용한 기능 중 하나는 mysql user variable(@var) 인데, 각 가상 테이블의 레코드마다 auto-increment 의 효과를 만들었다. 
- `CAST(@num3:=@num3+1 AS signed integer)as id ` 는 실수를 정수로 바꾼다. 

```sql
select
 CAST(@num3:=@num3+1 AS signed integer)as id
    ,student
from (
    (
    select
        @num:=@num+1 as num
        , s.id
        , s.student
    from
        (select @num:=0) a,
        seat s
    where 
        mod(s.id, 2)=0
    )
     union
    (select
        @num2:=@num2+1 as num
        ,s.id
        ,s.student
    from
        (select @num2:=0) a,
        seat s
    where 
        mod(s.id, 2)=1
     )
    order by num asc, id desc
)tb
, (select @num3:=0) c;
```

- 아래는 best practice 이다. 확실히 아래가 더 직관적이다. 각 레코드마다 홀수, 짝수를 비교 `mod()` 하고 그것이 홀수이면 +1 짝수면 -1을 하는 형태로 하였다. 
- `when id = counts then id` 는 총 갯수가 홀수이고 마지막 레코드의 경우 변경하지 않는 경우를 고려한 조건이다. 
- 그런데 속도는 위의 쿼리가 더 빨랐다. 그러나 더 직관적인 쿼리는 아무래도 아래의 것이라 생각한다. 

```sql
select
    (case 
        when mod(id, 2) = 0 then id - 1
        when id = counts then id
        when mod(id, 2) = 1 then id + 1
    end) as id
    , student
from 
    seat,
    (select 
        count(*) as counts
    from 
        seat) as seat_counts
order by id asc 
```

## 두 번째로 큰 값은?
- https://leetcode.com/problems/second-highest-salary/

### 요구사항

```text
Input: 
Employee table:
+----+--------+
| id | salary |
+----+--------+
| 1  | 100    |
| 2  | 200    |
| 3  | 300    |
+----+--------+
Output: 
+---------------------+
| SecondHighestSalary |
+---------------------+
| 200                 |
+---------------------+
```

### 해소

```sql
select 
    max(salary) SecondHighestSalary 
from employee 
where salary not in 
(select max(salary)
from employee)
```

## 세 번 같은 값이 연속된 데이터는?
- https://leetcode.com/problems/consecutive-numbers/

### 요구사항

```text
Input: 
Logs table:
+----+-----+
| id | num |
+----+-----+
| 1  | 1   |
| 2  | 1   |
| 3  | 1   |
| 4  | 2   |
| 5  | 1   |
| 6  | 2   |
| 7  | 2   |
+----+-----+
Output: 
+-----------------+
| ConsecutiveNums |
+-----------------+
| 1               |
+-----------------+
Explanation: 1 is the only number that appears consecutively for at least three times.
```

### 해소
- 기존의 테이블에 칼럼을 두 개 추가한다. 첫 번째는 인덱스가 하나 적은 레코드의 숫자를 자신의 숫자와 뺀 값이며, 두 번째는 인덱스가 두 개 적은 레코드의 숫자를 뺀 값이다. 뺀 값이 두 개가 모두 0 이면 동일함을 보장한다. 

```sql
select 
    tb.num ConsecutiveNums 
from (
    select 
        l.id,
        l.num,
        (l.num - (select a.num from logs a where a.id = (l.id - 1))) diff1,
        (l.num - (select a.num from logs a where a.id = (l.id - 2))) diff2
    from logs l
    where l.id > 1
    ) tb
where tb.diff1 = 0 and tb.diff2 = 0
group by tb.num
```

- 위의 방법은 끔찍하게 느렸다. 아래의 방법은 best practice 이며 매우 직관적이다.

```sql
select 
    l.id,
    l.num,
    (l.num - (select a.num from logs a where a.id = (l.id - 1))) diffNum,
    (select a.diffNum from logs a where a.id = (l.id - 1)) beforDiff
from logs l
```

## 각 부서마다 최고의 연봉을 받는 직원의 목록
- https://leetcode.com/problems/department-highest-salary/

### 요구사항

```text
Input: 
Employee table:
+----+-------+--------+--------------+
| id | name  | salary | departmentId |
+----+-------+--------+--------------+
| 1  | Joe   | 70000  | 1            |
| 2  | Jim   | 90000  | 1            |
| 3  | Henry | 80000  | 2            |
| 4  | Sam   | 60000  | 2            |
| 5  | Max   | 90000  | 1            |
+----+-------+--------+--------------+
Department table:
+----+-------+
| id | name  |
+----+-------+
| 1  | IT    |
| 2  | Sales |
+----+-------+
Output: 
+------------+----------+--------+
| Department | Employee | Salary |
+------------+----------+--------+
| IT         | Jim      | 90000  |
| Sales      | Henry    | 80000  |
| IT         | Max      | 90000  |
+------------+----------+--------+
Explanation: Max and Jim both have the highest salary in the IT department and Henry has the highest salary in the Sales department.
```

### 해소
- 연봉(salary)로 비교해야 하기 때문에 먼저 부서 별 max 값을 추출했다. 해당 max 값과 부서의 값이 일치하는 데이터를 join을 통해 추출하였다. 

```sql
select 
    d.name Department ,
    e.name Employee ,
    e.salary Salary 
from 
    employee e
join (
    select 
        max(departmentId) departmentId 
        , max(salary)  salary
    from employee
    group by departmentId
    ) tb
on 
    tb.departmentId  = e.departmentId 
    and e.salary = tb.salary
join 
    department d
on e.departmentId = d.id
```

- 아래는 best practice 이다. 위의 방법과 매우 유사하지만, where 절을 통해 해소했다.
- 나는 where 절의 비교를 괄호를 통해 두 개 동시에 할 수 있다는 것에 매우 놀랐다.

```sql
select 
    d.name Department ,
    e.name Employee ,
    e.salary Salary 
from 
    employee e
join 
    department d
on e.departmentId = d.id
where (e.departmentId , e.salary)
in 
(
    select 
        max(departmentId) departmentId 
        , max(salary)  salary
    from employee
    group by departmentId
    ) 
```

## 부서별 연봉 3위 이상인 직원의 목록
- https://leetcode.com/problems/department-top-three-salaries/

### 요구사항

```text
Input: 
Employee table:
+----+-------+--------+--------------+
| id | name  | salary | departmentId |
+----+-------+--------+--------------+
| 1  | Joe   | 85000  | 1            |
| 2  | Henry | 80000  | 2            |
| 3  | Sam   | 60000  | 2            |
| 4  | Max   | 90000  | 1            |
| 5  | Janet | 69000  | 1            |
| 6  | Randy | 85000  | 1            |
| 7  | Will  | 70000  | 1            |
+----+-------+--------+--------------+
Department table:
+----+-------+
| id | name  |
+----+-------+
| 1  | IT    |
| 2  | Sales |
+----+-------+
Output: 
+------------+----------+--------+
| Department | Employee | Salary |
+------------+----------+--------+
| IT         | Max      | 90000  |
| IT         | Joe      | 85000  |
| IT         | Randy    | 85000  |
| IT         | Will     | 70000  |
| Sales      | Henry    | 80000  |
| Sales      | Sam      | 60000  |
+------------+----------+--------+
Explanation: 
In the IT department:
- Max earns the highest unique salary
- Both Randy and Joe earn the second-highest unique salary
- Will earns the third-highest unique salary

In the Sales department:
- Henry earns the highest salary
- Sam earns the second-highest salary
- There is no third-highest salary as there are only two employees
```

### 해소
- 아래는 best practice 이다. 자기 자신보다 임금이 높은 사람의 횟수를 세고, 그것의 임금을 group by 를 하여, 그 임금의 갯수가 3개 초과하는 경우를 where로 한다. 

```sql


select 
    d.name as Department
    , e1.name as employee
    , e1.salary
from 
    employee e1
join department d
    on d.id = e1.departmentId
where 
    3 > (
    select
        count(distinct e2.salary)
    from employee e2
    where e2.salary > e1.salary
            and e2.departmentId = e1.departmentId
    )
```

## 3번 이상 연속된 숫자 구하기
- https://leetcode.com/problems/human-traffic-of-stadium/

### 요구사항

```text
Input: 
Stadium table:
+------+------------+-----------+
| id   | visit_date | people    |
+------+------------+-----------+
| 1    | 2017-01-01 | 10        |
| 2    | 2017-01-02 | 109       |
| 3    | 2017-01-03 | 150       |
| 4    | 2017-01-04 | 99        |
| 5    | 2017-01-05 | 145       |
| 6    | 2017-01-06 | 1455      |
| 7    | 2017-01-07 | 199       |
| 8    | 2017-01-09 | 188       |
+------+------------+-----------+
Output: 
+------+------------+-----------+
| id   | visit_date | people    |
+------+------------+-----------+
| 5    | 2017-01-05 | 145       |
| 6    | 2017-01-06 | 1455      |
| 7    | 2017-01-07 | 199       |
| 8    | 2017-01-09 | 188       |
+------+------------+-----------+
Explanation: 
The four rows with ids 5, 6, 7, and 8 have consecutive ids and each of them has >= 100 people attended. Note that row 8 was included even though the visit_date was not the next day after row 7.
The rows with ids 2 and 3 are not included because we need at least three consecutive ids.
```

### 해소
- 날짜는 함정으로 id만 봐야 한다.
- 사람의 숫자가 100명을 넘는 id를 추출하고, 아래의 조건을 만족해야 한다. 
  - 연속된 숫자가 앞에 두 개가 있거나
  - 뒤에 두 개가 있거나
  - 앞 뒤로 두 개가
- 정상 작동하고, 다른 쿼리 대비 88퍼센트나 빠르지만, 아 쿼리 자체가 아름답지는 않다. 
- 다른 사람들의 솔루션을 보니까, 대체로 테이블 3개를 만드는 것 까지는 유사하기 때문에 그냥 넘어간다!

```sql
select
    *
from 
    stadium
where 
    id in
    (select 
        *
    from
        (select id from stadium s where people >= 100) tb
    where 
        (select 
            count(1)
        from 
            (select id from stadium s where people >= 100) tb3
         where
            tb3.id in (tb.id - 1,  tb.id + 1)
        ) > 1
        or
        (select 
            count(1)
        from 
            (select id from stadium s where people >= 100) tb1
         where
            tb.id between tb1.id + 1 and tb1.id + 2
        ) > 1
        or
        (select 
            count(1)
        from 
            (select id from stadium s where people >= 100) tb2
         where
            tb2.id between tb.id + 1 and tb.id + 2
        ) > 1
    )
```

## 나아가며
- 테이블 하나를 가지고 다양하게 데이터를 조작하고 원하는 값을 추출할 수 있음을 배울 수 있었다. 
- 보통 나는 join을 사용하였는데 where 문을 통해 더 깔끔하게 쿼리를 뽑아낼 수 있음을 배울 수 있었다. 