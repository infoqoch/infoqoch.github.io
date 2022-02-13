---
layout: post
author: infoqoch
title: jpa, spring api의 entity collection 조회 최적화 (xToMany 연관관계)
categories: [jpa]
tags: [spring, jpa, rest]
---

## Entity를 직접 노출하는 방식
- Lazy 로딩이므로 프록시가 리턴된다. 이를 방지하기 위하여 Hibernate5Module 을 빈으로 등록한다. 
- Order를 기준으로 Json을 리턴한다. 그러므로 order를 ManyToOne으로 가지는 모든 필드는 @JsonIgnore를 해야 한다. 
- 아래의 쿼리는 앞서 블로그와 동일한 문제를 가진다. 엔티티를 api의 리턴값으로 해서는 안된다.

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

- dto 가 orderItems의 엔티티를 필드로 가진다. 이 경우 문제가 발생한다. api의 스펙이 entity에 의존하게 된다. 모든 entity를 dto로 변환해야 한다. 
- 참고로, 컨트롤러에서 item 프록시를 엔티티로 초기화함을 볼 수 있다. 트랜잭션 밖이라도 객체 그래프로 엔티티를 초기화할 수 있는 기능을 스프링이 제공해준다. 이 기능의 이름을 'open session in view' 이라 한다. 
- 모든 엔티티를 dto로 변경한 코드는 아래와 같다. 

### 모든 엔티티를 dto로 변환한다.

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
        address = order.getMember().getAddress();;

        // orderItems 의 엔티티에 대하여 초기화해야 한다. 참고로, 트랜잭션 밖에지만 조회가 가능하다. 왜냐하면 open session in view 라는 기능을 스프링에서 제공하기 때문이다. 만약 그 기능을 끈다면 컨트롤러에서는 더는 객체 그래프로 엔티티를 초기화 할 수 없어 조회 불가능하다.
        // 그러므로 이 경우 영속 상태의 객체를 wrapping 한 상태로 볼 수 있다.
        // 영속성 자체에 대한 의존성을 완전하게 끊어내야 한다.

//            order.getOrderItems().stream().forEach(orderItem -> orderItem.getItem().getName());
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
- order를 기준으로 데이터를 꺼낸다. order은 many 이며 join 된 데이터는 one(orderItem, item)이다. 관계형 데이터베이스는 데이터의 출력 기준이 order라 하더라도 하나의 order에 연결된 one의 레코드가 여러 개이면, one의 갯수에 의존하여 order 가 반복 출력된다. 
- 이로 인하여 아래와 같은 결과값이 나온다. order는 두 개이지만 orderItem과 item 은 각 각 네 개이다. 
- jpa 네 개의 객체를 모두 반환한다. order 참조변수가 4개이며, 실제 메모리에는 2개의 객체가 있다.


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

```log file
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
- 이를 해소하기 위하여 distinct를 사용한다. distinct 는 **엔티티 입장에서** 중복을 제거한다. 
- 하지만 관계형 데이타베이스 입장에서의 쿼리는 차이가 없다. 그러니까 리턴된 값은 이미 뻥튀기 된 데이타이며, 자바 메모리에서 정리를 한다. 
- 참고로 관계형 데이타베이스에서 distinct를 통해 뻥튀기를 제거하려면, select 절에 걸린 모든 칼럼의 값이 동일할 때 제거가 된다. 그러므로 jpa의 입장에서 순수한 관계형 데이타베이스의 distinct 를 온전히 사용할 수 없다. 

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
- 하나의 쿼리로 해결하기 때문에 성능이 매우 좋아진다.
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
- 관계형 데이타베이스를 기준으로 order를 페이징할 수 없다. 왜냐하면 item 과 orderItem 기준으로 레코드가 발생하는데, 이를 기준으로는 페이징 가능하다. 하지만 order 입장에서의 페이징이 불가능하다.
- join fetch를 여러 개 할 경우 데이터 정합성의 문제가 발생한다. 만약 페이징을 하더라도 반드시 **join fetch를 하나**만 사용해야 한다. 


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


## xToMany 관계에 대하여 fetch join을 쓰지 않고 lazy loading과 batch를 활용
- 관계형 데이타베이스에서는 many를 기준으로 row가 생성된다. 우리는 one을 기준으로 페이징을 하고 싶다. 
- 그렇다고 모든 데이터를 지연로딩할 수 없다. 
- 코드도 단순하고 성능도 해소할 수 있는 batch를 활용한다. 사실 이것 이외의 다른 대안이 없다고 한다. 

### 페이징 처리의 방향
- 1) xToOne 관계는 fetch join을 한다. 그러니까 데이터가 뻥튀기가 되지 않는 쿼리의 경우, fetch join으로 페이징에 전혀 문제가 없다. 이를 기준으로 먼저 페이징한다!
- 2) fetch join을 할 수 없는 데이터, xToMany는 지연로딩(lazy loading)을 한다. 그리고 batch를 사용한다.

### 지연로딩 + batch

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

    final List<OrderDto> collect = all.stream()
            .map(order -> new OrderDto(order))
            .collect(Collectors.toList());

    return collect;
}
```

