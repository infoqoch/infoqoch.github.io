---
layout: post
author: infoqoch
title: SQL Mapper로 객체지향적 개발은 어떻게 해야할까? 
categories: [refactoring]
tags: [refactoring, java]
---

## 들어가며
- SQL을 중심으로 개발하는 경우 코드를 작성할 때 sql에 의존적으로 되기 십상이다. 그 이유는 DB에 영속화하거나 영속화 된 데이터를 추출할 때 사용되는 데이터의 묶음이 하나의 의미있는 단위로서의 객체임을 보장하지 않기 때문이다. 단순한 데이터의 묶음일 뿐이다. 
- sql에 의존하기 되는 코드에서 그래도 객체지향적인 개발을 하려면 어떤 코드를 작성해야할까? 이에 대하여 고민이 있었고, 내 나름대로 내린 결론들을 정리하고 공유하고자 한다. 
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

- mybatis로 구현할 경우 위와 같은 형태로 insert 코드를 작성한다. 영속화된 위의 데이터를 update를 하면 어떻게 할까? stock 을 늘린다고 가정하자.

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

- 위의 코드는 무척 장황하다. 비슷한 메서드가 많고, 필드도 복잡하게 나열되어 있다.
- 복잡한 필드부터 해결하자. 먼저 매개변수를 하나의 객체로 하여 단순하게 만들어보자. 기존에 사용하는 Product 를 사용하면 아래와 같은 코드로 작성할 수 있다. 

```java
public interface ProductMapper{
    void updateStock(Product product); 
    void updatePrice(Product product);
    void updateStockAndPrice(Product product);
    void updateDetail(Product product);
}
```

- 하지만 위의 코드에 사용한 매개변수는 치명적인 문제를 가지고 있다. 필요로하는 필드와 필요하지 않는 필드가 무엇인지 확인할 수 없다. 해당 코드를 읽고 오류를 수정하거나 새로운 로직을 구현하는 사람 입장에서, Product의 필드 중 필요로 한 것과 필요하지 않은 것이 무엇인지 알 수 없다. 결국 sql를 확인해야 한다. 
- Sql을 확인해야한다는 말은, Product란 매개변수의 신뢰성이 전혀 없다는 것과 같다. 이를 관리하는 개발자는 해당 유사한 매서드와 해당 객체가 나오는 모든 소스에 대하여 무엇이 필요하고 무엇이 필요 없는지에 대하여 SQL을 통해 일일이 확인해야 하는 상황이 발생한다. 그래도 SQL은 직관적으로 작성되었기 때문에 빠르게 확인할 수는 있을테다. 

```java
Product product = new Product(?, ?, ?); // Product의 필드는 매우 많다. 그 중 무엇을 삽입해야 하는가? 
productMapper.updateStock(product); // updateStock의 쿼리를 확인하고 productId와 stock, modId가 필요함을 확인하였다. 
```

- 필요한 필드와 필요 없는 필드가 엉킨 객체에 대한 한계를 느끼며, 아래와 같이 각각의 메서드에 대한 dto를 만들 수도 있다. 
- 장점은 분명하다. 이러한 코드 작성 규칙을 명확하게 한다면, 각 메서드마다 필요한 필드가 무엇인지 좀 더 분명하게 드러난다. 그리고 각각의 메서드마다 사용하는 객체가 다르기 때문에, 수정 및 유지보수에 있어서도 사이드이펙트를 최소화 할 수 있다. 
- 다만 다소 장황하다. 

```java
public interface ProductMapper{
    void updateStock(ProductUpdateStockDto dto); 
    void updatePrice(ProductUpdatePriceDto dto);
    void updateStockAndPrice(ProductUpdateStockAndPriceDto dto);
    void updateDetail(ProductDetailDto dto);
}
```

- 장황한 메서드를 mybatis의 동적 sql 기능을 통해 해소할 수 있다. 아래의 <if> 태그를 활용하는 방식이다. 

```java
public interface ProductMapper{
    void update(Product product); 
}
```

