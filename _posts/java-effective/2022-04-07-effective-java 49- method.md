---
layout: post
author: infoqoch
title: 이펙티브자바, 49- 메서드
categories: [java]
tags: [java, effective]
---

## 49 매개변수가 유효한지 검사하라
- 매개변수의 유효성은 메서드 몸체가 시작하기 전에 검사해야 한다. 오류는 가능한 빨리 잡아야 한다.
- 만약 그렇지 않으면 오류가 예상치 못한 곳에 발생하여 유지보수를 어렵게 할 수 있다. 객체가 변경되어 실패 원자성을 어기는 결과를 낳을 수 있다.
- 노출된 API에 대해서는 매개변수에 일반적으로 사용되는 예외(IllegalArgumentException, IndexOutOfBoundsException, NullPointerException)만 제공하더라도 클라이언트가 제약을 지키도록 유도할 수 있다. 물론 이에 대한 문서화를 해야 한다.

- 자바에서는 버전이 올라가며 유효성 검사를 위한 좋은 기능을 마련했다. 
- assert, Object.requireNonNull 등이 그것이며 내용은 아래와 같다. 

### Objects 를 통한 널 검사

```java
@Test
void test1() {
	Object obj = null;
	Assertions.assertThatThrownBy(()->{
		Objects.requireNonNull(obj, "널이잖여!!");
	}).isInstanceOf(NullPointerException.class)
	.message().isEqualTo("널이잖여!!");

	int[] ints = new int[] {1,3,4};
	Assertions.assertThatThrownBy(()->{
		Objects.checkIndex(10, ints.length);
	}).isInstanceOf(IndexOutOfBoundsException.class);
}
```

### assert 를 통한 boolean 검사
- AssertionError는 검증을 위한 에러 클래스이다.
- true 와 false를 통해 해당 소스코드의 정상 유무를 판단한다.
- assert 절은 런타임 시점에서 모두 무시된다. assert는 개발자가 소스코드를 작성하고 테스트하는 개발 과정에서 사용한다. 테스트 시점에서는 엄격하게 설계하기 위해 작성하지만, 성능이나 암묵적인 승인 등 다양한 이유로 인해 런타임 시점에서 적용하고 싶지 않은 경우 사용한다. 
- 만약 런타임 시점에서 사용하고 싶으면, -ea 등 옵션을 사용한다.

```java
@Test
void test2() {
	int a = 0, b = 50;
	
    assert a<20; // 문제없이 동작한다.

	Assertions.assertThatThrownBy(()->{
		assert b<20; // 예외가 발생한다.
	}).isInstanceOf(AssertionError.class);
}
```

### 정리
- 매개변수의 유효성 검사는 실패원자성을 위하여 매우 중요하다.
- 성능이 우선되야 하거나, 설계가 좋아서 유효성 검사가 필요 없을 수 있다. 이런 경우 생략할 수 있으나 언제나 실패원자성을 최우선으로 고려해야 한다.
- 매개변수의 검사로 인해 발생한 예외는 적절한 고수준의 예외로 처리해야 한다. (catch IOException -> throw IllegalArgumentException)

## 50 적시에 방어적 복사본을 만들라
- 악의적인 의도를 가지고 보안을 뚫기 위하여 객체 내부에 침입, 수정 할 수 있다. 클라이언트가 의도치 않게 가변적인 객체의 데이터를 수정하고 이로 인한 문제가 발생할 수 있다. 단순하게 private final로 선언한다고 하여 이것이 불변임을 보장하지 못한다. 변경 가능성을 최소화하기 위해서 가변적인 객체를 인자로 하는 매개변수와 리턴에 대하여 방어적 복사본을 사용해야 한다. 

### 불변객체가 아니다.
- 아래는 private final인 Date 객체를 필드로 가지는 객체이다. 불변 객체가 아니다.

