---
layout: post
author: infoqoch
title: jpa, spring api의 entity 조회 최적화 1 - xToOne 연관관계와 엔티티 조회
categories: [jpa]
tags: [spring, jpa, rest]
---


## 들어가며
- 스프링을 기반으로 api 프로젝트를 생성한다. jpa로 데이터를 통제한다.
- api의 경우 json 형태로 데이터를 응답한다. 
- rest api 에서 스펙을 유지한 채, 효과적으로 엔티티 객체를 조작하는 방식을 정리한다. 
- xToOne과 xToMany를 분리하여 정리한다. 영속성 컨텍스트에서 엔티티를 리턴하여 dto로 변환하는 방식과 처음부터 dto 자체를 출력하는 방식으로 분리하여 정리한다.

## 엔티티가 노출된 api
- api를 가장 쉽게 만드는 방법은 데이타베이스에서 출력한 데이터를 바로 api의 응답값으로 설정하는 방법이다. 
- 이러한 방법은 많은 문제를 내제한다. 
- 아래의 주석은 요구사항이며, 그에 따른 코드는 아래와 같다. 

### 코드
- 컨트롤러

```java
/*
*
* xToOne 관계에서의 성능 최적화
* Order 를 호출. 회원과 주문에 대한 데이터가 필요하다. 
* Order -> Member (ManyToOne)
* Order -> Delivery (OneToOne)
*
*/
@RestController
@RequiredArgsConstructor
public class OrderSimpleApiController {

    private final OrderRepository orderRepository;

    @GetMapping("/api/v1/simple-orders")
    public List<Order> ordersV1(){
        final List<Order> all = orderRepository.findAllByString(new OrderSearch());
        return all;
    }
}
```

- 요구사항은 주문(order)를 출력하며, 필요로 한 데이터는 주문을 한 회원(member)와 발송 정보(delivery)이다.
- 참고로 findAllByString은 매우 단순한 조회 쿼리이며 다음과 같다. `select o from Order o join o.member m`
- 위의 쿼리는 아래와 같은 문제를 야기한다. 


### 1. 루프의 발생

- Order의 Member 필드

```java
@ManyToOne(fetch = LAZY)
@JoinColumn(name = "member_id")
private Member member;
```

- Member의 Order 필드

```java
@OneToMany(mappedBy = "member")
private List<Order> orders = new ArrayList<>();
```

- 해당 메서드에 대한 api 호출 결과

```json
[
    {
        "id": 4,
        "member": {
            "id": 1,
            "name": "userA",
            "address": {
                "city": "서울",
                "street": "1",
                "zipcode": "1111"
            },
            "orders": [
                {
                    "id": 4,
                    "member": {
                        "id": 1,
                        "name": "userA",
                        "address": {
                            "city": "서울",
                            "street": "1",
                            "zipcode": "1111"
                        },
                        "orders": [
                            {
                                "id": 4,
                                "member": {
                                    "id": 1,
                                    "name": "userA",
                                    "address": {
                                        "city": "서울",
                                        "street": "1",
                                        "zipcode": "1111"
                                    },
                                    "orders": [
                                        {
                                            "id": 4,
                                            "member": {
                                                "id": 1,
                                                "name": "userA",
                                                "address": {
                                                    "city": "서울",
                                                    "street": "1",
                                                    "zipcode": "1111"
                                                },
                                                "orders": [
                                                    {
                                                        "id": 4,
                                                        "member": {
                                                            "id": 1,
                                                            "name": "userA",
                                                            "address": {
                                                                "city": "서울",
                                                                "street": "1",
                                                                "zipcode": "1111"
                                                            },
                                                            "orders": [
                                                                {
// 후략                        
```

- 위의 결과를 보면 Member 가 Orders를 호출하고 Orders 가 Member를 호출한다. 무한 루프에 빠지게 된다. JPA의 ToString, Json 바인딩의 문제가 여기서 발생한다. 
- 서로를 호출할 때는 한 쪽은 Json으로의 변환을 하지 못하게 막아야 한다.

### 2. 프록시의 문제
- 무한루프를 해소하기 위하여 @JsonIgnore 어너테이션을 사용하여 Member 객체의 order 필드를 막았다.

- Order의 Member 필드

```java
@ManyToOne(fetch = LAZY)
@JoinColumn(name = "member_id")
private Member member;
```

- Member의 Order 필드

