---
layout: post
author: infoqoch
title: 클린코더스, SOLID
categories: [refactoring]
published: false
tags: [refactoring, java]
---

# SOLID

## The Source Code is the Design
- 엔지니어는 설계도를 만드는 사람이다. 소프트웨어 개발자에게 설계도는 무엇인가?
- 키보드 엔지니어? 키보드의 설계도를 만든다. 실제 키보드 생산은 공장이 한다.
- 소프트웨어 엔지니어? 빌드가 된 바이너리 코드가 생산물이다. 소스코드가 설계도이자 문서이다.
- 건물, 회로, 기계 : 저렴한 설계 비용, 비싼 수정 비용
- 소프트웨어 : 비싼 설계 비용(소스코드 작성), 저렴한 구축 비용(컴파일, 빌드). 
- 소프트웨어는 설계도인 소스코드를 수정하는데 정말로 많은 자원을 필요로 한다. 
- 좋은 설계는 좋은 소스코드를 구현하는 것에 있다. 

## Design Smells
- 나쁜 디자인으로 설계된 코드는 나쁜 냄새를 풍긴다.

### Rigidity 견고함
- 시스템의 의존성이 너무 견고하여 변경하기 어렵다. 
- 테스트와 빌드가 시간이 너무 오래 걸린다. 의존성 등 문제로 인하여 작은 변화로 전체의 변경이 발생한다. 

### Fragility 취약함
- 한 모듈의 수정이 다른 모듈에 영향을 미친다.
- 라디오 버튼을 수정하니까 창문의 동작에 영향을 미친다. 
- 모듈 간 의존성을 제거해야 한다. 

### Immobility 유연하지 않음
- 모듈이 쉽게 추출되지 않고 재사용되지 않는 경우
- 특정 db, 특정 ui에 강하게 의존되어 있음. 
- stuff로의 의존성을 없앤다. 

## Viscosity 점성
- 빌드/테스트, 체크인/체크아웃,머지 등의 비용이 너무 큼. 
- 여러 레이어를 가로지르는 의존성
- 무책임한 용인 : 나쁜 것이나 나빠질 것으로 보이는 것에 대하여 방치

## Needless Complexity 불필요하게 복잡함
- 불필요한 복잡성을 없애야 한다. 
    - 미래를 예측하는 구현 (나중을 상상하는 abstract class 들)
- 현재에 집중해라. 다만 변경에 대하여 유연할 수 있도록 한다 -> 테스트코드!
- 테스트코드에 집중하여 개발하자.
- 현재에 집중하고, 좋은 코드를 구현하기 위하여 리팩토링을 하다보면 코드의 디자인이 자연스럽게 만들어진다. 나도 모르게(emergent) 코드가 진화한다. 

## Code Rot
- 시간이 흐르며...
    - 요구사항이 늘어나고, 리팩터링과 디자인에 대한 고민 없이 요구사항을 덕지 덕지 붙여넣고, 코드는 복잡해지고... 
    - 어느 순간 코드를 건들고 싶지 않다. 
- OOP로 하였다면?  
    - 기존의 코드는 유지되는데
    - 객체 하나만 구현하고 의존성을 수정하면 된다. 
- 특정 클래스에 다양한 요구사항에 따른 분기가 발생한다 -> 특정 인터페이스를 구현하고, 이를 요구사항에 따른 의존성을 추가할 뿐이다. 
- Copy {switch case(keyboard)...case()}
- Copy - File(input, output) - DI(Keyboard IO Driver, Mouse IO Driver)

## What is OO?
- `o.f(x)` != `f(o, x)`
- OO는 메시지만 전달한다. 어떻게 동작하는지, 무엇을 원하는지 알 수 없다. 
- DI는 OO의 정수
- OO는 IoC를 통해 상위 레벨의 모듈이 하위 레벨의 모듈로부터 보호받는 것. 이것이 객체지향의 핵심.
- OOD란? Dependency 를 잘 관리하는 것. isolation이 제일 중요하다.
- SOLID란 OOP를 위한 중요한 규칙.


---

# SRP : Single Responsibility Priority

## Responsibility란 하나의 사용자를 의미한다.
### 사용자(actor, client)란 누구인가?

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

- 사용자는 개개인이 아니라 특정 역할을 수행하는 actor이다. 
- 한 명이 하나의 어플리케이션 전체를 다루더라도, 이를 다룰 때의 역할은 나뉘어져 있다. 

