---
layout: post
author: infoqoch
title: jpa, spring OSIV 최적화 - 커맨드와 쿼리의 분리
categories: [jpa]
tags: [spring, jpa, rest]
---


## Open Session in view
- 영속성 컨텍스트를 view 단까지 유지함을 의미한다. 그러니까 Trnasaction로 명시한 위치를 넘어서 controller 나 심지어 view template 까지 영속성 컨텍스트를 사용한다. 
- session 이란 현재 jpa를 의미한다. 하이버네이트에서 나온 기술이라서 jpa 가 아닌 session 단어를 사용한다. 
- 기본 값은 true 이다. 


## OSIV ON
- 스프링이 동작할 때 처음에 아래와 같은 경고가 뜬다. 왜 그럴까? 

```log
2022-02-13 22:03:32.276  WARN 13564 --- [  restartedMain] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
```

![](/assets/pasteimage/2022-02-13-jpa%20spring%20osiv/2022-02-13-22-12-19.png)

- 영속성 컨텍스트가 동작하려면, 데이타베이스 커넥션을 필요로 한다. 
- 데이타베이스 트랜잭션을 할 때, 영속성 컨텍스트가 데이타베이스 커넥션을 가진다. 
- OSIV가 true 일 때, 영속 객체가 트랜잭션으로 선언한 메서드를 떠나더라도, 영속성이 유지가 된다. 그러니까 데이타베이스 커넥션을 유지한다. 
- 커넥션의 유지로 인하여, controller에서 객체 그래프를 통해 lazy loading 이 가능했다. 클라이언트에 응답을 완전하게 마무리할 때까지, 영속성 컨텍스트가 계속 살아 있다. 
- OSIV ON 상태에서 커넥션이 반납되는 순간은, 뷰 템플릿의 렌더링이 완전히 완료되는 시점 혹은 API의 응답이 완전하게 마무리 되는 시점이다. 매우 긴 시간 동안 영속성 컨텍스트가 유지된다.
- 이는 개발과 유지보수에 있어서 큰 장점이지만 커넥션 입장에서는 리소스 낭비이다. 큰 서비스에서는 커넥션이 말라버리는 치명적인 문제가 발생한다.


### OSIV OFF

![](/assets/pasteimage/2022-02-13-jpa%20spring%20osiv/2022-02-13-22-12-40.png)

- @Transaction 이 있는 순간까지만 영속성 컨텍스트가 유효하다. MVC 패턴에서 service 까지 유효하다. 
- 커넥션을 빠르게 반환하기 때문에 리소스의 유지에 유리하다. 
- 지연로딩의 활용이 매우 어렵다. 

- 아래의 코드는 OSIV 를 끈 상태에서, 트랜잭션 밖에서 준영속 상태의 엔티티를 탐색하는 코드이다.

```yml
jpa: 
  open-in-view: false
```

```java
@GetMapping("/api/osiv/v1")
public List<Order> ordersOSIV(){
    final List<Order> all = orderRepository.findAllByString(new OrderSearch());

    for (Order order : all) {
        order.getMember().getName(); // lazy 로딩
        order.getDelivery().getAddress(); // lazy 로딩
        final List<OrderItem> orderItems = order.getOrderItems();
        orderItems.forEach(o->o.getItem().getName()); // lazy 로딩
    }
    return all;
}
```

- 어플리케이션은 아래와 같은 예외를 던진다. 준영속 상태에서 객체 그래프를 탐색할 때의 예외 메시지와 동일하다.

```text
"message": "could not initialize proxy [jpabook.jpashop.domain.Member#1] - no Session",
```

## OSIV off 에 대한 해결책
### 기본적인 방식
- 모든 커넥션을 트랜잭션(서비스, 리포지토리) 안으로 넣어야 한다. 
- 지연로딩을 컨트롤러 이후에 사용해서는 안된다. 

### QueryService
- QueryRepository 와 유사한 빈을 생성한다. 
- 비지니스로직과 분리되며, API에 의존하는, Controller 와 Service를 연결하는 클래스를 만든다.
- QueryService 에 대해서는 @Transaction 으로 영속성 컨텍스트가 유지되도록 한다. 
- 컨트롤러 이후의 모든 지연로딩에 대하여 QueryService에서 수행하도록 한다.

### QueryService 의 구현

- 컨트롤러

```java
private final OrderQueryService orderQueryService;

// api에 의존하는 QueryService를 만들고, QueryService까지 트랜잭션으로 읽을 수 있도록 한다.
@GetMapping("/api/osiv/v2")
public List<Order> ordersOSIV_V2(){
    return orderQueryService.ordersOSIV_V2();
}
```

- QuerySerivce

```java 
@Transactional(readOnly = true)
@RequiredArgsConstructor
@Component
public class OrderQueryService {

    private final OrderRepository orderRepository;

    public List<Order> ordersOSIV_V2(){
        final List<Order> all = orderRepository.findAllByString(new OrderSearch());

        for (Order order : all) {
            order.getMember().getName();
            order.getDelivery().getAddress();
            final List<OrderItem> orderItems = order.getOrderItems();
            orderItems.forEach(o->o.getItem().getName());
        }
        return all;
    }
}
```

### 커맨드와 쿼리의 분리
- 보통 비지니스 로직은 insert, update에서는 성능 상 큰 문제를 만들지 않는다.
- 비지니스 로직을 구현하면 거의 변경되지 않는다. 매우 긴 시간 동안 사용한다. 
- 반대로 select 쿼리는 많은 성능을 요구한다. 
- select 쿼리는 매우 복잡하고, 변동이 심하다. 추가되는 요구사항과 프레젠테이션 계층의 잦은 변화로 인하여, select query 는 자주 변경되고 자주 생성된다.
- 유지보수의 입장에서 select을 위한 로직과 update와 insert를 위한 로직을 분리해야 한다. 이를 커맨드와 쿼리의 분리라 한다. 
- OSIV의 최적화는 일종의 커맨드와 쿼리의 분리로 볼 수 있다. select을 위한 쿼리를 QueryService로 몰아 넣고 트랜잭션을 QueryService까지 한정하여, OSIV의 최적화가 가능하다. 더 나아가 커맨드와 쿼리의 분리를 통한 유지보수의 증대를 만들어 낸다. 

### OSIV와 커맨드 쿼리의 분리에 대한 결론
- **서비스가 커지면, OSIV를 OFF 하고 Service와 QueryService를 분리한다.** 
    - Service : 핵심 비지니스 로직
    - QueryService : 프레젠테이션에 의존하는 로직
- ADMIN의 경우 그냥 OSIV를 사용하는 것이 좋다. 관리자의 커넥션 갯수 자체가 많지 않음. 