- 리포지토리
- fetch join 으로 페이징 가능한 xToOne 쿼리를 사용한다. 그리고 그 내부에서 페이징 처리 한다. 

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

- sql에서 in을 통해 한번에 땡겨온다. 
- 코드로 작성하기 어려운 최적화를 아주 간단하게 처리해준다. 
- fetch join 한 번, orderItem, item 에 대한 3 번의 쿼리만 발생한다. 1:n:n 이 1:1:1이 되었다. 
- 이정도까지 최적화를 하면, 거의 대부분의 문제가 해소된다. 

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

- 지연로딩과 배치를 통한 방식의 장점은 페이징의 가능여부와 함께, 중복된 데이터가 없다는 장점이 있다. 
- 1) fetch join을 통해 order를 필요로한 데이터 두 개만 DB에서 가져온다. 
- 2) orderItem과 item의 경우 order 레코드를 제외하고 해당 엔티티에 대한 데이터만 가져온다. 
- 이와 달리 fetch join으로 컬렉션을 가져올 경우, 단 쿼리로 해결하기 때문에 장점이 있다. 

### [추가] fetch join을 아예 사용하지 않는다면?
- 아래와 같이 Order만 사용할 수 있다. 
- 그렇게 할 경우 member, delivery 가 추가적인 배치 조인으로 동작한다. order, member, delivery, orderItem, item 에 대하여 총 5개의 조인이 발생한다. 
- 그러므로 할 수 있는 한 최대한 fetch join을 한다. 그리고 불가능한 부분에서 lazy + batch 를 사용한다. 

``` java
final String query = "" +
        "select o " +
        "from Order o " +
        // "join fetch o.member m " +
        // "join fetch o.delivery d ";
```

### lazy + batch 정리
- lazy의 1+n 이 1+1로 바뀐다.
- 조인보다 DB 데이터 전송량이 최적화 된다. 그러니까 엔티티에 정확하게 맞는 데이터만 호출한다. 
- 다만, 쿼리 호출수가 완전한 fetch join보다 많다. 
- fetch join과 달리 페이징이 가능하다.
- 결론은,
    - xToOne은 페이징에 영향이 없으므로 fetch join을 사용하며, 이를 기준으로 페이징을 한다. 그 다음에,
    - xToMany에 대하여 lazy + batch 로 해결한다. 

### batch size는?
- batch 의 최대 갯수는 기본적으로 1000 개이다. DB의 in 절의 인자의 갯수가 1000개인 DB가 있기 때문이다.
- 다만, 1000개는 어플리케이션과 DB 모두에게 큰 영향이 갈 수 있다. 100개를 할 경우 시간을 더 걸리는 대신 부하가 줄어든다. 
- 권장하는 내용은 최대치(1000개)이다. 만약 부하가 우려된다면, 최소한 100개를 기준으로 차차 올린다.
- 다만, was의 메모리 입장에서는 어떤 방식이나 별 차이가 없다. 왜냐하면 메모리 사용량은 어플리케이션에서 요청한 갯수에 의존한다. 이것은 배치 사이즈와 관계 없이 언제나 같다. 이 부분이 걱정이라면 로직 자체에서 필요로 한 갯수를 줄어야 한다. 
- 사실상 이러한 전략으로 거의 대부분의 문제를 해소할 수 있다. 
