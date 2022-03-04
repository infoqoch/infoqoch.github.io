---
layout: post
author: infoqoch
title: 이펙티브자바, 19 상속을 고려해 설계하고 문서화하라. 그러지 않았다면 상속을 금지하라.
categories: [java]
tags: [java, effective]
---

## 19. 상속을 고려해 설계하고 문서화하라. 그러지 않았다면 상속을 금지하라.
- 매서드를 재정의하면 어떤 일이 일어나는지를 정확하게 정리하여 문서로 남겨야 한다. 달리 말하면, 상속용 클래스는 재정의할 수 있는 메서드들을 내부적으로 어떻게 이용하는지(자기사용) 문서로 남겨야 한다.
    - 자기사용이란 클래스 내부에서 사용하는 매서드를 의미한다. 자기사용 매서드를 노출하여 발생하는 문제는, Set을 extends하여 발생한 문제를 다뤘던 아이템18에서 확인할 수 있다. 
    - 재정의 가능이란 public 과 protected 메서드 중 final이 아닌 모든 메서드를 뜻한다. 해당 객체는 개방되어 있는 필드 혹은 메서드이며 하위 클래스나 객체를 통해 수정 가능하다.
- "좋은 API 문서란 '어떻게'가 아닌 '무엇'을 하는지를 설명해야 한다." 상속을 위하여 문서화하는 순간, 내부 구현 방식을 설명하기 시작하며, 좋은 API문서로부터 멀어진다. 

### 좋은 상속을 위한 상위 클래스의 구현
- 문서를 통해 설명하지 않고 코드로 보여준다. 예를 들면 클래스의 내부 동작 과정에 끼어들 수 있는 hook을 잘 선별한다. 이러한 객체를 protected 등 메서드 공개한다. 이를 상속하는 개발자는 자연스럽게 protected 메서드를 수정할 수 있다. 
    - 예를 들면, AbstractList 에서는 removeRange에 대하여 protected 로 선언한다. 이는 clear()에 영향을 주는 로직으로 고성능을 위하여 열어두었다. 
    - 상속을 통해 효과를 볼 수 있는 부분에 대해서만 적절하게 열어야 한다. 
- 상속을 검증하기 위해서는 실제로 상속하는 것 이외에는 없다. 다른 로직으로 여러 개의 구현체를 만들고 테스트해야 한다. 
- 마지막으로 생성자는 재정의 가능 메서드를 호출해서는 안된다. 

## 생성자는 재정의 가능 메서드를 호출해서는 안된다. 
- 상위 클래스의 생성자가 재정의 가능한 메서드를 호출할 경우 문제가 발생한다. 해당 코드는 아래와 같다.

- 상위 클래스

```java
public class WrongExtends {

	WrongExtends() {
		initConstruct();
	}

	protected void initConstruct() {
	}
}
```

- 하위 클래스

```java
/*
 * 생성자 구현시 순서
 * 1번 오버라이드
 * 2번 super() -> 오버라이드 된 매서드 호출
 * 3번 필드값 삽입
 *
 */
public class WrongExtendsChild  extends WrongExtends {
	private final String name;

	public WrongExtendsChild() {
		name = "kim";
	}

	@Override
	public void initConstruct() {
		System.out.println(name);
	}


	public static void main(String[] args) {
		WrongExtendsChild child = new WrongExtendsChild(); // override를 하지만 필드 초기화는 super 이후에 동작한다. 그러므로 오버라이드된 매서드를 상위 클래스가 호출 할 때(super()), name 필드는 null이다.
	}
}
```

- 결과

```text
null
```

- 상위 클래스의 생성자가 호출하는 메서드를 재정의하도록 열어두면 안된다.
- 하위 클래스가 생성자를 호출할 때, 동작 순서는 override -> super() -> this() 이다.
- 상위 클래스는 하위 클래스가 재정의한 메서드를 호출하지만, 해당 메서드에 대한 데이터가 적절하게 삽입되지 않으면 에러를 만들 수 있다. 
- 결론적으로 상속용 클래스의 생성자는 어떤 식으로든 해당 메서드를 호출할 수 있도록 하면 안된다. private으로 해야 한다. 

## 정리
- 결론적으로 상속을 할 이유가 명확하지 않으면 하지 않는다. 최대한 다른 방법을 강구한다. 
- 상속을 반드시 해야하는 상황이라면 procteced로 제한한다. 
- 상속을 막고자 한다면, private final을 통해 재정의할 수 없도록 하거나 정적 팩토리만으로 초기화 하도록 한다. 