---
layout: post
author: infoqoch
title: thymeleaf / 매개변수의 null 처리
categories: [thymeleaf]
tags: [thymeleaf, spring]
---

- 매개변수를 RequestParam으로 받을 때, 해당 값이 null일 수도 있다. 컨트롤러에서는 @Nullable @RequestParam(required=false)등을 통해 처리한다. 
- 하지만 타임리프에서도 null처리를 해야한다. 그 방법은 (객체)?.(필드값) 로 한다. 그 값이 존재하지 않으면 그 값을 공백으로 한다. 아래의 코드를 참고하자.

```html
<td><input type="text" name="bookId" th:value="${bookDto?.id}" ></td> 
```

- 컨트롤러는 아래와 같다. 

```java
@GetMapping("/register")
public void registerForm(Long bid, Model model){
    BookDTO bookDto = null;
    try{
        if(bid>=0){
            bookDto = bookService.getBookDTObyId(bid);
        }
    }catch (NullPointerException e){

    }
    model.addAttribute("bookDto", bookDto);
}
```