```java
import java.util.Date;

public class Period {
	// private final 을 통해 불변을 기대하였으나 의도대로 동작하지 않는다.
	private final Date start;
	private final Date end;

	public Period(Date start, Date end) {
		this.start = start;
		this.end = end;
	}

	public Date start() {
		return start;
	}

	public Date end() {
		return end;
	}

	public static void main(String[] args) {
		Date start = new Date();
		Date end = new Date();
		Period p = new Period(start, end);
		Period p2 = new Period(start, end);
		p.end().setYear(1522); // 데이터가 조작된다.
		System.out.println(p.end());

		System.out.println(p2.end()); // 다른 Period 객체에 영향을 미친다.
	}
}
```

### 불변객체
- 필드를 초기화 할 때 new Date(arg)를 통해 초기화한다. 값을 리턴할 때 return new Date(start); 를 통해 데이터를 전달한다. 이를 통하여 클라이언트는 초기화된 Period 객체의 Date 객체에 절대로 접근할 수 없다.
- clone을 사용하지 않는다. Date 객체를 상속하고 clone을 부정적인 방식으로 오버라이딩 한 후, 해당 객체를 인자로 삽입할 경우, 문제가 발생할 수 있기 때문이다. 
- 방어적 복사를 할 때는, 초기화를 한 후 유효성 검사를 해야 한다. 멀티 스레드 환경에서 찰나의 순간에 데이터가 바뀔 수 있기 때문이다.

```java
import java.util.Date;

public class Period2 {
	// private final 을 통해 불변을 목표하였다.
	private final Date start;
	private final Date end;

	public Period2(Date start, Date end) {
		// Date 객체를 새로 생성하여, 해당 객체가 다른 Period 객체간 복사되지 않도록 한다.
		this.start = new Date(start.getTime());
		this.end = new Date(end.getTime());

		// 유효성 검사는 객체를 생성한 후 진행한다.
		// 찰나의 순간에 다른 스레드가 원본 객체를 수정할 위험이 있기 때문이다. (TOCTOU 공격)
		// clone을 사용하지 않는다. 매개변수가 된 객체의 clone이 어떻게 정의되어 있는지 알 수 없기 때문이다.
		if(this.start.compareTo(this.end)>0)
			throw new IllegalArgumentException();
	}

	// 값을 리턴할 때도 새로운 객체를 생성하여 전달한다.
	public Date start() {
		return new Date(start.getTime());
	}

	public Date end() {
		return new Date(end.getTime());
	}

	public static void main(String[] args) {
		Date start = new Date();
		Date end = new Date(System.currentTimeMillis() + 100);
		Period2 p = new Period2(start, end);
		Period2 p2 = new Period2(start, end);
		p.end().setYear(1522); // 데이터가 조작된다.
		System.out.println(p.end()); // 하지만 원래의 값을 전달한다. 왜냐하면 Period 객체 내부의 Date는 외부에서 더는 변경되지 않기 때문이다.

		System.out.println(p2.end()); // 더 이상 다른 Period 객체에 영향을 주지 않는다.
	}
}
```

### 정리
- 불변 객체를 구현하기 위해서는 방어적 복사가 필요할 수 있다.
- 방어적 복사를 하지 않고 가변 객체를 공개할 수 있다. 객체에 대한 통제권을 클라이언트에게 넘길 수 있다. 이런 식으로 의도한 상황이라면 클라이언트에게 해당 내용을 알리기 위하여 명확하게 문서화한다.
- 통제권을 넘기더라도, 클라이언트의 조작으로 인한 문제는 클라이언트에 한정하도록 코드를 작성해야 한다.


## 51. 메서드 시그니처를 신중히 설계하라

### 메서드 이름을 신중히 짓자.
- 표준 명명 규칙을 따른다. 
- 패키지에 속한 이름들과 일관되게 짓는다.
- 개발자 커뮤니티에서 널리 받아들여지는 이름을 사용한다.
- 자바 라이브러리 Api를 참고한다.

### 편의메서드를 너무 많이 만들지 말자.
- 메서드가 복잡하면 클라이언트가 사용하기 어렵다. 가볍고 단순하게 한다.

