---
layout: post
author: infoqoch
title: SQL Mapper로 객체지향적 개발하기 위해서 어떻게 데이터를 추출해야 할까?
categories: [refactoring]
tags: [refactoring, java]
---

## 들어가며
- SQL을 중심으로 개발하는 경우 코드를 작성할 때 sql에 의존적으로 개발하기 십상이다. 그 이유는 DB에 영속화하거나 영속화 된 데이터를 추출할 때 사용되는 데이터의 묶음이 하나의 의미있는 단위로서의 객체임을 보장하지 않기 때문이다. 단순한 데이터의 묶음일 뿐이다. 
- sql에 의존하기 되는 코드에서 그래도 객체지향적인 개발을 위한 쿼리는 어떻게 짜야 할까? 이에 대하여 고민이 있었고, 내 나름대로 내린 결론들을 정리하고 공유하고자 한다. 
- 아래의 예를 보며 확인하자. (참고로 아래의 코드는 실제 동작을 확인하지 않았습니다.)

## update를 통해 보는 sql 및 자바 코드의 다양한 패턴

```xml
<insert id="save">
    insert into product(product_name, price, stock, reg_id, reg_dt) 
    values 
    (#{productName}, #{price}, #{stock}, #{regId}, now())
</insert>
```

```java
public interface ProductMapper{
    void save(Product product);
}

public class Product{
    private Long productId;
    private String productName; 
    private int price; 
    private int stock; 
    private String regId;
    private LocalDateTime regDt;
    private String modId;
    private LocalDateTime modDt;
}
```

- mybatis로 구현할 경우 위와 같은 형태로 insert 코드를 작성한다. 위의 형태로 데이터가 영속화되어 있다고 가정하며, 해당 데이터를 update를 하면 어떻게 해야 할까? 

##  1. 기본타입(+ Wrapper type) 각각을 인자로 한다. 
- stock 을 늘린다고 가정하자.

```xml
<insert id="updateStock">
    update product
    set 
        stock = #{stock}
        , modId = #{modId}
        , modDt = now()
    where product_id = #{productId}
</insert>
```

```java
public interface ProductMapper{
    void updateStock(Long productId, int stock, String modId); 
}
```

- 가장 단순하고 분명한 형태로 동적 sql과 매개변수를 작성했다. 이러한 형태는 특별한 문제가 없다. 하지만 복잡한 요구사항이 발생하면 어떨까? 

```java
public interface ProductMapper{
    void updateStock(Long productId, int stock, String modId); 
    void updatePrice(Long productId, int price, String modId);
    void updateStockAndPrice(Long productId, int price, int stock, String modId);
    void updateDetail(Long productId, String productName, int price, int stock, String modId);
}
```

- 위의 코드는 무척 장황하다. 비슷한 메서드가 많고, 매개변수도 복잡하게 나열되어 있다.

##  2. 매개변수를 하나의 객체로 통일한다.
- 복잡한 매개변수부터 해결하자. 먼저 매개변수를 하나의 객체로 하여 단순하게 만들어보자. 기존에 사용하는 Product 를 사용하면 아래와 같은 코드로 작성할 수 있다. 
- 각 매퍼마다 필요로 한 필드는 다르지만 정상 동작함을 확인할 수 있다. mybatis의 경우 필요로한 필드에 값만 존재하면 어떤 데이터 타입이 전달되더라도 상관 없다. 사실 map을 전달하는 것과 큰 차이가 없다. 

```java
public interface ProductMapper{
    void updateStock(Product product); 
    void updatePrice(Product product);
    void updateStockAndPrice(Product product);
    void updateDetail(Product product);
}
```

- 다만, 이를 유지보수하는 입장에서는 sql에 더 의존적인 문제를 일으킨다. 
- `updateStock` 메서드를 사용할 때, Product의 필드 중 무엇이 반드시 들어가야되는지 알 수 없다. 결국 sql을 재검토해야 하는 일이 발생한다. 자바 매서드에 대한 신뢰가 사라진다.

```java
Product product = new Product(?, ?, ?); // Product가 가진 필드는 많다. 그 중 무엇을 삽입해야 updateStock이 정상 동작하는가? 
```


## 3. 매서드마다가 각각의 매개변수를 가진다.
- 하나의 통일된 객체를 매개변수로 사용하는 것은 한계가 있다. 필요한 필드와 필요 없는 필드를 판별할 수 없어 사실 map 객체를 쓰는 것과 차이가 없다. 이를 극복하기 위하여 각각의 메서드에 대한 dto를 만들 수도 있다. 
- 장점은 분명하다. 각 메서드마다 필요한 값이 무엇인지 분명하게 알 수 있다. 그리고 각각의 메서드마다 사용하는 객체가 다르기 때문에, 수정 및 유지보수에 있어서도 사이드이펙트를 최소화 할 수 있다.
- 다만, 매서드마다 dto를 각각 사용하기 때문에 다소 장황하다.

```java
public interface ProductMapper{
    void updateStock(ProductUpdateStockDto dto); 
    void updatePrice(ProductUpdatePriceDto dto);
    void updateStockAndPrice(ProductUpdateStockAndPriceDto dto);
    void updateDetail(ProductDetailDto dto);
}
```

