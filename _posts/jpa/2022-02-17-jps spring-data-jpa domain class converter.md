---
layout: post
author: infoqoch
title: spring-data-jpa, web 확장 -도메인 클래스 컨버터
categories: [jpa]
tags: [jpa, spring]
---

## 도메인 클래스 컨버터
- 컨트롤러에서도 도메인을 조회할 수 있다. 

## 기본적인 형태
- 아래의 코드를 보면 id를 api의 인자로 받고, 해당 인자를 바로 Member 로 컨버팅하여 컨트롤러 코드블럭에서 사용한다. 

```java
@RestController
@RequiredArgsConstructor
public class MemberController {

    private final MemberRepository memberRepository;

    @GetMapping("/members1/{id}")
    public String findMember1(@PathVariable("id") Long id){
        return memberRepository.findById(id).get().getUsername();
    }

    @GetMapping("/members2/{id}")
    public String findMember2(@PathVariable("id") Member member){
        return member.getUsername();
    }

    @PostConstruct
    private void intit(){
        memberRepository.save(new Member("kim", 15));
    }
}
```

- 위의 경우 트랜잭션 외부에서 진행하기 때문에, 변경과 관련하여 사용하기에 신경써야 할 부분이 너무 많다. 
- pk 값을 기준으로 Member를 가져오기 때문에 제한적인 상황에서만 사용 가능하다. 
- 그러므로 아주 간단한 조회 기능을 위해서만 사용하는 것을 권장한다. 

## 페이징과 정렬
- 페이징과 정렬을 사용할 수 있다.
- 기본 형태는 페이지가 0부터 시작한다. 

```java
@PostConstruct
private void intit(){
    for(int i=0; i<100; i++){
        memberRepository.save(new Member("kim"+i, i));
    }
}

@GetMapping("/members")
public Page<MemberDto> list(@PageableDefault(size = 5) Pageable pageable){
    final Page<Member> page = memberRepository.findAll(pageable);
    final Page<MemberDto> map = page.map(MemberDto::new);
    return map;
}
```

- http://localhost:8080/members?page=2&size=3&sort=id,desc
- 다양한 인자를 사용할 수 있다. 

- 페이징과 관련해서는 프로퍼티스에서 설정 가능하다.

```yml
spring:
  data:
    web:
      pageable:
        default-page-size: 10
        max-page-size: 2000
#        one-indexed-parameters: true
```

### 페이지를 1부터 시작하려면?
#### spring.data.web.one-indexed-parameters: true 로 설정한다. 
- 실제 page로 선별된 값은 page를 3으로 하면, page가 2인 데이터를 추출한다. 하지만 page 객체의 값들도 page를 2에 맞춰서 리턴한다. 그러니까 일관성이 없으며 이러한 한계를 이해하고 사용해야 한다. 

- http://localhost:8080/members?page=3

```json
{   "content": {
    <!-- 중략 -->
},"pageable": {
    "sort": {
        "empty": true,
        "sorted": false,
        "unsorted": true
    },
    "offset": 10,
    "pageNumber": 2,
    "pageSize": 5,
    "unpaged": false,
    "paged": true
},
"last": false,
"totalPages": 20,
"totalElements": 100,
"size": 5,
"number": 2,
    "sort": {
        "empty": true,
        "sorted": false,
        "unsorted": true
    },
    "first": false,
    "numberOfElements": 5,
    "empty": false
}
```

#### pageable 을 직접 정의한다.
- 위의 문제로 사실상 정의하는 것이 나아 보인다.
- 가장 빠르고 쉬운 방법은 페이지가 0부터 시작됨을 인정하는 방식..이다.