### 매개변수 목록을 짧게 유지하자.
- 4개 이하를 유지한다.
- 같은 타임의 매개변수가 연달아 나오도록 하지 않는다. 
- 이를 위한 팁은 아래와 같다. 

#### 1. 여러 메서드로 쪼갠다.
- 리스트 객체가 있고, 그 객체의 특정 범위 중 특정 순서의 값을 꺼내고 싶을 수 있다.
- 이 경우 subListAndGetIndexOf(int start, int end, int index); 의 형태로 구현하고 싶을 수 있다.
- 하지만 이보다는 list가 구현한 subList와 get 메서드를 나누어 사용하는 것이 더 명확하고 직교성에 좋다. 

```java
@Test
    void split_method(){
        final List<Integer> list = List.of(1, 2, 3, 4, 5);

//        list.subListAndGetIndexOf(1,4,1);  

        final List<Integer> newList = list.subList(1, 4); // 1부터 4번째 값(2,3,4)를 꺼낸다.
        final Integer target = newList.get(1); //2,3,4 중 두 번째 값인 3을 꺼낸다.
        System.out.println("target = " + target);
    }
```

##### 직교성?
- 직교성이란 서로 영향을 주는 성분이 전혀 없고 독립적이란 의미이다. 
- 한 객체의 메서드가 직교성이 있을 때 메서드를 줄여주고 매개변수를 단순하게 만들어주는 효과를 가져다 준다. 그러니까 subListAndGetIndexOf 와 같은 유사하지만 약간 다른 메서드가 수십개 있는 것보다, subList와 get이 두 개 있는 것이 더 단순하고 명확할 수 있다. 
- 필요에 따라 직교성이 낮은 방식으로 구현할 수 있다. 특정 데이터를 db에서 추출할 때, entity를 단순하게 추출하여 자바 로직을 통해 복잡하게 dto를 리턴할 수도 있다. 그러나 상황에 따라 쿼리를 복잡하게 작성하여, 특정 상황에서만 사용할 수 있는 메서드가 여러 개를 구현하여, 성능이나 자바 로직을 단순하게 가져갈 수 있다. 

#### 2. 매개변수를 여러 개 묶어주는 도우미 클래스를 만든다
- 유사한 매개변수가 여러 메서드에서 반복되는 경우가 있다. 그리고 그런 메서드가 여러 개일 수 있다. 이 경우 해당 매개변수는 객체로 묶고, 유사한 메서드는 다른 클래스로 묶을 수 있다.

#### 3. 앞서의 두 기법을 혼합하여, 객체 생성에 사용한 빌더패턴을 메서드 호출에 응용한다.
- 매개변수를 추상화한 객체를 설정한 다음, execute 메서드를 호출해 앞서의 매개변수의 유효성을 검사한다. 해당 객체를 넘겨서 원하는 계산을 한다. 
- 위의 내용, 그러니까 2와 3에 대한 예제가 존재하지 않아 명확하지 않게 느껴졌다. 예시로 든 카드 게임이 아마 아래와 같은 형태라고 상상하였고, 이를 코드로 구현하면 아래와 같은 형태가 되지 않을까 싶다. 
- card_game_1 메서드는 String suit, String rank가 반복되고, 같은 타입의 매개변수이다.
- card_game_2는 반복되는 매개변수를 Card 객체로 바꾼다. 그리고 CardGame 객체를 구현하는데, 해당 객체는 setUp 메서드로 Card 객체를 생성하여 불변객체로 가진다. game.guessCard로 두 개가 같은 값을 가지는지 비교한다. 이런 방식으로 클래스를 외부로 꺼내고 구현하는 것이 더 명확하고 깔끔하다.

