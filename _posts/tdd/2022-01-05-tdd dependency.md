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
-  main을 사용하면 하나의 클래스에 다양한 테스트를 할 때 너무 복잡해지는 경향이 있다. 그래서 개인적으로 junit으로 돌리는 것을 좋아한다.
-  해당 디펜던시는 다음과 같다. 팁이라 할 것도 없는데 내가 자주 사용할 것 같아서(ㅎㅎ) 업로드 한다. 

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
