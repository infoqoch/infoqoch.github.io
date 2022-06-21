---
layout: post
author: infoqoch
title: Thread-safe로 바라보는 LocalThread와 ConcurrentHashMap
categories: [java]
tags: [java]
---

## Thread - safe 란?
- 지금까지 나는 Thread-safe를 어떻게 이해했는가? 대략 아래와 같이 이해했다. 
- 동기적 처리 보장 : 해당 메서드는 단 하나의 스레드만 사용한다.
- 이는 다음과 같은 효과를 준다.
    - 쓰레드의 동시요청과 관계 없는 유일한 생성 보장. 예를 들면 setter보단 생성자를 통하여 싱글톤을 생성한다. 
    - 정합성 보장 : 특정 로직에 대한 유일한 쓰레드의 접근 보장 
- Proxy에 대해여 학습하는 도중 나는 ThreadLocal에 대하여 배웠다. ThreadLocal은 하나의 쓰레드만 접근할 수 있는 자료구조라고 한다. 나는 이것을 학습하며 ConcurrentHashMap이 떠올랐다. 분명 이것은 thread-safe라고 하였다. 도대체 무슨 차이지? 라는 생각을 하며, 두 개를 비교해보기로 했다. 

## 멀티 스레드 상황에서 객체에 접근을 비교
- 아래는 ThreadLocal<String>과 ConcurrentHashMap<String, String>, String 세 개의 객체를 스토리지로 가지는 객체들이다. 

```java
@Slf4j
public class ThreadLocalServiceTest {
	ThreadLocalService threadLocalService = new ThreadLocalService();  // ThreadLocal<String> store
	StringService stringService = new StringService(); // String store
	ConcurrentHashMapService mapService = new ConcurrentHashMapService(); // ConcurrentHashMap<String, String> store

	@Test
	void thread_local() {
		threadLocalService.set("main value");

		new Thread(() -> {
			threadLocalService.set("threadA value");
			sleep(1000);
			log.info("hi, {}", threadLocalService.get());
		}, "threadA").start();

		new Thread(() -> {
			threadLocalService.set("threadB value");
			sleep(1000);
			log.info("hi, {}", threadLocalService.get());
		}, "threadB").start();


		log.info("hi, {}", threadLocalService.get());
		sleep(1000);
	}

	@Test
	void string_store() {
		stringService.set("main value");

		new Thread(() -> {
			stringService.set("threadA value");
			sleep(1000);
			log.info("hi, {}", stringService.get());
		}, "threadA").start();

		new Thread(() -> {
			stringService.set("threadB value");
			sleep(1000);
			log.info("hi, {}", stringService.get());
		}, "threadB").start();

		log.info("hi, {}", stringService.get());
		sleep(1000);
	}

	@Test
	void concurrent_hash_map_store() {
		mapService.set("main value");

		new Thread(() -> {
			mapService.set("threadA value");
			sleep(1000);
			log.info("hi, {}", mapService.get());
		}, "threadA").start();

		new Thread(() -> {
			mapService.set("threadB value");
			sleep(1000);
			log.info("hi, {}", mapService.get());
		}, "threadB").start();

		log.info("hi, {}", mapService.get());
		sleep(1000);
	}

	private void sleep(int mills) {
		try {
			Thread.sleep(mills);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
```

- 위의 로직의 결과를 확인하였을 때, 멀티 스레드 상황에서 데이터의 분리를 보장하는 것은 ThreadLocal 밖에 없었다. 그러니까 ThreadLocal은 하나의 쓰레드만 참조하기 때문에 데이터 입력과 출력이 쓰레드마다 분리되었다면, String과 ConcurrentHashMap은 다수의 쓰레드가 동시에 접근하여, 데이터가 의도하지 않게 엉킨다. 
- 그러면 ThreadLocal의 Thread-safe와 ConcurrentHashMap의 Thread-safe는 무엇인 다른 것일까?

## Synchronized
- 예전에 사용하던 자료구조 Vector는 add 메서드가 아래와 같다. 

```java
public synchronized boolean add(E e) {
    modCount++;
    add(e, elementData, elementCount);
    return true;
}
```

- add 메서드를 보면 synchronized가 선언되어 있다. 이 말은 해당 메서드에 진입하는 스레드가 단 하나라는 의미이다. 멀티 스레드 상황에서 유일한 스레드만 사용함을 보장한다. 왜 add 메서드는 단 하나의 스레드만 사용하는 것을 보장하였을까?
- add 메서드 내부에는 데이터를 다루는 알고리즘과 로직으로 이뤄져 있다. 이러한 로직 도중에 다른 쓰레드가 접근할 경우 의도치 않은 오류를 발생할 수 있기 때문이다. 그러니까 이 때의 Thread-safe의 의미는 add 메서드의 정상적인 동작을 보장하기 위함이다. 
- ArrayList는 Vector와 달리 synchronized가 없다. 그러므로 멀티스레드 상황에서 문제가 발생할 수 있다. 
- ConcurrentHashMap은 Vector와 달리 부분에 대해서만 ssynchronized로 잠근다. 이를 통하여 Vector보다 더 빠른 성능과 멀티 쓰레드 상황에서의 병렬적 처리를 보장한다. 

## Thread safe의 다양한 의미
- 결과적으로 ThreadLocal의 Thread-Safe와 ConcurrentHashMap 혹은 Vector의 Thread-Safe의 의미는 다르다. 
- 전자는 Thread 마다 새로운 자료구조가 존재함을 의미하며, 완전하게 분리되어 있기 때문에 Thread-safe하다.
- 후자는 같은 자료구조를 공유하고 쓰레드 간 공유할 수 있다. 이로 인하여 의도치 않는 데이터의 손실이나 변경 문제가 발생할 수 있다. 데이터가 분리된다는 의미에서의 Thread-safe가 아니다.
- 트랜잭션의 ACID와 유사하다. add라는 메서드가 동작하면 그 동작이 다른 스레드에 의하여 문제가 발생하지 않고 온전하게 동작함을 보장한다는 의미로 Thread-safe를 봐야 한다. 
- DB에 여러 개의 어플리케이션이 접근할 수 있다고 하여 문제가 있다고 말하지 않는다. 그보다는 격리수준과 락을 적절하게 사용하여 하나의 트랜잭션이 의도하는 바에 따라 DB를 조회하고 갱신하는 것에 우리는 초점을 맞춘다.

> 참고 
>
> https://www.inflearn.com/questions/347336 
>
> https://cornswrold.tistory.com/209
>