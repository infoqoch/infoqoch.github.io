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
- 복잡한 매개변수부터 해결하자. 먼저 매개변수를 하나의 객체로 하여 단순하게 만들어보자. 기존에 사용하는 Product 를 사용하면 아래와 같은 코드로 작성할 수 있다. 

```java
public interface ProductMapper{
    void updateStock(Product product); 
    void updatePrice(Product product);
    void updateStockAndPrice(Product product);
    void updateDetail(Product product);
}

// client

Product product = new Product(?, ?, ?); // Product의 필드는 매우 많다. 그 중 무엇을 삽입해야 하는가? 
productMapper.updateStock(product); // updateStock의 쿼리를 확인하고 productId와 stock, modId가 필요함을 확인하였다. 
```

- 하지만 위의 코드의 매개변수인 Product는 치명적인 문제를 가지고 있다. 필요로하는 필드와 필요하지 않는 필드가 무엇인지 확인할 수 없다. 해당 코드를 읽고 유지보수하거나 수정하거나 새로운 기능을 구현하는 사람 입장에서, Product는 그 어떤 정보를 제공하지 않는다. update를 위하여 필요한 필드와 필요하지 않은 필드가 무엇인지 알 수 없다. 결국 쿼리를 확인해야 한다. 쿼리를 확인해야한다는 말은, Product란 매개변수로서의 신뢰성이 없다는 것과 같다. 
- 다만, 쿼리 자체는 직관적으로 작성되었기 때문에 빠르게 확인할 수는 있을테다. 비록 Product에 어떤 필드를 채워야 할지는 모르지만, 명확한 메서드명 때문에 어떤 동작을 할지에 대해서는 쉽게 판단할 수 있다. 

- 필요한 필드와 필요 없는 필드가 복잡하게 섞인 것에 한계를 느끼며, 아래와 같이 각각의 메서드에 대한 dto를 만들 수도 있다. 
- 장점은 분명하다. 각 메서드마다 필요한 값이 무엇인지 분명하게 알 수 있다. 그리고 각각의 메서드마다 사용하는 객체가 다르기 때문에, 수정 및 유지보수에 있어서도 사이드이펙트를 최소화 할 수 있다.
- 하지만 매서드마다 dto를 각각 사용하기 때문에 장황하다.

```java
public interface ProductMapper{
    void updateStock(ProductUpdateStockDto dto); 
    void updatePrice(ProductUpdatePriceDto dto);
    void updateStockAndPrice(ProductUpdateStockAndPriceDto dto);
    void updateDetail(ProductDetailDto dto);
}
```

- 메서드와 dto를 하나로 둘 수도 있다. 이는 mybatis의 동적인 기능을 통해 해소할 수 있다. <if> 등 마이바티스의 태그를 활용하는 방식이다. 

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

- update할 칼럼을 <if> 태그를 통해 구분한다. 구분의 기준은 값의 empty 여부이다.
- 하나의 매서드와 하나의 매개변수를 사용하기 때문에 편리하다.  수정하지 않는 데이터에 대해서 null이나 ""를 대입하기 때문에 다소 명확하다. 다만, 값으로서의 null을 삽입하려 하는 경우 문제가 발생한다.

- 한편, 리팩토링을 접하고 jpa를 학습하면서 mybatis를 통한 객체지향적 개발이 가능하냐에 대한 의문이 항상 있었다. jpa를 통해 힌트를 얻을 수 있었다. jpa는 더티체킹을 통해 update를 한다. 아래는 그 예시이다.

```java
@Transactional
void updateStock(int updateId, int stock){
    Product product = productRepository.getOne(updateId); // select * from product where update_id = #{updateId}로 데이터를 추출 및 자바 객체로 변환한다.
    product.changeStock(stock); // 입력한 stock의 유효성 등을 검사한다. 그리고 정상동작할 경우 입력한 인자와 내부의 로직에 따라 stock 데이터를 변경한다. 
} // 트랜잭션이 종료되면 더티체킹으로 인하여 변경된 필드에 대해서만 update하는 쿼리가 발생한다.update product set stock = 15 where update_id = #{updateId} 라는 형태가 될 것이다. 
```

- 위와 같이 온전한 Product 객체를 select을 통해 구현하고, 변경할 필드에 대해서 수정을 하고, 해당 객체를 update할 수 있다. 그 예제는 아래와 같다. 

```xml
<insert id="update">
    update product
    set <!-- 아래에 없는 칼럼은 updatable 하지 않다고 볼 수 있다. -->
        stock = #{stock}
        price = #{price}
        product_name = #{productName} 
        , modId = #{modId}
        , modDt = now()
    where product_id = #{productId}
</insert>
```

```java
void updateStock(int updateId, int stock, String modId){
    Product product = productMapper.getOne(updateId);
    product.changeStock(stock); 
    product.setModId(modId); 
    productMapper.update(product); // jpa는 영속성 컨텍스트로 인하여 이와 같이 영속화를 위한 메서드를 필요로 하지 않다. 
} 
```

- <if> 태그에서 null과 equals를 통해 변경할 데이터를 판별하는 방식보다는 좀 더 나은 방식임은 분명하다. 하지만 jpa의 더티체킹보다는 열등한 방식이다. 왜냐하면 더티체킹은 변경된 필드에 대해서만 set 절에 삽입하는 반면, mybatis는 쿼리에 있는 모든 칼럼을 수정하기 때문이다. 

### 정리
- 네 가지 패턴으로 mybatis와 함께 리포지토리를 구현해봤다. 첫 번째는 각각의 매개변수를 활용, 두 번째는 메서드 마다 정확하게 필요로한 필드만 가지는 객체를 사용, 세 번째는 공통의 객체와 메서드를 사용하되 변경할 칼럼을 null이나 empty를 통해 판별하는 방식, 마지막은 select을 통해 데이터를 호출하고 그 중 수정이 필요한 부분에 대해서 변경 및 영속화하는 방식이다. 
- 지금까지 나는 필요에 따라 (아니면 아무런 고민 없이 손에 잡히는 대로) 위의 방식을 섞어서 개발해왔다. 다소 반성을 하며, SQL Mapper과 함께 객체지향적으로 개발할 경우 어떤 식으로 해야할지에 대한 정리하는 시간을 가질 수 있었다. 
- 내 생각에는, 객체지향적 개발을 한다면 마지막 방법이 가장 나은 방법이다. 온전한 객체를 호출하고 해당 객체 전체를 DB에 저장하는 형태이기 때문이다. 하지만 매개변수를 통해 변경되는 데이터를 명확하게 표현하는 첫 번째와 두 번재 방법 역시 좋은 방법이라 생각한다. 단순하고 명확하다. 
- sql을 직접 다루는 mybatis는 직관적으로 개발 할 수 있다는 장점이 있다. 다만, SQL을 짜는 것에 따라 영속화하는 방식이 다소 너무 자유로운 문제가 있다고 생각한다. 개발에는 일관된 규칙이  필요하다고 생각한다. 자유는 규율 속에서 존재하는 법이다. 그래서 불편하지만 네 번째 방법을 주로 사용하며, update 혹은 insert batch를 사용할 때만 한정적으로 두 번째 방법을 사용해야하지 않을까 싶다.