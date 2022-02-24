---
layout: post
author: infoqoch
title: 이펙티브자바, 불필요한 객체 생성은 피하라
categories: [java]
tags: [java, effective]
---

## 박싱타입과 기본타입의 성능 문제
- 대체로 객체를 생성하는 것은 좋다. 기본타입에서도 마찬가지인데 null을 사용할 수 있는 등 객체로서 동작한다.
- 하지만 기본타입을 객체로 박싱하기 때문에 이로 인한 성능 상 문제가 있다. 
- 아래의 코드는 전자가 후자보다 약 5배 느리다. 

```java
public class C06Test {
    @Test
    void test(){
        wrapper();
        primi();
        wrapper();
        primi();
    }

    private void wrapper() {
        final long startTime = System.currentTimeMillis();
        final int size = Integer.MAX_VALUE;
        Long sum1 = 0l; // 박싱 타입이다. 
        for(int i = 0; i< size; i++){
            sum1 += Integer.MAX_VALUE*i;
        }
        final long endTime = System.currentTimeMillis() - startTime;
        System.out.println("endTime with obj =" + endTime);
    }

    private void primi() {
        final long startTime = System.currentTimeMillis();
        final int size = Integer.MAX_VALUE;
        long sum1 = 0l; // 기본 타입이다.
        for(int i = 0; i< size; i++){
            sum1 += Integer.MAX_VALUE*i;
        }
        final long endTime = System.currentTimeMillis() - startTime;
        System.out.println("endTime with primitive type =" + endTime);
    }
}
```

## 객체가 아닌 정적 매서드도 효과적이다.

- 아래의 코드는 ObjectMapper를 하나를 만들어 사용하는 것과, 사용할 때마다 객체를 생성하는 코드이다.
- 속도 차이는 약 6 배 정도 발생했다. 

```java
@Test
void test3() throws JsonProcessingException {
    // given
    List<Member> members = new ArrayList<>();
    for (int i = 0; i < 1000; i++) {
        members.add(new Member());
    }

    // test1
    final long startTime = System.currentTimeMillis();
    for(int i=0; i<1000; i++){
        parseJson(members);
    }
    final long endTime = System.currentTimeMillis() - startTime;
    System.out.println("endTime, generate instance each time =" + endTime);

    // test2
    final long startTime2 = System.currentTimeMillis();
    for(int i=0; i<1000; i++) {
        parseJsonReusable(members);
    }
    final long endTime2 = System.currentTimeMillis() - startTime2;
    System.out.println("endTime, reusable static util = " + endTime2);

}

String parseJson(List<Member> members) throws JsonProcessingException {
    final ObjectMapper objectMapper = new ObjectMapper();
    final String result = objectMapper.writeValueAsString(members);
    return result;
}
static final ObjectMapper objectMapper = new ObjectMapper();

String parseJsonReusable(List<Member> members) throws JsonProcessingException {
    final String result = objectMapper.writeValueAsString(members);
    return result;
}

@Data
static class Member {
    private String name;
    private int age;

    public Member() {
        name = UUID.randomUUID().toString();
        age = (int) (Math.random() * Integer.MAX_VALUE);
    }
}

```

## 다만, 보조적으로 사용한다.
- 현재 JVM의 성능의 매우 좋다. 현 시점에서 객체를 반복 생성하여 얻는 손해보다, 객체를 재사용하다가 발생한 문제가 더 심각하다. 그러므로 객체의 반복사용은 고민해야 한다.
- 다만 위의 예제의 경우 static final로서 유일함을 보장하고, 유틸로서의 기능을 하는 경우 사용하기에 좋다. 