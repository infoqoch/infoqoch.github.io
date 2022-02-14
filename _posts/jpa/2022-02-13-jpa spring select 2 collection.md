---
layout: post
author: infoqoch
title: jpa, spring api의 entity 조회 최적화 2 - xToMany 연관관계와 엔티티 컬렉션 조회
categories: [jpa]
tags: [spring, jpa, rest]
---

## 들어가며
- xToOne 연관관계에 이어 xToMany 연관관계에서의 조회에 대한 최적화 방식을 정리한다.
- xToOne은 관계형데이타베이스의 입장에서 다의 입장을 가지며, 이는 한방 쿼리와 페이징 처리가 수월하다.
- xToMany는 일의 입장을 가지며, join을 수행할 경우 데이터 뻥튀기의 문제가 발생한다. 이로 인하여,
    - 페이징 처리가 어렵다. 페이징은 다의 입장에서 수행되기 때문이다. 
    - 한 방 쿼리가 사실상 불가능하다. 다의 입장에서 레코드를 출력하면 일의 데이터가 다의 칼럼에 중복되어 출력된다. 깔끔하게 떨어지는 쿼리를 만들기 어렵다.

- 이에 대한 해결책으로
    - 엔티티로 출력할 때는, xToOne에 대해서는 fetch 로 한 방 쿼리를 만들고, xToMany에 대해서는 batch를 통한 in 절 사용으로 최적화한다.
    - dto로 출력할 때는, 쿼리의 최소화와 자바 코드의 복잡성 사이에 적절한 선택을 통해 해소한다.
- 지금 블로그는 컬렉션 엔티티의 출력에 대한 내용을 다루며, 다음 블로그는 dto의 출력에 대하여 다룬다.

## Entity를 직접 노출하는 방식
- Lazy 로딩이므로 프록시가 리턴된다. 이를 방지하기 위하여 Hibernate5Module 을 빈으로 등록한다. 
- 이 방식은 다양한 문제를 가지며, 이에 관련한 내용은 앞서의 블로그에 정리하였다. 

```java
@GetMapping("/api/v1/orders")
public List<Order> ordersV1(){
    final List<Order> all = orderRepository.findAllByString(new OrderSearch());

    // 프록시 초기화를 위함.
    // Modul5는 빈에 등록되어 있음.
    // Order 객체에서는 json을 허용하고, Order에 대한 ManyToOne 객체에는 모든 order에 @JsonIgnore를 하였음.
    for (Order order : all) {
        order.getMember().getName();
        order.getDelivery().getAddress();
        final List<OrderItem> orderItems = order.getOrderItems();
        orderItems.forEach(o->o.getItem().getName());
    }
    return all;
}
```

## entity를 DTO로 전환
### entity collection 의 wrapping
- dto로 전환한다.
- dto의 컬렉션 필드는 엔티티를 직접 받는다.

```java
@GetMapping("/api/v2/orders")
public List<OrderDto> ordersV2(){
    final List<Order> all = orderRepository.findAllByString(new OrderSearch());

    final List<OrderDto> collect = all.stream().map(order -> new OrderDto(order)).collect(Collectors.toList());

    return collect;
}

@Data
static class OrderDto {
    private Long orderId;
    private String name;
    private LocalDateTime orderDate;
    private OrderStatus orderStatus;
    private Address address;

    private List<OrderItem> orderItems;

    public OrderDto(Order order) {
        // 모든 연관관계는 지연로딩으로 처리되어 있다. 객체 그래프의 탐색으로 엔티티를 초기화한다. 트랜잭션 밖에지만 조회가 가능하다. 왜냐하면 open session in view 라는 기능을 스프링에서 제공하기 때문이다. 만약 그 기능을 끈다면 컨트롤러에서는 더는 객체 그래프로 엔티티를 초기화 할 수 없어 조회 불가능하다.
        orderId = order.getId();
        name = order.getMember().getName();
        orderDate = order.getOrderDate();
        orderStatus = order.getStatus();
        address = order.getMember().getAddress();;

        order.getOrderItems().stream().forEach(orderItem -> orderItem.getItem().getName()); // open session in view 이 동작하여 프록시를 초기화 한다.
        orderItem = order.getOrderItems();
    }
}
```

