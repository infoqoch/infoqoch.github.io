---
layout: post
author: infoqoch
title: 테스트에서 main - test 파티션 간 소스 간섭 문제 (Classloader와 Url 문제)
categories: [tdd]
tags: [tdd, java]
---

# 통합테스트(@SpringBootTest)에서의 메인(main)과 테스트(test)의 동시 호출 문제
- 현 문제는 reflection 사용 중에 발생한 문제이다.
- 특정 어너테이션을 읽고, 해당 어너테이션의 값이 유일함을 보장해야 한다고 가정한다. 대표적으로 스프링의 `@GetMapping` 가 그러하다.
- 이때 메인과 테스트에서 둘 다 동일한 어너테이션과 value를 구현하고 싶을 수 있다. 예를 들면 아래와 같다.

```java
// main/.../MainController.java
@Controller
public class MainController {
    @GetMapping("/main")
    public void main(){
        // 중략
    }
}

// test/.../TestController.java
@Controller
public class TestController {
    @GetMapping("/main")
    public void main(){

    }
}
```

- 예외가 발생한다! `to {GET [/main]}: There is already 'testController' bean method`;
- 왜 이런 문제가 발생할까? 클래스로더가 클래스를 읽을 때 사용되는 url 문제 때문이다.

```java
@SpringBootTest
public class ApplicationTests {
    @Test
    void contextLoads() {
        final Collection<URL> urls = ClasspathHelper.forPackage(UpdateDispatcher.class.getPackageName());
        for (URL url : urls) {
            // 결과가 두 개 나오며 그 url은 아래와 같다. (그래들)
            // url = file:/C:/projects/some-project/out/test/classes/
            // url = file:/C:/projects/some-project/out/production/classes/
            // 메이븐은 /test-classes 라는 경로를 가진다.
            System.out.println("url = " + url);
        }
    }
}
```

- 이에 따라 특정 로직의 경우 test 파티션에 존재하는 소스코드를 읽지 않도록 제한할 필요가 있다. 
- 다만, 테스트와 관련한 코드가 메인에 위치하기 때문에, 좋은 코드인가에 대한 고민이 있다. 차후 이 부분은 해소하고 싶다.

```java
@Configuration
public class SomeAnnotationResolver{
    
    @Bean
    public SomeResolver someResolver(){
        Set<Url> urls = onlyMainUrl();
        // 소스코드
    }    

    public Set<Url> onlyMainUrl(){
        return ClasspathHelper.forPackage(UpdateDispatcher.class.getPackageName()).stream()
                .filter(url -> !url.toString().contains("/test-classes")) // 메이븐 
                .filter(url -> !url.toString().contains("/test/classes")) // 그래들
                .collect(Collectors.toSet());
    }
}
```
