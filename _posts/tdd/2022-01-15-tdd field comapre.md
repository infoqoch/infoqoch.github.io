---
layout: post
author: infoqoch
title: junit5 필드 값으로 객체 비교하기 (동등성 비교)
categories: [tdd]
tags: [java, junit]
---

## 들어가며
- 객체를 비교할 때 동등성, 동일성으로 비교 가능하다. 
- 동일성은 동일한 주소를 가리키냐의 문제이며 동등성은 내부 데이터의 값이 동일함을 의미한다.
- junit에서 동등성을 위한 비교 기능을 제공하지만, 동등성 비교는 기본적으로 동일한 클래스의 인스턴스에 대하여 잘 작동한다. 
- 하지만 위의 방식이 동작하지 않는 경우가 두 가지 정도 있어 보인다. 
  - 첫 번째는 regDt 등 몇 개의 필드가 어떤 동작 이후 변경되거나
  - 두 번째는 아예 인스턴스의 protoType이 바뀔 때이다.
- 이러한 상황에서 사용하는 junit 메서드가 `usingRecursiveComparison().ignoringFields()` 이다.


## 코드
- 아래의 코드는 db에 입력한 데이타와 그것의 출력 데이터를 비교하는 코드이다. 
- 대체로 입력과 출력의 클래스는 다르기 때문에 아래와 같이 유연한 방식의 비교를 해야할 것이다. 
- 아래의 예제에서 제외하는것은 regDt와 modDt이다. 이 두 가지를 제외하면 동일한 필드값을 가지고 있다. 

```java
@Test
void 검색(){
        // given
        final String target = UUID.randomUUID().toString();
        final long userNo = (long) (Math.random()*Integer.MAX_VALUE);
        final DictionaryInsertReqDTO insertDTO = DictionaryInsertReqDTO
                .builder()
                .word(target)
                .pronunciation("에:프오얼")
                .partOfSpeech("NOUN")
                .reference("ESL")
                .definition("사과")
                .sentence("I bought an apple")
                .userNo(userNo)
                .build();
        dictionaryMapper.add(insertDTO);

        // when
        final LookupReqDTO reqDTO = LookupReqDTO
                .builder()
                .lookupBy(LookupBy.WORD)
                .target(target)
                .isPaging(false)
                .isLookupAllUsers(false)
                .userNo(userNo)
                .build();

        final List<LookupResDTO> resultList = lookupMapper.lookupListBy(reqDTO);

        // then
        assertThat(resultList).size().isEqualTo(1);
        assertThat(resultList.get(0)).usingRecursiveComparison().ignoringFields("regDt", "modDt").isEqualTo(insertDTO);
}

```

## 참고
- junit의 경우 메서드 명에서 어떤 기능일지 상상할 수 있도록 잘 만들어졌다. 나도 메서드명을 이렇게 멋지게 만들고 싶다. 
- junit의 작명이 좋아서, 대충...🙄 맞아보이는 메서드를 찾고, 아래의 예제를 따라하면 대충...😏 된다.

> https://javadoc.io/doc/org.assertj/assertj-core/latest/org/assertj/core/api/AbstractObjectAssert.html#usingComparatorForFields(java.util.Comparator,java.lang.String...)