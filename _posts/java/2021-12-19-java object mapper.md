---
layout: post
author: infoqoch
title: Java - Json 의 직렬화 ObjectMapper
categories: [java]
tags: [java, ObjectMapper]
---

## 들어가며
- ObjectMapper를 사용하면서 직렬화 - 역직렬화 과정에서의 필요로 한 설정을 정리하였다. 직렬화란 java -> json 으로의 변환을 의미하며, 역직렬화는 json -> java 를 의미한다.
- LocalDateTime - json 간 변환
- camelCase - under_case_score 간 변환

## 직렬화와 JsonProperty
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
- 이를 위하여 해당 JsonSerializer 을 구현하여 포맷을 정의한다. 
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

## PropertyNamingStrategy 와 Visibility 를 통해 어너테이션의 제거
- JsonProperty 의 역할은 1) json으로의 직렬화-역직렬화 대상임을 명시하며 2) json의 프로퍼티의 명칭을 정의한다. 
- ObjectMapper를 설정하여 네이밍문법의 변환을 자동으로 수행할 수 있다. `setPropertyNamingStrategy` 매서드를 사용한다. 이를 통해 JsonProperty을 생략한다.
- `setVisibility` 를 통해 모든 필드가 json의 직렬화 대상임을 명시한다. 

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

## 역직렬화와 직렬화의 포매터를 따로 설정해야 한다. 
- 이제 역직렬화를 수행한다.
- objectmapper 를 설정하는 경우 직렬화 역직렬화 상관 없이 적용된다. 그러나 포매터의 경우 직렬화와 역직렬화 두 개 모두 세팅해야 한다. 
  
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

## json의 프로퍼티에 대응하는 필드값의 구현 필요 여부를 설정. JsonIgnoreProperties
- ObjectMapper json의 프로퍼티 전체를 pojo 로 변환한다. 이때 모든 프로퍼티스에 대응하는 필드가 있어야 한다. 그렇지 않으면 예외를 던진다. 
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
- 한편, 데이타를 바인딩 할 때, 인자가 있는 생성자나 setter 가 있고, 이를 통해 데이타를 주입한다. 반대로 데이타를 resource로 바꿀 때도 getter 나 기타 방식을 통해 메모리에서 데이터를 추출하여 변환한다. 
- 하지만 앞서의 코드는 이러한 부분을 최소화하기 위하여 노력했다. 그리고 문제없이 바인딩이 되었다. 사실 어느 수준으로 getter 와 setter를 열어야 하는지 ObjectMapper를 사용하면서 계속 혼란스러웠다. 
- 이에 따라 최소한으로 setter 와 getter, 생성자를 열어서 테스트를 진행해봤다. 

```java
static class TestB{
    @JsonProperty("value")
    private String value;

    TestB(String value){
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

- 위의 코드를 보면 getter가 없는데도 불구하고 문제 없이 json으로 직렬화 되는 것을 확인할 수 있다. 
- 다음으로 setter와 생성자를 제거하여 역직렬화를 하였다. 

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
- 세터와 생성자 자체를 막았는데도 문제 없이 객체가 생성된다. 뭐지!?. 
- 이 부분은 아래의 api를 통해 그 이유를 확인할 수 있었다. `JsonProperty`는 setter와 getter의 기능이 있으며,  `JsonProperty.Access` 은 생성자의 접근 제어 수준을 통제할 수 있다고 한다. 와.. ObjectMapper가 생각보다 상당히 강력한 권한을 가지고 있었다.
- 이를 통해 개발자 입장에서는 ObjectMapper를 사용해도 pojo를 최대한 유지하며 개발할 수 있음을 확인할 수 있었다. 

> - Marker annotation that can be used to define a non-static method as a "setter" or "getter" for a logical property (depending on its signature), or non-static object field to be used (serialized, deserialized) as a logical property.
> - Optional property that may be used to change the way visibility of accessors (getter, field-as-getter) and mutators (contructor parameter, setter, field-as-setter) is determined, either so that otherwise non-visible accessors (like private getters) may be used; or that otherwise visible accessors are ignored.
> - 링크 : https://fasterxml.github.io/jackson-annotations/javadoc/2.8/com/fasterxml/jackson/annotation/JsonProperty.html


> 참고
> - https://github.com/HomoEfficio/dev-tips/blob/master/Java8-LocalDateTime-Jackson-%EC%A7%81%EB%A0%AC%ED%99%94-%EB%AC%B8%EC%A0%9C.md*/
> - https://dumdildor.tistory.com/13*/
> - https://www.baeldung.com/jackson-object-mapper-tutorial


### 직렬화 때 비어있는 필드를 json으로 변환하지 않는다.
- 내용 다 끝나고 이렇게 추가해서 좀 그렇지만ㅠ 
- 직렬화할 때 필드값이 null 이거나 "" 인 경우가 있다. 이런 프로퍼티는 `setSerializationInclusion`을 통해 제거할 수 있다. 

```java
@Test
void pojo에_없는_필드값_프로퍼티로_안넘기기() throws JsonProcessingException {
    // given
    class Tester{
        private String name;
        private String address;

        public Tester(String name) {
            this.name = name;
        }
    }

    final Tester kim = new Tester("kim");

    // when
    ObjectMapper objectMapper = new ObjectMapper();
    objectMapper.setVisibility(PropertyAccessor.FIELD, JsonAutoDetect.Visibility.ANY);

    // then
    final String json = objectMapper.writeValueAsString(kim);
    System.out.println(json);
    assertThat(json).contains("address");


    // when
    ObjectMapper objectMapper2 = new ObjectMapper();
    objectMapper2.setVisibility(PropertyAccessor.FIELD, JsonAutoDetect.Visibility.ANY);
    objectMapper2.setSerializationInclusion(JsonInclude.Include.NON_EMPTY);

    // then
    final String json2 = objectMapper2.writeValueAsString(kim);
    System.out.println(json2);
    assertThat(json2).doesNotContain("address");
}
```

## 추가, ReponseEntity 와 ObjectMapper
- ReponseEntity를 사용하는데 camel case 와 관련한 에러가 발생했다. 
- 예외의 출처가 ObjectMapper와 같은 `com.fasterxml.jackson.databind` 에서 발생한 에러이다. 
- 앞서의 ObjectMapper 를 bean으로 등록하여 해소할 수 있다. 

## 추가, TypeReference
- 만약 객체가 제너릭으로 존재하거나 컬렉션일 경우 단순하게 token type 만 기입해서는 바인딩되지 않는다. TypeReference을 사용해야 한다. 
- `objectMapper.readValue(responseJson, new TypeReference<>(){});`
  