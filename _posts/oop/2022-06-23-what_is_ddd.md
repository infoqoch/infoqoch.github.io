---
layout: post
author: infoqoch
title: DDD Start! 도메인 주도 개발 시작하기 읽기
published: false
categories: [oop]
tags: [oop, ddd]
---

# 들어가며
- TDD, 리팩터링 등 OOP를 위한 다양한 패러다임을 학습하고 익히면서 도메인 주도 개발에 대한 욕구가 생겼다. 최범균 개발자님의 테스트 주도 개발 시작하기를 잘 읽었었다. 이번 신규 서적인 "도메인 주도 개발 시작하기: DDD 핵심 개념 정리부터 구현까지" 를 읽고 필요한 내용을 작성하고 느낀점을 정리했다.
- 백명석 개발자님의 클린코더스, 김영한 개발자님의 인프런 강의 덕분에 많은 내용을 이해할 수 있었다. 조금씩 발전하고 있다. 

# 도메인 주도 개발이란?
## 도메인이란?
- 도메인이란 개발자가 해결해야하는 일종의 문제 영역이다. 
- 쇼핑몰을 구현하는 개발자 입장에서, 쇼핑몰은 다시 한 번 하위 도메인으로 나뉜다. 주문, 배송, 회원, 할인. 
- 도메인 주도 개발은 이러한 문제 영역을 분리하고 구현하는 프로그래밍을 의미한다. 

## 어플리케이션의 레이어와 도메인의 위치
- 어플리케이션은 대략적으로 다음과 같은 레이어를 가진다.
    - 프레젠테이션|어플리케이션|도메인|인프라스트럭쳐
- 개발 과정에서 도메인의 분리와 더불어 어플리케이션 레이어의 분리가 중요하다.

# OCP(단일책임원칙)와 도메인 개발에서의 원칙들
- OCP(단일책임원칙)은 도메인에도 적용된다. 하나의 도메인은 그것에 대하여 홀로 온전하게 책임져야 한다. 
- 책임의 범위는 다양한다. 도메인과 관련한 비지니스 로직, 도메인을 이루는 테이블 관리, 객체 관리 등 그 모든 것을 도메인이 관리해야 한다. 이러한 역할은 애그리거트(루트 엔티티)가 수행한다. 
- 그렇다고 해당 도메인의 모든 로직을 루트 엔티티가 부담하는 것은 아니다. 루트 엔티티를 이루는 데이터 덩어리로서의 벨류가, 그 내부에서 로직을 처리하기 위한 기능을 가질 수 있다. 단일책임원칙은 하나의 도메인 내부에서도 지켜져야 한다. 이때 루트 엔티티는 이러한 도메인 내부의 흐름을 통제하는 역할을 한다. 
- Entity와 Value는 분리된다. 엔티티의 중요한 특징은 식별값이 존재하는 것이며 벨류는 이와 달리 단순한 정보의 조합만을 가진다. 
- Value를 적극적으로 활용한다. 기본 타입을 특정 객체로 감싸는 것도 좋은 방법이다. 예를 들면 long money를 Money money로 감쌀 수 있다. 이럴 경우 `add(money); exchange(DOLLAR);` 등 다양한 기능을 부여할 수 있다. 소박한 내용들을 하나의 벨류로 묶고 적절하게 기능을 분배하는 것이 도메인 주도 개발의 중요한 요소이다. 
- OCP를 지키기 위해서는 setter/getter를 제한하고 불변 객체로 구현해야 한다. 

# DI의 필요성
- OCP를 지키고 도메인 주도 개발을 하기 위해서는 DI를 통한 인터페이스 기반으로 개발해야 한다. 
- DI의 가장 중요한 요소는 관심사 분리이다. 도메인 구현의 중요한 지점은 인프라스트럭쳐를 사용하는 것이 아니라, 인프라스트럭쳐에 요구하는 행위를 인터페이스로 표현하는 행위이다. 이러한 개발을 할 경우 자연스럽게 특정 라이브러리나 코드에 종속되지 않는 개발을 할 수 있다. 

- 예를 들어, 아래와 같이 ABCPrinter을 사용하는 도메인이 있다고 가정하자. 

```java
public class OrderService{
    public void printOrders(){
        ABCPrinter printer = new ABCPrinter(); // 특정 모듈에 의존하는 코드가 작성된다.
        printer.print(args...); // 특정 모듈이 박혀 있다. 어떤 의도인지 알 수 없다. 
    }
}
```

- 위의 코드의 문제는 사실 특정 라이브러리에 종속된 코드가 아닐 수도 있다. 그보다 관심사가 명확하지 않다는 점이 치명적이다. 우리의 관심사는 ABCPrinter란 모듈이 아니다. 
- ABCPrinter를 구현한 후에 OrderService가 동작한다는 문제가 발생한다. 이로 인해 OrderService와 Printer를 동시에 개발하는 것이 어렵다. 
- 추가적으로 ABCPrinter를 교체하기 어렵기 때문에 테스트에 불리하다. 

