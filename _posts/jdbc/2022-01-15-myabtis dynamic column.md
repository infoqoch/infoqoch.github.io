---
layout: post
author: infoqoch
title: mybatis 동적으로 컬럼 지정하기
categories: [myabtis]
tags: [myabtis]
---


## 동적으로 칼럼 지정하기
- myabtis에서는 칼럼에 대해서도 동적인 데이타를 지원한다. 아래와 같다. 

```xml
<select id="lookupListBy" resultType="infoqoch.dictionary.core.dict.lookup.LookupResDTO">
    select 1 as priority
            , d.*
    from dictionary d
    where ${lookupBy} = #{target}
</select>
```

- enum을 연계하여 활용 가능하다. 
- myabtis는 대소문자를 구분하지 않기 때문에 칼럼을 대입할 때 case 에 대해서는 신경 쓰지 않아도 된다. 

```java
public enum LookupBy {
    DEFINITION, WORD, SENTENCE, ALL
}
```