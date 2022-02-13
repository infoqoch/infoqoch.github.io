---
layout: post
author: infoqoch
title: spring, rest controller 개발의 기본
categories: [spring]
tags: [spring, jpa, rest]
---

## 들어가며
- 스프링부트 / 스프링-데이터-jpa / rest api의 개발에서 기본적으로 지켜야할 내용들을 정리합니다.
- 김영한 선생님의 '스프링부트-JPA-API개발-성능최적화' 수업을 들으면서 정리 중입니다. (사실 jpa와 관련한 대부분의 블로깅은 김영한 선생님의 자료를 기본, 기준으로 하고 있습니다! 존경합니다😘.)

## API Controller의 Param은 entity가 되어서는 안된다. DTO로 해야 한다. 
- controller에서 entity를 param으로 받을 경우 간단해서 쉽다.
- validation 을 entity에 넣는 것이 좋지 않다. select, update 등 다양한 조건에서의 검증 로직이 다른데 이를 엔티티에서 다 감당할 수 없다. 더 나아가 프리젠테이션 로직이 엔티티에 들어가면 안되며 분리되어야 한다. 
- 엔티티 자체를 리턴하면, count 등 다양한 프로퍼티스에 대한 확장 가능성이 없다. 
- 문제는 entity의 스펙이 바뀌면 api 스펙도 변경될 수 있다. 이 경우 매우 위험하다.
- entity로 할 경우, 어떤 파라미터를 받는지 직관적으로 알 수 없다. DTO에 정확하게 필요한 필드를 설정하면, 어떤 데이터가 들어올지 알 수 있다. 기본적으로 코딩 자체에서 예측 가능한 방식으로 만드는 것이 중요함을 느낀다. 
- 회원가입이란 컨트롤러를 만든다 하더라도, 회원가입의 방식이 매우 다양할 수 있다. 그때마다 스펙이 변한다. 안전하게 엔티티가 아닌 DTO로 받으며, api 마다 DTO를 따로 만든다. 


```java
// DTO(CreateMemberRequest)와 entity(Member)를 분리한다.
@PostMapping("/api/v2/members")
public CreateMemberResponse saveMemberV2(@RequestBody @Valid CreateMemberRequest request){
    Member member = new Member();
    member.setName(request.getName());
    Long id = memberService.join(member);
    return new CreateMemberResponse(id);
}

@Data
@AllArgsConstructor
static class CreateMemberResponse {
    private Long id;
}

@GetMapping("/api/v2/members")
public Result membersV2(){
    final List<Member> findMembers = memberService.findMembers();
    final List<MemberDto> collect = findMembers.stream()
            .map(member -> new MemberDto(member.getName()))
            .collect(Collectors.toList());
    return new Result(collect, LocalDateTime.now());
}

@Data
@AllArgsConstructor
static class Result<T> {
    private T data;
    private LocalDateTime createdDate; // 스펙을 추가할 수 있다.
}

@Data
@AllArgsConstructor
static class MemberDto{
    private String name;
}
```

## 롬복의 제한
- 엔티티에는 롬복을 제한.
- DTO에는 @Data 등 자유롭게 사용. 

## 커맨드와 쿼리를 철저하게 분리한다.

- 컨트롤러 

```java
@PutMapping("/api/v2/members/{id}")
public UpdateMemberResponse updateMemberV2(
        @PathVariable("id") Long id,
        @RequestBody @Valid UpdateMemberRequest request){

    memberService.update(id, request.getName());

    // 영속성 컨텍스트를 새로 하여 값을 호출한다. 쿼리와 커맨드를 분리한다.
    final Member findMember  = memberService.findOne(id);

    return new UpdateMemberResponse(findMember.getId(), findMember.getName());
}


// 하나의 컨트롤러에만 사용하는 경우 내부 클래스로 한다.

@Data
@AllArgsConstructor
static class UpdateMemberResponse {
    private Long id;
    private String name;

}

@Data
static class UpdateMemberRequest {
    private String name;
}
```

- 서비스

```java
@Transactional
public void update(Long id, String name) {
    final Member findMember = findOne(id);
    findMember.setName(name);
}
```

- 위의 매서드는 Member 엔티티를 더티체킹으로 갱신하는 메서드이다.
- 리턴은 void 이다. void로 하는 이유는 매서드 간 업무를 철저하게 분리하기 위함이다. 
- `return findMember;`를 하게 될 경우, 커맨드가 쿼리(select)까지 수행하게 된다. 이로 인하여 매서드 간 업무가 섞이게 되고 유지보수가 어려워 진다. 
- 리턴이 필요하다 하더라도 pk를 방식(`return findMember.getId()`)정도로 제한다. 