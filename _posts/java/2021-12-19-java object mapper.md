---
layout: post
author: infoqoch
title: Java - Json 의 직렬화, 역직렬화(ObjectMapper, LocalDateTime, 네이밍 문법)
categories: [java]
tags: [java, ObjectMapper]
---

## 들어가며
- ObjectMapper를 사용하면서 직렬화 - 역직렬화 과정에서의 필요로 한 설정을 정리하였다. 직렬화란 java -> json 으로의 변환을 의미하며, 역직렬화는 json -> java 를 의미한다.
- LocalDateTime - json 간 변환
- camelCase - under_case_score 간 변환

## 직렬화와 
- ObjectMapper를 사용하기 위해서는 각 필드마다 json으로 직렬화/역직렬화를 수행함을 명시해야 한다. 이를 `@JsonProperty` 으로 표현한다.
- 대개 json은 under_case_score 를 사용하고, 자바는 camelCase 를 사용한다. java - json 을 변환하는 ObjectMapper는 자동으로 이러한 네이밍 문법의 변환을 제공하지 않는다.  `@JsonProperty` 에 value 를 통해 명시한다. 

```java
@Builder
@ToString
static class TesterV1{
    @JsonProperty("user_id")
    private String userId;

    @JsonProperty("date")
    private LocalDateTime date;

    @JsonProperty("instant")
    private Long instant;
}


@Test
void JsonProperty의_활용() throws JsonProcessingException {

    // given
    TesterV1 vo = TesterV1.builder()
            .userId("kim")
            .date(LocalDateTime.now())
            .instant(Instant.now().getEpochSecond())
            .build();

    System.out.println(vo);

    // when
    ObjectMapper objectMapper = new ObjectMapper();
    final String s = objectMapper.writeValueAsString(vo);

    // then
    System.out.println(s);
    assertThat(s).contains("user_id", "date", "instant");
}
```

## LocalDateTime 의 형변환
- LocalDateTime 이나 기타 데이타타입을 json 으로 변환할 때 정상적으로 동작하지 않거나 의도치 않은 방식으로 변환될 수 있다.
- 이를 위하여 해당 JsonSerializer 을 구현하여 데이타타입의 변환 방식을 명시한다. 
- 주석의 경우 java.util.Date의 데이타타입 변환 방식이다. 

```java
@Builder
@ToString
static class TesterV1{
    @JsonProperty("user_id")
    private String userId;

    @JsonProperty("date")
    private LocalDateTime date;

    @JsonProperty("instant")
    private Long instant;
}

@Test
void date타입의_직렬화_커스텀모듈() throws JsonProcessingException {

    // given
    TesterV1 vo = TesterV1.builder()
            .userId("kim")
            .date(LocalDateTime.now())
            .instant(Instant.now().getEpochSecond())
            .build();

    System.out.println(vo);


    // when
    ObjectMapper objectMapper = new ObjectMapper();
//        objectMapper.setDateFormat(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss"));
//        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"); // java.util.Date 의 경우 동작하는 것 같다(https://www.baeldung.com/jackson-object-mapper-tutorial)
//        objectMapper.setDateFormat(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss"));
    SimpleModule simpleModule = new SimpleModule();
    simpleModule.addSerializer(LocalDateTime.class, new CustomLocalDateTimeSerializer());
    objectMapper.registerModule(simpleModule);

    //then
    final String s = objectMapper.writeValueAsString(vo);
    System.out.println(s);
    assertThat(s).doesNotContain("dayOfMonth"); // LocalDateTime 객체 전체 필드값이 들어가지 않도록 한다.
}

public class CustomLocalDateTimeSerializer extends JsonSerializer<LocalDateTime> {

    private DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Override
    public void serialize(LocalDateTime value, JsonGenerator gen, SerializerProvider serializers) throws IOException {
        gen.writeString(formatter.format(value));
    }
}
```

