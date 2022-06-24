---
layout: post
author: infoqoch
title: 컴포지션 패턴 composition pattern, 사용에 초점을 맞추고 공개된 api를 축소하자.
categories: [design pattern]
tags: [design pattern, java]
---

# 컴포지션을 사용하는 다양한 패턴들
- 래퍼 클래스, 데코레이션 패턴, 컴포지션 패턴, 어댑터 패턴 등 다양한 패턴들의 공통점은 다음과 같다.
	- 실제 로직을 담당하는 객체는 내부에 컴포지션으로 존재한다. 
    - 컴포지션을 감싸는 상위 클래스는 해당 컴포지션을 구현(implements)한다.
    - 상위 클래스는 부차적 관심사를 다루고, 실제 동작은 컴포지션이 담당한다. 
    - 컴포지션을 구현하기 때문에 다형성으로 인해 마치 컴포지션인 것처럼 동작한다. 

# Wrapper class
- 앞서 패턴 중 특히 래퍼 클래스는 특히 기존의 구현 클래스의 기능을 활용하며 동시에 추가 기능을 마련하고 싶을 때 사용하는 디자인 패턴이다. 
- HashSet을 만족스럽게 사용하고 있다. 다만 한 가지 메서드를 추가하기 바란다고 가정하자. 메서드 `E enhencedPop()` 을 추가하고자 한다. 그리고 이를 위하여 내부 로직 몇 개를 재정의 하고자 한다. 
- 하지만 이러한 코드 작성은 위험하다. 재정의를 할 경우, 사이드 이펙트를 없애기 위해서 내부 로직에 대한 이해가 필요하게 된다. 충분하게 이해를 하더라도 해당 구현체의 버전업으로 인해 내부로직이 변경될 경우, 언제든 쉽게 깨질 수 있는 코드가 되기 때문이다. 
- 이 때, HashSet을 extends로 상속하는 것보다, HashSet을 컴포지션으로 하여 해당 구현체를 wrapping 하는 것이 더 낫다. 
- 대략적인 코드는 아래와 같다. 

```java
// Set에는 메서드가 아래 두 개밖에 없다고 하자.
public interface Set<E>{ 
	void save(E e);
	E pop();
}

public class EnhencedSet<E> implement Set<E>{
	private final Set<E> set;

	public EnhencedSet(Set<E> set){
		this.set = set;
	}
	
	@Override
	void save(E e){
		set.save(e); // 컴포지션의 것을 그냥 사용한다. 
	}

	@Override
	E pop(){
		return set.pop(); // 상동
	}

	E enhencedPop(){
		// 구현
	}
}
```

# wrapper 클래스에 미달하는 경우는?
- 나는 사실 이펙티브 자바에서 컴포지션이란 개념을 학습하고 큰 감명을 받았다. 그리고 wrapper class라는 단순하면서도 명확한 명칭에 큰 매력을 느꼈다. 그래서 컴포지션을 사용하는 클래스에 대하여 나도 모르게 SomethingWrapper라는 명칭을 붙이기 시작했다(....)
- 이번에도 나는 DocumentWrapper 라는 클래스를 작성하였는데, XML을 Document로 만들고, key를 통해 value를 찾는 기능을 구현했다. 
- 그 코드는 아래와 같다.

```sql
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class DocumentWrapper{
	private final Document document;

	public static DocumentWrapper createDocumentWrapper(String XMLString) throws Exception {
		InputSource is = new InputSource(new StringReader(XMLString));
		is.setEncoding("UTF-8");
		DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
		DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
		Document doc = dBuilder.parse(is);
		DocumentWrapper wrap =  new DocumentWrapper(doc);
		return wrap ;
	}

	public List<String> findValue(String tagName, String attName) {
		List<String> result = new ArrayList<>();

		Element root = document.getDocumentElement();

		// 해당 태그네임을 가지는 노드리스트, 순회
		NodeList nodeList = root.getElementsByTagName(tagName);
		for(int i=0; i<nodeList.getLength(); i++) {
			Node tagNode = nodeList.item(i);

			// 해당 태그네임을 가지는 노드리스트 각각의 노드가 가지는 속성을 순회
			NamedNodeMap map = tagNode.getAttributes();
			for(int j=0; j<map.getLength(); j++) {
				Node attNode =  map.item(j);
				if(attNode.getNodeName().equals(attName))
					result.add(attNode.getNodeValue());
			}
		}
		return result;
	}
}
```

- 위의 래퍼는 래퍼클래스일까? 고민이 생겼다. 
- 래퍼클래스는 어댑터 패턴이라고도 불린다. 인터페이스만 일치하면 어떻게 구현하든 교환 가능하기 때문이다. 하지만 위의 객체는 Document 구현체가 아니다. 결코 교환 가능하지 않다. 아답터로서 동작할 수 없다.
- 기능적으로도 마찬가지이다. Document의 어떤 기능도 사용할 수 없다. 
- 결론적으로 래퍼 클래스라고 부를 수 없다. 이런 결론에 도달하자 나는 래퍼클래스만큼 적절한 이름이 없는데 어떤 이름을 지어야 하냐는 절망에 빠졌다. Document를 감싼 클래스라는 DocumentWrapper를 쓸 수 없는 것인가? 그 이름을 못쓴다면 어떤 이름이 적합할까? ejb에게 setSomething() 명칭을 빼앗긴 그런 느낌이었다.

# 사용하는 기술에 의존하지 말고 그것의 사용에 초점을 맞추자.
- 명칭의 문제를 떠나서 애당초 Document는 관심사가 아니었다.
- String이 정상적인 xml인지 확인하고, 태그네임과 속성을 기준으로 값을 호출하는 기능만을 가질 뿐이다. 원하는 데이터만 뽑아낼 수 있다면 Document가 if문과 StringUtils를 사용해도 상관이 없다.
- 더하여 Document를 래퍼 클래스로 구현하는 것은 오히려 좋은 선택이 아니다. 클라이언트 입장에서는 필요 없는 기능은 혼란을 가중시킨다. 이는 유연한 코드가 좋다라는 명제보다 공개된 api는 적으면 적을수록 좋다는 명제가 맞는 상황이다.
- 결론적으로 XXXWrapper란 명칭 자체를 사용하는 것이 좋은 선택이 아니다. 만약 바꾼다면 다음과 같이 변경하는 것이 나아 보인다. DocumentWrapper → XMLValueFind. 이 이름도 별론가?