---
layout: post
title: Optional 활용하기
author: infoqoch
# last_modified_at: 2021-11-27 09:40:46
categories: [java]
tags: [java]
---

## Optional 의 활용
- 지금까지 Optional 을 사용했다. 바로 아래처럼...
```java
if(optional.isPresent()){
    // 로직
}
```
- 그런데 위와 같이 사용하면 기존의 방식과 뭐가 다를까?
```java
if(obj != null){
    // 로직
}
```
- 정말로 바보같이 사용했다. ㅠ 

## Optional 의 기본적인 사용 패턴
```java
@Test
void 단순하며_이상적인_optional_사용() {
    OpVo vo = new OpVo();
    vo.setTarget("hi");
    Optional<String> optional = vo.getTarget();
    optional.ifPresent(System.out::println);
}

class OpVo {
    private String target;

    public Optional<String> getTarget() { 
        return Optional.ofNullable(target) ;
    }

    public void setTarget(String target) {
        this.target = target;
    }
}
```
- Optional 는 함수형 인터페이스를 지원하며 아주 깔끔하게 처리 가능하다.

## 그 외 사용 패턴들 
- 스트림으로 사용 가능하다.
- null 일 경우 원하는 객체를 생성하여 주입 가능하다. 
  
```java
@Test
void 없을경우_다른값으로_데이타타입_입력() {
    OpVo vo = new OpVo();
//	vo.setTarget("hi");
    vo.setTarget(null);
    Optional<String> optional = vo.getTarget();
    String get = optional.orElse(new String("hello")); // 다른 객체로도 생성 가능. 제너릭형태
    System.out.println(get);
}

@Test
void 스트림_사용() {
    OpVo vo = new OpVo();
    vo.setTarget("hi");
    Optional<String> optional = vo.getTarget();
    boolean boo = optional.stream().anyMatch(s -> s.contains("k"));
    System.out.println(boo);
}

```