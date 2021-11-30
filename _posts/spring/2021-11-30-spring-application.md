---
layout: post
author: infoqoch
title: 스프링 부트의 SpringApplication의 활용
last_modified_at: 
categories: [spring]
tags: [spring]
---

## SpringApplication
- 스프링어플리케이션의 시작 단계 전후에서 여러가지 조작이 가능하다.
- 여러 조작이 가능하지만, `app.setWebApplicationType(WebApplicationType.NONE);` 은 무척 쓸모가 많다. NONE 으로 할 경우 웹 어플리케이션이 유지되지 않고 컨텍스트를 생성 후 종료한다. 기본 값은 SERVLET 이며 REACTIVE 로 설정 가능하다. 

```java
@SpringBootApplication
public class Application {

	public static void main(String[] args) {
        SpringApplication app = new SpringApplication(Application.class);
        app.setWebApplicationType(WebApplicationType.NONE);
        app.addListeners(new ApplicationListenerBefore());
        app.run(args);
    }
}
```

### ApplicationListener<ApplicationStartingEvent> 
- 스프링 컨텍스트가 동작하기 전에 수행한다.
- 컨텍스트가 동작하기 전이므로 빈으로 동작할 수 없다. SpringApplication 의 메서드를 통해 리스너를 등록한다.  `app.addListeners(new ApplicationListenerBefore());`

```java
public class ApplicationListenerBefore implements ApplicationListener<ApplicationStartingEvent> {

    @Override
    public void onApplicationEvent(ApplicationStartingEvent event) {
        System.out.println("=============================================");
        System.out.println("ApplicationListener<ApplicationStartingEvent>");
        System.out.println("=============================================");
    }
}
```

### ApplicationListener<ApplicationStartedEvent>
- 스프링 컨텍스트가 동작하고 나서 수행한다.
- bean 으로 등록하면 사용할 수 있다.

```java
@Component
public class ApplicationRunnerAndArgs implements ApplicationRunner {
    @Override
    public void run(ApplicationArguments args) throws Exception {
        System.out.println("=================");
        System.out.println("ApplicationRunner");
        System.out.println("Application Argument : contain foo? " + args.containsOption("foo"));
        System.out.println("Application Argument : contain bar? " + args.containsOption("bar"));
        System.out.println("==================");
    }
}
```

### ApplicationRunner
- ApplicationStartedEvent 와 유사하게 동작한다. 빈을 등록하고 컨텍스트 동작 후 수행한다.
- program argument 를 받을 수 있다. jar 파일을 동작할 때 --foo 이런 식으로 등록한다. -Dfoo 는 JVM 인자이다. 

```java
@Component
public class ApplicationListenerAfter implements ApplicationListener<ApplicationStartedEvent> {

    @Override
    public void onApplicationEvent(ApplicationStartedEvent event) {
        System.out.println("============================================");
        System.out.println("ApplicationListener<ApplicationStartedEvent>");
        System.out.println("============================================");

    }
}
```


### 무한 루프와 CommandLineRunner vs ApplicationRunner
- 이전에 텔레그램 봇을 만들면서 request 를 받을 while(true) 가 필요로 했다.
- 그 당시 검색을 통해 CommandLineRunner 를 배웠고, 이것을 사용하였다.
- 그런데 이때 문제는 CommandLineRunner가 while(true) 를 할 때 그외 어떤 조작도 어플리케이션에 입력되지 않았다. 
- 하지만 ApplicationRunner 와 위의 리스너들을 사용한 결과, while(true) 임에도 불구하고 다른 컨트롤러를 호출하는 등 명령이 가능했다.
- 이유는 무엇일까? 멀티스레드의 문제였을까? 
- 이러한 문제에 의해서라도 ApplicationRunner 을 사용할 이유가 있어 보인다.

```java
@Component
public class CommandLineRunnerAndArgs implements CommandLineRunner {
    @Override
    public void run(String... args) throws Exception {

        System.out.println("start infinitive loop!");
        while (true){
            Thread.sleep(1000);
            System.out.println("looping");

        }
    }
}
```