```java
String suit;
String rank;

@Test
void card_game_1(){
    setGame("diamond", "6");
    boolean isCorrect = guessCard("heart", "7");
}

private boolean guessCard(String suit, String rank) {
    if(this.suit != suit) return false;
    if(this.rank != rank) return false;
    return true;
}

private void setGame(String suit, String rank) {
    this.suit = suit;
    this.rank = rank;
}

@Test
void card_game_2(){
    CardGame game = CardGame.setUp(CardSuit.DIAMON, CardRank.SIX);

    boolean isCorrect = game.guessCard(new Card(CardSuit.HEART, CardRank.SEVEN));
}
```

### 배개변수의 타입으로는 클래스보다는 인터페이스가 낫다.
- setMap(HashMap<String> map) 보다는 setMap(Map<String> map)이 더 유연하고 낫다.

### boolean 보다는 원소 2개짜리 열거 타입이 낫다.
- setTemp(int value, boolean isCelsius) 보다  setTemp(int value, TemperatureScale.CELSIUS) 가 낫다.


## 52. 다중정의는 신중히 사용하라

> **재정의한 메서드는 동적으로 선택되고, 다중정의한 메서드는 정적으로 선택된다.**

### 재정의된 메서드 중 선택되는 것은 개발자의 입장에서 직관적이다.
- 메서드가 하위, 상위의 여러 클래스에서 재정의(override)가 되더라도, 초기화한 클래스의 메서드가 동작한다. 개발자가 기대하는 방식으로 동작한다.

```java
public class Overriding {
    public static void main(String[] args) {
        List<Wine> wineList = List.of(
                new Wine(), new SparklingWine(), new Champagne());

        for (Wine wine : wineList)
            System.out.println(wine.name()); // 포도주 - 발포성 포도주 - 샴페인이 출력된다.
    }
}
class Wine {
    String name() { return "포도주"; }
}

class Champagne extends SparklingWine {
    @Override String name() { return "샴페인"; }
}

class SparklingWine extends Wine {
    @Override String name() { return "발포성 포도주"; }
}
```

### 다중정의의 메서드의 선택 문제와 방안
- 다중정의(overload)란 매개변수만 다른 같은 시그니처의 메서드의 묶음을 말한다.
- 다중정의한 메서드 중 동작할 메서드를 선택할 때 컴파일 시점에서 결정한다. 이로 인하여 재정의에서 없었던 혼란이 발생한다. 아래의 코드를 확인해보자.

```java
import java.math.BigInteger;
import java.util.*;

public class CollectionClassifier {
    public static String classify(Set<?> s) {
        return "집합";
    }

    public static String classify(List<?> lst) {
        return "리스트";
    }

    public static String classify(Collection<?> c) {
        return "그 외";
    }

    public static void main(String[] args) {
        Collection<?>[] collections = {
                new HashSet<String>(),
                new ArrayList<BigInteger>(),
                new HashMap<String, String>().values()
        };

        for (Collection<?> c : collections)
            System.out.println(classify(c));
    }
}
```

- 아래 main 메서드를 실행할 경우, 모두 "그 외"가 선택됨을 확인할 수 있다. 

#### instanceof
- 아래와 같이 instanceof 를 사용하여 해당 문제를 해소할 수 있다. 

```java
import java.math.BigInteger;
import java.util.*;

public class FixedCollectionClassifier {
    public static String classify(Collection<?> c) {
        return c instanceof Set  ? "집합" :
                c instanceof List ? "리스트" : "그 외";
    }

    public static void main(String[] args) {
        Collection<?>[] collections = {
                new HashSet<String>(),
                new ArrayList<BigInteger>(),
                new HashMap<String, String>().values()
        };

        for (Collection<?> c : collections)
            System.out.println(classify(c));
    }
}
```

#### 형변환 불가와 Wrapper class
- instanceof도 좋지만 가장 근본적인 방식은 매개변수 최소 하나가 근본적으로 다른 경우, 그러니까 **형변환이 불가능한 경우** 앞서의 문제를 회피할 수 있다.
- 예를 들면 Scanner를 초기화할 때의 매개변수를 들 수 있다. InputStream과 File은 상호 형변환이 불가능하다.

