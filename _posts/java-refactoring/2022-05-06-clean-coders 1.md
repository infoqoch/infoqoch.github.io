---
layout: post
author: infoqoch
title: 클린코더스, 레거시 코드를 리팩터링의 간단한 예 (좋은 함수function로의 변경)
categories: [refactoring]
tags: [refactoring, java]
---

# function structure 좋은 함수를 구현하기 위한 방법
## Temporal Coupling
- 시기에 따라 발생하는 결합이 있다. 특정 시기에 로그를 작성하거나 메모리를 해제하는 등 반드시 필요하지만 핵심적인 로직이 아닌 경우가 있다.
- 예를 들면 아래의 코드는 File을 열고 닫아야 한다. 이로 인해 해당 메서드는 File 객체에 대한 종속성을 가진다. 

```java
// file should be opened
fileCommand.process(file);
// file should be closed
```

- 아래의 데코레이션 패턴을 통하여 File의 open 과 close를 처리한다. 이를 통해 핵심적인 로직, 아래서는 임시 객체, 에 집중할 수 있다. 

```java
fileCommandTemplate.process(myFile, new FileCommand(){
    public void process(File f){

    }
});

class FileCommandTemplate{
    public void process(File f, FileCommand command){
        f.open();
        command.process(f);
        f.close();
    }
}
```

## CQS
- 커맨드와 쿼리를 분리해야 한다.
- 쿼리는 인자에 따른 데이터의 변경이 없어서 사이드 이펙트가 없음을 보장한다. command는 데이터를 변경하여 사이드 이펙트가 있음을 알 수 있다. 일종의 약속이며, 커맨드와 쿼리가 섞여 있으면, 신뢰가 무너지고 커뮤니케이션 비용(소스 분석 등)이 발생한다.

```java
// 기존
User u = authorizer.login(userName, password); // login 명령을 하였는데, User 객체가 나온다.

// 리팩터링
authorizer.login(userName, password); // 커맨드.. login 명령은 void
User u = authorizer.getUser(userName, password); // 쿼리.. getUser 명령은 return user; 
```

- 만약 command에서 정보를 넘긴다면 exception으로 넘길 수 있다. 

## tell, don't ask
- CQS를 지키면 코드는 자연스럽게 Tell, don't ask가 된다.
- Tell, don't ask란, 어떤 로직을 수행하기 위하여 어떤 데이터를 query하고 유효성을 검토하고 데이터를 생산하는 것이 아닌, 특정 객체에게 메서드를 통해 명령을 하는 코드로 변경됨을 의미한다. 

```java
if(user.isLoggedIn()){ // 로그인이 되었다면
    user.execute(command); // 커맨드, 차기 명령을 수행한다
}else{
    authentication.promptLogin(); // 쿼리, 특정 데이터를 클라이언트에 보여준다.
}
```

```java
try{ 
    user.execute(command); // 커맨드
}catch(User.NotLoggedIn e){
    authentication.promptLogin(); // 커맨드 실패시 예외를 던진다. command의 정보를 예외를 통해 던진다
}
```

```java
user.execute(command, authentication); // tell, don't ask. user 객체에 명령한다. 내부에서 어떤 식으로 동작할지 우리는 알 필요가 없다. 다만 요구받은 데이터만 잘 전달한다.
```

- cos를 더 밀어 붙인다. 유저의 로그인의 여부와 그것에 따른 커맨드 등의 행위는 User 객체가 해야지 외부의 로직에서 실행할 이유가 없다.
- 쿼리(ask)를 기반으로 로직을 짤 경우, 클라이언트 입장에서는 user.a().b().c(); 따위의 객체 스트림을 요구할 수밖에 없다. 그보다는 user.execute(command); 를 통해 User 객체가 모든 것을 처리할 수 있도록 하는 것이 더 명확하고 업무가 확실하게 분리된다. 
- 테스트 코드 작성에도 유리하다. 객체 스트림이 복잡할 수록 유닛테스트가 어려워진다. 목킹이나 페이크 구현 객체를 만드는데 힘들다.
- tell, don't ask를 하면 할 수록 query 메서드가 사라진다. 
- query 메서드는 일종의 public api이다. public api가 많아질 수록 개발자가 통제해야 할 코드가 많아진다. tell, don't ask를 지킬 수록 query 메서드는 줄어들고 개발자의 유지보수가 더 편리해진다.

