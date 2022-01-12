---
layout: post
author: infoqoch
title: 입구가 두 개인 스택 구현하기, 스택을 위한 프리티 프린터
categories: [algorithm]
tags: [algorithm, java]
---

## 들어가며
- 보통 스택은 하나의 입구만 가지고 있다. 
- 이번에 구현한 스택은 하나의 배열이 두 개의 스택이 있다. 
- 프린터 기능을 최대한 예쁘게 구현해봤다. 


## pretty printer
- 글자의 길이에 따라 가변적으로 작동한다. 
- 영문/영어로 사용한다. 

```java
import java.util.ArrayList;
import java.util.List;

public class PrettyPrinter {

    private final String value;
    private int maxLength;

    public PrettyPrinter(Object value) {
        try {
            this.value =  String.valueOf(value);
        }catch (Exception e) {
            throw new IllegalArgumentException("Wapper class 혹은 primitive type 을 넣어주세요");
        }
    }

    public void setMaxLength(int maxLength) {
        this.maxLength = maxLength;
    }

    public int getLength() {
        return value.length();
    }

    public String toStringWithSpace() {
        StringBuilder sb = new StringBuilder();
        sb.append(value);
        for(int i=0; i<maxLength- value.length(); i++){
            sb.append(" ");
        }
        return sb.toString();
    }

    public static int maxLength(int... targets) {
        int max = 0;
        for(int i=0; i<targets.length; i++) {
            if(targets[i]>max)
                max = targets[i];
        }
        return max;
    }
}
```

- 테스터
  
```java
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class PrettyPrinterTest {

    @Test
    void 프리티프린터테스트(){
        int a = 99999;
        int b = 11;
        int c = 666;

        int num = 3;

        // 처음부터 글자를 늘릴 수는 없음. 최대값이 나와야 함.
        // 1. 각자의 길이를 구한다.
        // 2. 모두의 길이 중 최대 길이를 구한다.
        // 3. 최대 길이와 각자의 길이의 남은 숫자만큼 스페이스를 삽입한다.

        PrettyPrinter aa = new PrettyPrinter(a);
        PrettyPrinter bb = new PrettyPrinter(b);
        PrettyPrinter cc = new PrettyPrinter(c);

        int max = PrettyPrinter.maxLength(aa.getLength(), bb.getLength(), cc.getLength());

        aa.setMaxLength(max);
        bb.setMaxLength(max);
        cc.setMaxLength(max);

        System.out.println(aa.toStringWithSpace()+"!");
        System.out.println(bb.toStringWithSpace()+"!");
        System.out.println(cc.toStringWithSpace()+"!");
    }
}
```

## 실제 스택 구현

