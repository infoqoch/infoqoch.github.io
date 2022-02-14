---
layout: post
author: infoqoch
title: jpa, spring api의 entity 조회 최적화 3 - xToMany 연관관계와 dto 컬렉션 조회
categories: [jpa]
tags: [spring, jpa, rest]
---

## 들어가며
- 이전 블로그는 xToMany 를 출력할 때 entity 를 값으로 하였다. 지금 블로그는 dto로 반환하는 방식을 정리한다. 

## dto로 출력하기
- 커맨드와 쿼리를 분리한다. 
- DTO는 API에 의존적이기 때문에, QueryRepository를 별도로 분리하여 관리한다. 
- select 절에서 new SomethingDto() 를 사용해야 한다. 하지만 dto 내부에서 dto를 생성할 수 없다. 별도의 매서드로 분리하여 쿼리한다.
- 첫 번째 dto로 order를 꺼내고 두 번째 dto로 orderItem을 꺼낸다.

- 컨트롤러
 
```java
@GetMapping("/api/v4/orders")
public List<OrderQueryDTO> ordersV4(){
    return orderQueryRepository.findOrderQueryDtos();
}
```

- QueryRepository와 이에 딸린 dto를 구현한다.

```java
@Repository
@RequiredArgsConstructor
public class OrderQueryRepository {
    private final EntityManager em;

    public List<OrderQueryDTO> findOrderQueryDtos() {

        // order 에 대한 결괏값을 출력한다.
        final List<OrderQueryDTO> result = findOrders();

        // 필드에 대한 dto는 jpql에서 바로 생성할 수 없다. 반복문을 통하여 orderItem을 꺼낸다.
        result.forEach(orderQueryDTO -> {
            List<OrderItemQueryDto> orderItems = findOrderItems(orderQueryDTO.getOrderId());
            orderQueryDTO.setOrderItems(orderItems);
        });

        return result;
    }

    private List<OrderQueryDTO> findOrders() {
        final String query = "" +
                " select new jpabook.jpashop.repository.query.OrderQueryDTO(o.id, m.name, o.orderDate, o.status, d.address) " +
                " from Order o " +
                " join o.member m " +
                " join o.delivery d ";

        return em.createQuery(query, OrderQueryDTO.class)
                .getResultList();
    }

    private List<OrderItemQueryDto> findOrderItems(Long orderId) {
        final String query = "" +
                " select new jpabook.jpashop.repository.query.OrderItemQueryDto(oi.order.id, i.name, oi.orderPrice, oi.count) " +
                " from OrderItem oi " +
                " join oi.item i " +
                " where oi.order.id = :orderId ";

        return em.createQuery(query, OrderItemQueryDto.class)
                .setParameter("orderId", orderId)
                .getResultList();
    }
}
```

- 가장 먼저 Order에 대한 dto를 먼저 생성한다. `findOrders()`
- order 리스트를 반복문으로 동작하여, `findOrderItems(orderId)`를 통해 orderItem를 출력한다. xToMany의 쿼리의 한계를 인정하여, 반복문을 통해 쿼리한다. 
- order의 반복문에 의존하여 쿼리가 생성된다. 1 + n 문제가 발생한다. 

```sql
2022-02-13 21:01:42.374  INFO 6584 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 2 ms
2022-02-13 21:01:42.403 DEBUG 6584 --- [nio-8080-exec-1] org.hibernate.SQL                        : 
    select
        order0_.order_id as col_0_0_,
        member1_.name as col_1_0_,
        order0_.order_date as col_2_0_,
        order0_.status as col_3_0_,
        delivery2_.city as col_4_0_,
        delivery2_.street as col_4_1_,
        delivery2_.zipcode as col_4_2_ 
    from
        orders order0_ 
    inner join
        member member1_ 
            on order0_.member_id=member1_.member_id 
    inner join
        delivery delivery2_ 
            on order0_.delivery_id=delivery2_.delivery_id
2022-02-13 21:01:42.429 DEBUG 6584 --- [nio-8080-exec-1] org.hibernate.SQL                        : 
    select
        orderitem0_.order_id as col_0_0_,
        item1_.name as col_1_0_,
        orderitem0_.order_price as col_2_0_,
        orderitem0_.count as col_3_0_ 
    from
        order_item orderitem0_ 
    inner join
        item item1_ 
            on orderitem0_.item_id=item1_.item_id 
    where
        orderitem0_.order_id=?
2022-02-13 21:01:42.430 DEBUG 6584 --- [nio-8080-exec-1] org.hibernate.SQL                        : 
    select
        orderitem0_.order_id as col_0_0_,
        item1_.name as col_1_0_,
        orderitem0_.order_price as col_2_0_,
        orderitem0_.count as col_3_0_ 
    from
        order_item orderitem0_ 
    inner join
        item item1_ 
            on orderitem0_.item_id=item1_.item_id 
    where
        orderitem0_.order_id=?
```