```java
package java.util;

public final class Scanner implements Iterator<String>, Closeable {

	// 중략 
	public Scanner(InputStream source) {
			this(new InputStreamReader(source), WHITESPACE_PATTERN);
	}
	public Scanner(File source) throws FileNotFoundException {
        this((ReadableByteChannel)(new FileInputStream(source).getChannel()));
    }
	// 중략 

}
```

- 한편, 자바5 이후로 제네릭이 생겼고, 이로 인한 오토박싱 문제로 다중정의의 문제가 발생했다.

```java
List<Integer> list = new ArrayList<>();
list.add(1); // index 0
list.add(2); // index 1
list.add(3); // index 2

System.out.println("list.remove(2) = " + list.remove(2)); // 인덱스 2로 동작한다.
System.out.println("list.remove((Integer) 1) = " + list.remove((Integer) 1)); // Object인 값 Integer 1로 동작한다.
System.out.println("list.toString() = " + list.toString());
```

```java
package java.util;
public interface List<E> extends Collection<E> {
	// 중략
	E remove(int index);
	boolean remove(Object o);
	// 중략
}
```

- 위의 코드를 보면 remove가 기대하는 것과 다른 방식으로 동작함을 확인할 수 있다. list.remove(2) 은 index로서의 int가 사용되었고, list.remove((Integer) 1)) 은 자료구조 내 값으로서의 Object가 동작함을 확인할 수 있다. 
- 이처럼 오토방식으로 인한 int와 Integer 간 문제가 존재한다. 

#### 메서드의 이름을 다르게 하자.
- 위의 방식보다 더 직관적이고 명확한 방법은 **메서드의 이름을 다르게** 한다. 특별한 이유가 있지 않는 한, 같은 이름으로 메서드를 만들 이유는 없다.
- ObjectOutputStream은 그것의 매개변수에 따라 변수명을 설정했다. writeInt(int), writeLong(long) 등.


## 53. 가변인수는 신중히 사용하라
- 가변인수 매서드는 명시한 타입의 인수를 0개 이상 받을 수 있다. 그러니까 아무것도 받지 않을 수 있다(v1).
- 만약 배열이 0개가 아닌 한 개 이상임을 기대할 경우 아래(v2)와 같이 코드를 작성할 수 있다. 배열이 0개일 때 예외 처리를 한다.

```java
@Test
void test_runtime() {
	// v1
	Assertions.assertThat(min(10,1,2,3,4,5)).isEqualTo(1);
	// Assertions.assertThat(min()).isEqualTo(0); // expected: 0 but was: 2147483647

	// v2
	Assertions.assertThat(minV2(10,1,2,3,4,5)).isEqualTo(1);
	Assertions.assertThatThrownBy(()->minV2())
		.isInstanceOf(IllegalArgumentException.class)
		.message().isEqualTo("0개 이상 입력하세요.");  // 런타임 에러 발생
}

int min(int... arg) {
	int min = Integer.MAX_VALUE;
	for(int i : arg) {
		if(i<min)
			min = i;
	}
	return min;
}

int minV2(int... arg) {
	if(arg.length==0)
		throw new IllegalArgumentException("0개 이상 입력하세요.");

	int min = Integer.MAX_VALUE;
	for(int i : arg) {
		if(i<min)
			min = i;
	}
	return min;
}
```

- 한편, 위의 방식을 사용할 경우 런타임예외가 발생한다.
- 컴파일 시점에서 오류를 잡아내기 위하여, 초기값을 매개변수에 명시한다. 해당 내용은 아래와 같다.

```java
@Test
void test_compile() {
	// v3
	Assertions.assertThat(minV3(10,1,2,3,4,5)).isEqualTo(1);
	minV3(); // 컴파일 에러 발생
}

int minV3(int firstint, int... arg) {
	int min = firstint;
	for(int i : arg) {
		if(i<min)
			min = i;
	}
	return min;
}
```

