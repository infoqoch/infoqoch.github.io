---
layout: post
author: infoqoch
title: Remove Assignments to Parameters, 객체에서는 어떻게 적용하는가?
categories: [java]
tags: [java, refactoring]
---

## 매개변수에 값을 대입해서는 안된다. Remove Assignments to Parameters
- 아래의 코드를 보면 매개변수에 값을 대입하여 변경함을 확인할 수 있다. <리팩터링>은 매개변수는 final을 사용하진 않지만 묵시적으로 불변한 상태를 유지해야 한다고 한다. 그래서 지역변수 result를 두고, result에 값을 대입함을 확인할 수 있다. 

```java
int discount(int inputVal, int quantity) {
  if (inputVal > 50) {
    inputVal -= 2;
  }
  // ...
}
```

```java
int discount(int inputVal, int quantity) {
  int result = inputVal;
  if (inputVal > 50) {
    result -= 2;
  }
  // ...
}
```

- 한편, 객체는 어떻게 다뤄야 하는지 의문이 들었다. 매개변수에 특정 클래스가 들어갈 수 있고, 해당 메서드 로직을 통해 수정할 수 있다. 더 나아가 객체는 기본타입과 달리 같은 주소값을 가지는 매개변수만 있다면 어디서든 변경 가능하다. 그러므로 객체를 수정하는 일은 매우 간편하다. 그렇게 하면 안되는가?

```java
public class RemoveAssignmentsToParameters {
    public static void main(String[] args) {
        User user = new User("kim", LocalDate.of(2000, Month.of(5), 14));
        
        updateAccessDate(user);

        System.out.println("회원의 마지막 접속일은? = " + user.lastAccessDate);

    }

    private static void updateAccessDate(User user) {
        user.setLastAccessDate(LocalDate.now());
    }

    @Data
    @AllArgsConstructor
    static class User {
        private String name;
        private LocalDate lastAccessDate;
    }
}
```

- 만약 저자의 방식에 따라 매개변수를 수정하지 않고 지역변수를 하나 만든다면 아래와 같은 코드가 될 것이다.

```java
public static void main(String[] args) {
    User user = new User("kim", LocalDate.of(2000, Month.of(5), 14));
    
    user = updateAccessDate(user); //  user를 넣고 user를 대입한다.

    System.out.println("회원의 마지막 접속일은? = " + user.lastAccessDate);
}

private static User updateAccessDate(User user) {
    return new User(user.getName(), user.getLastAccessDate());
}
```

- 두 번째 코드는 그냥 봐도 예쁘지가 않다. user를 삽입하여 User를 리턴하고, 해당 참조변수 user에 대입하는 것 자체가 복잡하다. 더 나아가 다시 객체를 생성하고 복사하고 리턴하면 너무 많은 리소스를 사용한다. 더 복잡한 객체일 경우 이를 복사하는데 더 많은 코드와 노고가 필요하다. 
- 첫 번째 코드 역시도 좋은 코드가 아니다. updateAccessDate의 코드를 보면 User 객체의 필드만을 다룬다.  해당 메서드는 User 클래스 안에 있는 것이 더 낫다. 
- User로 해당 메서드를 옮기면 아래의 코드가 된다. 

```java
public static void main(String[] args) {
    // 중략
    user.updateAccessDate();   
}

@Data
@AllArgsConstructor
static class User {
    private String name;
    private LocalDate lastAccessDate;

    private void updateAccessDate() {
        lastAccessDate = LocalDate.now();
    }
}
```

- 훨씬 깔끔하고 명확하고 단순해졌다. 이를 <리팩터링>에서는 Move Method, Move Field라 한다. 
- 이렇게 정리하고 보니까, `user = someMethodToModifyUser(user);` 혹은 `someMethodToModifyUser(user);`  라는 식의 코드가 얼마나 이상한 코드인지 깨닫게 되었다. 그런데 왜 그런 괴상한 코드에 끌렸던 것일까? 돌이켜보니까. 그렇게 코드를 작성하는 경우가 있었다.

```java
// 지금부터 작성하는 코드는 테스트하지 않았습니다. 동작하지 않을 수 있습니다.

@PostMapping("/user/reg")
public void regUser(@ModelAttribute UserRegReqDto reqDto){
    validDto(reqDto);
    correctData(reqDto);
    userService.register(reqDto);
}

private void correctData(UserRegReqDto reqDto){
    // 이상한 예시지만 그냥 하겠음!!
    // 컨트롤러에서 성과 이름을 따로 가져왔다고 가정한다. DB에는 칼럼이 name이 하나이다. 그래서 두 개를 하나로 합쳐야 한다.
    String name = reqDto.getSurName() + reqDto.getLastName();
    reqDto.setName(name);
}
```

- 위의 코드를 보면, correctData 매서드를 활용하여 reqDto를 변경함을 확인할 수 있다. 
- Move Method를 통해 해당 메서드를 Dto로 옮기고자 한다. 그런데 의문이 든다. dto는 단순한 데이터 송수신을 위한 객체이다. 단순한 데이터 처리 객체에 로직을 구현하는 것이 좋은 코드일까? 음... 고민이 필요해 보인다. 어찌됐든 이러한 고민은 차치하고, 해당 메서드를 dto로 옮기면 아래와 같은 코드가 될 것이다.

```java
public class UserRegReqDto{
    public String getName(){
        return this.surName + this.lastName;
    }
}
```

- 그러나 위의 코드는 애당초 좋은 코드가 아니다. 왜냐하면 Controller와 Service는 분리되어야 하는데, UserRegReqDto은 누가보더라도 Controller에서만 사용하는 객체이다. Service는 Controller에 의존하지 않는 별도의 레이어다. Service의 매개변수와 Controller의 매개변수를 분리해야 한다. 이를 살려서 코드를 작성하면 아래와 같이 될 것이다.

```java
@PostMapping("/user/reg")
public void regUser(@ModelAttribute UserRegReqDto reqDto){
    validDto(reqDto);
    User user = reqDto.toUser();
    userService.register(user);
}
```

- 앞서의 코드보다 훨씬 깔끔하고 명확한 코드가 되었다. 
- 절차지향적 개발을 할 때가 있고 이러한 경우 Controller와 Service에 수많은 메서드가 과중되는 경향이 있다. 그리고 객체는 DTO로 격하되고 Map의 발전형 형태로만 사용된다. 
- 절차지향적 개발을 하더라도 객체지향적 개발을 공부하면 더 좋은 코드를 작성할 수 있다. 헤헤...