```java
@RequiredArgsConstructor
public class OrderService{
    private final OrderPrinter printer;

    public void printOrders(){
        printer.forCustomer(args...); // 고객을 위한 프린터를 하는 것이 명확하게 드러난다.
    }
}
```

- 관심사가 명확해졌다. 인터페이스로 변경하였고 테스트에 유리하다.
- 조심해야 할 지점은, 인터페이스의 주체가 상위 객체라는 점이다. ABCPrinter의 인터페이스라 하여 ABCPrinterInterface로 이름을 지어서는 안된다. 상위 객체의 입장에서 그것의 관심사에 맞춰 인터페이스를 구현해야 한다. 

## 항상 DI를 적용해야 하는 것은 아니다.
- 한편, 항상 DI를 적용해야 하는 것은 아니다.
- 인터페이스를 구현함에 있어 특정 인프라스트럭쳐에 의존적인 구현체를 작성하는 경우가 있다. 이런 경우 굳이 DI를 통해 구현할 필요는 없다. 반드시 필요하지 않은 상황에서 DI로 구현하면 시간을 소비하고 혼란을 가중시킨다. 

# 애그리거트
## 애그리거트란
- 애그리거트란 연관 도메인을 하나로 묶은 것이다. 
- 엔티티와 밸류보다 더 큰 개념으로서 세세한 내용보다 전체적인 그림을 그릴 때 활용한다. 특히 다양한 테이블로 구성된 ERD를 묶는 경계로서 사용한다. 
- 애그리거트는 대체로 하나의 엔티티를 가지며 이를 루트 엔티티라고 한다. 루트 엔티티는 애그리거트의 일종의 대리인 역할을 하며, 해당 애그리거트가 요구하는 로직을 수행한다. 
- 애그리거트에 소속된 값들은 동일한 라이프사이클을 가진다. 루트 엔티티에 속한 밸류들이 루트 엔티티와 함께 조회되고 저장되고 변경된다. 
- 애그리거트는 자신의 애그리거트만을 관리한다. 
- 애그리거트의 부분이 변경되면 전체가 변경될 수 있다. 주문한 상품이 변경되면 주문 가격이 변경되고 결제를 다시 해야할 수 있다. 캡슐화를 잘 구현해야 한다. 
- 자주 동시에 함께 사용된다고 하여 같은 애그리거트라고 확정할 수 없다. 상품의 주문 후 상품 리뷰가 이뤄진다고 하여, 주문과 리뷰가 같은 애그리거트는 아니다.

## 좋은 애그리거트의 특징
- 애그리거트의 내부를 외부에서 변경할 수 없다. 반드시 애그리거트를 통해 수정한다. 
- 트랜잭션 하나에 애그리거트 하나만 존재하는 것이 이상적이다. 만약 두 개를 동시에 처리해야 한다면 응용 서비스단에서 처리해야 하며, 도메인 내부로 가져와서는 안된다. 

## 루트 엔티티의 객체 탐색
- JPA를 기준으로 루트 엔티티가 하위 도메인이나 벨류에 참조하는 방법은 크게 두 가지이다.
    - 객체
    - pk

### 객체를 통한 탐색 
- 객체를 필드로 가진 루트 엔티티는 객체를 쉽게 탐색할 수 있다. DB를 쉽게 쿼리한다. 지연로딩의 편의성을 적극적으로 활용할 수 있다. 
- 객체 그래프는 오용의 여지가 있다. 객체는 자신의 필드를 드러내서는 안된다. 만약 해당 객체가 불변객체가 아니라면 더티체킹으로 인해 데이터가 오염될 수 있다. 

```java
public class Order{
    Member orderer(){        
        return member;
    }
}

public void static main(String[] args){
    Member member = order.orderer();
}
```

### PK를 통한 탐색 
- PK를 통해 탐색할 경우, 필요에 따라 리포지토리를 다른 기술로 구현할 수 있다. Order는 MariaDB로 사용하고 OrderLine은 몽고 DB를 사용하는 형태이다. 

### 팩토리 활용을 통한 객체 탐색의 우회
- 특정 로직은 여러 개의 애그리거트를 필요로 할 수 있다. 이때, 해당 로직의 핵심 애그리거트의 내부에서 다른 애그리거트를 관리하여, 비지니스로직에 드러내지 않는 방향이 낫다. 
- 예를 들면 더 이상 상품 주문을 허용하지 않는 회원이 있다고 가정하고, 해당 회원이 주문할 때 예외를 발생시키는 로직이 있다고 하자.

```java
public void order(...args){
    Member member = order.member();
    if(member.isBlocked())
        throw new SomeException();
    Order order = Order.newOrder(args...);
    // 후략...
}
```

- 위의 코드는 Member가 해당 비지니스 로직에 노출되어 버린다. 이보다는 아래와 같이 애그리거트 내부에 해당 로직을 구현하는 것이 낫다.

```java
public void order(...){
    Order order = Order.newOrder(args...);
}

public class Order{
    public statis Order newOrder(args...){
        if(member.isBlocked())
            throw new SomeException();
        // 후략...
    }
}
```