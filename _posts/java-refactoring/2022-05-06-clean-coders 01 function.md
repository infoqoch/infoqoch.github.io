---
layout: post
author: infoqoch
title: 클린코더스, function structure 좋은 함수의 구현
categories: [refactoring]
tags: [refactoring, java]
---

# function structure 좋은 함수를 구현하기 위한 방법
- 코드를 읽고 유지보수해야 하는 reader의 입장에서 코드는 수십번 읽혀진다. 코드 작성에 있어서 가장 존중받아야 할 사람은 reader이다. reader를 최우선으로 배려하는 방식으로 코드를 작성해야 한다. 
- TDD를 잘한 코드는 자연스럽게 좋은 디자인으로 만들어진다. TDD를 기반으로 좋은 함수를 만들자.

## Argument
### 매개변수의 갯수는 3개 이하
- 매개변수가 복잡해지면 이를 추상화하는 객체를 만든다.
- 생성자가 복잡한 것보다 자바빈패턴(getter/setter)이 낫고, 그보다는 빌더 패턴이 낫다.

### boolean을 매개변수로 사용하지 않는다.
- boolean을 매개변수로 사용할 경우, true / false를 분기로 하는 로직이 두 개 있을 것이란 뉘양스를 준다. 
- 각 분기에 따른 로직로 분리하는 것이 낫다.

### input에 사용한 매개변수를 output에 사용해서는 안된다.
- input 인자를 변경되어 output으로 절대로 변경하지 않도록 한다. 
- input 인자는 final이라 생각해야 한다. 매개변수에 final을 선언할 수 있지만 보통은 그렇게 명시까지는 안함.
- 애당초 input - output이 일치하는 것은 CQS 위반이다.

### null defense
- public api에 대해서는 null에 대하여 방어적인 프로그래밍이 옳다.
- 하지만 자신이 만들거나 팀원이 만드는 코드에 대하여 null에 대한 방어적 코드를 작성해서는 안된다.  테스트코드로 안정성을 확보해야 한다.

## step down rule, 좋은 포맷의 코드를 작성하기 위하여
- public은 위로, private은 아래로 배치한다. 
- 다른사람에게 보여줄 때는 public만 보여준다. public 만으로 코드를 이해할 수 있도록 해야 한다.
- top-down으로 읽을 수 있도록 들여쓴다. 들여쓰지 못하더라도 사용하는 로직의 순서대로 메서드를 배치하는 것이 낫다.

```java
public void main(){
    data = getData();
    executeData();
    print();
}

private String getData(){}  // ide의 collapse 기능으로 숨길 수 있다. 중요한 메서드만 열어 놓는다.
private void executeData(){}
private void print(){}
```

## switch를 사용하지 마라
### OO와 DI
- OO의 가장 큰 장점은 의존성 관리 능력이다.
- 런타임 시점에선 핵심 비지니스 로직인 A는 라이브러나 내부 모듈인 B에 의존성을 가질 수밖에 없다. 
- OO는 불가피한 런타임 시점에서의 의존성이 소스코드로의 의존성으로 확대되지 않기 위한 기법이다. 소스코드의 의존성으로 확대되면 여러 문제가 발생한다. 
    - B가 변경되면 A가 변경된다. 그러니까 A와 B의 독립적인 개발이 불가능하다. 
    - 테스트코드 작성이 어렵다.
- OOP는 소스코드 상 의존성을 분리한다.
    - A와 B 사이에 interface를 둔다. 
    - B는 interface에 의존하고, 비지니스로직은 인터페이스로부터 B를 derive한다.
- 인터페이스로 분리되기 때문에 서로 독자적인 개발이 가능하다. TDD가 가능하고 유닛테스트가 쉽다.
- 스프링 MVC의 강점은 다른 무엇보다 DI에 있다. 

### OO를 지키지 않은 코드의 특징 : swaitch 
- switch는 case에 따라 외부 모듈을 선택하는 코드이다. 여러 개의 외부 모듈에 비지니스로직이 의존한다. 

### switch를 다형성을 통해 해소
- switch는 다형성을 통해 해소한다. 
- switch가 각각의 모듈에 요청하는 내용은 공통의 메서드로 추상화 할 수 있다. 그러니까 해당 함수는 abstract method로 만들고, case 마다의 요구사항은 각각의 구현클래스를 통해 구현한다. 
- 런타임 시점에서 사용될 concrete class는 IoC를 통해 선택한다. Main 과 App 파티션이 분리된다. switch에서 interface로 변경된 클래스는 Base class가 되며, switch 분기되었던 외부 모듈은 해당 인터페이스이 구현 클래스가 된다.

### Main 과 APP 파티션
- 그러나 결과적으로 Base Class 는 여러 클래스 중 하나를 선택해야만 한다. 결과적으로 이는 switch와 다를바 없는 것 아닌가?
- Base class는 Main partition에 소속된다. 스프링은 Main Partition을 대신 작성해준다. 그러니까 Base class가 런타임 시점에서 사용할 구현 클래스가 무엇인지를 코드가 아닌 메타데이터를 통해 결정한다. Main partition의 역할은 소스코드로 의존성을 하드코딩하지 않고, config를 읽어서 적절하게 사용할 객체를 주입시키는 역할을 한다. 스프링은 이러한 역할을 대신한다. 

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
- 명확한 이유가 있어야 한다. 예외를 특정 방식으로 처리하기를 기대할 때, checked exception을 사용할 수 있다. 
- public api의 경우, 클라이언트를 완전하게 신뢰할 수 없기 때문에 checked exception을 사용할 수 있다. 클라이언트는 이러한 경우 wrapper를 통해 사용하는 것이 낫다. 클라이언트는 저수준의 checked exception(IOException 등)를 고수준의 예외 (앞서의 Stack.IllegalCapacity 등)로 전달하는 것이 낫다.

### 그 외
- 예외 상황이 복잡하고 이를 처리할 로직이 필요하다면, Exception Resolver 등을 구현하고 해당 예외에 필드를 둘 수 있다. 
- 무엇이 되었든 예외 처리의 가장 이상적인 방식은 예외의 명칭을 분명하게 하여 클라이언트로 하여금 어떤 문제가 발생했는지를 이해할 수 있도록 하는 것이다.

## Null is not an error. null is a value
- null은 값이다. 에러가 아니다.
- 상황에 따라 null과 예외 중 하나를 적절하게 선택해야 하는 경우가 있다. 

```java
stack.pop();  // 대체로 pop는 null 이 리턴 되기를 기대하지는 않음. 그러므로 예외를 던진다.

repo.findById(123l);  
// find의 경우 없을 수 있음을 상정함. 예외가 아니라 null을 던지는 것이 낫다. 
// -1 과 같은 애매한 것을 던지면 안된다. 정확하게 null을 던지거나 Optional을 사용한다. 이도저도 아니면 예외를 던질 수 있다.
```

## try도 하나의 역할이다
- try도 하나의 역할을 한다. 
- try가 메서드 처음에 나와야 한다. finally 가 마지막이어야 한다.
- try,catch,finally 내에는 하나의 메서드만 호출해야 한다. 