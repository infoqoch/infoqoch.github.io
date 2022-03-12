---
layout: post
author: infoqoch
title: 이펙티브자바, 35-38. 열거 타입 사용에서의 팁들, ordinal(), EnumSet, EnumMap
categories: [java]
tags: [java, effective]
---

## 35. ordinal 메서드 대신 인스턴스 필드를 사용하라
- enum은 ordinal()을 제공하며, 이것은 각각의 상수를 숫자로 관리하는 기능이다.
- 이 기능은 상수의 변화에 따라 가변적이기 때문에 사용해서는 안된다. 
- 만약 정수를 사용하고 싶다면 ordinal()이 아닌 필드를 사용해야 한다.

```java
public enum OrdinalEnum {
    // APPLE, CARROT;
    GRAPH, APPLE, CARROT;

    public static void main(String[] args) {
        System.out.println("OrdinalEnum.APPLE.ordinal() = " + OrdinalEnum.APPLE.ordinal()); // 0 -> 1
    }
}
```

- APPLE, CARROT 만 있었을 때 아래의 값은 0이었다.
- GRAPH가 추가되면 아래의 값은 1이 된다. 

```java
public enum OrdinalField {
    APPLE(1), CARROT(2);

    private final int intType;

    OrdinalField(int intType) {
        this.intType = intType;
    }

    int intType(){
        return intType;
    }

    public static void main(String[] args) {
        System.out.println("OrdinalField.APPLE.intType(); = " + OrdinalField.APPLE.intType());
    }
}
```

- 위의 방식을 할 경우 항상 필드값을 가져오기 때문에 상수의 변화와 관계 없이 1을 리턴한다. 
- 실제로 ordinal()은 열거타입을 위한 자료구조를 위한 메서드이며, 개발자는 사용할 일이 없다. 

## 36. 비트 필드 대신 EnumSet을 사용하라
- 상수를 집합으로 사용할 때, 이전에는 2의 거듭제곱을 할당한 방식을 사용했다.
- 비트로 할 필요가 없이 EnumSet으로 처리한다.

```java
public class Text {
    public enum Style {BOLD, ITALIC, UNDERLINE, STRIKETHROUGH}

    public void applyStyles(Set<Style> styles) {
        for (Style style : styles) {
            System.out.printf("적용할 스타일은 %s 입니다.\n", style.toString());
        }
    }

    public static void main(String[] args) {
        Text text = new Text();
        text.applyStyles(EnumSet.of(Style.BOLD, Style.UNDERLINE));
    }
}
```

## 37. ordinal 인덱싱 대신 EnumMap을 사용하라
- 아래는 Plant 클래스이며, 각 식물의 생애주기(LifeCycle)을 enum으로 표현한다.
- Plant의 속성으로 생애주기를 보고 싶지만, 생애주기를 기준으로 Plant를 분류하고 싶을 수 있다.
- 이런 경우 아래의 테스트와 같이 EnumMap을 사용한다. 

```java
class Plant {
    enum LifeCycle { ANNUAL, PERENNIAL, BIENNIAL }

    final String name;
    final LifeCycle lifeCycle;

    Plant(String name, LifeCycle lifeCycle) {
        this.name = name;
        this.lifeCycle = lifeCycle;
    }

    @Override public String toString() {
        return name;
    }
}
```

```java
@Test
void test1()
    Plant[] garden = {
            new Plant("바질",    LifeCycle.ANNUAL),
            new Plant("캐러웨이", LifeCycle.BIENNIAL),
            new Plant("딜",      LifeCycle.ANNUAL),
            new Plant("라벤더",   LifeCycle.PERENNIAL),
            new Plant("파슬리",   LifeCycle.BIENNIAL),
            new Plant("로즈마리", LifeCycle.PERENNIAL)
    };

    final EnumMap<LifeCycle, Set<Plant>> plantsByLifeCycle = new EnumMap<>(LifeCycle.class);

    // EnumMap 을 초기화 한다.
    for(Plant.LifeCycle lc : Plant.LifeCycle.values()){
        plantsByLifeCycle.put(lc, new HashSet<>());
    }

    // 각 Plant 객체를 삽입한다.
    for(Plant p : garden){
        plantsByLifeCycle.get(p.lifeCycle).add(p);
    }

    for (LifeCycle lifeCycle : plantsByLifeCycle.keySet()) {
        System.out.println("lifeCycle = " + lifeCycle);
        System.out.println("plantsByLifeCycle.get(lifeCycle) = " + plantsByLifeCycle.get(lifeCycle));
        System.out.println();
    }
}
```

- 위의 방식이 아닌 Stream을 활용할 수 있으며 예제는 아래와 같다.
- 전자는 단순한 HashMap이며 후자는 EnumMap을 사용한다. 
- 위의 방식와 스트림의 방식은 동작이 다소 다르다. 전자는 모든 이넘이 키로 있다면 후자는 값이 없는 이넘에 대해서 키가 존재하지 않는다. 


```java
final Map<LifeCycle, List<Plant>> plantsByLifeCycle1 = Arrays.stream(garden)
        .collect(groupingBy(p -> p.lifeCycle));

final EnumMap<LifeCycle, Set<Plant>> plantsByLifeCycle2 = Arrays.stream(garden)
        .collect(groupingBy(
                p -> p.lifeCycle
                , () -> new EnumMap<>(LifeCycle.class)
                , toSet()));
```