- dto 가 orderItems의 엔티티를 필드로 가진다. 이 경우 문제가 발생한다. api의 스펙이 entity에 의존하게 된다. 엔티티를 리턴할 때와 동일한 문제에 봉착한다. 모든 entity를 dto로 변환해야 한다. 
- 모든 엔티티를 dto로 변경한 코드는 아래와 같다. 

### dto의 필드를 포함한 엔티티를 dto로 변환한다.

```java
@Data
static class OrderDto {
    private Long orderId;
    private String name;
    private LocalDateTime orderDate;
    private OrderStatus orderStatus;
    private Address address;

//        private List<OrderItem> orderItems;

    private List<OrderItemDto> orderItems;

    public OrderDto(Order order) {
        orderId = order.getId();
        name = order.getMember().getName();
        orderDate = order.getOrderDate();
        orderStatus = order.getStatus();
        address = order.getMember().getAddress();       
        
//            order.getOrderItems().stream().forEach(orderItem -> orderItem.getItem().getName()); // 영속성 자체에 대한 의존성을 완전하게 끊어내야 한다.
        orderItems = order.getOrderItems().stream().map(orderItem -> new OrderItemDto(orderItem)).collect(Collectors.toList());
    }
}

@Data
static class OrderItemDto{
    private String itemName;
    private int orderPrice;
    private int count;


    public OrderItemDto(OrderItem orderItem) {
        itemName = orderItem.getItem().getName();
        orderPrice = orderItem.getOrderPrice();
        count = orderItem.getCount();
    }
}
```

- sql 은 아래와 같다. 엄청나게 많이 발생함을 확인할 수 있다. 

```sql
2022-02-13 17:36:51.205 DEBUG 11160 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        order0_.order_id as order_id1_6_,
        order0_.delivery_id as delivery4_6_,
        order0_.member_id as member_i5_6_,
        order0_.order_date as order_da2_6_,
        order0_.status as status3_6_ 
    from
        orders order0_ 
    inner join
        member member1_ 
            on order0_.member_id=member1_.member_id limit ?
2022-02-13 17:36:51.209 DEBUG 11160 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        member0_.member_id as member_i1_4_0_,
        member0_.city as city2_4_0_,
        member0_.street as street3_4_0_,
        member0_.zipcode as zipcode4_4_0_,
        member0_.name as name5_4_0_ 
    from
        member member0_ 
    where
        member0_.member_id=?
2022-02-13 17:36:51.211 DEBUG 11160 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        orderitems0_.order_id as order_id5_5_0_,
        orderitems0_.order_item_id as order_it1_5_0_,
        orderitems0_.order_item_id as order_it1_5_1_,
        orderitems0_.count as count2_5_1_,
        orderitems0_.item_id as item_id4_5_1_,
        orderitems0_.order_id as order_id5_5_1_,
        orderitems0_.order_price as order_pr3_5_1_ 
    from
        order_item orderitems0_ 
    where
        orderitems0_.order_id=?
2022-02-13 17:36:51.212 DEBUG 11160 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        item0_.item_id as item_id2_3_0_,
        item0_.name as name3_3_0_,
        item0_.price as price4_3_0_,
        item0_.stock_quantity as stock_qu5_3_0_,
        item0_.artist as artist6_3_0_,
        item0_.etc as etc7_3_0_,
        item0_.author as author8_3_0_,
        item0_.isbn as isbn9_3_0_,
        item0_.actor as actor10_3_0_,
        item0_.director as directo11_3_0_,
        item0_.dtype as dtype1_3_0_ 
    from
        item item0_ 
    where
        item0_.item_id=?
2022-02-13 17:36:51.213 DEBUG 11160 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        item0_.item_id as item_id2_3_0_,
        item0_.name as name3_3_0_,
        item0_.price as price4_3_0_,
        item0_.stock_quantity as stock_qu5_3_0_,
        item0_.artist as artist6_3_0_,
        item0_.etc as etc7_3_0_,
        item0_.author as author8_3_0_,
        item0_.isbn as isbn9_3_0_,
        item0_.actor as actor10_3_0_,
        item0_.director as directo11_3_0_,
        item0_.dtype as dtype1_3_0_ 
    from
        item item0_ 
    where
        item0_.item_id=?
2022-02-13 17:36:51.214 DEBUG 11160 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        member0_.member_id as member_i1_4_0_,
        member0_.city as city2_4_0_,
        member0_.street as street3_4_0_,
        member0_.zipcode as zipcode4_4_0_,
        member0_.name as name5_4_0_ 
    from
        member member0_ 
    where
        member0_.member_id=?
2022-02-13 17:36:51.214 DEBUG 11160 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        orderitems0_.order_id as order_id5_5_0_,
        orderitems0_.order_item_id as order_it1_5_0_,
        orderitems0_.order_item_id as order_it1_5_1_,
        orderitems0_.count as count2_5_1_,
        orderitems0_.item_id as item_id4_5_1_,
        orderitems0_.order_id as order_id5_5_1_,
        orderitems0_.order_price as order_pr3_5_1_ 
    from
        order_item orderitems0_ 
    where
        orderitems0_.order_id=?
2022-02-13 17:36:51.216 DEBUG 11160 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        item0_.item_id as item_id2_3_0_,
        item0_.name as name3_3_0_,
        item0_.price as price4_3_0_,
        item0_.stock_quantity as stock_qu5_3_0_,
        item0_.artist as artist6_3_0_,
        item0_.etc as etc7_3_0_,
        item0_.author as author8_3_0_,
        item0_.isbn as isbn9_3_0_,
        item0_.actor as actor10_3_0_,
        item0_.director as directo11_3_0_,
        item0_.dtype as dtype1_3_0_ 
    from
        item item0_ 
    where
        item0_.item_id=?
2022-02-13 17:36:51.217 DEBUG 11160 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        item0_.item_id as item_id2_3_0_,
        item0_.name as name3_3_0_,
        item0_.price as price4_3_0_,
        item0_.stock_quantity as stock_qu5_3_0_,
        item0_.artist as artist6_3_0_,
        item0_.etc as etc7_3_0_,
        item0_.author as author8_3_0_,
        item0_.isbn as isbn9_3_0_,
        item0_.actor as actor10_3_0_,
        item0_.director as directo11_3_0_,
        item0_.dtype as dtype1_3_0_ 
    from
        item item0_ 
    where
        item0_.item_id=?
```