- 위와 같이 가변인자와 함께 매개변수를 입력하여 코드를 더 명확하게 작성할 수 있다.
- 가변인자는 그것의 갯수가 늘어날 때마다 배열을 새로 생성한다. 그러니까 성능 상 문제가 존재한다. 가변인자의 장점과 성능을 동시에 누리기 위하여 아래와 같은 형태로 코드를 작성하기도 한다. EnumSet 또한 아래와 유사한 형태로 다중정의가 되어 있다.

```java
int min(int first);
int min(int first, int second);
int min(int first, int second, int third);
int min(int first, int second, int third, int... args);
```

## 54. null이 아닌, 빈 컬렉션이나 배열을 반환하라
- (여담인데) 54장의 전제는 이미 초기화가 된 컬렉션 필드가 있다. 이 컬렉션은 값이 있을 수도 있고 없을 수도 있다. 불변객체를 유지하기 위하여 방어적 복사를 한 후 값을 리턴한다. 만약 이 때 해당 컬렉션이 빈 값일 경우, 어떻게 리턴하는 것이 좋은지를 논의하는 것이 이번 장의 목표이다. 이러한 전제가 명확하지 않아 나는 이해하는데 다소 시간이 걸렸다. 아무튼,

- 방어적 복사를 한다면 `new ArrayList<>(target);` 의 형태로 전달하게 된다. 값이 있다면 당연하게 이 방식을 따라야겠지만, 만약 어떤 요소도 없다면 어떻게 할까? 초기화의 비용을 아끼기 위하여 null을 리턴할 수 있다. 

```java
// 특정 API를 구현했고, 불변객체로서 아래의 객체를 방어적 복사를 통하여 전달한다고 가정한다.
// 상황에 따라 컬렉션에 어떤 값도 없을 수 있다. 이런 경우 어떤 식으로 전달하는 것이 가장 좋을까?
private List<LocalDate> target = new ArrayList<>();

List<LocalDate> getAttendanceNullable(){
	return target.isEmpty() ?
			null : // null을 반환환다.
			new ArrayList<>(target); // 방어적 복사를 한다.
}

@Test
void test_null() {
	final List<LocalDate> attendance = getAttendanceNullable();
	if(attendance !=null&& attendance.contains(LocalDate.now())) // !=null 이란 조건절을 추가해야한다. 
		System.out.println("오늘 출석했구나. 아주 성실하구나?");
}
```

- 컬렉션이 null일 경우, 예외를 피하기 위하여 !=null 등의 조건절을 굳이 삽입해야 한다. 
- !=null 과 같은 조건절을 삽입하기보다 빈 컬렉션을 제공하는 것이 더 낫다. 코드가 더 명확하고 예상하지 못한 예외로부터 더 안전하다. 

```java
List<LocalDate> getAttendanceV1() {
	// 초기화는 큰 성능을 요구하지 않는다. 
	// 훨씬 깔끔하다.
	return new ArrayList<>(target); 
}

@Test
void test_empty(){
	final List<LocalDate> attendance = getAttendanceV1();
	if(attendance.contains(LocalDate.now()))
		System.out.println("오늘 출석했구나. 아주 성실하구나?");
}
```

- 초기화로 인한 성능저하는 거의 없다. 만에 하나 성능 이슈가 있다면 `Collections.emptyList();` 등 메서드를 활용할 수 있다. 초기화를 하지 않아 성능에 도움이 된다. 

```java
List<LocalDate> getAttendanceV2() {
	return target.isEmpty()
			? Collections.emptyList() 
			: new ArrayList<>(target);
}

@Test
void test_return_exist_empty(){
	final List<LocalDate> attendance = getAttendanceV2();
	if(attendance !=null&& attendance.contains(LocalDate.now()))
		System.out.println("오늘 출석했구나. 아주 성실하구나?");
}
```

- 만약 배열을 반환해야 한다면 아래와 같은 코드를 작성할 수 있다.
- 참고로 빈 배열은 불변 객체이다.

```java
private final LocalDate[] EMPTY_ARRAY = new LocalDate[0];

LocalDate[] getArray() {
	return attendance.toArray(EMPTY_ARRAY);
}
```
