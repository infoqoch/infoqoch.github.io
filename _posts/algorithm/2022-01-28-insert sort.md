---
layout: post
author: infoqoch
title: 알고리즘 삽입정렬의 기초 
categories: [algorithm]
tags: [algorithm, java]
---

## 삽입정렬과 선택정렬
- O(n<sup>2</sup>)의 정렬은 버블정렬, 삽입정렬, 선택정렬이 있다. 
- 삽입정렬과 선택정렬은 유사하지만 다르다. 이 두 개의 차이를 설명하고, 삽입 정렬에 대해 정리하고자 한다. 
- 선택정렬은 최소값을 삽입할 인덱스를 두고, 검색할 값들 중에 최소값의 위치를 구한다음, 두 위치의 값을 교환하는 방식이다. 
- 삽입정렬은 위치를 이동시킬 값을 선택하고, 그 값보다 작은 값의 바로 뒤로 옮기는 형태이다. 
- 예를 들면 [1,7,5,4]가 있고 인덱스 0인 값 1까지 정렬이 끝났다고 가정한다. 선택정렬의 경우 인덱스 1의 위치에 넣을 값을 탐색하며 그 값의 위치는 인덱스 3(값은 4)에 있다. 인덱스 1(7)과 인덱스 3(4)를 교환하는 방식이다. 삽입정렬의 경우 자신의 값(7)을 기준으로 하며, 자신의 앞에 있는 값을 순차적으로 비교하는 방식이다. 7의 앞은 1이며, 1은 7보다 작으므로 변동 없다. 하지만 5의 경우 자신의 앞인 7과 비교하면 작으므로, 1,5,7이 되고, 그 다음 앞에 있는 1은 5보다 작으므로 자리를 옮기지 않는다. 
- 그러므로 선택정렬은 각 인덱스마다 삽입할 값을 구하는 형태이지만, 삽입정렬은 인덱스에 있는 값이 이동할 위치를 찾는 형태이다.

## 삽입 정렬을 구현할 때의 주의점
- 코드를 통해 삽입 정렬을 구현할 때, 우리는 적절한 위치에 이동하는 것으로 생각하지만, 코드에서는 값을 뒤로 밀어내는 형태로 구현한다. 
- 예를 들면 [1,7,5,4] 이 있고, 5를 옮긴다면, 임시변수에 5를 두고, [1,7,null,4] 로 자신의 위치를 비운다음, 임시변수와 자신의 앞의 값(7)을 비교한 후, 자신이 더 작으면 앞의 값을 뒤로 밀어내는 형태([1,null,7,4])이다. 그리고 앞의 값(1)과 비교해서 자신이 크면 빈 곳에 자신을 두는 형태([1,5,7,4])이다. 
- 삽입정렬의 경우 자신의 앞의 값은 이미 정렬되어있음을 가정하기 때문에, 자신보다 작은 값이 앞에 있을 경우 정렬을 종료한다. 그러므로 값을 비교할 때는 반드시 뒤에서부터 앞으로 한 칸씩 진행한다. 

## 코드의 구현

```java
import java.util.List;
public class InsertSort {

	public static void sort(List<Integer> list) {
		for(int i=1; i<list.size(); i++) {
			int target = list.get(i);
			int idx = i;
			for(int j=i; j > 0 && list.get(j-1) > target; j--) {
				list.set(j, list.get(j-1));
				idx = j-1;
			}
			list.set(idx, target);
		}
	}
}
```

## 테스트 코드

```java
import java.util.List;

import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.Test;

import utils.IntListGenerator;

public class InsertSortTest {
	@Test
	void test_before() {
		List<Integer> list = IntListGenerator.generateIntList(5, 10); 
		System.out.println(list.toString());
		for(int i=1; i<list.size(); i++) {
			// 내부 인덱스의 경우 외부 반복문의 최대값부터 시작해서 0으로 향해야 한다. (정확하게는 1까지 탐색한다. 자신(1이면)과 자신의 앞의 것(0이다)과 비교하기 때문이다.
			// 오름차순이기 때문에 앞의 값이 해당 값보다 크면 앞의 값을 뒤로 한 칸 씩 옮긴다.
			// 자신의 값보다 작은 값을 만나면 빈 곳에 해당 값을 삽입한다.
			// 종료를 위한 코드가 필요가 없다. 자신이 삽입된 값 앞은 무조건 자신보다 작고, 정렬되어 있음을 보장하기 때문이다.
			int target = list.get(i);
			int idx = i;
			for(int j=i; j > 0 && list.get(j-1) > target; j--) {
				list.set(j, list.get(j-1));
				idx = j-1;
			}
			list.set(idx, target);
		}

		System.out.println(list.toString());
	}


	int loopSize = 10000;
	int size = 400;
	int max = Integer.MAX_VALUE;


	@Test
	void sort_v1() {
		// given
		List<List<Integer>> sampleList = IntListGenerator.generateIntListofList(size, max, loopSize);

		long start = System.currentTimeMillis();

		for(int i=0; i<loopSize; i++) {
			List<Integer> list = sampleList.get(i);
			// when
			InsertSort.sort(list);

			// then
			Assertions.assertThat(list).isSorted();
		}
		System.out.printf("v1 : %d\n", (System.currentTimeMillis()- start));
	}

}

```

## 참고로...
- 아래의 코드는 테스트에 사용할 리스트를 만드는 코드이다. 
- 하나 만들어 놓으면 매우 편하게 테스트 진행 가능하다.

```java
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class IntListGenerator {

	public static List<List<Integer>> generateIntListofList(int size, int max, int sizeOfSize){
		List<List<Integer>> result = new ArrayList<>();
		for(int i = 0;i < sizeOfSize; i++) {
			result.add(generateIntList(size, max));
		}
		return result;
	}

	public static List<Integer> generateIntList(int size, int max){
		if(size>max)
			throw new IllegalArgumentException("size는 max보다 클 수 없다.");

		Set<Integer> sets = new HashSet<>();
		do {
			sets.add((int) (Math.random()*max));
		}while(sets.size()<size);
		List<Integer> result = new ArrayList<>(sets);
		Collections.shuffle(result);
		return result;
	}

}
```


## 배운 점
- 삽입정렬에 대해 정리하는 이유는 내가 삽입정렬에 대하여 잘 이해하지 못했기 때문이다. 버블정렬과 선택정렬은 인덱스 간 교환으로 이뤄지는데, 삽입정렬은 값을 기준으로 이동하기 때문이다. 
- 삽입정렬을 이해하게 된 계기는 참고 도서 이외에 다른 블로그를 읽은 것도 크지만, 삽입정렬 그 자체의 흐름을 글로 정리한 것이 계기가 되었다. 그리고 그 이해를 기반으로 코드를 이해하려 했기 때문이다. 마음이 급하면 코드로 구현하기 급급한데, 이런 경우 오히려 시간을 두고 요구사항을 명확하게 정리하고 코드를 꼼꼼하게 읽는 것이 도움이 됨을 배웠다. 
- 신중하게 코드를 읽자.