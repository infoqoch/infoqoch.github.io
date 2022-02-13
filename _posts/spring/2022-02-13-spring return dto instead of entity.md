---
layout: post
author: infoqoch
title: spring rest controller 개발에서 entity 대신 dto를 리턴해야 한다. (특히 xToOne 관계에서)
categories: [spring]
tags: [spring, jpa, rest]
---

## API Controller의 Param은 entity가 되어서는 안된다. DTO로 해야 한다. 
- controller에서 entity를 param으로 받을 경우 간단해서 쉽다.
- validation 을 entity에 넣는 것이 좋지 않다. select, update 등 다양한 조건에서의 검증 로직이 다른데 이를 엔티티에서 다 감당할 수 없다. 더 나아가 프리젠테이션 로직이 엔티티에 들어가면 안되며 분리되어야 한다. 
- 엔티티 자체를 리턴하면, count 등 다양한 프로퍼티스에 대한 확장 가능성이 없다. 
- 문제는 entity의 스펙이 바뀌면 api 스펙도 변경될 수 있다. 이 경우 매우 위험하다.
- entity로 할 경우, 어떤 파라미터를 받는지 직관적으로 알 수 없다. DTO에 정확하게 필요한 필드를 설정하면, 어떤 데이터가 들어올지 알 수 있다. 기본적으로 코딩 자체에서 예측 가능한 방식으로 만드는 것이 중요하다.
- 회원가입이란 컨트롤러를 만든다 하더라도, 회원가입의 방식이 매우 다양할 수 있다. 이러한 상황을 유연하게 대처할 수 없다. 각 API마다 DTO를 따로 만들어야 한다. 
- 아래는 post에 대한 간단한 DTO의 활용 사례이다.

## 기본적인 DTO의 활용

```java
// DTO(CreateMemberRequest)와 entity(Member)를 분리한다.
@PostMapping("/api/v2/members")
public CreateMemberResponse saveMemberV2(@RequestBody @Valid CreateMemberRequest request){
    Member member = new Member();
    member.setName(request.getName());
    Long id = memberService.join(member);
    return new CreateMemberResponse(id);
}

@Data
@AllArgsConstructor
static class CreateMemberResponse {
    private Long id;
}

@GetMapping("/api/v2/members")
public Result membersV2(){
    final List<Member> findMembers = memberService.findMembers();
    final List<MemberDto> collect = findMembers.stream()
            .map(member -> new MemberDto(member.getName()))
            .collect(Collectors.toList());
    return new Result(collect, LocalDateTime.now());
}

@Data
@AllArgsConstructor
static class Result<T> {
    private T data;
    private LocalDateTime createdDate; // 스펙을 추가할 수 있다.
}

@Data
@AllArgsConstructor
static class MemberDto{
    private String name;
}
```


## JPA에서 엔티티 사용의 위험성
- 앞서의 내용은 쿼리 지향 개발에서도 통용되는 보편적인 문제이다. 
- JPA는 순환 참조로 인한 무한 루프, Lazy 로딩과 프록시, 쿼리의 n+1 등의 문제로 인하여, 엔티티를 API에 노출하여 발생하는 문제가 훨씬 심각하다. 
- 해당 내용을 알아보기 위하여, 먼저 컨트롤러와 요구사항을 살펴보자. 그 내용은 아래의 코드와 같다. 

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

- 위의 요구사항은 주문 내역을 출력하는 것이며, 더 정확하게는 주문한 회원과 발송 정보를 요구한다. 
- 만약 이를 entity(여기서는 List<Order>)로 출력하면 어떻게 될까?


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

- 위의 결과를 보면 Member 가 - Orders를 호출하고 Orders 가 Member를 호출함을 확인할 수 있다.
- JPA의 ToString, Json 바인딩의 문제가 여기서 발생한다. Order 객체는 Member를 가지고 있고, Member 객체는 Order를 가지고 있기 떄문에, 서로를 호출하면 무한한 루프가 발생한다. 
- 그러므로 서로를 호출할 때는 한 쪽은 Json으로의 변환을 하지 못하게 막아야 한다.

### 2. 프록시의 문제
- @JsonIgnore로 한쪽을 막았다. 

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

```log file
Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed; nested exception is org.springframework.http.converter.HttpMessageConversionException: Type definition error: [simple type, class org.hibernate.proxy.pojo.bytebuddy.ByteBuddyInterceptor]; nested exception is com.fasterxml.jackson.databind.exc.InvalidDefinitionException: No serializer found for class org.hibernate.proxy.pojo.bytebuddy.ByteBuddyInterceptor and no properties discovered to create BeanSerializer (to avoid exception, disable SerializationFeature.FAIL_ON_EMPTY_BEANS) (through reference chain: java.util.ArrayList[0]->jpabook.jpashop.domain.Order["member"]->jpabook.jpashop.domain.Member$HibernateProxy$EPLQjC8q["hibernateLazyInitializer"])] with root cause
```

- 위의 내용은 ByteBuddyInterceptor 의 핵심인데, 이것은 프록시 객체를 생성한다. 현재 페치 전략은 Lazy로써, 프록시 객체를 리턴한다. 그런데 젝슨 라이브러리 입장에서는 프록시를  json으로 바인딩하여 리턴해야하는데, 해당 객체를 json으로 만들 방법이 묘연하다. 그러므로 예외를 던진다. 
- 이를 해소하기 위하여 Hibernate5Modul을 사용하여 프록시에 대한 대응을 한다. 

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