## fetch join
### fetch join 의 사용
- fetch join으로 최적화 한다. 

```java
public List<Order> findAllWithItem() {
    final String query = "" +
            " select o " +
            " from Order o " +
            " join fetch o.member m " +
            " join fetch o.delivery d " +
            " join fetch o.orderItems oi " +
            " join fetch oi.item i";
    return em.createQuery(query, Order.class).getResultList();
}
```

- sql은 아래와 같다.
- 이전과 달리, 단 한 번의 쿼리로 해결된다!

```sql
2022-02-13 17:45:01.788 DEBUG 11160 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        order0_.order_id as order_id1_6_0_,
        member1_.member_id as member_i1_4_1_,
        delivery2_.delivery_id as delivery1_2_2_,
        orderitems3_.order_item_id as order_it1_5_3_,
        item4_.item_id as item_id2_3_4_,
        order0_.delivery_id as delivery4_6_0_,
        order0_.member_id as member_i5_6_0_,
        order0_.order_date as order_da2_6_0_,
        order0_.status as status3_6_0_,
        member1_.city as city2_4_1_,
        member1_.street as street3_4_1_,
        member1_.zipcode as zipcode4_4_1_,
        member1_.name as name5_4_1_,
        delivery2_.city as city2_2_2_,
        delivery2_.street as street3_2_2_,
        delivery2_.zipcode as zipcode4_2_2_,
        delivery2_.status as status5_2_2_,
        orderitems3_.count as count2_5_3_,
        orderitems3_.item_id as item_id4_5_3_,
        orderitems3_.order_id as order_id5_5_3_,
        orderitems3_.order_price as order_pr3_5_3_,
        orderitems3_.order_id as order_id5_5_0__,
        orderitems3_.order_item_id as order_it1_5_0__,
        item4_.name as name3_3_4_,
        item4_.price as price4_3_4_,
        item4_.stock_quantity as stock_qu5_3_4_,
        item4_.artist as artist6_3_4_,
        item4_.etc as etc7_3_4_,
        item4_.author as author8_3_4_,
        item4_.isbn as isbn9_3_4_,
        item4_.actor as actor10_3_4_,
        item4_.director as directo11_3_4_,
        item4_.dtype as dtype1_3_4_ 
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

- 다만, 레코드의 뻥튀기 문제가 발생한다. json의 응답값은 아래와 같다. 동일한 값이 두 번 반복된다. 
- 관계형 데이타베이스와 jpa 간 패러다임의 간격으로 인한 문제가 발생한다.
- order를 기준으로 데이터를 꺼낸다. order은 one이며 join 된 데이터는 many(orderItem, item)이다. 관계형 데이터베이스는 데이터의 출력 기준이 order라 하더라도 하나의 order에 연결된 many의 레코드가 여러 개이면, many의 갯수에 의존하여 one이 반복 출력된다. 
- jpa의 출력 결과는 기본적으로 관계형 데이타베이스의 쿼리에 의존한다. 그 결과는 아래와 같다. 

```json
[
    {
        "orderId": 4,
        "name": "userA",
        "orderDate": "2022-02-13T17:44:51.037102",
        "orderStatus": "ORDER",
        "address": {
            "city": "서울",
            "street": "1",
            "zipcode": "1111"
        },
        "orderItems": [
            {
                "itemName": "JPA1 BOOK",
                "orderPrice": 10000,
                "count": 1
            },
            {
                "itemName": "JPA2 BOOK",
                "orderPrice": 20000,
                "count": 2
            }
        ]
    },
    {
        "orderId": 4,
        "name": "userA",
        "orderDate": "2022-02-13T17:44:51.037102",
        "orderStatus": "ORDER",
        "address": {
            "city": "서울",
            "street": "1",
            "zipcode": "1111"
        },
        "orderItems": [
            {
                "itemName": "JPA1 BOOK",
                "orderPrice": 10000,
                "count": 1
            },
            {
                "itemName": "JPA2 BOOK",
                "orderPrice": 20000,
                "count": 2
            }
        ]
    },
    {
        "orderId": 11,
        "name": "userB",
        "orderDate": "2022-02-13T17:44:51.042109",
        "orderStatus": "ORDER",
        "address": {
            "city": "진주",
            "street": "2",
            "zipcode": "2222"
        },
        "orderItems": [
            {
                "itemName": "SPRING1 BOOK",
                "orderPrice": 20000,
                "count": 3
            },
            {
                "itemName": "SPRING2 BOOK",
                "orderPrice": 40000,
                "count": 4
            }
        ]
    },
    {
        "orderId": 11,
        "name": "userB",
        "orderDate": "2022-02-13T17:44:51.042109",
        "orderStatus": "ORDER",
        "address": {
            "city": "진주",
            "street": "2",
            "zipcode": "2222"
        },
        "orderItems": [
            {
                "itemName": "SPRING1 BOOK",
                "orderPrice": 20000,
                "count": 3
            },
            {
                "itemName": "SPRING2 BOOK",
                "orderPrice": 40000,
                "count": 4
            }
        ]
    }
]
```

- 컨트롤러에 List<Order> 를 로그로 찍어보면 아래와 같이 나온다. 동일한 엔티티가 반복됨을 확인할 수 있다. 

```java
for (Order order : all) {
    log.info("order = " + order);
    log.info("order.getId() = " + order.getId());
}
```

```log
order = jpabook.jpashop.domain.Order@7b4be4ce
order.getId() = 4
order = jpabook.jpashop.domain.Order@7b4be4ce
order.getId() = 4
order = jpabook.jpashop.domain.Order@79415a8a
order.getId() = 11
order = jpabook.jpashop.domain.Order@79415a8a
order.getId() = 11
```

### distinct 의 사용
- 이를 해소하기 위하여 distinct를 사용한다. distinct는 **엔티티 입장에서** 중복을 제거한다. 관계형 데이터베이스의 distinct와 jpa의 distinct는 다르다.
- 관계형 데이터베이스는 단 하나의 칼럼이라도 다르면 distinct가 동작하지 않는다. 하지만 jpa에게 distinct는 one의 입장에서 중복을 제거한다. 그러니까 order 객체의 중복이 제거된다. 

```java
public List<Order> findAllWithItem() {
    final String query = "" +
            " select distinct o " +
            " from Order o " +
            " join fetch o.member m " +
            " join fetch o.delivery d " +
            " join fetch o.orderItems oi " +
            " join fetch oi.item i";
    return em.createQuery(query, Order.class).getResultList();
}
```

```sql
2022-02-13 17:58:37.868 DEBUG 9812 --- [nio-8080-exec-3] org.hibernate.SQL                        : 
    select
        distinct order0_.order_id as order_id1_6_0_, -- 쿼리에 distinct를 사용한다. 하지만 레코드의 값(orderItem, item)이 다르기 때문에 사실상 distinct 가 먹지 않는다. 
        member1_.member_id as member_i1_4_1_,
        delivery2_.delivery_id as delivery1_2_2_,
        orderitems3_.order_item_id as order_it1_5_3_,
        item4_.item_id as item_id2_3_4_,
        order0_.delivery_id as delivery4_6_0_,
        order0_.member_id as member_i5_6_0_,
        order0_.order_date as order_da2_6_0_,
        order0_.status as status3_6_0_,
        member1_.city as city2_4_1_,
        member1_.street as street3_4_1_,
        member1_.zipcode as zipcode4_4_1_,
        member1_.name as name5_4_1_,
        delivery2_.city as city2_2_2_,
        delivery2_.street as street3_2_2_,
        delivery2_.zipcode as zipcode4_2_2_,
        delivery2_.status as status5_2_2_,
        orderitems3_.count as count2_5_3_,
        orderitems3_.item_id as item_id4_5_3_,
        orderitems3_.order_id as order_id5_5_3_,
        orderitems3_.order_price as order_pr3_5_3_,
        orderitems3_.order_id as order_id5_5_0__,
        orderitems3_.order_item_id as order_it1_5_0__,
        item4_.name as name3_3_4_,
        item4_.price as price4_3_4_,
        item4_.stock_quantity as stock_qu5_3_4_,
        item4_.artist as artist6_3_4_,
        item4_.etc as etc7_3_4_,
        item4_.author as author8_3_4_,
        item4_.isbn as isbn9_3_4_,
        item4_.actor as actor10_3_4_,
        item4_.director as directo11_3_4_,
        item4_.dtype as dtype1_3_4_ 
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

