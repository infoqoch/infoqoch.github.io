---
layout: post
author: infoqoch
title: myabtis 하나의 메서드에 여러 개의 쿼리 작성하기 (MultiQueries)
categories: [mybatis]
tags: [mybatis]
---

## 쿼리를 여러 개 작성해야 하는 순간은 언제일까? 

### 하나의 insert 쿼리, 참조하는 값은 select로
- insert를 할 때 이전의 값을 select 해서 참조하는 경우가 있다. 이 경우 한 줄의 쿼리로 가능하다. 

```sql
insert test_table(no, id, age)
values((select max(no) + 1 from test_table), 'kim', 23);
```

- 위의 경우보다 좀 더 복잡한 조건에서 myabits를 조작하는 방법을 정리한다. 

### 여러 개의 insert를 하는 경우
- insert가 여러 개인 경우가 있다. 이련 경우는 보통 fk로 연결 되어 다른 테이블 간 의존하는 경우이다. 그런 경우 아래와 같이 한다. 
- dictionary 와 source 는 1:1의 관계를 가지고 있으며 dictionary.no 와 source_dictionary_no 와 연결되어 있다.

```xml
<insert id="addList" parameterType="java.util.List">
    <foreach item="item" collection="list">
        insert into DICTIONARY(word, pronunciation, part_of_speech, reference, definition, sentence, user_no, source_no)
        values
        (#{item.word}, #{item.pronunciation}, #{item.partOfSpeech}, #{item.reference}, #{item.definition}, #{item.sentence}, #{item.userNo}, #{item.sourceNo}) ;

        insert into source (dictionary_no, type, idx_on_sheet, idx_of_sheet, name_of_sheet)
        values ((select max(no) from dictionary), #{item.type}, #{item.idxOnSheet}, #{item.idxOfSheet}, #{item.nameOfSheet}) ;
    </foreach>
</insert>
```

- 보통 myabtis는 세미콜론을 생략하나 이 경우 쿼리가 끝나면 세미콜론을 붙인다. 
- 그리고 myabtis url의 파라미터를 아래와 같이 추가해야 한다. 
- `allowMultiQueries=true`