```java
@JsonIgnore
@OneToMany(mappedBy = "member")
private List<Order> orders = new ArrayList<>();
```

- 해당 메서드에 대한 api 호출 결과

```log
Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed; nested exception is org.springframework.http.converter.HttpMessageConversionException: Type definition error: [simple type, class org.hibernate.proxy.pojo.bytebuddy.ByteBuddyInterceptor]; nested exception is com.fasterxml.jackson.databind.exc.InvalidDefinitionException: No serializer found for class org.hibernate.proxy.pojo.bytebuddy.ByteBuddyInterceptor and no properties discovered to create BeanSerializer (to avoid exception, disable SerializationFeature.FAIL_ON_EMPTY_BEANS) (through reference chain: java.util.ArrayList[0]->jpabook.jpashop.domain.Order["member"]->jpabook.jpashop.domain.Member$HibernateProxy$EPLQjC8q["hibernateLazyInitializer"])] with root cause
```

- ByteBuddyInterceptor은 지연로딩으로 인해 생성되는 프록시 객체이다. 페치 전략은 Lazy로써 프록시 객체를 리턴한다. 젝슨 라이브러리 입장에서는 프록시를 json으로 바인딩할 수 없으며, 예외를 던진다. 
- 이를 해소하기 위하여 Hibernate5Modul을 사용한다.

### 3. Hibernate5Modul 의 활용

```groovy
implementation group: 'com.fasterxml.jackson.datatype', name: 'jackson-datatype-hibernate5'
```

```java
@Bean
Hibernate5Module hibernate5Module(){
    final Hibernate5Module hibernate5Module = new Hibernate5Module();
    // hibernate5Module.configure(Hibernate5Module.Feature.FORCE_LAZY_LOADING, true);
    return hibernate5Module;
}
```

```json
[
    {
        "id": 4,
        "member": null,
        "orderDate": "2022-02-13T15:04:53.532551",
        "status": "ORDER",
        "totalPrice": 50000
    },
    {
        "id": 11,
        "member": null,
        "orderDate": "2022-02-13T15:04:53.660548",
        "status": "ORDER",
        "totalPrice": 220000
    }
]
```

- 정상 동작한다. 프록시 객체는 null로 반환한다.
- null을 허용하지 않고 모든 필드를 채우고 싶을 수 있다. 이 경우 다음의 코드를 사용한다. 지연로딩을 사용하는 모든 필드에 대하여 초기화한다. `hibernate5Module.configure(Hibernate5Module.Feature.FORCE_LAZY_LOADING, true);`

### 4. 필요한 엔티티에 대한 초기화
- `FORCE_LAZY_LOADING`은 객체 그래프의 모든 엔티티를 초기화한다. FORCE_LAZY_LOADING을 사용하지 않고 hibernate5Module을 빈으로 등록한 상태에서 원하는 객체만 초기화하고 싶은 경우, 반복문을 통한 초기화를 사용한다. 
- 그 코드는 아래와 같다. 

```java
@GetMapping("/api/v1/simple-orders")
public List<Order> ordersV1(){
    final List<Order> all = orderRepository.findAllByString(new OrderSearch());
    for (Order order : all) {
        order.getMember().getName();
        order.getDelivery().getStatus();
    }
    return all;
}
```

```json
[
    {
        "id": 4,
        "member": {
            "id": 1,
            "name": "userA",
            "address": {
                "city": "서울",
                "street": "1",
                "zipcode": "1111"
            }
        },
        "delivery": {
            "id": 5,
            "address": {
                "city": "서울",
                "street": "1",
                "zipcode": "1111"
            },
            "status": null
        },
        "orderDate": "2022-02-13T15:09:26.246786",
        "status": "ORDER",
        "totalPrice": 50000
    },
    {
        "id": 11,
        "member": {
            "id": 8,
            "name": "userB",
            "address": {
                "city": "진주",
                "street": "2",
                "zipcode": "2222"
            }
        },
        "delivery": {
            "id": 12,
            "address": {
                "city": "진주",
                "street": "2",
                "zipcode": "2222"
            },
            "status": null
        },
        "orderDate": "2022-02-13T15:09:26.316785",
        "status": "ORDER",
        "totalPrice": 220000
    }
]
```

