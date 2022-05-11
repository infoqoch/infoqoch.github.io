---
layout: post
author: infoqoch
title: 클린코더스, 레거시 코드 리팩터링 시작하기
categories: [refactoring]
tags: [refactoring, java]
---

## 들어가며
- 클린코더스에서는 좋은 함수를 구현하기 위한 여러 기법을 소개하였다.
- 한편, 좋은 코드를 레거시 코드에 작성하기 위해서 리팩터링을 해야 한다. 
- 이러한 리팩터링은 위험하고 어려워 선뜻 시도하기 어렵다. 특히 리팩터링 과정에서 기존에 동작하는 코드를 망가뜨린다는 두려움에 이러한 시도를 더욱 어렵게 만든다. 
- 좋은 함수를 적용하기 위하여, 레거시 코드를 리팩터링 하기 위한 좋은 기법을 소개해줬으며 그 방법은 아래와 같다.

## 리팩터링 시작 전, 반드시 테스트 코드를 작성한다.
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
- 메서드를 정리하다 보면 클래스를 분리하는 상황이 발생한다. 이 때 클래스 간 공통으로 사용되는 필드와 클래스 각각이 사용하는 필드를 확인할 수 있다. 후자는 쉽게 나눌 수 있다. 전자의 경우 특정 클래스가 다른 클래스의 생성자 혹은 메서드의 매개변수로 참조되어 사용되곤 한다. 이러한 참조 관계를 해제하기 위하여 클래스 자체를 매개변수로 사용하지 않는다. 각각의 값으로 데이터를 전달한다.

### 나아가며
- 앞서의 리팩터링까지 진행하면, 리팩터링의 절반이 진행된다. 레거시 코드에 대한 까다로운 문제들이 해결되었다.
- 개인적으로 나는 캐릭터라이제이션 테스트가 감명깊었다. 개인적으로 레거시 코드를 리팩터링할 때, 솔직히 그것이 가능할 것 같다는 느낌을 받지 않았다. 내가 새로운 기능을 추가 할 때만 테스트코드를 작성했지 기존의 코드에 테스트 코드를 작성한다는 결심을 하지 못했다. 
- 그 이유는 회귀 테스트를 작성할 방법을 찾지 못했다. 그런데 이런 식으로 가능하다는 단초를 마련해줬다. 한 번 해봐야 겠다. 테스트 코드에 조금 시간을 들이더라도 이를 만들기만 한다면 자신감이 생길 것 같다.