## n+1 문제의 해소 : in 절 사용
- 앞서의 예제는 각 각의 orderItem 에 대하여 `orderItem.orderId =  orderId`로 처리하였다. 이를 `orderItem.orderId in(orderIds)` 로 변환한다. 엔티티의 batch 와 유사하다.
- 아래의 과정을 보면, 사실상 JPA의 기능을 다루기보다, 자바의 객체를 다루는 것과 유사하다. 다소 복잡하고 재미없는 코드를 구현한다. 

```java
public List<OrderQueryDTO> findAllByDto_optimization() {
    final List<OrderQueryDTO> result = findOrders();

    final List<Long> orderIds = result.stream().map(OrderQueryDTO::getOrderId).collect(Collectors.toList());

    // where orderid in (orderids) 로 in 처리를 한다. batch와 유사하다.
    final String query = "" +
            " select new jpabook.jpashop.repository.query.OrderItemQueryDto(oi.order.id, i.name, oi.orderPrice, oi.count) " +
            " from OrderItem oi " +
            " join oi.item i " +
            " where oi.order.id in :orderIds ";

    final List<OrderItemQueryDto> orderItems = em.createQuery(query, OrderItemQueryDto.class)
            .setParameter("orderIds", orderIds)
            .getResultList();

    // Collectors.groupingBy은 stream을 통해 List를 map으로 변환하는 코드이다. 인자의 전자는 value 이고 후자는 key 이다.
    final Map<Long, List<OrderItemQueryDto>> orderItemMap = orderItems.stream()
            .collect(Collectors.groupingBy(orderItemQueryDto -> orderItemQueryDto.getOrderId()));

    // 반복문을 통하여 order의 orderItem의 필드를 채운다. 
    result.forEach(orderQueryDTO -> orderQueryDTO.setOrderItems(orderItemMap.get(orderQueryDTO.getOrderId())));

    return result;
}
```

- 위의 쿼리를 보면, order의 결과물에서 orderId를 리스트로 추출한다. 이 리스트를 가지고 orderItem을 where in으로 출력한다. 
- 이로 출력한 `List<OrderItemQueryDto> orderItems` 은 order와 연관관계가 없다. 이를 map 형태로 변환하여, order 객체의 orderItem에 적합한 참조변수를 연결한다.
- 1+n이 1:1로 축소된다. 이전에 비하여 최적화가 상당하게 이뤄진다.

```sql
2022-02-13 21:15:09.926 DEBUG 3580 --- [nio-8080-exec-3] org.hibernate.SQL                        : 
    select
        order0_.order_id as col_0_0_,
        member1_.name as col_1_0_,
        order0_.order_date as col_2_0_,
        order0_.status as col_3_0_,
        delivery2_.city as col_4_0_,
        delivery2_.street as col_4_1_,
        delivery2_.zipcode as col_4_2_ 
    from
        orders order0_ 
    inner join
        member member1_ 
            on order0_.member_id=member1_.member_id 
    inner join
        delivery delivery2_ 
            on order0_.delivery_id=delivery2_.delivery_id
2022-02-13 21:15:09.927 DEBUG 3580 --- [nio-8080-exec-3] org.hibernate.SQL                        : 
    select
        orderitem0_.order_id as col_0_0_,
        item1_.name as col_1_0_,
        orderitem0_.order_price as col_2_0_,
        orderitem0_.count as col_3_0_ 
    from
        order_item orderitem0_ 
    inner join
        item item1_ 
            on orderitem0_.item_id=item1_.item_id 
    where
        orderitem0_.order_id in (
            ? , ?
        )
```

## flat데이터 추출을 통한 한방 쿼리
- 한방 쿼리를 만든다. 한방쿼리를 위한 DTO를 만든다. 그 내용은 아래의 코드와 같다. 

```java
public List<OrderFlatDto> findAllByDto_flat() {
    final String query = " " +
            " select new jpabook.jpashop.repository.query.OrderFlatDto(o.id, m.name, o.orderDate, o.status, d.address, i.name, oi.orderPrice, oi.count) " +
            " from Order o " +
            " join o.member m" +
            " join o.delivery d " +
            " join o.orderItems oi " +
            " join oi.item i ";

    return em.createQuery(query, OrderFlatDto.class).getResultList();
}
```