- 원하는 엔티티에 대하여 초기화를 하였다.
- 하지만 엔티티 내부에서 필요한 데이터와 노출해야할 데이터가 존재한다. 하지만 이 방식은 모든 엔티티의 필드를 노출하는 문제를 가지고 있다. 
- 세세한 조작을 위하여 엔티티의 필드마다 @JsonIgnore를 할 수 없다. 엔티티 클래스가 매우 지저분해진다.
- 더 나아가 특정 API에서는 @JsonIgnore 했던 필드를 필요로 할 수 있다. 
- 엔티티를 직접 노출하는 방식을 선택하면 안된다는 결론에 도달할 수밖에 없다.

### 처음부터 엔티티를 노출하지 말자.
- 엔티티를 노출하면 매우 많은 문제가 발생한다.
- 엔티티를 노출할 경우 프레젠테이션에 대한 메타데이터가 엔티티 클래스에 쌓이게 된다. 엔티티 클래스가 어렵고 복잡해 진다. 
- API의 스펙이 엔티티가 완전하게 의존하게 된다. 
- 엔티티를 수정할 때, api 스펙을 유지한 채 수정해야 한다. 
- 엔티티 이외의 데이터를 삽입하는 것이 불가능하다. 요청시간, 응답 내용 등등의 내용을 추가할 수 없다. 반대로 노출을 제한하고 싶은 데이터에 대한 로직이 복잡해진다. 유연한 API 스펙을 구현할 수 없다. 
- 성능 최적화의 방식에서 한계가 있다. 
- 그러므로 엔티티를 API로 절대로 노출시키지 말자. 노출로 인한 단점이 너무 많다. 

## DTO 리턴 + 지연로딩으로 인한 n+1의 문제
- 컨트롤러를 아래와 같이 변경한다. 

```java
@GetMapping("/api/v2/simple-orders")
public Result<SimpleOrderDto> ordersV2(){
    final List<Order> orders = orderRepository.findAllByString(new OrderSearch());

    final List<SimpleOrderDto> collect = orders.stream()
            .map(o -> new SimpleOrderDto(o))
            .collect(Collectors.toList());

    return new Result(collect, "good!");
}

@Data
@AllArgsConstructor
static class Result<T> {
    T data;
    private String message;
}

@Data // DTO는 롬복을 자유롭게 써도 큰 문제가 없다.
static class SimpleOrderDto {
    private Long orderId;
    private String name;
    private LocalDateTime orderDate;
    private OrderStatus orderStatus;
    private Address address;

    // DTO는 중요하지 않기 때문에, 의존관계가 어떻든 크게 문제는 없다. 그러니까 Order나 기타 어떤 인자를 가지던 큰 문제가 없다. 
    public SimpleOrderDto(Order order) {
        orderId = order.getId();
        final Member member = order.getMember();
        name = member.getName();
        orderDate = order.getOrderDate();
        orderStatus = order.getStatus();
        address = order.getDelivery().getAddress();
    }
}
```

- 엔티티 대신 DTO로 리턴한다. 
- 다만, Lazy로딩으로 인한 n+1 문제가 발생한다. 
- order를 한 번 호출하고, stream.map()에서 member와 delivery를 초기화 한다. 2(member, delivery)*2(레코드 각 각 두 개)가 발생.

```sql
2022-02-13 15:35:57.532 DEBUG 7180 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
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
2022-02-13 15:35:57.553 DEBUG 7180 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
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
2022-02-13 15:35:57.558 DEBUG 7180 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        delivery0_.delivery_id as delivery1_2_0_,
        delivery0_.city as city2_2_0_,
        delivery0_.street as street3_2_0_,
        delivery0_.zipcode as zipcode4_2_0_,
        delivery0_.status as status5_2_0_ 
    from
        delivery delivery0_ 
    where
        delivery0_.delivery_id=?
2022-02-13 15:35:57.559 DEBUG 7180 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
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
2022-02-13 15:35:57.560 DEBUG 7180 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
    select
        delivery0_.delivery_id as delivery1_2_0_,
        delivery0_.city as city2_2_0_,
        delivery0_.street as street3_2_0_,
        delivery0_.zipcode as zipcode4_2_0_,
        delivery0_.status as status5_2_0_ 
    from
        delivery delivery0_ 
    where
        delivery0_.delivery_id=?
```


## fetch join 의 활용
- 위의 문제를 Eager로 해결하려는 순간 더 큰 문제가 발생한다.
- fetch join으로 해소한다. 

- 컨트롤러

