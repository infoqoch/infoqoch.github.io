---
layout: post
author: infoqoch
title: 스프링의 HttpMessageConverters와 MvcMock
categories: [spring]
tags: [spring, test]
---

## 들어가며
- 스프링은 데이타에 대하여 자동 바인딩을 지원한다. 
- 아래의 예제는 rest api를 맵핑한 것이며, controller 에서 구현하였다.
- 응답값에 대한 import static 의 경우 `MockMvcResultMatchers` 의 메서드를 사용한다.

## 구현
- 아래의 예제는 json 으로 데이타를 수신한다. 하지만 @RequestBody 를 통해 json 을 pojo 로 자동 바인딩한다. 
- 이는 스프링의 HttpMessageConverters 을 통해 가능하다.
 
```java
@Controller
@Slf4j
public class SimpleController {

	@PostMapping("/hello")
	public @ResponseBody Greet hello(@RequestBody Greet greet) {
		log.info("request to /hello, Greet : {}", greet);
		greet.setTime(LocalDateTime.now());
		return greet;
	}

	@GetMapping("/hi")
	public @ResponseBody String hi() {
		log.info("request to /hi");
		return "hi!";
	}
}
```

## MvcMock와 테스트코드
- RestController 에 대한 테스트코드는 아래와 같이 작성한다. 
- MvcMock 를 사용한다. MockMvc의 경우 인코딩의 문제가 발생하기 때문에 init과 같이 세팅한다.

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Slf4j
@AutoConfigureMockMvc
public class SimpleControllerTest {

    @Autowired
    private WebApplicationContext ctx;

    @BeforeEach
    void init(){
        this.mockMvc = MockMvcBuilders.webAppContextSetup(ctx)
                .addFilters(new CharacterEncodingFilter("UTF-8", true))
                .build();
    }

	
	private MockMvc mockMvc;

	@Test
	void getTest() throws Exception {
		mockMvc.perform(get("/hi"))
			.andExpect(status().isOk())
			.andExpect(content().string("hi!"))
			.andDo(print());
	}

	@Autowired
	ObjectMapper objectMapper;

	@Test
	void postTest() throws Exception {
	    String content = objectMapper.writeValueAsString(new Greet("aoi"));

		mockMvc.perform(post("/hello")
				.content(content)
				.contentType(MediaType.APPLICATION_JSON)
				.accept(MediaType.APPLICATION_JSON)
				)
			.andExpect(status().isOk())
			.andExpect(content().string("hi!"))
			.andDo(print());
	}

}
```

## MockMvc의 데이타 검증
- Mock으로 받은 데이터의 검증은 기대하는 메시지로 응답하는지로 확인할 수 있다고 한다. 
- 그 방법은 다음과 같다. 응답값을 String으로 전환하고, 해당 값을 조작하는 방식이다. json으로 받은 경우 ObjectMapper를 통해 pojo로 변환 가능하다. 

```java
String requestContent = objectMapper.writeValueAsString(insertDTO);

mockMvc.perform(post("/dictionary")
				.content(requestContent)
				.contentType(MediaType.APPLICATION_JSON)
				.accept(MediaType.APPLICATION_JSON)
		)
		.andExpect(status().isOk()) // 200을 기대한다. 
		.andDo(print()) // 어떤 값이 왔는지 확인하기 위하여 콘솔에 값을 출력한다.
		.andReturn() 
		.getResponse()
		.getContentAsString()  // 응답값을 string으로 만든다. 
		.contains("정상적으로 등록되었습니다"); // string에 다음의 값이 있는지를 검색한다. 
```