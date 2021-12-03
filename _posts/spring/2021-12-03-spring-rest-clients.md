---
layout: post
author: infoqoch
title: 스프링 rest clients
categories: [spring]
tags: [spring]
---

## 들어가며
- 스프링은 rest controller 를 제공하며 동시에 client 도 제공한다. 클라이언트는 크게 두 개가 있다. rest client 와 web client 로서 각 각 동기 비동기 방식을 채택했다.

## 구현

- pom.xml 에 dependency를 추가한다. RestClient 는 기본 내장되나 WebClient 는 WebFlux 를 가져와야 한다. 
- RestClient는  httpclient를 주입받아 사용할 수 있다. 

```xml
<!--  webflux for async client -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>
<dependency>
    <groupId>org.apache.httpcomponents</groupId>
    <artifactId>httpclient</artifactId>
</dependency>
```

```java
@RestController
public class SampleRestController {

	@GetMapping("/three")
	public String sleepThree() throws InterruptedException {
		Thread.sleep(3000);
		return "after Three seconds";

	}

	@GetMapping("/five")
	public String sleepFive() throws InterruptedException {
		Thread.sleep(5000);
		return "after Five seconds";

	}
}
```
- 필요에 따라 Client 를 조작하여 빈에 등록할 수 있다. 

```java
@Configuration
public class RestClientConfig {

	@Bean
	public WebClientCustomizer webClientCustomizer() {
		return new WebClientCustomizer() {
			@Override
			public void customize(Builder webClientBuilder) {
				webClientBuilder.baseUrl("http://localhost:8080/");
			}
		};
	}

}
```

```java
@Component
@Slf4j
public class RestClientsRunner implements ApplicationRunner{
	@Autowired
	RestTemplateBuilder restTemplateBuilder;

	@Autowired
	WebClient.Builder webClientBuilder;

	@Override
	public void run(ApplicationArguments args) throws Exception {
		restClientTest();
        
        webClientTest();
	}

	private void webClientTest() {
		WebClient webClient = webClientBuilder.build();
		Mono<String> three2 =  webClient.get().uri("/three")
				.retrieve()
				.bodyToMono(String.class);

		Mono<String> five2 =  webClient.get().uri("/five")
				.retrieve()
				.bodyToMono(String.class);

		StopWatch stopWatch2 = new StopWatch();

		System.out.println("======== webClient 시작 ==========");

		stopWatch2.start();

		three2.subscribe(s -> {
			System.out.println(s);
			if(stopWatch2.isRunning()) {
				stopWatch2.stop();
				System.out.println(stopWatch2.prettyPrint());
			}
			stopWatch2.start();

		});

		five2.subscribe(s -> {
			System.out.println(s);
			if(stopWatch2.isRunning()) {
				stopWatch2.stop();
				System.out.println(stopWatch2.prettyPrint());
			}
			stopWatch2.start();
		});

        // stopWatch2.stop();
        // System.out.println(stopWatch2.prettyPrint());

    }

	private void restClientTest() {
		System.out.println("======== restClient 시작 ==========");

		RestTemplate restTemplate = restTemplateBuilder.build();

		StopWatch stopWatch = new StopWatch();
		stopWatch.start();

		String three =  restTemplate.getForObject("http://localhost:8080/three", String.class);
		System.out.println(three);

		String five =  restTemplate.getForObject("http://localhost:8080/five", String.class);
		System.out.println(five);

		stopWatch.stop();
		System.out.println(stopWatch.prettyPrint());
	}

}
```

- stopwatch를 다루는 방식이 rest 와 web 이 다르다. rest 는 동기로 진행되기 때문에 마지막에 stop() 을 하면 된다.
- 한편, webClient 의 경우 
  - 무엇이 먼저 끝날지 모르기 때문에 각 각의 스레드마다 stop, start를 따로 해줘야 하며
  - 메인스레드 마지막에 stop을 뒀지만 스탑워치의 매서드 중 가장 먼저 만나게 되므로 다른 방식으로 정리해야 한다. 
  - 멀티스레드의 코딩이 복잡하다는 것을 알게 되었다. 