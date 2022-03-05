---
layout: post
author: infoqoch
title: 이펙티브자바, 자원을 직접 명시하지 말고 의존 객체 주입을 사용하라
categories: [java]
tags: [java, effective]
---

## 싱글턴과 정적유틸리티가 외부 객체를 사용할 때
- 아래는 정적유틸리티를 구현한 형태이다. 
- 클래스 내부에서 필요한 객체의 인스턴스를 생성하고 static 매서드로 활용한다. 

```java
public class SpellCheckerV1 {
    private static final Lexicon dictionary = new Lexicon();

    public static boolean isValid(String word) {
        return dictionary.contains(word);
    }
}
```

- 아래는 싱글턴 형태이다.
- 싱글턴으로 사용할 객체만 static이며 나머지는 인스턴스를 통해 사용한다. 

```java
public class SpellCheckerV2 {
    private final Lexicon dictionary = new Lexicon();

    private static final SpellCheckerV2 INSTANCE = new SpellCheckerV2();

    private SpellCheckerV2(){}

    public static SpellCheckerV2 getInstance(){
        return INSTANCE;
    }

    public boolean isValid(String word){
        return dictionary.contains(word);
    }
}
```

- 하지만 필드에서 초기화를 하는 방식은 유연하지 않다. Lexicon 객체를 상황에 따라 다른 값으로 넣는 것이 나을 수 있는데, 이러한 가능성을 없애버린다. 
- 그러므로 싱글턴으로 사용할 객체 자체를 외부에서 주입하는 방식을 택한다. 이를 의존 객체 주입이라 한다. 

## 의존 객체 주입 : 유연성과 테스트 용이성을 높여준다.
- 아래의 코드는 생성자로 객체를 구현할 때, 필요로 한 객체를 주입하는 형태로 진행한다.
- 생성자에서 필요한 데이터를 주입하기 때문에, final 로 구현할 수 있다. 
- 해당 객체를 인터페이스나 서플라이어, 와일드 카드 등 다형성을 보장할 수 있다. 

```java
public class SpellCheckerV3 {
    private final Lexicon dictionary;

    public SpellCheckerV3(Lexicon dictionary){
        this.dictionary = dictionary;
    }

    public boolean isValid(String word){
        return dictionary.contains(word);
    }
}
```

- 이에 대한 수많은 장점이 있지만, 나에게 가장 큰 장점은 테스트 코드 작성에 있었다. 
- 싱글턴을 테스트 코드를 작성하면 아래와 같은 형태가 된다.
- 아래의 문제는 SpellCheckerV2 객체와 그 내부에 있는 Lexicon 객체에 대한 통제가 아예 불가능하다. 테스트 자체가 사실상 어렵다. 

```java
@Test
void test(){
    final SpellCheckerV2 instance = SpellCheckerV2.getInstance();
    final boolean kim = instance.isValid("kim");
    System.out.println("kim = " + kim);

}
```

- 하지만 의존 형태로 할 경우 태스트가 매우 자유롭다.
- Lexicon에 대하여 구현할 수 있다. 

```java
@Test
void test(){
    Lexicon dictionary = new Lexicon();
    SpellCheckerV3 spellCheckerV3 = new SpellCheckerV3(dictionary);
    final boolean kim = spellCheckerV3.isValid("kim");
    System.out.println("kim = " + kim);
}
```

## 스프링과 테스트 코드 작성
- 사실, 이러한 패턴은 스프링에서 자주 봤다. 
- DI를 필드주입 할 경우 일종의 싱글턴과 같은 형태로 소스코드가 작성된다. 

```java
@Service
public class TestService {
    @Autowired
    private TestRepository testRepository;

    public boolean getOne(Long id){
        return testRepository.getOne(id);
    }
}
```

```java
class TestServiceTest {
    @Test
    void test(){
        TestService testService = new TestService();
        testService.getOne(120l); // 예외가 발생한다. 왜냐하면 필드 TestRepository는 DB와 커넥션이 필요로 한다. 이는 SpringBoot가 로딩되지 않으면 동작하지 않는다. 유닛 테스트가 불가능하다. 
    }
}
```

- 하지만 생성자를 통해 주입할 경우 테스트 코드 작성이 가능하다. 자원으로 사용하는 객체에 대하여 목 데이터를 생성할 수 있다. 의존 객체 주입은 테스트 코드를 위해서 아주 좋은 형태이다. 

```java
@Service
@RequiredArgsConstructor
public class TestService {
    private final TestRepository testRepository;

    public boolean getOne(Long id){
        return testRepository.getOne(id);
    }
}
```

```java
class TestServiceTest {
    @Test
    void test(){
        // given
        TestRepository testRepository = new TestRepository(){
            @Override
            public boolean getOne(Long id) {
                if(id<=0){
                    throw new IllegalArgumentException();
                }
                return true;
            }
        }; // 유닛테스트가 가능하다. 적당한 형태로 해당 객체를 구현할 수 있다. 

        // when
        TestService testService = new TestService(testRepository);
        final boolean result = testService.getOne(120l);

        // then
        Assertions.assertThat(result).isTrue();
    }
}
```
