---
layout: post
author: infoqoch
title: spring 개발 규칙 - 커맨드와 쿼리는 분리한다.
categories: [spring]
published: false
tags: [spring]
---

## 커맨드와 쿼리를 철저하게 분리한다.
- 매서드에 대한 이해와 유지보수의 편의를 위하여, 매서드 간 명확한 업무 분리가 필요하다. 
- 특히 데이터를 변경하는 커맨드와 데이터를 조회하는 쿼리를 분리해야 한다. 

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
// 엔티티에는 롬복을 제한하지만, DTO에는 단순한 데이터 통신을 위한 값의 모음이기 때문에, @Data 등 자유롭게 사용. 

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