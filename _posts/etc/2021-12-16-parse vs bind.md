---
layout: post
author: infoqoch
title: parsing 과 binding의 차이는 무엇일까?
categories: [etc]
tags: [etc]
---

## 들어가며
- binding 이나 parsing 은 개발자들이 매우 흔하게 쓰는 단어이다.
- 단어는 보통 듣고 읽으면서 자연스럽게 그 뜻을 이해하는데 parse 와 bind는 아무리 들어도 그 차이를 이해하기 어려웠다.
- 두 단어 모두 대략적으로 데이터를 변환하는 것으로 이해가 되는데 두 개의 차이를 정확하게 이해하기 위하여 인터넷 서핑을 해봤다. 

## binding vs parsing
- 두 개의 단어의 차이를 찾기 위하여 노력했다. 그러나 생각보다 두 개의 차이를 비교하는 글을 확인하지 못했다. 스택오버플로우에 이를 비교하는 글 하나가 있었고 그 내용은 아래와 같다. 

> What does it mean binding and what is a binding tool?
- Binding is the process of in-memory(as the application is running) conversion of XML document to object represantation. Binding is achieved through unmarshalling.

> What does it mean parsing and what is a parsing tool?
- Parsing is reading an input stream of data and checking whether if the stream of data coforms to certain grammar. Parsing tools consume stream of data and generate errors when the data fails to conforms to grammar that the tool is checking. It would also generate events to indicate that it has received certain "tokens" from the stream. In java/xml scenario, there are multiple types of parsers such as DOM, StAx, SAX...

> Parsing :
- in order to convert XML document to object represantation, the JAXB engine has to first "parse" the xml document to ensure correctness and then tokenize to instatiate java objects. This happens internally and you do not control ito ensure correctness and then tokenize to instatiate java objects.

> 참조 : https://stackoverflow.com/questions/9843120/what-are-the-differences-between-mapping-binding-and-parsing

## 바인딩 binding
- 바인딩은 "conversion" 으로서 특정 데이터의 형태를 어플리케이션의 메모리 상 어떤 데이터의 형태로 읽고 변경하는 것을 의미한다. XML → java object 라고 표현한 것을 볼 수 있다. properties 나 xml 의 다양한 설정 값을 어플리케이션의 메모리 형태로 전환하는 것을 의미한다.
- 바인딩은 "unmarshalling" 이란 단어와 함께 사용된다. 언마셜링이란 마찬가지로 어플리케이션 외부의 자원에서 내부 메모리 안으로 불러오는 것을 의미한다.
- 마셜링은 반대로 인메모리의 데이타를 외부 자원으로 변환하는 것을 의미할테다. 이런 경우는 log를 파일로 남기거나 엑셀 파일로 남기는 것을 의미하려나.
- 바인딩은 더 나아가 `int a = 100;` 과 같은 선언 역시도 포함하는 것 같다. 어찌 됐든 이러한 선언을 통해 메모리를 할당받으니까 그런가 보다. 
  > 참조 : https://medium.com/pocs/바인딩-binding-4a4a2f641b27

- 위키는 바인딩의 합성어를 나열했다. 네임바인딩, 키바인딩, 데이터바인딩... 이 중 키 바인딩이 와닿았다. 우리가 사용하는 키보드의 키 각각은 어떤 명령을 가리킨다. 인 메모리로 할당받는 어떤 기능을 우리는 물리적인 키로 사용한다. 
  > 참조 : https://ko.wikipedia.org/wiki/바인딩

## 파싱 parsing
- 파싱은 언어학에서 나온 단어라 한다. 문장을 분석하는 것을 의미한다.
- 컴퓨터과학에서 파싱이란, 읽고, 문법에 맞는지를 검토하여, 의미가 있는 데이터로 조합하는 것을 의미한다.
- 바인딩은 일방향적인 단어이다. 왜냐하면 자원을 메모리 안으로 불러오기 때문이다. 
- 파싱은 데이타를 읽고 검증하고 그 내용을 수행하는 것에 있는 것 같다.
- 방향성의 차이가 있지, 그러나 전반적인 내용은 큰 차이가 없는 것 같다.

## mashalling, unmashalling
- 자바 프로그래밍을 하다보면 marshalling(마셜링), unmarshalling(언마셜링) 등의 단어를 자주 접하게 되는데 이것도 와닿지 않았다. 그래서 같이 찾아봤다. 

> '자바에서 마셜링이란 자바 객체를 byte stream으로 변환하는 과정을 의미한다. 또는 자바 객체를 XML문서로 변환하는 것을 의미하기도 한다. 마셜링이란 단어가 정렬시키기를 의미한다고 생각했을 때  데이터를 잘 정돈된 상태로 만드는 이미지를 상상할 수 있다. 잘 정돈된 상태여야 나중에 복원(언마셜링)을 할 수 있을 것이기 때문이다.
> 정리하면, 메모리에 존재하는 자바 객체를 범용적인 파일이나 바이트 스트림으로 변환 하는 작업을 마셜링이라고 부르고, 거꾸로 스트림이나 파일로부터 자바 객체를 만들어내는 작업을 언마셜링이라고 부른다.
> 출처 : https://blog.naver.com/weekamp/222095153419

- 실제로 스프링에서는 soap에 대응하는 기능을 지원하고 있다. 다음의 가이드(https://spring.io/guides/gs/consuming-web-service/)를 사용해본적이 있고, 이를 현 블로그에 정리한 내용이 있다. 