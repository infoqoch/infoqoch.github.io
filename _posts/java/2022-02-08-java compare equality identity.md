---
layout: post
author: infoqoch
title: java equals와 hashcode, HashSet과 HashMap의 key 중복 판단 방식
categories: [java]
tags: [java]
---

## 동등성과 동일성은?
- 자바에서의 동일성이란 완전하게 같음을 의미한다. 완전하게 같음의 의미는 참조변수의 경우 가리키는 메모리의 위치가 동일함을 의미한다.
- 동등성은 동일성보다 넓은 개념이다. 메모리의 위치가 같지 않더라도 값이 동일할 경우 동등하다고 본다.
- 자바는 기본타입의 경우 참조변수가 아닌 값만을 가지고 있기 때문에 동등성 비교와 동일성 비교가 차이를 가지지 않는다. 연산자 역시 `==`을 사용한다.
- String 도 마찬가지이다. String의 경우 같은 문자열은 같은 메모리 공간에 할당된다. 
- 객체는 그렇지 않다. Object 역시 `==` 연산자를 사용하며, 이는 동일성 비교이다. Object는 매서드로 equals 를 가지고 있으며, 기본 값은 ==과 같은 동일성 비교다. 하지만 이것을 override 하여 동등성 비교로 변경할 수 있다. 

## SET은 중복을 허용하지 않는다고 했는데...
- SET은 중복 허용을 하지 않는 컬렉션이다. 그러므로 쓸모가 많다.
- 그런데 SET이 허용하지 않는 중복이란 무엇을 의미하는가? 동등성인가? 아니면 동일성인가?
- 동등성과 동일성, 그리고 SET의 중복제거와 관련하여 아래의 코드로 정리하였다.
- equals의 오버라이딩은 인텔리제이가 만들어준 내용 그대로 만들었다. 해당 오버라이딩은 언제나 IDE의 힘을 빌려야 한다고 한다. 

```java
import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Objects;
import java.util.Set;

public class CompareTest {
    @Test
    void test(){
        Sample sample1 = new Sample();
        Sample sample2 = sample1;
        System.out.println("(sample1==sample2) = " + (sample1==sample2));
        System.out.println("(sample1 equals sample2) = " + (sample1.equals(sample2)));
        Assertions.assertThat(sample1).isEqualTo(sample2);

        Sample sampleA = new Sample();
        sampleA.name = "kim";
        Sample sampleB = new Sample();
        sampleB.name = "kim";

        System.out.println("(sampleA==sampleB) = " + (sampleA==sampleB));
        System.out.println("(sampleA equals sampleB) = " + (sampleA.equals(sampleB))); // false
        Assertions.assertThat(sampleA).isNotEqualTo(sampleB);

        Set<Sample> set1 = new HashSet<>();
        set1.add(sample1);
        set1.add(sample2);
        set1.add(sampleA);
        set1.add(sampleB);

        System.out.println("set1.size() = " + set1.size()); // 3
        Assertions.assertThat(set1).size().isEqualTo(3);
    }

    @Test
    void test2(){
        SampleEquality sample1 = new SampleEquality();
        SampleEquality sample2 = sample1;
        System.out.println("(sample1==sample2) = " + (sample1==sample2));
        System.out.println("(sample1 equals sample2) = " + (sample1.equals(sample2)));
        Assertions.assertThat(sample1).isEqualTo(sample2);

        SampleEquality sampleA = new SampleEquality();
        sampleA.name = "kim";
        SampleEquality sampleB = new SampleEquality();
        sampleB.name = "kim";
        Assertions.assertThat(sampleA).isEqualTo(sampleB);

        System.out.println("(sampleA==sampleB) = " + (sampleA==sampleB));
        System.out.println("(sampleA equals sampleB) = " + (sampleA.equals(sampleB))); // true

        Set<SampleEquality> set1 = new HashSet<>();
        set1.add(sample1);
        set1.add(sample2);
        set1.add(sampleA);
        set1.add(sampleB);

        System.out.println("set1.size() = " + set1.size()); // 2 
        Assertions.assertThat(set1).size().isEqualTo(2);
    }

    static class SampleEquality{
        private String name;

        @Override
        public boolean equals(Object o) { // 인텔리제이 IDE의 힘을 빌렸다. 
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            SampleEquality that = (SampleEquality) o;
            return Objects.equals(name, that.name);
        }

        @Override
        public int hashCode() { // 인텔리제이 IDE의 힘을 빌렸다. 
            return Objects.hash(name);
        }
    }

    static class Sample{
        private String name;
    }
}
```

## 결론
- SET은 equals 의 정의한 바에 따라 동등성 혹은 동일성 비교를 통해 중복 값을 제거한다. 
