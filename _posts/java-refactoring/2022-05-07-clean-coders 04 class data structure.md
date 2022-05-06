---
layout: post
author: infoqoch
title: 클린코더스, form, class와 data structure
categories: [refactoring]
tags: [refactoring, java]
---

## class와 data structure란?
- class는 필드가 private 이며 method로 동작한다.
- data structure는 필드가 public 이며 method가 존재하지 않는다.
- 자바를 사용하고 class 파일을 만들어도 자바빈 패턴을 사용한다면 이는 class가 아닌 data structure를 사용하는 것과 다름 없다. 

### class
- class는 IoC를 통하여 High Level Policy(클라이언트, 비지니스 로직)을 Low Level Detail로부터 보호한다. 이것이 객체지향 개발의 핵심이다.
- 소스코드는 interface에만 의존하고 런타임 시점에서 실제의 Low Level Detail에 의존하는 형태가 된다. 
- concrete class는 인터페이스의 메서드를 구현한다. 동일한 메서드를 구현하는 구현체가 늘어날 때 장점이 크다. 반대로 인터페이스의 메서드가 변경될 경우 모든 구현체를 변경해야 하므로 단점으로 작용한다. 이러한 장단을 방식을 고려하여 개발한다. data structure 기반의 개발은 이와 반대이다.

### data structure
- 필드가 공개되고 메서드가 존재하지 않는다. 
- Tell 은 불가능하고 ask만 가능하다. 비지니스 로직는 데이터를 호출하고, 그 값을 조작하는 형태로 진행한다. 
- 데이터를 기반으로 조작하기 때문에 대체로 switch 문장이 많다. 잘 개발된 class는 스위치가 없고 다형성이 존재한다. 
- 자바빈 패턴(getter/setter)는 class 보다는 data structure에 가깝다고 볼 수 있다.

### 응집도 cohesive
- class는 응집도가 높고 data structure는 응집도가 낮다.
- data structure의 필드 혹은 getter/setter는 하나의 필드에만 접근한다. 
- class는 하나의 메서드가 여러 개의 필드에 접근하고 조작한다. 
- 자바빈 패턴은 public이기 때문에 차후 수정하기가 매우 어렵다. 모든 public은 사실상 관리해야할 대상이 된다. 하지만 class는 특정 메서드만 노출하기 때문에 유지보수에 낫다. 
- class를 구현함에 있어 getter/setter는 최소한으로 한다. getter도 getSomething보다는 다른 명칭을 사용하여 외부에 필드를 추측할 수 있도록 하지 않는다. 필드는 최대한 숨겨야 한다. 