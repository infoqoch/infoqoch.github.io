---
layout: post
author: infoqoch
title: 자바 Comparable와 Comparator, Arrays.sort를 활용한 비교 및 정렬
categories: [java]
tags: [java]
---

# 비교를 위하여
- 자바에서는 Comparable 와 Comparator 를 비교를 위한 인터페이스로 제공한다.
- 기본타입의 경우 단순하게 비교가 되지만 객체의 경우 비교하기가 어렵다.

```java
if(10>20) {} // 가능
if(userA > userB){} // 불가능
```

- 객체를 비교할 때 기준을 마련하는 인터페이스가 Comparable 와 Comparator 이다.

# Comparable
- Comparable 은 특히 객체를 구현할 때 사용한다. 
- `int compareTo(Object o);` 메서드를 활용한다.

```java
public class CompareTest {

    static class User implements Comparable<User>{ // Comparable를 구현한다.
        private final String name;
        private final int money;
        private final int level;

        public User(String name, int money, int level) {
            this.name = name;
            this.money = money;
            this.level = level;
        }
        
        @Override
        public int compareTo(User o) {
            return level - o.level; // level로 비교한다.
        }
    }

    @Test
    void comparable_level() {
        // name, money, level
        User highLevel = new User("kim", 10, 20);
        User rich = new User("lee", 30, 10);

        assertThat(rich.compareTo(highLevel)).isLessThan(0);
        assertThat(highLevel.compareTo(rich)).isGreaterThan(0);
    }
}
```

# Comparator
- Comparator는 객체 외부에서 구현한다. 
- 객체 두 개를 비교한다. 

```java
public class CompareTest {
    @Test
    void comparator() {
        Comparator<User> compareWithMoney = (o1, o2)-> o1.money - o2.money;
        Comparator<User> compareWithLevel = (o1, o2)-> o1.level - o2.level;

        // name, money, level
        User highLevel = new User("kim", 10, 20);
        User rich = new User("lee", 30, 10);

        assertThat(compareWithMoney.compare(rich, highLevel)).isGreaterThan(0);
        assertThat(compareWithLevel.compare(rich, highLevel)).isLessThan(0);

        assertThat(compareWithMoney.compare(highLevel, rich)).isLessThan(0);
        assertThat(compareWithLevel.compare(highLevel, rich)).isGreaterThan(0);
    }
}
```

# Arrays.sort
- 비교의 결과는 int로 나온다. Arrays.sort는 int를 기준으로 배열한다.
- 10과 5가 있다. 10 - 5 = 5이므로 양수가 나온다. 이 때 두 개의 값을 바꾼다. 그러므로 Arrays.sort는 기본적으로 오름차순을 지원한다. 
- junit은 배열이 정렬되어있는지를 확인할 수 있는 메서드 `isSorted`, `isSortedAccordingTo`를 제공한다. 각 각 Comparable와 Comparator를 구현해야 사용할 수 있다. 이 말은 오버플로우 등의 문제가 발생하는 비교에 대해서는 Array.sort가 하는 것과 같이 잘못된 결과를 junit이 반환한다. 오버플로우에 대해서는 아래에서 다룬다. 

```java
public class CompareTest {

    @Test
    void sort_comparator() {
        // given
        User[] users = generateRandomUsers(10);
        printMoney(users); // 14 21 73 58 24 25 94 20 2 28

        // when
        Arrays.sort(users, compareWithMoney);
        printMoney(users); // 2 14 20 21 24 25 28 58 73 94

        // then
        assertThat(users).isSortedAccordingTo(compareWithMoney);
    }

    @Test
    void sort_comparable() {
        // given
        User[] users = generateRandomUsers(10);
        printLevels(users); // 98 33 40 83 92 82 87 51 25 70

        // when
        Arrays.sort(users);
        printLevels(users); // 25 33 40 51 70 82 83 87 92 98

        // then
        assertThat(users).isSorted();
    }

    private User[] generateRandomUsers(int size) {
        User[] result = new User[size];
        for(int i=0; i<size; i++) {
            result[i] = new User(randomName(), randomInt(), randomInt());
        }
        return result;
    }

    private int randomInt() {
        return ThreadLocalRandom.current().nextInt(1,99);
    }

    private String randomName() {
        return UUID.randomUUID().toString().substring(0,8);
    }

    private void printMoney(User[] users) {
        for(User u : users) {
            System.out.print(u.money+" ");
        }
        System.out.println();
    }

    private void printLevels(User[] users) {
        for(User u : users) {
            System.out.print(u.level+" ");
        }
        System.out.println();
    }
}
```

# overflow 문제
- 다만 int의 범위는 한정된다. 오버플로우가 발생한 데이터는 위의 로직으로 정상동작하지 않는다.

```java
public class OverflowTest {
    @Test
    void int_max(){
        int x = Integer.MAX_VALUE;
        int y = - 10;

        // -2147483639
        // 음수가 나왔으므로 Integer.MAX_VALUE 은 - 10보다 작은 숫자가 되어버린다.
        System.out.println("(x-y) = " + (x - y));
    }
}
```

- 실제로 이러한 방식으로 테스트를 진행할 경우 아래와 같은 잘못된 결과가 발생한다.

```java
public class OverflowTest {
    Comparator<Value> overflowCompare = (o1, o2) -> o1.value - o2.value;

    @Test
    void overflow() {
        System.out.println("== overflow ==");

        // 오버플로우 발생
        Value[] values = generateValues();
        printValues(values); // -50 -58 2147483647 -7 -33

        Arrays.sort(values, overflowCompare);
        printValues(values); // 2147483647 -58 -50 -33 -7
    }
}
```

- overflow를 방지하기 위한 코드가 필요하며, `Integer.compare(o1, o2)` 라이브러리를 사용하여 간단하게 처리한다.

```java
public class OverflowTest {
    Comparator<Value> safeCompare = (o1, o2) -> Integer.compare(o1.value, o2.value);

    @Test
    void safe() {
        System.out.println("== safe ==");

        // 오버플로우 발생
        Value[] values = generateValues();
        printValues(values); // -84 -62 2147483647 -41 -20

        Arrays.sort(values, safeCompare);
        printValues(values); // -84 -62 -41 -20 2147483647 
    }
}
```