- 정상 동작함을 확인할 수 있다. 
- 필요에 따라 Member 객체를 삽입하기 위하여 Hibernate5Module 을 조작할 수 있다. 다만 이 경우 n+1 문제가 발생할 수 있다. 
- 더 나아가 원하는 데이터에 대한 세세한 관리가 어렵다. 


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
        "orderDate": "2022-02-13T15:06:30.271307",
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
        "orderDate": "2022-02-13T15:06:30.353305",
        "status": "ORDER",
        "totalPrice": 220000
    }
]
```

### 4. 엔티티 강제 초기화
- Lazy 상태에서 원하는 필드를 꺼내고 싶을 때는, 반복문을 통해서 강제 초기화를 할 수 있다. proxy를 초기화 한다. 
- 요구사항은 Delivery 와 Member를 가져오는 것이다. 그러므로 두 개의 엔티티를 아래와 같이 초기화 한다. `Hibernate5Module.Feature.FORCE_LAZY_LOADING`는 모든 프록시를 초기화한다. 이와 달리 원하는 것만 초기화 한다는 장점이 있다. 

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

- Member 객체의 모든 필드가 필요한 것은 아니다. 단순하게 이름만 필요할 수 있다. 그러나 API에 모든 데이터를 노출시키는 문제가 있다. 이러한 내용을 엔티티 차원에서 더 세세하게 조작하는 것은 무척 복잡하다. 

### 그러니까, 처음부터 엔티티를 노출하지 말자.
- 엔티티를 노출하면 매우 많은 문제가 발생한다.
- 엔티티를 노출할 경우 프레젠테이션에 대한 메타데이터가 엔티티 클래스에 쌓이게 된다. 엔티티 클래스가 어렵고 복잡해 진다. 
- API의 스펙이 엔티티에 완전 의존하게 된다. 이로 인하여 api 스펙을 유지한 채 엔티티를 수정하는 것이 매우 어려워 진다. 
- 엔티티 이외의 데이터를 삽입하는 것이 불가능하다. 요청시간, 응답 내용 등등의 내용을 추가할 수 없다. 반대로 노출을 제한하고 싶은 데이터에 대한 로직이 복잡해진다. 유연한 API 스펙을 구현할 수 없다. 
- 성능 최적화의 방식에서 한계가 있다. 
- 그러므로 엔티티를 API로 절대로 노출시키지 말자. 노출로 인한 단점이 너무 많다. 


## jpa의 DTO를 리턴과 n+1의 문제
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

@Data
static class SimpleOrderDto {
    private Long orderId;
    private String name;
    private LocalDateTime orderDate;
    private OrderStatus orderStatus;
    private Address address;

    // DTO는 중요하지 않기 때문에, 의존관계가 어떻든 크게 문제는 없다.
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

- 다만 위의 방식은 Lazy 로딩에서의 여러 개의 쿼리를 발생시키는 문제가 발생한다.
- order를 한 번 호출하고, map에서 member와 delivery의 필드를 호출하며, 해당 객체가 호출한다. n+1 문제가 발생한다. 2(레코드 두 개)*2(프록시 초기화 두 번)가 발생.
- Eager 로딩으로도 해소가 안된다. 예측 불가능한 코드가 발생하며, 쿼리도 여러 번 나간다. 이 내용은 생략.

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

- sql. 쿼리 한 번으로 해소한다. 지연로딩 자체가 발생하지 않는다.

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


## 리포지토리에서 entity가 아닌 DTO로 리턴
- 기존의 방식은 join fetch를 통해 entity를 호출하고, java에서 해당 데이터를 조작하는 방식이다. 
- join fetch를 사용하지 않는다. 왜냐하면 join fetch는 엔티티를 위한 기능이기 때문이다. 

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

- dto를 리포지토리에서 바로 가져오는 것은 아래와 같은 장단이 있다. 
- DB를 통해 필요로한 데이터만 가져온다. 이를 통해 DB와의 통신에서 최적화를 만든다.
- 다만, dto로 반환할 경우 사실상 재사용성이 없다. 엔티티가 아니므로 엔티티 매니저를 통한 활용이 불가능하다. jpql 쿼리가 다소 지저분하다. 
- 리포지토리에 프레젠테이션 객체의 코드가 들어가는 단점이 있다. 


## 정리
- **API에 엔티티를 노출하지 않는다.**
- **lazy 로딩으로 인한 프록시 초기화로 n+1문제를 해소해야 한다.**
- fetch join(v3)이나 dto(v4)로의 호출, 둘 중 하나를 선택한다.

## 최적화
- **fetch join을 우선**한다. 
- 대체로 select 절에서 많은 데이터를 호출하는 것이, 대체로 성능상 영향이 크지 않다. 이 때 대부분의 문제가 해소된다.

- 만약, 그래도 성능 최적화가 안된다면, 그러니까 데이터가 매우 많은 경우, dto를 사용한다. 
- 다만, 엔티티를 위한 리포지토리와 dto 쿼리를 위한 리포지토리는 분리해야 한다. 왜냐하면 **api의 스펙이 리포지토리에 있는 것**은 좋지 않은 구조이기 때문이다. 그러므로 dto를 통한 성능 최적화를 위해서, **api 스펙을 위한 쿼리를 따로 묶은 리포지토리를 만들어 분리해야 한다.**. 엔티티를 위한 조회 리포지토리는 순수한 상태로 유지한다.
- 아래와 같이 작성한다. 

- 위의 방식으로도 해결이 안되면 네이티브 SQL이나 jdbc를 직접 사용한다. 

```java
// 엔티티 이외의 데이터 추출을 위한 리포지토리를 구현한다.
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