## Law of Demeter 디미터의 법칙
- tell, don't ask를 잘 하기 위한 법칙
- 데이터를 호출할 때, 호출의 범위를 최소화 해야한다.

```java
user.a().b().c().doSomething(); 
// 객체 스트림으로 인해 복잡한 참조 관계가 드러난다. 
// 이 코드를 이해하기 위해서 우리는 user, a, b, c 객체에 대해 다 알아야 한다.

user.doSomething(); 
// 내장을 보여주지 않는다. 
// 로컬 변수 user 의 메서드만 사용한다. 
```

- Law of Demeter : Tell, don't ask를 구현하는 방법. 아래의 객체만 호출할 수 있다.
    - 인자로 전달된 객체
    - local에서 생성된 객체
    - 필드로 선언된 객체
    - 전역 객체

## early return
- return이 로직 중간에 있으면 이해하기 어렵다. 
- 특히 반복문의 break와 return은 코드를 이해하기 어렵게 만든다. 

```java
private boolean doSomething(){
    while(true){
        doSomething1();
        doSomething2();
        if(isDone){
            break;
            // 혹은 return result;
        }
        doSomething3();
    }
}
```

- 아래와 같은 코드는 가능하다.

```java
private boolean doSomething(){
    if(isTrue){
        return true;
    }else{
        return false;
    }
    return true;
}
```

## error handling
### 커맨드 메서드의 정보는 예외로 표현한다.
- 커맨드는 void이다. 그런데 값을 리턴하면 안된다. 이때 그냥 예외를 던진다.

```java
void push(int i){
    // return -1; // int의 입장에서 -1 역시도 값이 될 수 있음. 참조변수가 결과라 하더라도 null이 값이 될 수 있음. 
    if(stack.length=<0){
        throw new IllegalCapacity(); // 예외를 통해 명확하게 함
    }
}

public static class IllegalCapacity extends RuntimeException{

}
```

- 참고로 IllegalCapacity은 내부 클래스이다. 이를 통해 외부 클라이언트는 Stack.IllegalCapacity 의 형태로 사용한다. 이러한 방식이 예외의 메시지를 더 분명하게 드러낼 수 있다. 상황에 따라 적극적으로 사용하자. 

### checked exception은 가능하면 사용하지 않는다.
- checked exception 의 경우 사용하지 않는다. 사용한다면,
    - 명확한 이유... 예를 들면 명확하게 요구하는 지시사항이 있을 경우 사용할 수 있다. 
    - public api의 경우 믿을 수 없기 때문에 checked exception을 던진다. 
        -> 이런 경우 wrapper를 통해 사용해야 한다.

- 가장 이상적인 예외는 예외 그 자체로 이해할 수 있는 경우이다. 만약 예외처리를 Exception Resolver 등을 구현하고 처리해야하는 등 복잡한 요구사항이 있을 경우, 해당 예외에서 필드 등을 줄 수 있다.

## Null is not an error. null is a value
- null 은 값이다. 에러가 아니다.
- 그러므로 값이 없으며 nullㅇ이 반환되어서 안되는 상황에서는 예외를 던지는 것이 낫다.

```java
stack.pop();  // 대체로 pop는 null 이 리턴 되기를 기대하지는 않음. 그러므로 예외를 던진다.
repo.findById(123l);  // find의 경우 없을 수 있음을 상정함. 그러므로 예외가 아니라 null을 던질 수 있다. -1 과 같은 애매한 것을 던지면 안된다. 정확하게 null을 던지거나 Optional을 사용하거나 차라리 예외를 던져라.
```

## try도 하나의 역할이다
- try도 하나의 역할을 한다. 
- try가 메서드 처음에 나와야 한다. finally 가 마지막이어야 한다.
- try,catch,finally 내에는 하나의 메서드만 호출해야 한다. 


## 레거시 코드의 리팩터링
### 리팩터링 시작 전, 반드시 테스트 코드를 작성한다.
- 리팩터링할때는 테스트코드가 없으면 위험하다. 테스트 코드를 작성한다.
- 테스트 코드는 회귀테스트로서 기대하는 동일한 결과값을 출력할 수 있도록 한다. 예제에서는 HTML의 결과물을 사용하였다. 
- 만약 main 에 코드가 복잡하게 나열되어 있으면, 클래스로 추출하고 invoke, execute 등의 메서드로 추출한다. 이를 통해 결과값을 테스트 할 수 있는 상태로 변경한다. 

