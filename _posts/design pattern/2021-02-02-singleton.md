---
layout: post
author: infoqoch
title: 싱글턴의 구현
categories: [design pattern]
tags: [design pattern, java]
---

## 싱글턴은?
- 싱글턴이란 인스턴스를 생성함에 있어서 동일하며 유일한 객체임을 보장하는 기술이다. 클라이언트의 요구마다 새로운 객체를 제공할 필요가 없을 때, 메모리를 효율적으로 관리하기 위한 기술이다. 
- 재활용을 하기 때문에 반드시 불변식이어야 한다. 만약 재활용 과정에서 이전 사용의 데이터로 오염될 경우, 다음 사용에 있어서 영향이 갈 수 있다. 그러므로 싱글턴을 사용할 때는 불변식으로 구현해야 한다. 그렇지 않으면 싱글턴을 포기하는 것이 낫다. 
- 싱글턴은 static 필드이기 때문에 static 블럭이나 필드, 메서드에서 초기화를 한다. 다만, 멀티 스레드에서 안정성을 위하여 클래스로더가 동작하는 시점에서 초기화를 한다. 필드에서 선언과 동시에 초기화를 하거나 static 블럭에서 한다. 
- 싱글턴 객체를 호출할 때, 필드나 매서드 둘 중 한 곳에서 출력할 수 있으나, 유연성을 위하여 정적 메서드 팩터리에서 출력한다. (SampleClass.getInstance();)

## 메서드에서 초기화, 매서드로 호출 (사용X)

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

- 매서드를 통한 싱글턴 구현은 멀티스레드 상황에서 안전하지 않다. 
- 맴버변수가 null 일 때 여러 개의 쓰레드가 동시에 접근하면 여러 개의 객체가 생성될 수 있기 때문이다.

## 클래스 로더 시점에서 생성된 싱글턴 객체 : 멀티스레드에서 안전 + 지연로딩
- 메서드가 아닌 클래스의 초기화 시점에서 싱글턴을 구현하면 이러한 위험을 회피할 수 있다. 
- 클래스를 로딩 할 때 싱글턴을 호출하면, 스레드로부터 무관(thread-safe)하게 작동한다. 
- 아래는 한 발자국 더 나아가 지연로딩 기법을 사용하였다. 
	- 앞서의 싱글턴 역시 메서드의 호출 시점에서 객체가 생성되기 때문에 지연로딩으로 볼 수 있다. 하지만 스레드 세이프티하지 않다. 
	- 이너 클래스를 통한 지연로딩의 경우 static이기 때문에 JVM 차원에서 멀티 스레드라 하더라도 유일함을 보장한다.
	- 다만 지연로딩은 구현이 복잡하기 때문에 대체로 필드에 초기화하고 정적 팩토리 메서드로 호출하는 방식을 사용한다. 
  
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
  
## 단순하며 안전한 싱글턴
- 캡슐화의 원칙을 지키고 메서드의 유연함을 위하여, 필드를 private으로 숨기고 팩토리 메서드를 public으로 공개한다. 
- 유일함을 보장하기 위하여 static final을 사용한다. 
- 지연로딩을 하지 않고, 필드에서 바로 초기화한다.

```java
public class Singleton {
	private static final Singleton Instance = new Singleton();

	public static Singleton getInstance() {
		return INSTANCE;
	}
}
```

> 참고 : 
- https://medium.com/@joongwon/multi-thread-%ED%99%98%EA%B2%BD%EC%97%90%EC%84%9C%EC%9D%98-%EC%98%AC%EB%B0%94%EB%A5%B8-singleton-578d9511fd42
- https://javaplant.tistory.com/21
- 이펙티브 자바, 이것이 자바다