## JsonProperty 를 명시해야 하는가?
- JsonProperty를 반드시 명시할 필요가 없다. ObjectMapper를 설정하여 네이밍문법의 변환을 자동으로 수행할 수 있다. `setPropertyNamingStrategy` 매서드를 사용한다.
- 필드값에 json으로 변환 필드를 명시할 필요가 없다. `setVisibility`를 통해 자동으로 그 대상을 탐색하도록 한다.

```java
@Builder
@ToString
static class TesterV2{
    private String userId;

    private LocalDateTime date;

    private Long instant;
}

@Test
void pojo설정의최소화() throws JsonProcessingException {

    // init
    TesterV2 vo = TesterV2.builder()
            .userId("kim")
            .date(LocalDateTime.now())
            .instant(Instant.now().getEpochSecond())
            .build();

    System.out.println(vo);

    ObjectMapper objectMapper = new ObjectMapper();
    objectMapper.setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
    SimpleModule simpleModule = new SimpleModule();
    simpleModule.addSerializer(LocalDateTime.class, new CustomLocalDateTimeSerializer());
    objectMapper.registerModule(simpleModule);
    objectMapper.setVisibility(PropertyAccessor.FIELD, JsonAutoDetect.Visibility.ANY);
    final String s = objectMapper.writeValueAsString(vo);

    System.out.println(s);
}

```

## 역직렬화와 직렬화의 커스텀 모듈은 다르다.
- 이제 역직렬화를 수행한다.
- 다른 부분은 특별한 설정을 필요로 하지 않는다. 하지만 LocalDateTime 의 경우 직렬화와 역직렬화 양측 모두 형변환을 위한 포맷을 설정해야 한다. 
- 직렬화는 모든 필드에 대한 생성자로 구현이 가능하지만, 역직렬화는 인자가 없는 생성자를 필요로 한다. (이 부분의 매커니즘은 사실 정확하게 이해가 가지 않는다. 어떤 세터도 없는데 NoArgsConstructor 만으로 어떻게 데이타를 주입하는 것일까?)
  
```java
@Builder
@ToString
@NoArgsConstructor
@AllArgsConstructor
static class TesterV3{
    private String userId;

    private LocalDateTime date;

    private Long instant;
}

public class CustomLocalDateTimeDeserializer extends JsonDeserializer<LocalDateTime> {
    private DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Override
    public LocalDateTime deserialize(JsonParser jsonParser, DeserializationContext deserializationContext) throws IOException, JsonProcessingException {
        return LocalDateTime.parse(jsonParser.getText(), formatter);
    }
}

@Test
void 역직렬화() throws JsonProcessingException {

    // given
    TesterV3 vo = TesterV3.builder()
            .userId("kim")
            .date(LocalDateTime.now())
            .instant(Instant.now().getEpochSecond())
            .build();
    System.out.println(vo);

    // when
    ObjectMapper objectMapper = new ObjectMapper();
    objectMapper.setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
    SimpleModule simpleModule = new SimpleModule();
    simpleModule.addSerializer(LocalDateTime.class, new CustomLocalDateTimeSerializer());
    simpleModule.addDeserializer(LocalDateTime.class, new CustomLocalDateTimeDeserializer());
    objectMapper.registerModule(simpleModule);
    objectMapper.setVisibility(PropertyAccessor.FIELD, JsonAutoDetect.Visibility.ANY);
    final String jsonSerial = objectMapper.writeValueAsString(vo);

    final TesterV3 jsonDeSerial = objectMapper.readValue(jsonSerial, TesterV3.class);

    //then
    System.out.println(jsonDeSerial);
    assertThat(vo).usingRecursiveComparison().isNotNull();
}

```

## json 중 필요한 필드만 받는다.
- ObjectMapper json의 프로퍼티 전체를 pojo 로 변환한다. 이때 모든 프로퍼티스에 대응하는 필드가 있어야 하고 없으면 예외 처리한다.
- 이를 해소하기 위하여 `@JsonIgnoreProperties(ignoreUnknown = true)` 을 사용하거나 `configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)` 를 사용한다.

