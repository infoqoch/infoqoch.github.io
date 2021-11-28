---
layout: post
title: 스프링부트와 Rest api, json
author: infoqoch
categories: [spring]
tags: [spring, rest, json]
---

### 들어가며
- 스프링의 Controller 의 메서드의 리턴 값은 String 과 void 로 있으며, 이것은 view 의 위치를 의미한다(redirect:/main 으로 url 을 가리킬 수도 있지만..). 하지만 특정 값을 클라이언트에 전달할 수 있으며 이 경우 RestController 와 ResponseBody 등을 사용한다. 
- RestApi 는 보통 json 을 자주 활용하며, 자바 스프링은 이를 쉽게 다루도록 도와준다. 

### controller 에서 json

```java
@GetMapping(value = "/board/{bno}", produces = MediaType.APPLICATION_JSON_VALUE)
public ResponseEntity<List<ReplyDTO>> getListByBoard(@PathVariable("bno")Long bno){
    log.info("bno : "+bno);
    return new ResponseEntity<>(replyService.getList(bno), HttpStatus.OK);
}
```

- ResponseEntity는 Restapi를 활용하기 위한 좋은 데이타타입으로 사용된다. 활용하기에 좋은 이유로는 헤더를 사용할 수 있기 때문이다. 위의 예제는 HttpStatus.OK로 간단하게 처리하지만 다양한 Header 객체를 생성할 수 있다. 
- 데이타 타입과 자료 구조를 쉽게 entity 바디로 바인딩한다.  
  
```java
@PostMapping("")
public ResponseEntity<Long> register(@RequestBody ReplyDTO replyDTO){
    log.info(replyDTO);

    Long rno = replyService.register(replyDTO);

    return new ResponseEntity<>(rno, HttpStatus.OK);
}
```

- 컨트롤러에서는 @RequestBody를 통해 json 을 데이타타입으로 자동 주입한다. 
  
### HTML, javascript와 ajax
    
```js
function loadJSONData(){
    $.getJSON('/replies/board/'+bno, function(arr){
        console.log(arr);

        var str = "";

        $('.replyCount').html("Reply Count : "+arr.length)

        $.each(arr, function (idx, reply){
            console.log(reply);

            str+='<div class="card-body" data-rno="'+reply.rno+'"><b>'+reply.rno+'</b>'
            str+='<h5 class="card-title">'+reply.text+'</h5>'
            str+='<h6 class="card-subtitle mb-2 text-muted">'+reply.replyer+'</h6>'
            str+='<p class="card-text">'+formatTime(reply.regDate)+'</p>'
            str+='</div> '
        });
        listGroup.html(str);
    });
};

function formatTime(str){
    var date = new Date(str);

    return date.getFullYear() + '/' +
        (date.getMonth()+1)+ '/' +
        date.getDate() + ' ' +
        date.getHours() + ':' +
        date.getMinutes();
}

$('.replySave').click(function (){
    var reply = {
        bno: bno,
        text: $('input[name="replyText"]').val(),
        replyer: $('input[name="replyer"]').val()
    }
    console.log(reply);
    $.ajax({
        url : '/replies/',
        method : 'post',
        data : JSON.stringify(reply),
        contentType : 'application/json; charset=utf-8',
        dataType : 'json',
        success : function (data){
            console.log(data);

            var newRno = parseInt(data);

            alert(newRno + "번 댓글이 등록되었다. ")
            modal.modal('hide');
            loadJSONData();
        }
    });
});

```

- ajax를 활용하여 특정 json 값을 가져오거나(get) 특정 json 값을 입력한다(post)

### body의 존재 유무에 따라
- 마지막으로 delete 통신 방식을 통해 body를 전달하려다 실패한 경험을 공유하고자 한다. delete를 body 형태로 통신하려 하였지만 계속 에러가 발생했다. 
- 특이한 점은 바디는 컨트롤러에 옮겼고, 서버에서는 원하는 요구사항이 동작했다. 다만,  ajax는 통신 결과를 error로 받아온다.
  
```js
$.ajax({
    url: '/replies/',
    method:'delete',
    data: JSON.stringify(reply),
    contentType:'application/json; charset=utf-8',
    dataType:'json',
    success : function (data){
        alert(data);
    }, error : function (request,status,error) {
        alert("code:" + request.status + "\n" + "message:" + request.responseText + "\n" + "error:" + error);
    }
});

// 메시지 코드 출처: https://shonm.tistory.com/454 [정윤재의 정리노트]
```
 
- 에러의 발생 이유를 찾아본 결과, delete 메서드 방식은 페이로드를 지원하지 않는다. 그러니까 json(body)을 지원하지 않는다. get과 같이 @PathVariable(url 매개변수)를 통해서는 가능하다. 
> 페이로드 관련 내용 : https://blog.naver.com/lewisel/221829301069

- 다음과 같이 변경했다.
    
```js
$.ajax({
    url: '/replies/'+id,
    method:'delete',
    success : function (data){
        alert(data);
    }
});
```