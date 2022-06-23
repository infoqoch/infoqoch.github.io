---
layout: post
author: infoqoch
title: thymeleaf, 객체에 대한 null 처리
categories: [thymeleaf]
tags: [thymeleaf]
---

- 스프링 컨트롤러에서는 null이 올 수 있는 객체에 대해서는 `@Nullable`, `@RequestParam(required=false)` 등 어너테이션을 붙인다.
- 타임리프에서도 객체에 대한 null을 보정할 수 있다. `(객체)?.(필드값)` 으로 물음표를 삽입한다. 
- 값이 존재하지 않으면 그 값을 공백으로 한다. 아래의 코드를 참고하자.

```html
<td><input type="text" name="objId" th:value="${obj?.id}" ></td> 
```

- 다른 방법은 model에 처음부터 빈 객체를 넣는 것이다. 

```java
@GetMappoing("/form")
void execute(Model model){
    model.addAttribute("obj", new Object());
}
```