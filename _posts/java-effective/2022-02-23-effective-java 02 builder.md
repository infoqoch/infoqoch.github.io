---
layout: post
author: infoqoch
title: 이펙티브자바, 빌드패턴, 들어가며
categories: [java]
tags: [java, effective]
---

## 객체를 생성하는 다양한 방법
### 점진적 생성자
- 점진적 생성자란 모든 필드를 인자로 가지는 생성자(일종의 @AllArgsConstructor)를 만든다. 그리고 필요에 따라 일부분의 인자만을 가지는 생성자를 만들고, 자신보다 더 많은 인자를 가진 생성자에 대하여 this()로 생성자를 호출한다. 작은 생성자 -> 중간 생성자 -> 전체 생성자를 호출하는 형태를 가진다. 이러한 형태를 점진적 생성자라 한다.

```java
public class NutritionFacts {
    // 필드 값은 final로 한다. 모든 값에 대하여 생성자 인자로 삽입한다.
	private final int servingSize;
	private final int servings;
	private final int caloreis;
	private final int fat;
	private final int sodium;
	private final int carbohydrate;

	// 점진적 생성자
	public NutritionFacts(int servingSize, int servings, int caloreis, int fat, int sodium, int carbohydrate) {
		super();
		this.servingSize = servingSize;
		this.servings = servings;
		this.caloreis = caloreis;
		this.fat = fat;
		this.sodium = sodium;
		this.carbohydrate = carbohydrate;
	}

    // 점진적 생성자
	public NutritionFacts(int fat, int sodium, int carbohydreate) {
		this(0,0,0,fat,sodium,carbohydreate);
	}

    // 점진적 생성자
	public NutritionFacts(int calories, int fat, int sodium, int carbohydreate) {
		this(0,0,calories,fat,sodium,carbohydreate);
	}

}
```

- 점진적 생성자의 장점은 final을 사용 가능하다. 생성자는 여러 번을 사용하지만 final로 필드를 사용할 수 있다.
- 단점은 인자의 위치가 변경되거나 어떤 필드에 대한 값인지 인지하기가 어렵다. 
- 각 생성자가 어떤 의도인지를 파악하기 어렵다.

### 자바빈즈 패턴, 세터
- 생성자는 기본 생성자만 존재한다. 세터를 통해 필요한 값을 주입한다.
- 점진적 생성자와 달리 필드값이 매서드에 분명하기 드러나기 때문에 이해하기 쉽다.
- 단점은 객체 생성 후 주입하기 때문에 final을 사용할 수 없다. 특정 필드의 setter를 누락하여 발생한 문제를 예방하기가 어렵다. 

```java
@Setter
public class NutritionFacts2 {
	private int servingSize;
	private int servings;
	private int caloreis;
	private int fat;
	private int sodium;
	private int carbohydrate;

	public NutritionFacts2() {
	}
}
```

```java
@Test
void test(){
    NutritionFacts2 obj = new NutritionFacts2();
    obj.setCaloreis(123);
    obj.setFat(123);
}
```

## 빌드패턴
- 점진적 생성자와 자바빈즈 패턴의 장점을 수용한 형태
- 클래스 내부에 정적 클래스 Builder를 만든다.
- Builder 객체를 생성하고 stream 처럼 매서드를 체인처럼 엮어서 값을 삽입한다. 마지막에 build() 매서드를 호출할 때, 해당 객체의 필드값을 구현하려는 객체의 AllArgConstructor 에 한번에 삽입하는 형태이다. 
- 이를 통해 setter와 유사하게 매서드의 이름이 명시되고 동시에 원하는 값만을 삽입할 수 있다. 마지막에 전체 생성자로 목표하는 객체를 만들기 때문에 필드를 final로 할 수 있다. 생성자 생성 타임에 데이터의 정합성 및 예외처리 가능해서 좋다.

```java
@Getter
@ToString
public class NutritionFacts {
    private final int servingSize;
    private final int servings;
    private final int calories;
    private final int fat;
    private final int sodium;
    private final int carbohydrate;

    public static class Builder{
        private final int servingSize;
        private final int servings;
        private int calories;
        private int fat;
        private int sodium;
        private int carbohydrate;

        public Builder(int servingSize, int servings){
            this.servings = servings;
            this.servingSize = servingSize;
        }

        public Builder calories(int val){
            this.calories = val;
            return this;
        }
        public Builder fat(int val){
            this.fat = val;
            return this;
        }
        public Builder sodium(int val){
            this.sodium = val;
            return this;
        }
        public Builder carbohydrate(int val){
            this.carbohydrate = val;
            return this;
        }

        public NutritionFacts build(){
            return new NutritionFacts(this);
        }

    }

    public NutritionFacts(Builder builder){
        this.servingSize = builder.servingSize;
        this.servings = builder.servings;
        this.calories = builder.calories;
        this.fat = builder.fat;
        this.sodium = builder.sodium;
        this.carbohydrate = builder.carbohydrate;
    }
}
```



