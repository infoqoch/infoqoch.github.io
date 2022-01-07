---
layout: post
author: infoqoch
title: 순차탐색과 이진탐색, 정렬과 Comparator api
categories: [algorithm]
tags: [algorithm, java]
---

## 들어가며
- 순차탐색은 처음부터 끝까지 인덱스를 조사한다. n 만큼의 시간이 필요하다. 
- 이진탐색은 정렬이 되었다는 전제한다. 리스트를 반으로 나누고 그 가운데의 값이 찾는 값보다 크면 그 다음 검색은 중간부터 마지막까지로 한다. 이렇게 검색을 계속 하면 n 의 루트인 log n 만큼의 시간이 소비된다. 
- 함께 테스트를 할 수 있는 내용을 포함한다. 
- 테스트를 같이 해본 결과, 정렬 자체가 이미 시간을 소비하기 때문에, 정렬 한 다음 이진탐색은 더 느리다. 이진탐색 사용 자체가 제한적이다.
- 코드를 구현할 때 이하인지 미만인지 0을 포함하는지 아닌지의 세세함이 중요한 것처럼 여기서도 범위를 구현할 때 세세하게 따져야 한다. 범위를 반절로 나눌 때 중간에서 +1 이나 -1을 해야하는데, 왜냐하면 99, 100 사이의 중간값은 99가 되므로 무한 루프에 빠진다. 

## 소스

```java

public class BasicSearch {

    private static List<Integer> init(int size, int max, int target) {
        Set<Integer> sets = randomSets(size-1, max);
        sets.add(target);
        List<Integer> result = new ArrayList<>(sets);
        Collections.shuffle(result);
        return result;
    }

    private static Set<Integer> randomSets(int size, int max) {
        Set<Integer> sets = new HashSet<>();
        do{
            int random = (int) (Math.random() * max);
            sets.add(random);
        } while(sets.size()<size);

        return sets;
    }

    @Test
    void 순차탐색(){
        // given
        final int target = 7653;
        final List<Integer> list = init(100, 100000, target);

        // when
        final int idx = linearSearch(list, target);

        // then
        Assertions.assertThat(list.get(idx)).isEqualTo(target);
    }

    private static int linearSearch(List<Integer> list, int target) {
        for(int i=0; i<list.size(); i++) {
            if(list.get(i)==target) {
                return i;
            }
        }
        return -1;
    }
    
    @Test
    void 이진탐색(){
        // given
        final int target = 7653;
        final List<Integer> list = init(100, 100000, target);
        list.sort(INTEGER_ASC);

        // when
        final int idx = binarySearch(list, target);

        // then
        Assertions.assertThat(list.get(idx)).isEqualTo(target);
    }
    public static final Comparator<Integer> INTEGER_ASC = new IntegerDescOrderComparator();

    static class IntegerDescOrderComparator implements Comparator<Integer> {

        @Override
        public int compare(Integer o1, Integer o2) {
            return o1>o2? 1 :
                    o1<o2? -1 : 0;
        }
    }

    private static int binarySearch(List<Integer> listOrdered, int target) {
        int front = 0;
        int rear = listOrdered.size()-1;

        do {
            int mid = (rear+front)/2;
            int value =  listOrdered.get(mid);
            if(value==target) {
                return mid;
            }else if(target>value) {
//                front = mid;
                front = mid + 1;
            }else {
//                rear = mid;
                rear = mid - 1;
            }

        }while(front<=rear);

        return -1;
    }

    @Test
    void 이진탐색_순차탐색_비교_정렬포함(){
        final List<Integer> list = init(1000, 1000000, 50000);
        
        final long start2 = System.currentTimeMillis();
        for(int i=0; i<list.size(); i++){
            int target = list.get(i);
            final List<Integer> list2 = init(10000, 1000000, target);
            Assertions.assertThat(list2.get(linearSearch(list2, target))).isEqualTo(target);
        }
        System.out.println(System.currentTimeMillis()-start2);

        final long start1 = System.currentTimeMillis();
        for(int i=0; i<list.size(); i++){
            int target = list.get(i);
            final List<Integer> list2 = init(10000, 1000000, target);
            list2.sort(INTEGER_ASC);
            Assertions.assertThat(list2.get(binarySearch(list2, target))).isEqualTo(target);
        }
        System.out.println(System.currentTimeMillis()-start1);
    }


    @Test
    void 이진탐색_순차탐색_비교_정렬미포함(){
        final Map<Integer, List<Integer>> orderedMap = getOrderedList(10000, 1000000);
        final Set<Integer> keys = orderedMap.keySet();

        final Iterator<Integer> iterator = keys.iterator();

        final long start2 = System.currentTimeMillis();
        while(iterator.hasNext()){
            Integer target = iterator.next();
            final List<Integer> list = orderedMap.get(target);
            final int index = binarySearch(list, target);
            Assertions.assertThat(list.get(index)).isEqualTo(target);
        }
        System.out.println(System.currentTimeMillis()-start2);


        final Iterator<Integer> iterator2 = keys.iterator();

        final long start1 = System.currentTimeMillis();
        while(iterator2.hasNext()){
            Integer target = iterator2.next();
            final List<Integer> list = orderedMap.get(target);
            final int index = linearSearch(list, target);
            Assertions.assertThat(list.get(index)).isEqualTo(target);
        }
        System.out.println(System.currentTimeMillis()-start1);


    }

    private Map<Integer, List<Integer>> getOrderedList(int size, int max){
        final Map<Integer, List<Integer>> result = new HashMap();
        for(int i=0; i<size; i++){
            int target = (int) (Math.random()*max);
            final List<Integer> list = init(size, max, target);
            list.sort(INTEGER_ASC);
            result.put(target, list);
        }
        return result;

    }

}

```
