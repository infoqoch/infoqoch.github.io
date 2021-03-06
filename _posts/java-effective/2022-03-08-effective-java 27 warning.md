---
layout: post
author: infoqoch
title: 이펙티브자바, 27. 비검사 경고를 제거하라
categories: [java]
tags: [java, effective]
---

## 제네릭의 컴파일 경고
- 제네릭타입을 사용할 경우 컴파일러의 경고를 확인할 수 있다. 
- 컴파일러의 경고를 최대한 해소한다.
- 컴파일러의 경고에도 불구하고 문제가 없음이 확실하다면 @SuppressWarnings 어너테이션으로 경고를 없앤다. @SuppressWarnings을 사용하면 컴파일 시점에서 제너릭과 관련한 에러를 누락한다. 하지만 런타임 시점에서 컴파일러의 우려대로 예외가 발생할 수 있다. 

## 정리
- 컴파일러의 경고를 확실하게 없애고, 
- 분명한 대상에 대해서만 어너테이션을 활용하며, 
- 어너테이션의 적용 범위는 최대한 좁게 하고, 
- 주석을 통해 사유를 명확하게 명시해야 한다. 