```java
import utils.PrettyPrinter;

import java.util.ArrayList;
import java.util.List;

public class IntDoubleStack {
    private int max;
    private int leftPointer;
    private int rightPointer;
    private int[] stack;

    public void clear(){
        stack = new int[max];
        leftPointer = 0;
        rightPointer = max-1;
    }
    public IntDoubleStack(int capacity){
        max = capacity;
        stack = new int[max];
        leftPointer = 0;
        rightPointer = max-1;
    }

    public void pushLeft(int v){
        if(max <= getTotalSize())
            throw new OverFlowIntDoubleStackException();

        stack[leftPointer++] = v;
    }

    public void pushRight(int v){
        if(max <= getTotalSize())
            throw new OverFlowIntDoubleStackException();

        stack[rightPointer--] = v;
    }

    public int popLeft(){
        if(leftPointer<=0)
            throw new EmptyIntDoubleStackException();

        return stack[--leftPointer];
    }

    public int popRight(){
        if(rightPointer>=max-1)
            throw new EmptyIntDoubleStackException();

        return stack[++rightPointer];
    }

    public int getTotalSize() {
        return getLeftSize() + getRightSize();
    }

    public int getRightSize(){
        return (max-rightPointer-1);
    }

    public int getLeftSize(){
        return leftPointer;
    }


    public boolean isFull(){
        return getTotalSize()>=max-1?true:false;
    }
    public boolean isEmpty(){
        return getTotalSize()<=0?true:false;
    }


    // 0 1 2 3 4 5 6 7 8 9
    // 1 2 3 0 0 0 1 0 2 0
    //     L       R
    public void print(){
        StringBuilder sb1 = new StringBuilder();
        StringBuilder sb2 = new StringBuilder();
        StringBuilder sb3 = new StringBuilder();

        for(int i=0; i<stack.length; i++){
            PrettyPrinter line1 = new PrettyPrinter(i);
            PrettyPrinter line2 = new PrettyPrinter(stack[i]);

            String status  = "";
            if(leftPointer==i+1)
                status = "L";
            else if(rightPointer == i-1)
                status = "R";
            PrettyPrinter line3 = new PrettyPrinter(status);

            int max = PrettyPrinter.maxLength(line1.getLength(), line2.getLength(), line3.getLength());

            line1.setMaxLength(max);
            line2.setMaxLength(max);
            line3.setMaxLength(max);

            sb1.append(line1.toStringWithSpace()).append(" ");
            sb2.append(line2.toStringWithSpace()).append(" ");
            sb3.append(line3.toStringWithSpace()).append(" ");
        }
        System.out.println(sb1.toString());
        System.out.println(sb2.toString());
        System.out.println(sb3.toString());

    }

    public class OverFlowIntDoubleStackException extends RuntimeException{}

    public class EmptyIntDoubleStackException extends RuntimeException{}

}
```