- 객체가 두 개만 출력됨을 확인할 수 있다. 4개의 레코드를 두 개의 엔티티로 jpa가 전환한다.

```log
order = jpabook.jpashop.domain.Order@65124dda
order.getId() = 4
order = jpabook.jpashop.domain.Order@7df59680
order.getId() = 11
```

### fetch join 의 페이징 처리의 한계
- 하나의 쿼리로 해결하기 때문에 DB와의 통신 횟수로 인한 최적화가 가능하다.
- 다만 치명적인 단점이 있다. **페이징 처리가 안된다**.

```java
public List<Order> findAllWithItem() {
    final String query = "" +
            " select distinct o " +
            " from Order o " +
            " join fetch o.member m " +
            " join fetch o.delivery d " +
            " join fetch o.orderItems oi " +
            " join fetch oi.item i";
    return em.createQuery(query, Order.class)
            .setFirstResult(1)
            .setMaxResults(100)
            .getResultList();
}
```

- limit 이 없다. 
- 모든 데이터를 가지고 온 다음 메모라 차원에서 페이징한다. `firstResult/maxResults specified with collection fetch; applying in memory!`. 오더의 레코드가 엄청 많다면, 성능 상 매우 큰 문제가 발생한다.
- 관계형 데이타베이스를 기준으로 order를 페이징할 수 없다. 관계형 데이타베이스를 기준으로, item 과 orderItem 기준으로 레코드가 발생하며 이를 기준으로 페이징이 가능하다. order 입장에서의 페이징을 할 기준이 존재하지 않기 때문이다. 
- 추가적으로 jpa의 한계가 존재한다. xToMany에서 join fetch를 할 경우 데이터 정합성의 문제가 발생한다고 한다.


