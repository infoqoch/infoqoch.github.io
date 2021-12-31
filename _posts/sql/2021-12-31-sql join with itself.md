---
layout: post
author: infoqoch
title: sql 테이블 자기 자신과 조인하기
categories: [sql]
tags: [sql, mysql]
---

## 테이블 자기 자신과 조인?
- 어쩌다가 leetcode에서 sql 코딩 테스트를 하였다. 이 때 나는 자기 자신과 조인하는 것을 처음(?)으로 해봤다. 대체로 직장에서 쿼리를 짤 때는 다른 테이블과 비교하지 자기 자신과 비교할 일은 크게 없었기 때문이다.
- 테이블 자신과 조인하는 과정이 나에게는 일종의 쇼크였고, 그러나 이러한 방식을 통해 새로운 시야를 얻을 수 있기 때문에, 그 내용을 아래에 정리코자 한다. 

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
- 테이블을 두 개를 join 하는데, 조인의 대상으로는 날짜이며, 첫 번째 테이블과 두 번째 테이블의 날짜 하나의 차이를 비교하여 조인한다.

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
- 이 때 사용한 기능 중 하나는 mysql user variable 인데, 각 가상 테이블의 레코드마다 auto-increment 의 효과를 만들었다. 
- `CAST(@num3:=@num3+1 AS signed integer)as id ` 의 의미는 실수를 정수로 바꿔주는 효과를 가진다. 

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
- 마지막 레코드의 경우 홀수이고 그대로 쿼리를 진행하면 짝수가 되어 중간에 숫자가 빌 수 있기 때문에 이 부분도 처리해준다. 
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
- 테이블을 하나 만드는데, 칼럼을 두 개 추가한다. 첫 번째는 자기 자신 앞의 유니크 키와 자신의 숫자가 같은지를 확인하고, 두 번째 칼럼은 자기 자신보다 두 개 앞의 유니크 키와 자신의 숫자가 같은지를 확인한다. 두 칼럼이 동일하다고 하는 값을 추출한다.

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

- 위의 방법은 끔찍하게 느렸다. 테이블을 하나 만들고 그것의 값을 비교까지 하니까 그런 것 같다. 
- 아래의 방법은 best practice 이며 매우 직관적이다.

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
- (사실) 이 문제는 못풀었다. 
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

## 나아가며
- 기본적으로 나는 join을 위주로 사용한다. 이렇게 사용하는 이유는 일단 테이블을 하나 만들고 테이블 간 비교를 하는 것이 더 직관적이기 때문이다. 그러나 위의 best practice를 보면 대체로 join 보다 where를 사용한다. 경우에 따라 join과 where 중 빠른 것이 다르다. 대체로 각 레코드마다 조작을 하는 경우 join 으로 새로운 테이블을 만드는 것이 더 빠르다. 각 레코드를 조작할 필요가 없이 특정 값으로 제외하는 방향을 선택한다면 where 문이 더 빠른 것 같다. 
- 릿코드에서 solution 이 없는 경우 문제가 이상한 경우가 있다. 그러므로 solution 이 있는 문제를 풀자! 
- 릿코드의 문제 대부분은 유로다ㅠ.  