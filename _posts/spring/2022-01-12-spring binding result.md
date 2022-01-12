---
layout: post
author: infoqoch
title: 스프링 ModelAttribute의 BindingException 잡기
categories: [spring]
tags: [spring]
---

## 들어가며
- @ModelAttribute 등 컨트롤러의 메서드를 통해 객체나 값을 받을 때 예외가 발생한다. 매서드 파라미터에 대하여 예외를 처리할 수 없기 때문에 다소 까다롭다.
- 이 경우 reqeust에서 꺼내오고 null 처리를 하거나 데이타 검증을 할 수 있지만 이 또한 번거롭다.
- 이 때 BindingResult를 사용 가능하다. BindingResult은 Validate에 대한 작업 이외의 다양한 업무를 한다. 

```java
public String editTemplateGoods(@ModelAttribute ReqVO reqVO, BindingResult bindingResult, HttpServletRequest request, HttpServletResponse response) {
    // 소스코드
}
```
