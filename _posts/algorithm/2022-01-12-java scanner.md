---
layout: post
author: infoqoch
title: java scanner api 로 리스트 추출
categories: [java]
tags: [java]
---

## 들어가며
- Scanner나 BufferedReader 등 콘솔을 활용한 개발을 웹 개발 과정에서 사용할 일은 솔직히 없다. 
- Poi나 File api를 통해 파일로 데이타를 추출하기는 작고, 그렇다고 String data =""; 값을 로직에 넣기에는 가변적이고 양이 많은 경우가 있다. 이 때 console로 데이타를 삽입하면 매우 좋다. 
- 특히 나의 경우 콘솔로 삽입한 값을 리스트로 생성하고, 한 줄을 하나의 DTO 객체로 주입하는 경우가 많다. 그러므로 보통 나는 console의 값을 리스트로 만든다. 
- 콘솔의 값을 리스트로 간단하게 구현하였다. 

```java
public class ConsoleService {

	// next 의 경우 split 기준이 공백으로 한다. 
	public static List<String> consoleToListSplitBySpace(){
		Scanner sc = new Scanner(System.in);

		System.out.println("==== console to list start ===");
		System.out.println("스페이스 마다 하나의 리스트로 넣습니다. exit 을 누르면 종료하고 리스트를 리턴합니다.");
		System.out.println();
		List<String> list = new ArrayList<>();
        while(true){
        	String target = sc.next().trim();
        	if(target.equals("exit")) {
        		break;
        	}
        	list.add(target);
        }

        sc.close();

        System.out.println("==== console to list end   ===");
        System.out.println();
        return list;
	}

	public static List<String> consoleToListSplitByNextLine(){
		Scanner sc = new Scanner(System.in);

		System.out.println("==== console to list start ===");
		System.out.println("한 줄을 하나의 리스트로 넣습니다. exit 을 누르면 종료하고 리스트를 리턴합니다.");
		System.out.println();
		List<String> list = new ArrayList<>();
        while(true){
        	String target = sc.nextLine().trim();
        	if(target.equals("exit")) {
        		break;
        	}
        	list.add(target);
        }

        sc.close();

        System.out.println("==== console to list end   ===");
        System.out.println();
        return list;
	}
}
```
