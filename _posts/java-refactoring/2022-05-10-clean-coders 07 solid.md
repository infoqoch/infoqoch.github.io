---
layout: post
author: infoqoch
title: 클린코더스, SOLID
categories: [refactoring]
tags: [refactoring, java]
---

# SOLID
## The Source Code is the Design
- 엔지니어는 설계도를 만드는 사람이다. 소프트웨어 개발자에게 설계도는 무엇인가?
- 키보드 엔지니어는 키보드의 설계도를 만든다. 실제 키보드 생산은 공장이 한다.
- 소프트웨어 엔지니어는 소스코드를 생산한다. 실제 어플리케이션은 빌드가 된 바이너리 코드이다.
- 좋은 설계는 좋은 소스코드이며, 좋은 소스코드를 생산하는 것이 매우 중요하다.

## Design Smells
- 나쁜 디자인으로 설계된 코드는 나쁜 냄새를 풍긴다.

### Rigidity 견고함
- 시스템의 의존성이 너무 견고하여 변경하기 어렵다. 
- 테스트와 빌드가 시간이 너무 오래 걸린다. 작은 변화로 전체의 변경이 발생한다. 

### Fragility 취약함
- 한 모듈의 수정이 다른 모듈에 영향을 미친다.
- 라디오 버튼을 수정하니까 창문의 동작에 영향을 미친다. 

### Immobility 유연하지 않음
- 모듈이 쉽게 추출되지 않고 재사용되지 않는다.
- 특정 db, 특정 ui에 강하게 의존되어 있음. 

### Viscosity 점성
- 빌드/테스트, 체크인/체크아웃,머지 등의 비용이 너무 크다.
- 여러 레이어를 가로지르는 의존성

## Needless Complexity 불필요하게 복잡함
- 불필요한 복잡성을 예측하여 구현해서는 안된다.
- 현재에 집중하고, 미래에 변경 가능한 유연한 코드를 작성해야 한다. 여기에 가장 중요한 것은 테스트 코드이다.

## Code Rot 썩은 코드
- 개발된 코드는 시간이 흐르며... 요구사항이 늘어나고, 리팩터링과 디자인에 대한 고민 없이 요구사항을 덕지 덕지 붙여넣고, 코드는 복잡해지고.... 어느 순간 그 누구도 그 코드를 건들고 싶지 않다. 

## Two Values of SW
- 소프트웨어가 현재의 요구사항을 수행하는 것은 두 번째 가치이다.
- 가장 중요한 소프트웨어의 가치는 미래의 요구사항을 수용하는 일이다.
- 지속적인 요구사항을 수용할 수 있어야 한다. 
- 이는 SOLID를 지킨 객체지향 개발을 통해 가능하다.

## What is OO?
<!--  - `o.f(x)` != `f(o, x)` -->
- 소스코드의 의존성을 줄이고 의존성을 DI 와 IoC를 통해 주입한다. 이것이 나쁜 냄새를 없애기 위한 가장 중요한 원칙이다. 
- 메시지만 전달한다. 우리는 내부의 동작에 관심을 가지지 않는다.
- OO는 IoC를 통해 상위 레벨의 모듈이 하위 레벨의 모듈로부터 보호받는 것. 이것이 객체지향의 핵심.
- 올바른 객체지향 개발을 통해 의존성을 줄이고 유지보수하기 좋은 코드를 작성하기 위한 원칙이 SOLID이다.


# SRP : Single Responsibility Priority

## Single Responsibility란 하나의 사용자에 대한 책임을 의미한다.

```java
public class EmployeeImpl{
    public int cacluatePay(){}
    public void save(Employee e){}
    public String describeEmployee(){}
    public findById(Long id){}
}
```

- SRP에서의 Responsibility은 책임으로서, 클래스가 하나의 책임만 가져야 함을 의미한다.
- 어떤 기준으로 책임을 나누는가? 같은 부류? 유사한 기능?
- *사용자*를 기준으로 봐야 한다. *누가 해당 메서드의 변경을 유발하는 사용자인가?*

- EmployeeImpl 의 사용자, 역할
    - policy : cacluatePay
    - architect : save / findById
    - operation : describeEmployee

- 사용자는 개개인이 아니다. 특정 역할을 수행하는 actor이다. 
- 한 명이 하나의 어플리케이션 전체를 다루더라도, 이를 다룰 때의 역할은 나뉘어져 있다. 

### 모듈은 반드시 하나의 변경사유만을 가져야 하며, 변경 사유는 사용자이다.
- One and Only one Responsibility
- 변경사유는 사용자이다. 하나의 모듈은 하나의 사용자만을 만족시켜야 한다.