```sql
2022-02-13 19:30:00.999  WARN 9812 --- [nio-8080-exec-2] o.h.h.internal.ast.QueryTranslatorImpl   : HHH000104: firstResult/maxResults specified with collection fetch; applying in memory!
2022-02-13 19:30:00.999 DEBUG 9812 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        distinct order0_.order_id as order_id1_6_0_,
        member1_.member_id as member_i1_4_1_,
        delivery2_.delivery_id as delivery1_2_2_,
        orderitems3_.order_item_id as order_it1_5_3_,
        item4_.item_id as item_id2_3_4_,
        order0_.delivery_id as delivery4_6_0_,
        order0_.member_id as member_i5_6_0_,
        order0_.order_date as order_da2_6_0_,
        order0_.status as status3_6_0_,
        member1_.city as city2_4_1_,
        member1_.street as street3_4_1_,
        member1_.zipcode as zipcode4_4_1_,
        member1_.name as name5_4_1_,
        delivery2_.city as city2_2_2_,
        delivery2_.street as street3_2_2_,
        delivery2_.zipcode as zipcode4_2_2_,
        delivery2_.status as status5_2_2_,
        orderitems3_.count as count2_5_3_,
        orderitems3_.item_id as item_id4_5_3_,
        orderitems3_.order_id as order_id5_5_3_,
        orderitems3_.order_price as order_pr3_5_3_,
        orderitems3_.order_id as order_id5_5_0__,
        orderitems3_.order_item_id as order_it1_5_0__,
        item4_.name as name3_3_4_,
        item4_.price as price4_3_4_,
        item4_.stock_quantity as stock_qu5_3_4_,
        item4_.artist as artist6_3_4_,
        item4_.etc as etc7_3_4_,
        item4_.author as author8_3_4_,
        item4_.isbn as isbn9_3_4_,
        item4_.actor as actor10_3_4_,
        item4_.director as directo11_3_4_,
        item4_.dtype as dtype1_3_4_ 
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

- 결론적으로, **join fetch로 페이징을 하면 안된다!!**.

## xToMany 는 fetch join을 쓰지 않는다. lazy loading과 batch를 선택한다.
- 관계형 데이타베이스에서는 many를 기준으로 row가 생성된다. 우리는 one을 기준으로 페이징을 하고 싶다. 
- 코드도 단순하고 성능도 해소할 수 있는 batch를 활용한다. 사실 이것 이외의 다른 대안이 없다고 한다. 

### 페이징 처리의 방향
- 1) xToOne 관계는 fetch join을 한다. xToOne 만 존재하는 쿼리에서는 fetch join을 여러 번 사용하더라도 페이징에 전혀 문제가 없다. 이를 기준으로 먼저 페이징 한다. 
- 2) xToMany의 데이터는 따로 쿼리한다. 지연로딩(lazy loading)과 batch를 사용하여 엔티티를 초기화한다.

### 코드
- 배치를 위하여 아래와 같이 설정한다. 

```yml
spring:
  jpa:
    properties:
      hibernate:
        default_batch_fetch_size: 100