```xml
<insert id="updateStock">
    update product
    set 
        <if test="stock!=null and !stock.equals('')">  <!-- 자바 int 타입이 !=null과 .equals('')로 판별되는지는 확인하지 않았습니다. -->
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

```java
productMapper.update(new Product(productId, null, null, stock, null, modId)); // 나는 stock만 변경할 거야. 그러므로 나머지는 null로 해야지!
```

- update의 대상이 되는 칼럼의 여부를 <if> 태그를 통해 구분한다. 
- 필요로한 필드만 삽입하고 필요 없는 필드는 null이나 ""를 대입한다. 
- 하나의 매서드와 하나의 매개변수 객체로 사용할 수 있기 때문에 편리하다. 수정하지 않는 데이터에 대해서 null을 대입하기 때문에, 수정하려고 하는 데이터가 무엇인지 다소 명확하게 표현할 수 있다. 다만, 값으로서의 null을 삽입하려 하는 경우 문제가 발생한다.

- mybatis를 활용한 데이터 처리 방식을 다양한 방식으로 정리해봤다. 경우에 따라 (혹은 아무런 고민 없이 손에 잡히는 대로) 위의 모든 방식을 사용하고 있으며, 같은 클래스 내부에서 위의 모든 방법을 섞어서 작성하곤 했다. 
- 한편, 리팩토링을 공부하고 jpa를 학습하면서, mybatis를 통한 객체지향적 개발이 가능하냐에 대한 의문이 항상 있었다. 그리고 jpa를 통해 힌트를 얻을 수 있었다. 
- orm인 jpa는 update를 하는 방식이 더티체킹으로 한정되는 경향이 있다. 더티체킹으로 update를 할 경우 아래와 같은 형태로 코드가 작성된다. 

```java
@Transactional
void updateStock(int updateId, int stock){
    Product product = productRepository.getOne(updateId);
    product.changeStock(stock); // 입력한 stock의 유효성 등을 검사한다.
} // 트랜잭션이 지금의 메서드에서 종료된다면, 더티체킹으로 인하여 stock만 update 하는 쿼리가 발생한다. 
```

- 사실 이러한 방식을 mybatis로 개발하는 상황에서 활용할 수 있다. select을 통해 변경할 데이터를 추출한 다음, 변경할 필드에 대해서 수정을 하고, 해당 객체를 update하는 방식이다. 

```xml
<insert id="update">
    update product
    set <!-- 아래의 칼럼과 필드는 일종의 updatable 하지 않다고 볼 수 있다. -->
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
    productMapper.update(product);
} 
```
- <if> 태그에서 null과 equals를 통해 변경할 데이터를 판별하는 방식보다는 좀 더 나은 방식임은 분명하다. 하지만 jpa의 더티체킹보다는 열등한 방식이다. 왜냐하면 더티체킹은 변경된 필드에 대해서만 set 절에 삽입하는 반면, mybatis는 쿼리에 있는 모든 칼럼을 수정하기 때문이다. 

### 정리
- 네 가지 패턴으로 mybatis와 함께 리포지토리를 구현했다. 첫 번째는 각각의 매개변수를 활용, 두 번째는 메서드 마다 정확하게 필요로한 필드만 가지는 객체를 사용, 세 번째는 공통의 객체와 메서드를 사용하되 변경할 칼럼을 null이나 empty를 통해 판별하는 방식, 마지막은 select을 통해 데이터를 호출하고 그 중 수정이 필요한 부분에 대해서 변경 및 영속화하는 방식이다. 
- 객체지향적 개발을 한다면 마지막 방법이 가장 나은 방법이다. 하지만 변경되는 필드가 요구사항보다 크기 때문에, 쿼리가 단순 명료한 첫 번째와 두 번재 방법 역시 자주 사용한다.
- sql을 직접 다루는 mybatis는 직관적으로 개발 할 수 있다는 장점이 있다. 다만 sql에 의존하는 자바 코드의 문제와 너무 유연한 영속화 방식은 다소 사용하는 것에 있어서 까다롭다. 개발 과정에서의 명확한 규칙이 필요하다는 생각을 이 블로그를 작성하며 많이 했다. 자유는 규율 속에서 존재하는 법이다. insert의 경우 정적 팩터리 메서드나 빌드 패턴을 사용하고, update의 경우 해당 객체 내부의 인스턴스 메서드를 잘 활용할 필요가 있다. 
- 코드에 의존하여 SQL이 생성되는 것과 SQL에 의존하여 코드를 작성하는 것은 다르다. jpa를 통해 무척 유연하게 코드를 작성할 수 있으며 이로 인한 장점이 무척 큼을 다시금 느꼈다. 