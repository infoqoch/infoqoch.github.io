---
layout: post
author: infoqoch
title: 싱글톤의 구현과 스프링
categories: [design pattern]
tags: [design pattern, spring]
---

### 싱글톤은?
- 스프링의 DI는 하나의 컨테이너를 재활용하여 자원의 낭비를 최소화하기 위한 일종의 방법론이다. 작은 부품이 큰 부품을 이루고 그것이 하나의 어플리케이션으로 만들어지는 것을 DI라 한다. 
- 스프링의 이러한 작업에 있어서 활용되는 디자인 패턴은 싱글톤이다. 클라이언트의 요구마다 필요로 한 어플리케이션을 재생성하지 않는다. 하나의 어플리케이션만 만들고 그 이상의 생성을 방지한다. 클라이언트의 요구마다 하나의 어플리케이션을 재활용한다.
  
```java
public class PersonDao {
	private static PersonDao instance;
    
	private PersonDao(){}
    
	public static PersonDao getInstance() {
		if(instance ==null) {
			instance = new PersonDao();
            System.out.println("PersonDao 초기화");
        }
		return instance;		
	}
}
```

- 메인 스레드에서 해당 객체를 getInstance() 메서드를 통해 싱글톤을 호출하는 방법은 아래와 같다. 

```java
public class MemberMain {
	public static void main(String[] args) {
//		PersonDao pDao1 = new PersonDao(); // private 이기 때문에 메인 스레드에서 해당 클래스를 찾을 수 없음. 컴파일 오류 발생. 
	
		PersonDao dao2 = PersonDao.getInstance(); // 출력 : PersonDao 초기화
		System.out.println("dao2 :"+dao2); // dao2 :PersonDao@3830f1c0

		PersonDao dao3 = PersonDao.getInstance();
		System.out.println("dao3 :"+dao3); // dao3 :PersonDao@3830f1c0

		PersonDao dao4 = PersonDao.getInstance();
		System.out.println("dao4 :"+dao4);// dao4 :PersonDao@3830f1c0
 
	}
}
```

- 싱글톤의 맴버변수는 static(정적 맴버)이다. static이 있어야만 메소드 영역에 해당 값이 저장되고, 어플리케이션 내에서 유일함을 보장받으며, 어플리케이션이 끝날 때까지 사용할 수 있다.
- 하지만 매서드를 통한 싱글톤 구현은 멀티스레드 상황에서 안전하지 않다. 맴버변수가 null 일 때 여러 개의 쓰레드가 동시에 접근하면 여러 개의 객체가 생성될 수 있기 때문이다.

### 초기화 시점에서의 싱글톤
- 메서드가 아닌 클래스의 초기화 시점에서 싱글톤을 구현하면 이러한 위험을 회피할 수 있다. 클래스를 로딩 할 때 싱글톤을 호출하면, 스레드로부터 무관(thread-safe)하게 작동한다. 
- 아래의 예제는 클래스의 초기화 시점에서 객체를 생성한다. 
  
```java
public class PersonDao {
	
	private PersonDao(){}

	public static PersonDao getInstance() {
		return LazyHolder.INSTANCE; 
	}
	
	private static class LazyHolder {
		private static final PersonDao INSTANCE = new PersonDao(); 
	}
}
```
  
> 참고 : 
- https://medium.com/@joongwon/multi-thread-%ED%99%98%EA%B2%BD%EC%97%90%EC%84%9C%EC%9D%98-%EC%98%AC%EB%B0%94%EB%A5%B8-singleton-578d9511fd42
- https://javaplant.tistory.com/21