```


- 컨트롤러

```java
@GetMapping("/api/v3.1/orders")
public List<OrderDto> ordersV3_lazyAndBatch(
        @RequestParam(value = "offset", defaultValue = "0") int offset,
        @RequestParam(value = "limit", defaultValue = "100") int limit){

    // xToMany의 fetch join을 가져온다.
    final List<Order> all = orderRepository.findAllWithMemberDelivery(offset, limit);


    // 지연로딩과 함께 dto를 생성한다.
    final List<OrderDto> collect = all.stream()
            .map(order -> new OrderDto(order))
            .collect(Collectors.toList());

    return collect;
}
```

- 리포지토리

```java
public List<Order> findAllWithMemberDelivery(int offset, int limit) {
    final String query = "" +
            "select o " +
            "from Order o " +
            "join fetch o.member m " +
            "join fetch o.delivery d ";

    return em.createQuery(query, Order.class)
            .setFirstResult(offset)
            .setMaxResults(limit)
            .getResultList();
}
```
- 주문과 고객은 1:다 관계이다. 주문과 배송은 1:1 관계이다. 이 세 개의 엔티티는 fetch join 으로 출력한다. 그리고 페이징 처리를 이 때 수행한다. 
- `new OrderDto(order)` 에서 객체 그래프를 사용하여 엔티티를 초기화한다. batch로 인하여 단 건마다 쿼리하지 않고 한 번에 처리한다. 
- 그 결과는 아래와 같다. 

```sql
2022-02-13 19:52:53.681 DEBUG 13436 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        order0_.order_id as order_id1_6_0_,
        member1_.member_id as member_i1_4_1_,
        delivery2_.delivery_id as delivery1_2_2_,
        order0_.delivery_id as delivery4_6_0_,
        order0_.member_id as member_i5_6_0_,
        order0_.order_date as order_da2_6_0_,
        order0_.status as status3_6_0_,
        member1_.city as city2_4_1_,
        member1_.street as street3_4_1_,
        member1_.zipcode as zipcode4_4_1_,
        member1_.name as name5_4_1_,
        delivery2_.city as city2_2_2_,
        delivery2_.street as street3_2_2_,
        delivery2_.zipcode as zipcode4_2_2_,
        delivery2_.status as status5_2_2_ 
    from
        orders order0_ 
    inner join
        member member1_ 
            on order0_.member_id=member1_.member_id 
    inner join
        delivery delivery2_ 
            on order0_.delivery_id=delivery2_.delivery_id limit ?
