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

## 참고
- 소스코드
- https://github.com/WegraLee/effective-java-3e-source-code