## 나아가며, 이펙티브 자바를 읽으며
- 개발자로서 정말로 할 것들이 많다. 스프링 / 자바는 기본이다. 자바/스프링만이 아니다. Junit, Spring JPA, security, batch, reactive 등 다양한 라이브러리를 알아야 한다. 알고리즘 공부도 빼놓을 수 없다. 서버에 대한 학습도 필요하다. 최소한 도커나 AWS, 리눅스 따위는 어느정도 다뤄야 할테다. 백엔드만이 아니다. 최소한 타임리프 정도는 자유롭게 사용할 줄 알아야 한다. 가능하면 js나 vue.js 정도를 능숙하게 다뤄야겠지.
- 다양한 기술과 깊이도 중요하지만, 내가 좋은 코드를 작성하느냐에 대한 고민도 많다. 클린코드, 테스트 주도 개발, 도메인 주도 개발, 리팩터링, 디자인 패턴, 에자일 등 좋은 품질의 코드를 작성하고 좋은 문화를 위한 고민 또한 빼놓을 수 없다. 
- 하루 하루 할 수 있는 만큼 우적우적 하고 있다. 정말로 나를 표현함에 있어 우적 우적이란 단어보다 더 잘 표현하는 단어는 없어 보인다. 가끔은 내가 해야하는 그 모든 것들에 압도된다. 그 순간에 내가 할 수 있는 일은 필요로 해 보이고 할 수 있는 일을 퇴근하고 하루 하루 하는 일 밖에 없다. 
- 항상 그랬지만 요새 특히 나는 혼란함을 느낀다. 우적우적 하고 있지만 지금 내가 잘하고 있는지 혼란스럽다. 그 많은 과업에 나는 이것을 찍어 먹고 저것을 찍어 먹다가 이도 저도 아니라는 느낌이 들 때가 많다. 그냥 하루 하루며 우적 우적 하는 것도 하루 이틀이다.  해야할 일은 많다. 그래서 요새 고민이 많다. 무엇이 우선되어야 할까?
- 일단, 좋은 기술과 좋은 품질의 코드는 분리된다는 느낌을 가진다. 물론, 엄격하게 분리할 수 없다. 나는 최근 JPA를 다시 공부하고 실제 토이 프로젝트에 적용하면서, 도메인 주도 개발이 무엇인지를 이해할 수 있었다. DB가 중심이 아니라, 객체가 중심이 되고, 그 객체를 위한 순수한 코드를 짤 수 있다는 것에 나는 충격을 받았다. 그러나 편의상 대략 그렇게 나누고자 한다. 
- 두 개의 부류 중 나에게 필요한 것이 무엇일까를 생각하면, 솔직히 고르기 쉽지 않다. 나를 뽐내고 나 개인만을 위해서라면 전자에 집중하는 것이 유리해 보인다. 자바, 스프링만 할 수 있다는 것보다, 스프링에 딸린 수많은 라이브러리, 도커, 리눅스, AWS, js, msa 따위를 능숙하게 다룰 수 있는 것이, 훨씬 매력적으로 보이니까.
- 내가 처한 현재의 조건에서 좋은 성과를 내기 위해서는 후자에 집중하는 것이 맞다. 회사는 보수적이다. 기존의 기술을 고집한다. 내가 새로운 기술에 대하여 강력하게 주장하는 것이 쉬운 일은 아니다. 하지만 내가 어떤 기술을 쓰던, 현재의 조건에서 좋은 품질을 코드를 작성하는 것은 언제나 좋은 일이다. 누가 알아주지 않더라도, 내가 나중에 내가 구현한 어플리케이션을 유지보수하고 운영을 할 때 분명 장점이 된다. 그래서 지금 나는 이펙티브 자바를 읽는다. 
- 이펙티브 자바는 솔직히 어렵다. 빌드 패턴에 대한 내용은 위에 정리한 것보다 더 많다. 전혀 알지도 못한 개념들이나 자바 API에 대한 설명도 나오기도 하고, 그래서 위축되기도 한다. 하지만 이펙티브 자바가 나에게 감동을 준 부분이 있다. "빌드패턴을 사용해라" 라는 그 문장이 나에게는 무척 중요하다. 무엇이 좋은 코드이고 나쁜 코드인지 갈피가 잡히지 않는 상황에서, 무엇이 좋고 나쁨을 선언을 해줄 수 있는 스승이 있다는 것이 중요하니까. 음, 이렇게 작성하니까 조금은 외롭네. 

## 참고
- 소스코드
- https://github.com/WegraLee/effective-java-3e-source-code