## 4. `<if>` 태그를 활용하여 원하는 칼럼만 변경하는 동적 쿼리를 생성한다. 
- 매서드마다 객체가 존재하여 장황하다고 판단할 수 있다. 
- 기존으로 돌아가 update 매서드를 단 하나만 두고, 이에 사용할 객체 역시 단 하나만 둔다. 2번의 방식과 동일하다.
- 다만 다른 점은,  mybatis의 동적인 기능을 통해, 정확하게 필요로 한 칼럼에 대해서만 동적 쿼리를 작성한다. `<if>` 등 마이바티스의 태그를 활용하여 구현할 수 있다. 

```java
public interface ProductMapper{
    void update(Product product); 
}

// client
productMapper.update(new Product(productId, null, null, stock, null, modId)); // 나는 stock만 변경할 거야. 그러므로 나머지는 null로 해야지!
```

```xml
<insert id="updateStock">
    update product
    set
        <if test="stock!=null and !stock.equals('')">
        stock = #{stock}
        </if>
        <if test="price!=null and !price.equals('')">
        price = #{price}
        </if>
        <if test="productName!=null and !productName.equals('')">
        product_name = #{productName}
        </if>
        , modId = #{modId}
        , modDt = now()
    where product_id = #{productId}
</insert>
```

## 5. select 후 update 하기
- if문을 통한 방법은 편리하지만 null과 같은 의도를 반영할 수 없다. 
- sql문에 대한 세세한 조작은 불가능하다는 것을 인정하고, 단순하게 처리할 수 있다. 
- jpa가 특정 객체를 영속성 컨텍스트에 호출한 후, 필요한 필드를 변경한 뒤, 더티체킹으로 데이터를 갱신한다. 그러한 방식을 활용하되, mybatis는 더티체킹을 할 수 없으므로, `repository.update(product);` 메서드만 추가한다.

```java
void updateStock(int updateId, int stock){
    Product product = productMapper.getOne(updateId);
    product.changeStock(stock); 
    productMapper.update(product);
} 
```

```xml
<insert id="update">
    update product
    set <!-- 아래의 칼럼은  updatable 한 칼럼이라고 볼 수 있다. -->
        stock = #{stock}
        price = #{price}
        product_name = #{productName} 
        , modId = #{modId}
        , modDt = now()
    where product_id = #{productId}
</insert>
```

- 기존의 데이터(getOne)를 기반으로 수정하기 때문에 데이터의 정합성 문제는 발생하지 않는다.
- 다만, select 쿼리를 한 번 더 호출하는 문제가 발생한다. jpa와 달리 영속성 컨텍스트가 필요 없는 mybatis는, pk만 정확하다면 바로 쿼리를 날리는 것이 더 빠르고 효율적이다.

```java
void updateStock(int updateId, int stock){
    // Product product = productMapper.getOne(updateId);
    // product.changeStock(stock); 
    
    // 굳이 위의 두 과정을 지킬 필요가 없다.
    productMapper.updateStock(updateId, stock); 
} 
```
## 정리
- 다섯 가지 패턴으로 mybatis와 함께 리포지토리를 구현해봤다. 각 패턴의 변수는 다음과 같다. 매서드 : 1개 vs 여러개. 인자 : 기본타입들 vs 여러 객체 vs 객체 하나. 
- 마지막 방법의 경우 select을 반드시 추가하는 형태를 취하였다. 
- mybatis로 개발하면서 내가 주로 사용하는 방법은 다섯 번째 방법과 세 번째 방법이다.
- 데이터를 갱신하는 커맨드의 경우 다섯 번째 방법을 사용한다.
    - 클라이언트의 데이터를 신뢰할 수 없기 때문이다. 클라이언트의 데이터를 믿고 그냥 `updateStock(updateId, stock)`로 데이터를 밀어 넣는 것은 위험하다. 
    - 클라이언트가 전달한 데이터를 select을 통해 검증하고 update를 하는 것이 더 안전한 방법이다. 
    - 어차피 select으로 기존 데이터를 가지고 있는 상태이면, 변경된 데이터에 대해서만 해당 객체를 수정하고, 그 객체를 update를 위한 매개변수로 전달하는 것이 간단하고 직관적이다.
- 쿼리의 경우 세 번째 방법을 사용한다. 
    - 쿼리는 각각의 요구사항에 따라 sql문 자체가 달라져 버린다. 필요로 한 필드 값도 전부 다르다. 이를 하나의 매서드나 하나의 매개변수처리하는 것보다, 처음부터 완전하게 분리하여 개발하는 것이 편하다.

- sql을 직접 다루는 mybatis는 직관적으로 개발 할 수 있다는 장점이 있다. 다만, 인자에 대해서는 불필요하게 열려 있어 개발함에 있어 엄밀한 코드를 작성하기 어렵다. map을 매개변수로 전달하는 것과 큰 차이가 없다. 그렇기 때문에 모델에서 상황에 맞춰 인자를 명확하게 한정하는 것이 중요하다. 자유는 규율 속에서 존재하는 법이라 생각한다.