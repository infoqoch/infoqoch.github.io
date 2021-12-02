---
layout: post
author: infoqoch
title: 스프링의 HttpMessageConverters 와 MvcMock
categories: [spring]
tags: [spring, test]
---

## 들어가며
- 스프링은 데이타에 대하여 자동 바인딩을 지원한다. 
- 아래의 예제는 rest api를 맵핑한 것이며, controller 에서 구현하였다.

## 구현
- 아래의 예제는 json 으로 데이타를 수신한다. 하지만 @RequestBody 를 통해 json 을 pojo 로 자동 바인딩한다. 
- 이는 스프링의 HttpMessageConverters 을 통해 가능하다.
 
```sql
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

## 테스트코드
- RestController 에 대한 테스트코드는 아래와 같이 작성한다. 

```sql
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Slf4j
@AutoConfigureMockMvc
public class SimpleControllerTest {

	@Autowired
	MockMvc mockMvc;

	@Test
	void init() {
		log.info("hi");

	}

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