```java
// before
public static void main(String[] args){
    // 로직들.....
    // 로직들.....
    // 로직들.....
    // print.... 결과를 html로 렌더링한다.
}

// after
public static void main(String[] args){
    DoSomething do = new DoSomething();
    String result = do.execute(); // result의 결과가 테스트의 대상이 된다.
    print(result);
}
static class DoSomething {
    String execute(){
        // 로직들.....
        // 로직들.....
        // 로직들.....
    }
}
```

- 위의 경우 do.execute()의 결과값이 테스트의 대상이 된다. 우리는 기존의 코드에 여러 값을 삽입하고 이에 대한 결과값을 추출할 수 있다. 이를 회귀테스트의 기대값으로 사용한다. 
- 이러한 방식을 캐릭터라이제이션 테스트(Characterization Tests)라 한다. 

```html
<html>
    <head>
        <title>테스트 페이지</title>
    </head>
    <body>
        <h3>오늘의 수입</h3>
        <table>
            <tr>
                <th>날짜</th>
                <th>금액</th>
                <th>어제와 비교</th>
            </tr>
            <!-- 내용 ...... -->
        </table>
    </body>
</html>
```

- 임의의 값을 넣은 결과가 위와 같면, 이를 String expect = "<hrml>......</html>"; 의 지역변수로 가질 수 있다. 이를 테스트의 대상으로 사용한다. 혹은 특정 값이 렌더링이 되는지를 contains를 통해 할 수도 있다. 

```java
String expect = "<hrml>......</html>";
assertThat(do.execute()).isEqualTo(expect);
assertThat(expect).contains("expect contain this sentence!");
```

- 이 테스트 코드 하나만으로 리팩터링에 대한 자신감이 생긴다. 이러한 테스트를 만드는 것은 힘들고 우아하지는 않지만 그러나 명확하기 때문에 충분히 할 가치가 있다고 생각한다. 
- 나는 이 부분에서 개인적으로 큰 감명을 받았다. 이렇게라도 해서 회귀테스트를 마련한다면 레거시 코드의 리팩터링에 자신감이 붙을 것이다.

### 필드로 옮기기
- 테스트코드를 작성하고 가장 먼저 하는 것은 지역변수를 필드로 옮긴다. 필드 추출의 장점은 다양하다.
- 매서드 스택마다 전달해야할 매개변수를 최소화할 수 있다. 
- 필드를 지역변수로 돌리는 것은 쉽다.

### 클래스의 분리 : 클래스간 참조하지 않도록
- 메서드를 정리하다 보면 클래스를 분리하는 상황이 발생한다. 이 때 클래스 간 공통으로 사용되는 필드와 클래스 각각이 사용하는 필드를 확인할 수 있다. 후자는 쉽게 나눌 수 있다. 전자의 경우 특정 클래스가 다른 클래스의 생성자 혹은 메서드의 매개변수로 사용되곤 한다. 이러한 형태로 클래스를 분리할 경우 클래스가 다른 클래스에 참조하는 상황이 발생한다. 그러므로 클래스로 참조하는 것이 아닌, 매개변수를 통해 데이터를 전달할 수 있도록 한다. 

### 나아가며
- 앞서의 리팩터링까지 진행하면, 리팩터링의 절반이 진행된다. 레거시 코드에 대한 까다로운 문제들이 해결되었다.
- 개인적으로 나는 캐릭터라이제이션 테스트가 감명깊었다. 개인적으로 레거시 코드를 리팩터링할 때, 솔직히 그것이 가능할 것 같다는 느낌을 받지 않았다. 내가 새로운 기능을 추가 할 때만 테스트코드를 작성했지 기존의 코드에 테스트 코드를 작성한다는 결심을 하지 못했다. 
- 그 이유는 회귀 테스트를 작성할 방법을 찾지 못했다. 그런데 이런 식으로 가능하다는 단초를 마련해줬다. 한 번 해봐야 겠다. 테스트 코드에 조금 시간을 들이더라도 이를 만들기만 한다면 자신감이 생길 것 같다.