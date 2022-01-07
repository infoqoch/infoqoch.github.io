---
layout: post
author: infoqoch
title: java array 에서 list로 바꾸기
categories: [java]
tags: [java]
---

## 들어가며
- 테스트코드를 작성하거나 데이터를 조작할 때 배열보다 리스트 형태가 유리한 경우가 많다. 
- 그 방법은 다음과 같다.


## 코드
- 원시 타입으로 선언하면 동작하지 않는다. 반드시 박싱해야 한다. 
- String 의 경우 asList 에서 바로 삽입한다. 

```java
    @Test
    void 원시타입배열_리스트(){
//        final List<Integer> ints1 = Arrays.asList(new int[]{1, 2, 3, 1, 4, 1, 2}); // 컴파일 에러

        final List<Integer> ints1 = Arrays.asList(new Integer[]{1, 2, 3, 1, 4, 1, 2});
        Assertions.assertThat(ints1).size().isEqualTo(7);

//        final ArrayList<String> strs1 = (ArrayList<String>) Arrays.asList("안녕", "반가워"); // ClassCastException

        final ArrayList<String> strs2 = new ArrayList<>(Arrays.asList("안녕", "반가워")); 
        Assertions.assertThat(strs2).size().isEqualTo(2);
    }
```