2022-02-13 19:52:53.701 DEBUG 13436 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        orderitems0_.order_id as order_id5_5_1_,
        orderitems0_.order_item_id as order_it1_5_1_,
        orderitems0_.order_item_id as order_it1_5_0_,
        orderitems0_.count as count2_5_0_,
        orderitems0_.item_id as item_id4_5_0_,
        orderitems0_.order_id as order_id5_5_0_,
        orderitems0_.order_price as order_pr3_5_0_ 
    from
        order_item orderitems0_ 
    where
        orderitems0_.order_id in (
            ?, ?
        )
2022-02-13 19:52:53.714 DEBUG 13436 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        item0_.item_id as item_id2_3_0_,
        item0_.name as name3_3_0_,
        item0_.price as price4_3_0_,
        item0_.stock_quantity as stock_qu5_3_0_,
        item0_.artist as artist6_3_0_,
        item0_.etc as etc7_3_0_,
        item0_.author as author8_3_0_,
        item0_.isbn as isbn9_3_0_,
        item0_.actor as actor10_3_0_,
        item0_.director as directo11_3_0_,
        item0_.dtype as dtype1_3_0_ 
    from
        item item0_ 
    where
        item0_.item_id in (
            ?, ?, ?, ?
        )
```

- 코드로 작성하기 어려운 최적화를 아주 간단하게 처리해준다. batch 설정만 하면 해결된다. 
- fetch join 한 번, orderItem, item 에 대한 3 번의 쿼리만 발생한다. 1:n:n 이 1:1:1이 되었다. 
- 지연로딩과 배치를 통한 방식의 장점은 매우 크다. 페이징이 가능하며, 중복된 데이터가 없다. 
- 이정도까지 최적화를 하면, 거의 대부분의 문제가 해소된다. 

### [추가] fetch join을 아예 사용하지 않는다면?
- 아래와 같이 Order만 쿼리한다.
- 이 경우 member, delivery 가 추가적인 배치 조인으로 동작한다. order, member, delivery, orderItem, item 에 대하여 총 5개의 조인이 발생한다. 
- 가능한 최대한의 엔티티를 fetch join을 한다. 그리고 불가능한 부분에서 lazy + batch 를 사용한다. 

``` java
final String query = "" +
        "select o " +
        "from Order o " +
        // "join fetch o.member m " +
        // "join fetch o.delivery d ";
```

### lazy + batch 정리
- batch는 n+1의 문제를 1+1로 바꿔버린다.
- 다만, 쿼리 호출수가 fetch join보다 많다. 한 방 쿼리가 아니다. 
- fetch join과 달리 페이징이 가능하다.
- 결론은,
    - xToOne은 한 번에 fetch join을 사용하며, 이때 페이징을 한다. 그 다음에,
    - xToMany 객체에 대하여 지연로딩 + batch 로 해결한다. 

### batch size는?
- batch 의 최대 갯수는 기본적으로 1000 개이다. DB의 in 절의 인자의 갯수가 1000개인 DB가 있기 때문이다.
- 다만, 1000개는 어플리케이션과 DB 모두에게 큰 영향이 갈 수 있다. 100개를 할 경우 시간을 더 걸리는 대신 부하가 줄어든다. 
- 권장하는 내용은 최대치(1000개)이다. 만약 부하가 우려된다면, 최소한 100개를 기준으로 차차 올린다.
- 다만, was의 메모리 입장에서는 어떤 방식이나 별 차이가 없다. 왜냐하면 메모리 사용량은 어플리케이션에서 요청한 갯수에 의존한다. 이것은 배치 사이즈와 관계 없이 언제나 같다. 이 부분이 걱정이라면 로직 자체에서 필요로 한 갯수를 줄어야 한다. 
- 사실상 이러한 전략으로 거의 대부분의 문제를 해소할 수 있다. 