```java
import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class IntDoubleStackTest {

    @Test
    void 예외테스트(){
        //given
        final IntDoubleStack stack = new IntDoubleStack(5);

        // 초과 입력
        Assertions.assertThatThrownBy(() -> {
            stack.popLeft();
        }).isInstanceOf(IntDoubleStack.EmptyIntDoubleStackException.class);

        Assertions.assertThatThrownBy(() -> {
            stack.popLeft();
        }).isInstanceOf(IntDoubleStack.EmptyIntDoubleStackException.class);

        stack.print();
        stack.pushLeft(1);
        stack.print();
        stack.pushLeft(2);
        stack.print();
        stack.pushLeft(3);
        stack.print();
        stack.pushLeft(4);
        stack.print();
        stack.pushRight(9);
        stack.print();

        // 초과 입력
        Assertions.assertThatThrownBy(() -> {
            stack.pushRight(8);
        }).isInstanceOf(IntDoubleStack.OverFlowIntDoubleStackException.class);

        Assertions.assertThatThrownBy(() -> {
            stack.pushLeft(8);
        }).isInstanceOf(IntDoubleStack.OverFlowIntDoubleStackException.class);
    }

    @Test
    void 사이즈테스트(){
        //given
        final IntDoubleStack stack = new IntDoubleStack(5);

        // when
        stack.pushLeft(1);
        stack.pushLeft(2);
        stack.pushRight(5);
        stack.pushRight(4);
        stack.pushRight(3);

        // then
        Assertions.assertThat(stack.getLeftSize()).isEqualTo(2);
        Assertions.assertThat(stack.getRightSize()).isEqualTo(3);
        Assertions.assertThat(stack.getTotalSize()).isEqualTo(5);
    }

    @Test
    void fullOrEmpty(){
        // given
        final IntDoubleStack stack = new IntDoubleStack(5);

        // when

        // then 비었을 때
        Assertions.assertThat(stack.isEmpty()).isEqualTo(true);
        Assertions.assertThat(stack.isFull()).isEqualTo(false);

        // when
        stack.pushLeft(1);
        stack.pushLeft(2);
        stack.pushRight(5);

        // then 어설프게 채웠을 떄
        Assertions.assertThat(stack.isEmpty()).isEqualTo(false);
        Assertions.assertThat(stack.isFull()).isEqualTo(false);

        // when
        stack.pushRight(4);
        stack.pushRight(3);

        // then 가득 찼을 떄
        Assertions.assertThat(stack.isEmpty()).isEqualTo(false);
        Assertions.assertThat(stack.isFull()).isEqualTo(true);
    }

    @Test
    void clearTest(){

        // when
        final IntDoubleStack stack = new IntDoubleStack(5);

        // given
        stack.pushLeft(1);
        stack.pushLeft(2);
        stack.pushRight(5);
        stack.pushRight(4);
        stack.pushRight(3);
        stack.print();

        // then
        stack.clear();
        stack.print();
        Assertions.assertThat(stack.getTotalSize()).isEqualTo(0);
        Assertions.assertThat(stack.getLeftSize()).isEqualTo(0);
        Assertions.assertThat(stack.getRightSize()).isEqualTo(0);
    }

    @Test
    void 테스트_푸쉬_팝(){
        final IntDoubleStack stack = new IntDoubleStack(5);

        // 왼쪽에 넣고 왼쪽을 뺀다.
        stack.pushLeft(1);
        stack.print();
        Assertions.assertThat(stack.popLeft()).isEqualTo(1);
        Assertions.assertThat(stack.getLeftSize()).isEqualTo(0);

        // 왼쪽에 두 번 넣고 왼쪽에 두 번 뺀다.
        stack.clear();
        stack.pushLeft(1);
        stack.pushLeft(2);
        Assertions.assertThat(stack.popLeft()).isEqualTo(2);
        Assertions.assertThat(stack.popLeft()).isEqualTo(1);
        Assertions.assertThat(stack.getLeftSize()).isEqualTo(0);

        // 오른쪽에 넣고 오른쪽에 뺀다.
        stack.clear();
        stack.pushRight(1);
        Assertions.assertThat(stack.popRight()).isEqualTo(1);
        Assertions.assertThat(stack.getRightSize()).isEqualTo(0);

        // 오른쪽에 두 번 넣고 오른 쪽에 두 번 뺸다.
        stack.clear();
        stack.pushRight(1);
        stack.pushRight(2);
        Assertions.assertThat(stack.popRight()).isEqualTo(2);
        Assertions.assertThat(stack.popRight()).isEqualTo(1);
        Assertions.assertThat(stack.getRightSize()).isEqualTo(0);

        // 왼쪽에 넣고 오른쪽에 넣고 왼쪽에 뺀다.
        stack.clear();
        stack.pushLeft(1);
        stack.pushRight(2);
        stack.print();
        Assertions.assertThat(stack.popLeft()).isEqualTo(1);
        Assertions.assertThat(stack.getRightSize()).isEqualTo(1);

        // 오른쪽에 넣고 왼쪽에 넣고 오른쪽에 뺀다.
        stack.clear();
        stack.pushRight(2);
        stack.pushLeft(1);
        stack.print();
        Assertions.assertThat(stack.popRight()).isEqualTo(2);
        Assertions.assertThat(stack.getRightSize()).isEqualTo(0);

        // 왼쪽 오른쪽 왼쪽 오른쪽에 넣고 왼쪽에 두 번 빼고 오른쪽에 두 번 뺴고 비어있는지 확인한다.
        stack.clear();
        stack.pushLeft(1);
        stack.pushRight(2);
        stack.pushLeft(3);
        stack.pushRight(4);
        stack.print();
        Assertions.assertThat(stack.popRight()).isEqualTo(4);
        Assertions.assertThat(stack.popRight()).isEqualTo(2);
        Assertions.assertThat(stack.getRightSize()).isEqualTo(0);
    }
}
```

## 나아가며
- 요새는 테스트코드 짜는게 참 재밌다. 약간의 정리병을 자극한다.
- 세세하게 테스트를 잘 짜면, 코드를 수정하더라도 그것으로 인한 사이드 이펙트를 즉각적으로 알 수 있다. 테스트코드는 너무도 매력적인 개발 스타일이다. 