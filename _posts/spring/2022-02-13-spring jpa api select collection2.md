---
layout: post
author: infoqoch
title: spring, jpa api의 entity collection 조회 최적화2 (dto로 리턴)
categories: [spring]
tags: [spring, jpa, rest]
---

## 들어가며
- xToMany 컬렉션의 데이터 조회와 관련하여, 앞서의 블로그는 entity를 DB에서 출력했다. 그리고 어플리케이션에서 entity 를 dto로 변환한다.
- 아래의 방식은 쿼리에서부터 dto의 값을 호출하고 바로 dto 객체를 반환한다. 

## dto로 db에서 출력하기
- 프레젠테이션에 의존하는 dto 쿼리는 별도의 리포지토리로 분리한다.
- select 절에서 new SomethingDto() 를 사용해야 한다. 하지만 dto의 dto를 한 번 더 생성할 수 없다. 그러므로 반복문을 통해 해당 데이터는 따로 추출해야 한다. 전자는 order를 꺼내고 후자는 orderItem을 꺼낸다.

- 컨트롤러
 
```java
@GetMapping("/api/v4/orders")
public List<OrderQueryDTO> ordersV4(){
    return orderQueryRepository.findOrderQueryDtos();
}
```

- query 패키지를 생성하였고, repository를 엔티티를 repository와 분리한다.  OrderItemQueryDto, OrderQueryDto를 따로 만들었다. 

```java
@Repository
@RequiredArgsConstructor
public class OrderQueryRepository {
    private final EntityManager em;

    public List<OrderQueryDTO> findOrderQueryDtos() {
        final List<OrderQueryDTO> result = findOrders();

        // 필드에 대한 dto는 jpql에서 바로 생성할 수 없다. 반복문을 통하여 꺼내와야 한다.
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
- order를 반복문을 돌려서, `findOrderItems(orderId)` 로, dto를 추출하여, `setOrderItem(dtos);`로 마무리한다. xToMany의 쿼리의 한계를 인정하여 반복문을 선택함.
- 다만 `findOrderItems()`를 동작할 때마다 select 쿼리가 발생한다. order에 대해선 1번만 실행되고 orderItem 에 대하여 n 번이 발생한다. n+1 문제가 발생한다. 

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

## 필드 dto에 대한 in 을 사용하기
- 앞서의 예제는 각 각의 orderItem 에 대하여 `orderItem.orderId =  orderId`로 처리하였다. 이를 `orderItem.orderId in(orderIds)` 로 변환한다.
- 변환의 과정은 사실상 자바를 다루는 것과 거의 유사하다. 짙은 자바의 향기를 느낀다.

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
- 이로 출력한 `List<OrderItemQueryDto> orderItems` 은 order와 연관관계가 없다. 이를 map 형태로 변환하여 참조변수를 연결하면 된다. 
- 이를 통해 쿼리를 두 번 사용한다. order와 orderitem을 쿼리한다. 후자는 in을 사용한다. 

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


## DTO의 변환의 쿼리 최적화, flat데이터 추출
- 한방 쿼리를 만든다. 한방쿼리를 위한 DTO를 만든다. 
- DTO가 변경되기 때문에 이전의 api와 스펙이 바뀐다. 만약 기존의 스펙(OrderQueryDTO)을 사용하려면 OrderFlatDto를 변환하는 로직을 짜면 된다. 이 내용은 생략한다. 
- many를 기준으로 출력한다. orderItem을 기준으로 order가 배치된다. 그러니까 order 입장에서는 중복 데이터가 발생한다.
- 페이징을 할 경우 orderItem을 기준으로 한다. 그러므로 사실상 페이징을 할 수 없다. 

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
- 하나의 쿼리를 만든다.
- join이 많다. 어플리케이션에서의 추가작업이 크다. 페이징이 one을 기준으로 불가능하다. 



## xToMany, 컬렉션 엔티티의 select에 대한 총 정리
### 다양한 방법들
- 엔티티를 조회하여 dto로 변환하는 방법과 처음부터 dto로 출력하는 방식으로 크게 나뉘어 진다. 
- 엔티티 조회의 경우 
    - xToOne 연관관계의 경우, fetch join 을 통해 최대한 데이터를 추출하고 페이징 처리 한다. 
    - 컬렉션인 xToMany에 대해서는 지연로딩과 배치를 통해 최적화 한다. 
- dto 조회의 경우
    - xToOne의 경우 쿼리 한 번으로 쉽게 select 가능하다.
    - xToMany의 경우 in 절을 사용하려 메모리에 로딩을 한 다음 xToOne과 연결하는 방식으로 한다. 
    - 혹은 flatDTO로 추출한 다음 원하는 DTO로 다시 변경한다. 

### 권장 : 엔티티 조회 방식을 권장
- 엔티티 조회를 최대한 활용한다. 
- fetch, batch 를 통해 성능 최적화의 가능성이 많음. 
- dto 방식의 경우 생짜 쿼리를 짜는 것과 같으며, 성능에 따른 최적화는 쿼리 자체를 변경하는 방식임. 복잡함.
- 엔티티를 통한 조회로 사실상 거의 모든 문제를 해결할 수 있다. 엔티티 조회로 성능이 나오지 않는다면, 캐쉬(redis)나 기타 방식으로 접근하지, dto로 변경하여 해결하는 경우도 사실상 많지 않음. 
    - 참고로 캐쉬 처리의 경우 영속성 컨텍스트의 2차 캐쉬는 사용하지 않음. redis로 사용하는데, 그 때 dto로 반드시 캐싱해야함. 엔티티를 저장할 경우 영속성 컨텍스트가 엉키는 경우가 있음. 

### 만약 dto를 쓴다면...
- 성능 최적호와 코드 복잡도, 둘 중 하나를 선택해야 할 때, 무엇을 선택해야 하는가?
- sql 최적화를 할 때, jpa fetch join이나 batch 와 유사한 형태의 쿼리를 짜는 것으로 해결함. 일종의 객체지향이라는 패러다임으로서의 jpa를 선택하지만, 동시에 성능 최적화를 위한 쿼리를 jpa가 매우 간단하고 단순하게 생성한다. 코드가 단순하며 성능 최적화를 만든다. 
- dto의 경우 쿼리를 직접 짜는 것과 유사하다. 하지만 실제 성능 최적화가 되는지에 대한 의문이 있다. 

- v4는 many가 적을 때 사용한다. 
- v5는 many가 많을 때 사용한다. 성능이 v4 보다 월등할 가능성이 매우 높다. 다만, 로직 자체를 작성하는 품이 많이 든다. 특별하게 성능이 많이 오르지 않을 것으로 기대되는데 품을 쓸 이유는 없다. 
- v6은 쿼리 한 방으로의 최적화. 다만 이전의 방식과 전혀 다른 스펙임. 페이징 자체가 불가능. 애당초 많은 데이터를 추출할 경우 페이징이 필수인데 페이징을 사용할 수 없음. 네트워크로 전송할 중복 데이터 또한 많다. 그러므로 성능 최적화가 아닐 수 있다. 
- 그러므로 사실상 v5 방법을 선택한다. 그러나 batch 옵션 하나로 해결하는 방식과 다르지 않음. 