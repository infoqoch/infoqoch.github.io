---
layout: post
author: infoqoch
title: 스프링부트와 DI의 다양한 방법들
published: false
last_modified_at: 
categories: [spring]
tags: [spring]
---

- 차후에 좀 더 정리하자.

```java
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
//@AllArgsConstructor
public class MemberService {

//    필드에 바로 주입하는 방식은 테스트코드 작성에 어렵다. 왜냐하면 MemberService 에 삽입하기가 어렵기 때문이다.
//    @Autowired
//    private MemberRepository memberRepository;

//    테스트 코드 등 유연한 사용을 위하여 세터를 통해 DI 가능하다.
//    하지만, 어플리케이션 로딩 시점에서 자동 조립 이후, 세터를 쓸 일은 없음. 세터를 닫는 것이 좋음.
//    @Autowired
//    public void setMemberRepository(MemberRepository memberRepository){
//        this.memberRepository = memberRepository;
//    }

//   생성자 인젝션을 추천.
//   테스트 코드에서도 사용 가능함. 동시에 생성자를 통해 강제적으로 삽입해야 하는 장점이 있음.
//    @Autowired
//    public MemberService(MemberRepository memberRepository) {
//        this.memberRepository = memberRepository;
//    }

//    생성자를 AllArgumentConstructor 로 사용하여 롬복으로 생성자를 자동 생성할 수 있으며 이러한 것을 RequiredArgsConstructor 이다. final 필드만 있는 값을 생성자로 한다.

//   final을 사용한다.
    private final MemberRepository memberRepository;


```