```java
@ToString
//    @JsonIgnoreProperties(ignoreUnknown = true)
static class UserId{
    private String userId;
}

@Test
void 없는_pojo필드() throws JsonProcessingException {
    // given
    TesterV3 vo = TesterV3.builder()
            .userId("kim")
            .date(LocalDateTime.now())
            .instant(Instant.now().getEpochSecond())
            .build();
    System.out.println(vo);

    ObjectMapper objectMapper = new ObjectMapper();
    objectMapper.setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
    SimpleModule simpleModule = new SimpleModule();
    simpleModule.addSerializer(LocalDateTime.class, new CustomLocalDateTimeSerializer());
    simpleModule.addDeserializer(LocalDateTime.class, new CustomLocalDateTimeDeserializer());
    objectMapper.registerModule(simpleModule);
    objectMapper.setVisibility(PropertyAccessor.FIELD, JsonAutoDetect.Visibility.ANY);
    objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

    final String jsonSerial = objectMapper.writeValueAsString(vo);

    // when
    final UserId deSerialPojo = objectMapper.readValue(jsonSerial, UserId.class);

    // then
    System.out.println(deSerialPojo.toString());
}
```

## JsonProperty 와 setter, getter
- 앞서 직렬화 - 역직렬화 할 때, getter와 setter를 제한하고 NoArgsConstructor 임에도 불구하고 필드에 값을 부여하거나 혹은 필드의 값을 꺼내왔다. 
- 실제로 getter와 setter를 제한해봤다.

```java

static class TestB{
    @JsonProperty("value")
    private String value;

    private TestB(String value){
        this.value = value;
    }
}

@Test
void noGetter_serialization() throws JsonProcessingException {

    TestB testB = new TestB("hello!");

    ObjectMapper objectMapper = new ObjectMapper();
    final String json = objectMapper.writeValueAsString(testB);

    System.out.println(json);

}
```

- api에서 확인하니까, 허무하게도, JsonProperty 는 setter 와 getter 를 가지고 있다고 한다. 

> Marker annotation that can be used to define a non-static method as a "setter" or "getter" for a logical property (depending on its signature), or non-static object field to be used (serialized, deserialized) as a logical property.
> - 링크 : https://fasterxml.github.io/jackson-annotations/javadoc/2.8/com/fasterxml/jackson/annotation/JsonProperty.html


## 생성자의 접근 제한과 역직렬화
- 한편, setter 와 constructor 자체를 닫아봤다. 

```java
@Getter
public class TestA {
    @JsonProperty("value")
    private String value;

    private TestA() {
    }
}

public class ObjectMapperTest{

    @Test
    void noSetterNoConstructor_deserialization() throws JsonProcessingException {

//        TestA testA = new TestA(); // 문법 오류 발생


        String json = "{\"value\": \"hihi!\"}";

        ObjectMapper objectMapper = new ObjectMapper();
        final TestA vo = objectMapper.readValue(json, TestA.class);
        System.out.println(vo.getValue());
        assertThat(vo.getValue()).isEqualTo("hihi!");
    }
}
```
- 분명, 생성자 자체를 막았는데도 값이 들어간다. 이 부분은 `JsonProperty.Access` 에 따라 접근 제어자의 수준을 통제한다고 한다. 와.. ObjectMapper가 생각보다 상당히 강력한 권한을 가지고 있었다.

> Optional property that may be used to change the way visibility of accessors (getter, field-as-getter) and mutators (contructor parameter, setter, field-as-setter) is determined, either so that otherwise non-visible accessors (like private getters) may be used; or that otherwise visible accessors are ignored.


> 참고
> - https://github.com/HomoEfficio/dev-tips/blob/master/Java8-LocalDateTime-Jackson-%EC%A7%81%EB%A0%AC%ED%99%94-%EB%AC%B8%EC%A0%9C.md*/
> - https://dumdildor.tistory.com/13*/
> - https://www.baeldung.com/jackson-object-mapper-tutorial