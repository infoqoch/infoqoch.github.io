---
layout: post
author: infoqoch
title: spring Rest api 예외처리
categories: [spring]
tags: [spring]
---

## 들어가며
- Controller의 경우 보통 몇 가지의 view 탬플릿을 만들고, 해당 view로 전달하면 된다. 
- RestController의 경우 예외를 처리하는 다양한 방식이 있지만 가장 단순하고 빠른 방법은 RestControllerAdvice을 활용하는 방식이다.

## RestControllerAdvice의 활용
- RestExceptionAdvice 의 경우 모든 RestController에 대한 aop로서 동작한다. 
- 기본적인 스프링의 예외처리는, 발생한 예외가 WAS까지 전파 된 후, WAS가 해당 예외를 컨트롤러로 다시 전달하여, 컨트롤러에서 예외처리를 수행하는 방식이다.
- ExceptionHandler은 예외의 전파를 최소화 하는 방식이다. Dispatcher Servlet는 예외에 대하여 그것의 하위 기능인 ExceptionResolver 에서 예외처리를 한다. 그러니까 예외 발생 -> DispactherServlet -> ExceptionResolver -> 예외처리 및 종료의 흐름을 가진다. 
- ResponseStatus은 헤더의 응답값을 정의한다.
- 특정 객체(아래의 코드에서는 ErrorResult)를 리턴값으로 전달하거나 ResponseEntity로 응답 가능하다. 객체로 응답값을 전달할 경우 Getter가 있어야 한다. 

```java
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;


@Slf4j
@RestControllerAdvice
public class RestExceptionAdvice {

    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ExceptionHandler({MethodArgumentTypeMismatchException.class, IllegalArgumentException.class})
    public ErrorResult illegalArgumentExceptionHandle(Exception e) {
        log.error("[exception] ", e);
        return new ErrorResult("값을 제대로 입력하여 주세요.", HttpStatus.BAD_REQUEST.toString());
    }

    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ExceptionHandler
    public ErrorResult notFoundSuchFileExceptionHandler(NotFoundSuchDataException e) {
        log.error("[exception] ", e);
        return new ErrorResult("요청한 값을 찾을 수 없습니다.", HttpStatus.BAD_REQUEST.toString());
    }

    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    @ExceptionHandler
    public ErrorResult exHandle(Exception e) {
        log.error("[exception] ", e);
        return new ErrorResult("서버 내부에 문제가 발생하였습니다.", HttpStatus.INTERNAL_SERVER_ERROR.toString());
    }
}
```


```java
import lombok.AllArgsConstructor;
import lombok.Getter;

@AllArgsConstructor
@Getter
public class ErrorResult {
    private String message;
    private String code;
}
```

