---
layout: post
title: 지역변수의 데이터 유지에 관하여 - 스택과 힙
author: infoqoch
# last_modified_at: 2021-11-27 09:40:46
categories: [java]
tags: [java]
---

## 값을 대입하지 않는데 값이 변한다?
자바를 학습하면서 계속하여 해소되지 않은 문제가 있었다. 지역변수의 데이터 유지와 관련한 문제였다. 그러니까 리턴이 없는 void 매서드의 매개변수로 들어가는데, 그 매서드에서 어떤식으로 데이터를 조작하든 값이 변하지 않는 경우가 있고, 또 그렇지 않은 경우가 있다. 해소되지 않은 문제에 대하여 이번에 아래와 같이 테스트코드로 정리를 해봤다. 결과적으로 원시 타입, wrapper class, String 은 변하지 않았고, 객체와 컬랙션은 변했다.

```java
public class LocalVariableTest {

    @Test
    void test_object() {
        Tester tester = new Tester();
        tester.setName("홍길동");
        innerMethod_object(tester);
        System.out.println(tester.getName());
        System.out.println(tester.getCity());
    }

    private void innerMethod_object(Tester tester) {
        tester.setCity("서울");
    }

    @Test
    private void test_collection_list() {
        List<String> list = new ArrayList<>();
        list.add("outer");
        innerMethod_collection(list);
        list.stream().forEach(System.out::println);
    }

    private void innerMethod_collection(List<String> list) {
        list.add("inner");
    }

    @Test
    @DisplayName("이 테스트만 리턴하지 아니하면 값의 변화가 없음")
    private void test_primitive_wrapper_string() {
        int a = 0;
        innerMethod_primitive(a);
        System.out.println(a);

        Integer A = 0;
        innerMethod_wrapper(A);
        System.out.println(A);

        String str = "hi";
        innerMethod_string(str);
        System.out.println(str);
    }

    private void innerMethod_string(String a) {
        a = "hihi";
    }

    private void innerMethod_wrapper(Integer a) {
        a += 100;
    }

    private void innerMethod_primitive(int a) {
        a += 100;
    }
}

class Tester {
    private String name;
    private String city;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }
}
```

- 위의 문제에 대하여 다음의 영상을 통해 문제를 해소할 수 있었다. 
> https://www.youtube.com/watch?v=-mqL3LJ4iVc&list=PLW2UjW795-f6xWA2_MUhEVgPauhGl3xIp&index=62

## 스택과 힙
- 위의 문제는 JVM의 메모리 영역 중 스택과 힙의 관계를 통해 해결할 수 있다. 스택은 하나의 스레드에서 사용하는 메모리 영역이다. 여기에는 특히 원시변수와 참조변수를 담는다. 힙은 스택 밖에 있는 객체와 컬랙션을 저장하는 공간이며, 참조변수는 이를 가리키는 주소로써의 역할을 한다.
- 스레드는 작업 내용을 아래서부터 위로 쌓는다. 그리고 작업은 가장 위의 것만을 수행한다. 그러니까 `test_primitive_wrapper_string()` 메서드에서 `int a = 0;` 을 저장하더라도 그것이 다른 매서드`innerMethod_primitive(a)`의 매개변수로 들어간 순간, 부모 메서드는 작동을 중지하며 동시에 어떤 참조도 불가능하다. 다른 방식으로 말하면 데이터가 복사되었을 뿐이다. 
- 하지만 참조변수는 다르다. `Tester tester = new Tester();` 의 의미는, `new Tester()` 를 힙 메모리에 저장하고, 그것의 주소를 `tester` 가 가진다는 의미이다. 그러니까 참조변수가 어디에 있든 힙 메모리는 유지가 된다. 그리고 참조변수가 있으면 언제 어디서든 변경하고 그 변경된 데이터를 유지한다. 

## 교훈
- 면접 보기 전에 그렇게 외웠던 스택과 힙이 무슨 차이인지를 명확하게 알 수 있었다. 
- new 라는 것이 어떤 의미를 가지는지 다시금 정리할 수 있었다. 