### 모듈은 반드시 하나의 변경사유만을 가져야 하며, 변경 사유는 사용자이다.
- One and Only one Responsibility
- 변경사유는 사용자이다. 하나의 모듈은 하나의 사용자만을 만족시켜야 한다.

### USE CASE
- 사용자를 기준으로 설계를 하기 때문에 SRP에 사용하기 좋다.
- Actor들을 serve하기 위한 책임을 인식하고 분리한다.

## Two Values of SW
- Secondary value of SW is it's behavior
    - 소프트웨어가 현재의 요구사항을 수행하는 것은 두 번째 가치이다.

- Primary Value of SW?
    - 가장 중요한 소프트웨어의 가치는 미래의 요구사항을 수용하는 일이다.
    - 지속적인 요구사항을 수용할 수 있어야 한다. 
    - 요구사항을 수용하기 위해서는 SRP가 전제되어야 한다. 

## Primary Value of SW를 저하하는 요소들
### Collocation is Coupling
- 하나의 클래스에 사용자가 결합되어 있으면 안된다.
- 하나의 사용자를 만족시키기 위한 클래스 변경이 모든 사용자에게 영향을 미침. 
- 소스코드, git merge, 컴파일에서 Collision 충돌이 발생함. 

### Fan Out problem
- 너무 많은 업무를 수행한다. 
- 변경에 민감하다.
- 책임을 줄여야 한다.

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
- 클래스로 분리한다. 각각의 actor 마다 클래스를 만든다. 
- Inverted Dependencies와 적절하게 섞어서 사용한다.

```java
public class EmployeePolicyImpl {
    public int cacluatePay(){}
}
// 후략
```

### Facade
- actors - a facade - concrete classes
- SRP를 준수한 모듈 사이에 하나의 facade를 둔다.
- 구현된 위치를 찾기 쉽지만 actors는 a facade class에 의존한다. 

### interface Segregation
- actors - interfaces - a concrete class
- SRP를 준수한 각각의 인터페이스가 존재한다. 여러 인터페이스를 구현한 구현체는 하나이다. 가능하다면 각 인터페이스마다 구현체를 분리하면 좋다. 
- 완전히 decoupled 된다. 
- 다만, 인터페이스를 구현한 클래스를 찾기 어렵다. 
- 가장 이상적이고 추천하는 방식. 다만 가장 어렵고 번거로운 방식.

---

# OCP Open Closed Principle
- Open For extension, but Closed for modification

## Open과 Closed?

```java
public interface Mouse{
    void connect(Connector connector);
    void click();
}
```

- 마우스는 그것이 연결하는 메서드로서 connect, 사용할때 click이란 기능이 있다고 하자.
- connect는 유선, 무선, 블루투스, 터치패드 등 다양할 수 있다. 이 부분이 OCP에서 말하는 확장이다. OO에서는 이를 인터페이스로 통해 의존성을 끊는다. 
- 만약 OO로 개발하지 않은 상태에서 확장을 하면, 해당 소스코드를 사용하는 모든 소스코드에 영향을 받는다. 그러니까 변경에 열려 있다. 
- 만약 OO로 개발했다면, 해당 인터페이스에 맞는 구현체를 새롭게 만들고, 이를 주입할 것이다. 그러니까 Mouse 클래스의 소스코드에 어떤 영향이 없다. 
- 만약 click(); 이란 기능이 부족해서 다음의 기능을 추가할 수 있다. `void scrolling();`. 이때를 기능적 확장으로 볼 수 있다. OO에서 기능적 확장은 해당 인터페이스 구현체 전제에게 구현을 강제하기 때문에 불리하다.





---



## 완전한 기획보다는 개발 과정에서 자연스럽게
- use case는 waterfall 방식이 아닌 TDD, 에자일을 선택해야 한다. 
- 테스트 코드를 통과하도록 했다.
- 리팩토링을 했다. 
- 시스템의 모든 동작이 잘 돌아가도록 개발 및 테스트를 계속 진행한다.
- 이러한 설계는 사실 80퍼센트 만들다보면 자동적으로 된다. 
- 책임(사용자)가 확인되는 시점이 존재한다. 
- 유닛 테스트가 많으므로 적극적으로 리팩터링을 수행한다. 
- 마지막으로 다이어그램을 예쁘게 그린다.  (기획 때는 그냥 화이트보드로 찍찍 그리면 된다.)