### USE CASE
- use case는 사용자를 기준으로 설계를 한다. SRP를 위하여 주로 설계에 주요 사용되는 방식이다.

## SRP를 저해하는 요소
### Collocation is Coupling
- 하나의 클래스에 여러 사용자의 요구사항이 결합되어서는 안된다. 하나의 사용자를 위한 소스수정이, 다른 모든 사용자에 영향을 미치기 때문이다. 
- 소스코드, git merge, 컴파일에서 충돌이 발생한다.

### Fan Out problem
- 하나의 클래스가 너무 많은 업무를 수행한다. 
- 작은 변경에 민감하다.

## 해결책 : 구조의 변경
### Inverted Dependencies
- 구현된 클래스의 interface를 만든다. 소스코드나 런타임 등에 문제가 없으므로 사이드 이펙트가 가장 적다. 
- 레거시 프로젝트에 주로 적용하는 방식. 가장 쉽고 단순.

```java 
public class EmployeeImpl implements EmployeeImpl{
    @Override
    public int cacluatePay(){}
    @Override
    public void save(Employee e){}
    @Override
    public String describeEmployee(){}
    @Override
    public findById(Long id){}
}
```

### Extract Classes
- 하나의 큰 클래스를 작은 여러 개의 클래스로 분리한다.
- 클래스의 분리는 사용자를 기준으로 한다.
- Inverted Dependencies와 적절하게 섞어서 사용한다.

```java
public class EmployeePolicyImpl {
    public int cacluatePay(){}
}
// 후략
```

### Facade
- actors - a facade - concrete classes
- 사용자와 SRP를 준수한 모듈 사이에 하나의 facade를 둔다.
- actors는 facade에 의존하는 문제가 발생한다. 

### interface Segregation
- actors - interfaces - a concrete class
- 가장 이상적인 형태. 완전히 decoupled 된다. 
- 다만, 구현 클래스를 찾기 어렵고, 어렵고, 번거롭다. 


# OCP Open Closed Principle
- Open For extension, but Closed for modification

## Open과 Closed?

```java
public interface Mouse{
    void connect(Connector connector);
    void click();
}
```

- 마우스는 하드 웨어 간 연결을 위한 connect(), 사용을 위한 click()이 존재한다. 
- connect()는 유선으로만 사용하였으나 현재 무선, 블루투스, 터치패드 등 다양한 조건에 대응한다. 이러한 확장이 OCP에서 말하는 확장이다. 기존의 마우스 코드가 유선으로만 연결될 수 있었던 의존적이던 소스코드에서, 확장성을 고려한 인터페이스 기반의 소스코드로 수정한다.  
    - 만약, OO로 개발하지 않은 상태에서 확장을 하면, connect와 관련이 없는 코드까지 영향을 받는다. 변경에 열려 있다. 
    - 만약 OO로 개발했다면, 해당 인터페이스에 맞는 구현체를 만들고, 이를 주입하는 것으로 끝난다. 
- click()은 확장이 아닌 기능으로서 볼 수 있다. 만약 스크롤링이라는 기능  `void scrolling();`을 추가한다면 어떨까? interface를 구현한 모든 구현체는 강제적으로 `void scrolling();`을 구현해야 한다. **OO는 기능의 추가한다는 측면에서는 불리**하다. 

## The Lie
- 그러나 OCP는 거짓이다.
- 확장에는 열려있고 변경에는 닫혀있는 구현을 할 수 있다는 의미는 이미 완성된 기획이 존재하는 것과 같다. 
- 완성된 기획이란 존재하지 않는다. 우리는 모르는 것이 무엇인지도 모르는 상태이다. Unknown unknowns.

### 요구사항은 변한다
- 확장 가능성까지 염두한 코드가 작성가능한가? 혹은 그렇게 작성하는 것이 좋은가? 
- 확장 가능성을 염두하여 추상화 수준이 복잡해지면, 코드를 이해하는데 어려움. 더불어 사용하지 않은 확장성은 더러운 코드가 되어버림. OCP를 준수한다는 것 자체가 사실상 불가능한 상황. 
- 복잡한 상황을 예측하여 코드를 작성하는 것보다, 요구사항에 딱 맞는 수준으로 최대한 빨리 전달하는 것이 낫다. 피드백을 기반으로 리팩터링하는 것이 더 낫고 빠르다. 

## 현실적인 OCP의 적용 방안
### Big Design Up Front BDUF
- 고객의 요구사항을 예측하여 모델을 만든다.
- 다만 앞서의 내용처럼 쓰레기 설계가 되고 과도하게 추상화되어 있고 이해하기 어려운 코드가 될 수도 있다. 