```java
@GetMapping("/api/v3/simple-orders")
public Result<SimpleOrderDto> ordersV3(){
    final List<Order> orders = orderRepository.findAllWithMemberDelivery();

    final List<SimpleOrderDto> collect = orders.stream()
            .map(SimpleOrderDto::new)
            .collect(Collectors.toList());

    return new Result(collect, "good!");
}
```

- 리포지토리

```java
public List<Order> findAllWithMemberDelivery() {
    final String query = "" +
            "select o " +
            "from Order o " +
            "join fetch o.member m " +
            "join fetch o.delivery d ";

    return em.createQuery(query, Order.class).getResultList();
}
```

- fetch 조인으로 인하여 쿼리 한 번으로 끝난다. 지연로딩 자체가 발생하지 않는다.

```sql
2022-02-13 15:53:02.246 DEBUG 18616 --- [nio-8080-exec-3] org.hibernate.SQL                        : 
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
            on order0_.delivery_id=delivery2_.delivery_id
```

- jpa 에서 엔티티를 출력할 때, 지연로딩 + fetch 로 거의 대부분의 문제가 해결된다.
- 다음은 엔티티가 아닌 dto로 바로 출력하는 방식이다.

## entity가 아닌 DTO로 데이터 출력
- 기존의 방식은 엔티티 객체를 출력했다. 그리고 엔티티를 DTO로 변환하고, DTO를 json으로 변환하는 방식을 채택했다. 
- DTO로 바로 반환하는 방식은 아래의 코드와 같다. 

```java
// DTO를 호출할 때 fetch를 사용하지 않음. fetch는 엔티티만 호출할 때 사용한다.
public List<OrderSimpleQueryDto> findOrderDtos() {
    final String query = "" +
            " select new jpabook.jpashop.repository.OrderSimpleQueryDto(o.id, m.name, o.orderDate, o.status, d.address) " +
            " from Order o " +
            " join o.member m " +
            " join o.delivery d ";
    return em.createQuery(query, OrderSimpleQueryDto.class)
            .getResultList();
}
```

```sql
2022-02-13 16:14:31.064 DEBUG 17880 --- [nio-8080-exec-2] org.hibernate.SQL                        : 
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
```

### DTO vs ENTITY
- dto와 entity로 출력하는 두 개의 방식은 장단이 있다. 
- dto로 출력할 경우 DB를 통해 필요로한 데이터만 가져온다. 쿼리로 요청하는 select 칼럼 자체의 갯수가 줄어든다. DB와의 통신에서 최적화를 만든다.
- 다만, dto로 반환할 경우 사실상 재사용성이 없다. 엔티티가 아니므로 영속성 컨텍스트의 기능을 활용할 수 없다. 
- jpql 쿼리가 다소 지저분하다. 
- 리포지토리에 프레젠테이션 계층의 코드가 들어가는 단점이 있다. 더 정확하게는 DTO 자체가 프레젠테이션 계층에 의존하는 경향이 있다. 이 경우 커맨드와 쿼리를 분리하여 QueryRepository에 구현하는 방식을 채택할 수 있다. 이 경우 QueryRepository는 API 스펙을 위한 쿼리로 분리, 사용된다. 이와 대비하여 엔티티를 위한 리포지토리는 최대한 순수한 상태를 유지한다. 해당 코드는 아래와 같다.

### QueryRepository : 커맨드와 쿼리의 분리

```java
@Repository
@RequiredArgsConstructor
public class QueryRepository {
    private final EntityManager em;

    public List<OrderSimpleQueryDto> findOrderDtos() {
        final String query = "" +
                " select new jpabook.jpashop.repository.OrderSimpleQueryDto(o.id, m.name, o.orderDate, o.status, d.address) " +
                " from Order o " +
                " join o.member m " +
                " join o.delivery d ";
        return em.createQuery(query, OrderSimpleQueryDto.class)
                .getResultList();
    }
}
```

## 정리
- **API에 엔티티를 노출하지 않는다.**
- **fetch join을 활용하여 지연로딩으로 인한 n+1문제를 해소한다**
- fetch join(v3) 혹은 dto(v4), 둘 중 하나를 선택한다. 
- **fetch join을 우선**한다. 
- 대체로 select 절에서 많은 데이터를 호출한다고 하여 성능을 많이 소모하지 않는다. 엔티티를 최대한 활용한다. 
- 성능상 한계에 도달하면, 최적화의 방법 중 하나로 dto를 고려한다. 
- 도저히 해소가 불가능하면, 네이티브 SQL를 사용하거나, jdbc를 직접 조작한다.

