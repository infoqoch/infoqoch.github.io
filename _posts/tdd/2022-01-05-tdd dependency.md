---
layout: post
author: infoqoch
title: java 자바 프로젝트에서 junit 사용하기
last_modified_at: 
categories: [java]
tags: [java, tdd]
---

## 들어가며
- 보통 코딩테스트나 소스를 동작할 때, `main` 메서드를 사용한다.
-  main을 사용하면 하나의 클래스에 다양한 테스트를 할 때 너무 복잡해지는 경향이 있다. 이로 인하여 @Test를 main 메서드보다 선호한다.
- junit의 스코프를 test에 한정하지 않는 것에 또 하나의 장점은 구현한 클래스 내부에서 테스트를 바로 수행할 수 있다. 간단한 툴로서 빠르게 만들고 적용하는 클래스를 제작할 때 매우 편하다. 

```gradle
dependencies {
    implementation 'org.junit.jupiter:junit-jupiter:5.7.0'
    implementation 'org.junit.jupiter:junit-jupiter-api:5.7.2'
    implementation 'org.junit.jupiter:junit-jupiter-engine:5.7.2'
    implementation group: 'org.assertj', name: 'assertj-core', version: '3.8.0'

    implementation('org.projectlombok:lombok:1.18.22')
    annotationProcessor('org.projectlombok:lombok:1.18.22')
    testAnnotationProcessor('org.projectlombok:lombok:1.18.22')

}

test {
    useJUnitPlatform()
    testLogging {
        events "passed", "skipped", "failed"
    }
}

test {
    useJUnitPlatform()
}

```