```json
[
    {
        "orderId": 4,
        "name": "userA",
        "orderDate": "2022-02-13T21:29:35.126366",
        "status": "ORDER",
        "address": {
            "city": "서울",
            "street": "1",
            "zipcode": "1111"
        },
        "itemName": "JPA1 BOOK",
        "orderPrice": 10000,
        "count": 1
    },
    {
        "orderId": 4,
        "name": "userA",
        "orderDate": "2022-02-13T21:29:35.126366",
        "status": "ORDER",
        "address": {
            "city": "서울",
            "street": "1",
            "zipcode": "1111"
        },
        "itemName": "JPA2 BOOK",
        "orderPrice": 20000,
        "count": 2
    },
    {
        "orderId": 11,
        "name": "userB",
        "orderDate": "2022-02-13T21:29:35.136361",
        "status": "ORDER",
        "address": {
            "city": "진주",
            "street": "2",
            "zipcode": "2222"
        },
        "itemName": "SPRING1 BOOK",
        "orderPrice": 20000,
        "count": 3
    },
    {
        "orderId": 11,
        "name": "userB",
        "orderDate": "2022-02-13T21:29:35.136361",
        "status": "ORDER",
        "address": {
            "city": "진주",
            "street": "2",
            "zipcode": "2222"
        },
        "itemName": "SPRING2 BOOK",
        "orderPrice": 40000,
        "count": 4
    }
]
```

```sql
2022-02-13 21:30:59.397 DEBUG 6820 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        order0_.order_id as col_0_0_,
        member1_.name as col_1_0_,
        order0_.order_date as col_2_0_,
        order0_.status as col_3_0_,
        delivery2_.city as col_4_0_,
        delivery2_.street as col_4_1_,
        delivery2_.zipcode as col_4_2_,
        item4_.name as col_5_0_,
        orderitems3_.order_price as col_6_0_,
        orderitems3_.count as col_7_0_ 
    from
        orders order0_ 
    inner join
        member member1_ 
            on order0_.member_id=member1_.member_id 
    inner join
        delivery delivery2_ 
            on order0_.delivery_id=delivery2_.delivery_id 
    inner join
        order_item orderitems3_ 
            on order0_.order_id=orderitems3_.order_id 
    inner join
        item item4_ 
            on orderitems3_.item_id=item4_.item_id
```

### 플랫데이터 정리
- 플랫데이터, 한방 쿼리는 사실 `select * from ... join ... join ...` 과 동일하다. many를 기준으로 레코드를 출력하며 one은 중복된다. 
- DTO가 변경되기 때문에 이전의 api와 스펙이 바뀐다. 만약 기존의 스펙(OrderQueryDTO)을 사용하고자 한다면, OrderFlatDto로부터 변환하는 로직을 구현한다.
- 페이징은 불가능하다. many인 orderItem을 기준으로 할 수 밖에 없다. 엔티티가 아니므로 JPA의 distinct를 사용할 수 없다. 
- join이 많다. 어플리케이션에서의 추가작업이 크다. 페이징이 one을 기준으로 불가능하다. 
- 장점은 '한방 쿼리' 이외에 없다.

## xToMany - 컬렉션 엔티티의 조회에 대한 정리
### 다양한 조회 방법
- 엔티티를 조회하여 dto로 변환하는 방법 혹은 처음부터 dto로 출력하는 방식으로 크게 나뉘어 진다. 
- 엔티티 조회의 경우 
    - xToOne 연관관계의 경우 fetch join 을 통해 최대한 데이터를 추출하고 페이징 처리 한다. 
    - 컬렉션인 xToMany에 대해서는 지연로딩과 배치를 통해 최적화 한다. 
- dto 조회의 경우
    - xToOne를 dto로 출력한다.
    - xToMany의 경우
        - 반복문을 통해 지연로딩 한다. 혹은,
        - in 절을 위한 쿼리를 구현한다. 그리고 xToOne DTO에 맵핑한다. 혹은,
        - flatDTO로 추출한다.

### 엔티티 조회 방식을 권장
- 엔티티 조회를 최대한 활용한다. jpa가 제공하는 fetch, batch를 통한 성능 최적화가 매우 강력하고 쉽다.
- dto 조회의 경우, 순수 쿼리를 짜는 것과 유사하며, 장황한 자바 로직을 요구한다. 코드 자체가 여러 모로 복잡해진다.
- 엔티티를 통한 조회로 사실상 거의 모든 문제를 해결할 수 있다. 엔티티 조회로 성능이 나오지 않는다면, 캐쉬(redis)나 기타 방식으로 접근하는 것을 추천. dto가 엔티티보다 성능이 좋음을 보장하지 않음.
    <!-- - 참고로 캐쉬 처리의 경우 영속성 컨텍스트의 2차 캐쉬는 사용하지 않음. redis로 사용하는데, 그 때 dto로 반드시 캐싱해야함. 엔티티를 저장할 경우 영속성 컨텍스트가 엉키는 경우가 있음.  -->

### 꼭 dto를 사용해야 한다면
- v4 혹은 v5를 사용한다. 
- v5가 v4보다 분명하게 성능이 좋다. 그러나 코드와 쿼리가 장황하다. 코드의 복잡성과 성능 사이에서 v4와 v5 중 하나를 선택한다. 
- v6는 사실상 사용하지 않는다. 기존의 dto 스펙과 큰 차이를 가진다. 페이징이 불가능하다. DB와 어플리케이션, 어플리케이션과 클라이언트 간 중복 데이터가 많다. 
- 결과적으로 v5 를 권장하며 편의에 따라 v4를 사용한다.