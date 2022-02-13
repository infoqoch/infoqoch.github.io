---
layout: post
author: infoqoch
title: jpa, spring OSIV 최적화
categories: [jpa]
tags: [spring, jpa, rest]
---


## Open Session in view
- 하이버네이트에서 처음 나온 개념이자 기술.
- session 이란 현재 jpa를 의미한다. jpa 전에 나온 기술이라서 jpa 가 아닌 session 단어를 사용한다. 
- 기본 값은 true 이다. 


## OSIV ON
- 스프링이 동작할 때 처음에 아래와 같은 경고가 뜬다. 왜 그럴까? 

```log file
2022-02-13 22:03:32.276  WARN 13564 --- [  restartedMain] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
```

![](/assets/pasteimage/2022-02-13-jpa%20spring%20osiv/2022-02-13-22-12-19.png)

- 영속성 컨텍스트가 동작하려면, 데이타베이스 커넥션을 필요로 한다. 
- 데이타베이스 트랜잭션을 할 때, 영속성 컨텍스트가 데이타베이스 커넥션을 가진다. 
- OSIV가 true 일 때, 트랜잭션이 있는 메서드를 떠나더라도, 영속성 컨텍스트가 유지가 된다. 그러니까 데이타베이스 커넥션을 유지한다. 
- 커넥션의 유지로 인하여, controller에서 객체 그래프를 통해 lazy loading 이 가능했다. 클라이언트에 응답을 완전하게 마무리할 때까지, 영속성 컨텍스트가 계속 살아 있다. 
- 커넥션이 반납되는 순간은, 뷰 템플릿의 렌더링이 완전히 완료되는 시점 혹은 API의 응답이 완전하게 마무리 되는 시점이다. 이는 매우 큰 장점이다. 
- 이로 인하여 커넥션을 너무 오랫동안 가지고 있다. 커넥션이 말라버리는 치명적인 문제가 발생할 수 있다. 


### OSIV OFF

![](/assets/pasteimage/2022-02-13-jpa%20spring%20osiv/2022-02-13-22-12-40.png)

- @Transaction 이 있는 순간까지만 영속성 컨텍스트가 유효하다. MVC 패턴에서 service 까지 유효하다. 
- 커넥션을 빠르게 반환하기 때문에 리소스의 유지에 유리하다. 
- 지연로딩의 활용이 매우 어렵다. 

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

- json의 결과값 중 일부는 아래와 같다. 준영속 상태에서 지연로딩을 할 수 없다.

```text
"message": "could not initialize proxy [jpabook.jpashop.domain.Member#1] - no Session",
```

## OSIV off 에 대한 해결책
### 핵심적인 방법
- 모든 커넥션을 트랜잭션(서비스, 리포지토리) 안으로 넣어야 한다. 
- 지연로딩을 컨트롤러 이후에 사용해서는 안된다. 

### QueryService
- API에 의존하며 Controller 와 Service를 연결하는 QueryService를 만든다. 
- QueryService 에 대해서는 @Transaction 으로 영속성 컨텍스트가 유지되도록 한다. 

- 컨트롤러

```java
private final OrderQueryService orderQueryService;

// api에 의존하는 Service를 만들고, 이를 트랜잭션으로 읽을 수 있도록 한다.
@GetMapping("/api/osiv/v2")
public List<Order> ordersOSIV_V2(){
    return orderQueryService.ordersOSIV_V2();
}
```

- 쿼리 서비스

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
- 비지니스 로직의 경우 한 번 생성되면 거의 변경되지 않는다. 매우 긴 시간 동안 사용한다. 
- 대체로 select 으로 성능을 많이 소비한다. 그리고 select에 매우 복잡하고 유지보수가 어렵다. 화면과 api 관련한 변동이 생기므로 짧은 기간 동안 사용한다. 
- 유지보수의 입장에서 커맨드와 쿼리 분리는, 장기적인 운영에서 무척 좋다. 
- 그러므로 프레젠테이션 계층에 의존하는 로직은 따로 만드는 것이 좋으며, JPA를 구현하는 것을 떠나서, QueryService를 구현하는 방식은 장점이 크다. 

### 결론 
- **서비스가 커지면, OSIV를 OFF 하고 Service와 QueryService를 분리한다.** 
    - Service : 핵심 비지니스 로직
    - QueryService : 프레젠테이션에 의존하는 로직
    - 기타 기획과 필요에 따라 레이어를 분리하고 트랜잭션의 유지 수준을 설정한다. 
- 하지만, ADMIN 서비스의 경우 그냥 OSIV를 사용하는 것이 좋다. 커넥션 자체를 얼마 사용하지 않음. 