### Agile Design
- 빠르게 만들고 빠르게 평가 받는다.
- 일단, 요구사항에 맞는 개발을 최대한 빨리 한다. 피드백을 최대한 빨리 받는다. 피드백에 따라 개발을 한다. 이러한 과정을 반복한다. 
- 요구사항과 시장의 평가를 가장 빠르게 경험하고 예측하는 것은, 빨리 만들고 빠르게 피드백을 받는 것에 있다. 

# Interface Segregation Principle ISP
- Don't depend on things that you don't need.
- 사용하지 않는 의존성에 의존하지 않는다. SRP와 유사한 개념.
- 레거시 class를 리팩토링함에 있어, 각각의 사용자를 상정하고, 이에 준하는 인터페이스를 만든다. interface를 기반으로 소스코드가 의존하도록 한다.

# Liskov Substitution Principle LSP
- LSP란, 상위 타입의 객체를 하위 타입으로 변경하더라도 정상적으로 동작함을 보장하는 원칙을 의미한다. 
- LSP는 OCP에 대한 다형성의 원칙을 제공한다. LSP를 위반하면, OCP를 위반한다.

## IS-A 원칙은 생각보다 잘 지켜지지 않는다.
- 객체지향개발의 특징은 현실세계를 컴퓨터의 세계에 적용시킨다는 점에 있다.
- 직사각형 Rectangle은 정사각형 Square 이다. Square IS-A Rectangle.
- 객체지향 개발에 따라 아래와 같이 작성하였다.

```java
public class Rectangle {
    private int height;
    private int width;

    public void setHeight(int height) {
        this.height = height;
    }

    public void setWidth(int width) {
        this.width = width;
    }

    public int getHeight() {
        return height;
    }

    public int getWidth() {
        return width;
    }

    public int area(){
        return height*width;
    }
}

public class Square extends Rectangle {
}

@Test
void test1() {
    Rectangle rec = new Square();
    rec.setWidth(10);
    assertThat(rec.area()).isEqualTo(100);
}
```

- 하지만 위의 테스트 코드는 동작하지 않는다.
- 왜냐하면 height를 정의하지 않았기 때문이다. 하지만 정사각형의 높이와 너비는 같으므로, Rectangle의 width와 height를 동시에 구현한다는 것은 말이 되지 않는다. 
- 그래서 아래와 같은 코드를 구현했다. 1) width, height 둘 중 하나만 입력해도 나머지 값이 입력된다. 2) side라는 명칭을 통해 width와 height을 동시에 삽입할 수 있도록 하였다. 

```java
public class Square extends Rectangle {
    @Override
    public void setHeight(int height) {
        setSide(height);
    }
    @Override
    public void setWidth(int width) {
        setSide(width);
    }

    public void setSide(int size) {
        super.setHeight(size);
        super.setWidth(size);
    }
}
```

- 위와 같이 코드를 변경하니까 첫 번째 테스트는 정상 동작함을 확인한다.
- 하지만 아래의 코드는 테스트를 통과하지 못한다.

```java
@Test
void test2() {
    Rectangle rec = new Square();
    rec.setWidth(10);
    rec.setHeight(20);
    assertThat(rec.area()).isEqualTo(200);
}
```

- 리스코프 원칙이란 부모 객체가 하위타입으로 변경되더라도 기대하는 값을 출력해야 한다. 직사각형을 하위타입인 정사각형으로 객체를 만들었다. 하지만 기대하는 값인 200이 아닌 400으로 출력된다. 리스코프 원칙을 어긴다. 

## The Representative Rule 대리인은 관계까지 대리하지 않는다. 
- 객체지향 개발이 현실을 반영한다고 하지만, 실제 코드의 세계에서는 그렇지 않다. 이를 대리인은 관계까지 대리하지 않는다는 표현을 통해 잘 보여준다. 누군가 이혼 소송을 대리한다고 하여 부부관계까지 공유하는 것은 아니다.
- LSP는 상위클래스를 extends하는 코드 작성이 위험함을 보여준다. 이는 LSP로 인하여 SOLID 위반, 그러니까 객체지향 개발이 아닐 가능성이 높다. 
- 더 나아가 자식클래스가 부모클래스에 무척 취약하다는 단점 또한 가지고 있다.
- 가능하면 컴퍼지션 패턴이나 기타 디자인 패턴을 활용하여 extends를 사용하지 않는 방향으로 코드를 작성해야 한다. 
