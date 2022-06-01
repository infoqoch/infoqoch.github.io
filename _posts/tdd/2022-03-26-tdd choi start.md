---
layout: post
author: infoqoch
title: 테스트 주도 개발 시작하기
categories: [tdd]
tags: [tdd, java]
---

## 들어가며
- 최범균 개발자님의 '테스트 주도 개발 시작하기' 를 읽었다. 
- 테스트 주도 개발이 왜 "테스트" 주도 개발인지 알 수 있었다. 
- 책에서 이해한 내용을 간략하게 정리하였다. 예제로 있던 숫자야구를 직접 구현해봤다. TDD에 대한 나의 이해를 블로그에 담았다. 
- (2022.06.01) 블로그도 리팩터링이 필요하다. 이전에 있었던 나의 예제 코드가 많이 조잡하여 새롭게 작성하였다. 깃에도 첨부하였다(https://github.com/infoqoch/tdd_baseballgame).

## 기존의 개발 방식
- 숫자야구(https://namu.wiki/w/%EC%88%AB%EC%9E%90%EC%95%BC%EA%B5%AC) 구현을 요구사항으로 받았다. 
- 나는 개발할 때 보통 아래의 느낌으로 하였다. 

### Scanner와 숫자 입력 구현
- 숫자야구를 구현하기 위해서는 데이터를 받아야 한다. Scanner로 값을 입력받고 구현한다.
- 먼저 Scanner로 데이터를 잘 받는지 확인한다. 

```java
public class BaseballGame {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        String[] nums = new String[3];
        nums[0] = sc.nextLine();
        nums[1] = sc.nextLine();
        nums[2] = sc.nextLine();
        for (String num : nums) {
            System.out.println("num = " + num);
        }
    }
}
```

- Scanner는 문자열로만 받는다. 숫자로 변경해야 한다. 더 나아가 1부터 9까지 숫자를 입력하며 중복되어서는 안된다. 이에 대한 검증로직을 만든다. 

```java
public class BaseballGame {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        List<Integer> nums = new ArrayList<>();
        while(nums.size()<3){
            try{
                String target = sc.nextLine();
                int num = Integer.parseUnsignedInt(target);
                if(num>9 || num < 0)
                    throw new IllegalArgumentException();
                nums.add(num);
            }catch (NumberFormatException e){
                System.out.println("숫자가 아닙니다!");
            }catch (IllegalArgumentException e){
                System.out.println("0-9 사이를 입력하십시오!");
            }
        }
        System.out.println("nums = " + nums.toString());
    }
}
```

### 정답을 맞추는 메서드 구현
- 한편, 정답과 이를 맞추기 위한 추측 숫자는 동일한 로직이며 재사용된다. 이를 메서드로 분리한다. 
- 분리한 메서드에 대한 검증 정도는 테스트코드로 구현할 수 있어 보인다. 테스트코드도 구현해본다. 

```java
public class BaseballGame {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        List<Integer> answer = get3Nums(sc);
        System.out.println("입력한 정답은? = " + answer);

        List<Integer> query = get3Nums(sc);
        System.out.println("입력한 예상 답은? = " + query);
    }

    private static List<Integer> get3Nums(Scanner sc) {
        List<Integer> nums = new ArrayList<>();
        while(nums.size()<3){
            try{
                String target = sc.nextLine();
                int num = Integer.parseUnsignedInt(target);
                if(num>9 || num < 0)
                    throw new IllegalArgumentException();
                nums.add(num);
            }catch (NumberFormatException e){
                System.out.println("숫자가 아닙니다!");
            }catch (IllegalArgumentException e){
                System.out.println("0-9 사이를 입력하십시오!");
            }
        }
        return nums;
    }
}
```

```java
public class BaseballGame {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        List<Integer> answer = get3Nums(sc);
        System.out.println("입력한 정답은? = " + answer);

        List<Integer> query = get3Nums(sc);
        System.out.println("입력한 예상 답은? = " + query);

        final Result result = valid(answer, query);
        System.out.println(result.toString());

    }

    // 검증 대상
    public static Result valid(List<Integer> answer, List<Integer> query) {
        int ball = 0, strike = 0;

        for(int i=0; i<3; i++){
            final Integer a = answer.get(i);
            final Integer q = query.get(i);
            if(Objects.equals(a, q)){
                strike++;
                continue;
            }
            if(answer.contains(q))
                ball++;
        }
        if(ball==0 && strike==0)
            return new Result(0, 0, true);

        return new Result(ball, strike, false);
    }

    private static List<Integer> get3Nums(Scanner sc) {
        List<Integer> nums = new ArrayList<>();
        while(nums.size()<3){
            try{
                String target = sc.nextLine();
                int num = Integer.parseUnsignedInt(target);
                if(num>9 || num < 0)
                    throw new IllegalArgumentException();
                nums.add(num);
            }catch (NumberFormatException e){
                System.out.println("숫자가 아닙니다!");
            }catch (IllegalArgumentException e){
                System.out.println("0-9 사이를 입력하십시오!");
            }
        }
        return nums;
    }
}

public class Result {
    private int ball;
    private int strike;
    private boolean out;

    public Result(int ball, int strike, boolean out) {
        this.ball = ball;
        this.strike = strike;
        this.out = out;
    }

    public int getBall() {
        return ball;
    }

    public int getStrike() {
        return strike;
    }

    public boolean isOut() {
        return out;
    }

    @Override
    public String toString() {
        if(out)
            return "아웃!";
        return "볼 : " + getBall() + ", 스트라이크 : "+getStrike();
    }
}

class BaseballGameTest {
    @Test
    @DisplayName("정답과 답변간 비교가 잘 되는지 확인한다.")
    void test(){
        List<Integer> answer = new ArrayList<>();
        answer.add(1);
        answer.add(2);
        answer.add(3);

        List<Integer> query = new ArrayList<>();
        query.add(1);
        query.add(3);
        query.add(6);

        final Result result = BaseballGame.valid(answer, query);
        Assertions.assertThat(result.getBall()).isEqualTo(1);
        Assertions.assertThat(result.getStrike()).isEqualTo(1);
        Assertions.assertThat(result.isOut()).isFalse();
    }
}
```

### 코드 정리 및 마무리
- 메인 메서드를 아래와 같이 정리하였다. 

```java
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        List<Integer> answer = get3Nums(sc);
        System.out.println("입력한 정답은? = " + answer);

        while(true){
            List<Integer> query = get3Nums(sc);
            System.out.println("입력한 예상 답은? = " + query);

            final Result result = valid(answer, query);
            System.out.println(result.toString());
            
            if(result.getStrike()==3)
                break;
        }
        
        System.out.println("맞췄습니다!");
    }
```

## 테스트 주도 개발은?
- 테스트 주도 개발의 특징은 public api를 먼저 드러내는 방식으로 구현한다. 이로 인하여 TDD에 대한 나의 첫 인상은 클라이언트를 고려한 개발로 느껴졌다. 내부의 구조를 설명하기보다 어떻게 사용하는지에 초점을 맞춘다. 
    - 테스트 코드에 작성하는 코드의 메서드는 public이 된다. "클래스와 멤버의 접근 권한을 최소화하라"에 따라 테스트 코드에 없는 나머지 메서드는 모두 private이 된다. 
    - 클래스간 흐름을 명확해진다. 이로 인하여 코드를 이해하기 매우 쉬워진다.
- 이러한 기준을 잡고 테스트 코드를 작성했다.

### 기본적인 틀 작성
- 실제 구현된 코드를 작성하지 않기 때문에, 테스트는 언제나 IDE의 경고로부터 시작한다. 이를 실패하는 케이스를 작성이라 한다.

```java
public class BaseballGameTest {
    @Test
    @DisplayName("기본 흐름")
    void base_structure(){
        InputCommand input = new InputCommand();
        BaseballGame game = new BaseballGame(input);
        GameRecord gameRecord = game.play();
    }
}
```

### 이닝의 계산 구현
- 다만, 위의 코드를 작성하기에 앞서 play()를 작성하기로 하였다. 이닝에 따른 점수를 계산하는 것이 가장 중요하다고 판단했기 때문이다. 
- 일단 위의 내용은 주석 처리를 하였다. 이닝을 계산하는 테스트 코드를 아래와 같이 작성했다. 
- 가장 먼저 아웃을 구현하였다. 가장 쉬운 로직이기 때문이다. 

```java
public class CalculateScoreTest {
    @Test
    @DisplayName("아웃")
    void out(){
        // given
        final List<Integer> answer = Arrays.asList(1, 2, 3);
        final List<Integer> query = Arrays.asList(5, 8, 9);

        // when
        final Score score = Score.calculate(answer, query);

        // then
        Assertions.assertThat(score.getStrike()).isEqualTo(0);
    }
}
```

- 앞서의 out에 대한 테스트를 통과하도록 코드를 작성한다. 
- 테스트가 통과하면 아래의 다양한 조건을 통과할 수 있도록 코드를 추가 작성한다. 

```java
@Test
@DisplayName("아웃")
void out(){
    // given
    final List<Integer> query = Arrays.asList(5, 8, 9);

    // when
    final Score score = Score.calculate(Arrays.asList(1, 2, 3), query);

    // then
    assertThat(score.strike()).isEqualTo(0);
    assertThat(score.ball()).isEqualTo(0);
    assertThat(score.isOut()).isEqualTo(true);
}

@Test
@DisplayName("스트라이크 1 볼 1")
void valid_strike1_ball1(){
    // given
    final List<Integer> answer = Arrays.asList(1, 2, 3);
    final List<Integer> query = Arrays.asList(1, 3, 8);

    // when
    final Score score = Score.calculate(answer, query);

    // then
    assertThat(score.strike()).isEqualTo(1);
    assertThat(score.ball()).isEqualTo(1);
    assertThat(score.isOut()).isFalse();
}


@Test
@DisplayName("볼 2")
void valid_ball2(){
    // given
    final List<Integer> answer = Arrays.asList(1, 2, 3);
    final List<Integer> query = Arrays.asList(2, 1, 7);

    // when
    final Score score = Score.calculate(answer, query);

    // then
    assertThat(score.strike()).isEqualTo(0);
    assertThat(score.ball()).isEqualTo(2);
    assertThat(score.isOut()).isFalse();
}


@Test
@DisplayName("스트라이크 1")
void valid_strike1(){
    // given
    final List<Integer> answer = Arrays.asList(1, 2, 3);
    final List<Integer> query = Arrays.asList(6, 2, 8);

    // when
    final Score score = Score.calculate(answer, query);

    // then
    assertThat(score.strike()).isEqualTo(1);
    assertThat(score.ball()).isEqualTo(0);
    assertThat(score.isOut()).isFalse();
}


@Test
@DisplayName("스트라이크 3, 게임끝")
void valid_strike3(){
    // given
    final List<Integer> answer = Arrays.asList(1, 2, 3);

    // when
    final Score score = Score.calculate(answer, answer);

    // then
    assertThat(score.strike()).isEqualTo(3);
    assertThat(score.ball()).isEqualTo(0);
    assertThat(score.isOut()).isFalse();
}
```
- 이를 구현한 코드는 아래와 같다.

```java
import java.util.ArrayList;
import java.util.List;

public class Score {
    private final List<Integer> query;
    private final int strike;
    private final int ball;

    private Score(List<Integer> answer, List<Integer> query) {
        this.query = new ArrayList<>(query);

        int strike = countStrike(answer, this.query);
        int ball = countBall(answer, this.query, strike);

        this.strike = strike;
        this.ball = ball;
    }

    private int countBall(List<Integer> answer, List<Integer> query, int strike) {
        return (int) (answer.stream().filter(i -> query.contains(i)).count() - strike);
    }

    private int countStrike(List<Integer> answer, List<Integer> query) {
        int strike = 0;
        for(int i=0; i<3; i++){
            if(answer.get(i)== query.get(i)){
                strike ++;
            }
        }
        return strike;
    }

    public static Score calculate(List<Integer> answer, List<Integer> query) {
        return new Score(answer, query);
    }

    public boolean isOut() {
        return ball == 0 && strike == 0;
    }

    public int strike() {
        return strike;
    }

    public int ball() {
        return ball;
    }
}
```

### Fake의 활용. InputCommand 구현
- 이제 본격적으로 게임을 구현한다. 가장 먼저 InputCommand를 구현한다. 
- InputCommand에 필요한 기능은 숫자 3개를 계속 출력하는 기능이다. 이를 next()메서드로 하여 구현하고자 한다. 
- InputCommand를 Scanner 등으로 구현할 경우, 테스트할 때마다 값을 커맨드에 입력해야 한다. 이보다는 Queue 컬렉션을 통해 미리 값을 입력하고 테스트를 수행하도록 한다. 이름은 FakeInputCommand로 한다. 
    - 이러한 명칭은 BaseballGame을 테스트하기 위한 대역임을 명확하게 하는 효과를 가진다. 실제로 해당 클래스는 main 패키지가 아닌 test 패키지에 위치한다. 그리고 BaseballGameTest과 같은 패키지에 위치한다.
    - "Deferring Decisions"에 따라 InputCommand의 툴을 최대한 늦추는 효과를 가진다.
- 아래는 대역 객체를 구현을 위한 테스트 코드와 실제 구현 코드이다. 

```java
import static java.util.Arrays.asList;
import static org.assertj.core.api.Assertions.assertThat;

class FakeInputCommandTest {
    @Test
    void test(){
        FakeInputCommand input = new FakeInputCommand();
        input.add(asList(1,2,3));
        input.add(asList(3,4,5));
        input.add(asList(6,7,9));

        assertThat(input.next()).isEqualTo(asList(1,2,3));
        assertThat(input.next()).isEqualTo(asList(3,4,5));
        assertThat(input.next()).isEqualTo(asList(6,7,9));
    }
}

import java.util.LinkedList;
import java.util.List;
import java.util.Queue;

public class FakeInputCommand implements InputCommand {
    private final Queue<List<Integer>> queue = new LinkedList<>();

    @Override
    public List<Integer> next() {
        return queue.poll();
    }

    public void add(List<Integer> command) {
        queue.add(command);

    }
}
```

### Fake를 사용하여 코드 작성
- FakeInputCommand를 활용하여 아래와 같이 작성한다.
- 가장 쉬운 테스트를 먼저 수행하였다. 첫 번째 이닝에서 게임이 끝난다.

```java
public class BaseballGameTest {
    @Test
    @DisplayName("1이닝 게임 종료")
    void game_set_first_inning(){
        // given
        FakeInputCommand input = new FakeInputCommand();
        input.add(asList(1,2,3)); // answer
        input.add(asList(1,2,3)); // 첫 번째 이닝
        
        BaseballGame game = new BaseballGame(input);

        // when
        GameRecord gameRecord = game.play();

        // then
        assertThat(gameRecord.answer()).containsExactlyElementsOf(asList(1,2,3));
        assertThat(gameRecord.lastInning()).isEqualTo(1);
    }
}
```

- 위의 테스트가 통과하도록 코드를 구현한다. 나머지 테스트 코드도 작성한다.
- 테스트 코드 역시 리팩토링의 대상이다. 추가적인 테스트 코드를 작성하기 전에 중복되는 코드를 없애고 읽기 쉽도록 만든다.

```java
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static java.util.Arrays.asList;
import static org.assertj.core.api.Assertions.assertThat;

public class BaseballGameTest {

    private FakeInputCommand input;

    @BeforeEach
    void setUp(){
        input = new FakeInputCommand();
    }

    @Test
    @DisplayName("1이닝 게임 종료")
    void game_set_first_inning(){
        // given
        input.add(asList(1,2,3)); // answer
        input.add(asList(1,2,3)); // 첫 번째 이닝

        assertAnswerAndLastInning(asList(1, 2, 3), 1);
    }
    
    @Test
    @DisplayName("2이닝 게임 종료")
    void game_set_2_inning(){
        // given
        input.add(asList(5,7,3)); // answer
        input.add(asList(1,2,3)); // 첫 번째 이닝
        input.add(asList(5,7,3)); // 두 번째 이닝

        assertAnswerAndLastInning(asList(5,7,3), 2);
    }

    @Test
    @DisplayName("9이닝 게임 종료")
    void game_set_9_inning(){
        // given
        input.add(asList(5,7,3)); // answer
        input.add(asList(1,2,3)); // 1
        input.add(asList(1,2,3)); // 2
        input.add(asList(1,2,3)); // 3
        input.add(asList(1,2,3)); // 4
        input.add(asList(1,2,3)); // 5
        input.add(asList(1,2,3)); // 6
        input.add(asList(1,2,3)); // 7
        input.add(asList(1,2,3)); // 8
        input.add(asList(5,7,3)); // 마지막 이닝

        assertAnswerAndLastInning(asList(5,7,3), 9);
    }

    private void assertAnswerAndLastInning(List<Integer> answer, int lastInning) {
        BaseballGame game = new BaseballGame(input);
        GameRecord gameRecord = game.play();

        // then
        assertThat(gameRecord.answer()).containsExactlyElementsOf(answer);
        assertThat(gameRecord.lastInning()).isEqualTo(lastInning);
    }
}
```

- 테스트코드를 통과한 구현 코드는 아래와 같다. 

```java
import java.util.ArrayList;
import java.util.List;

public class BaseballGame {
    private final InputCommand input;
    private final List<Integer> answer;

    public BaseballGame(InputCommand input) {
        this.input = input;
        this.answer = new ArrayList(this.input.next());
    }

    public GameRecord play() {
        int inning = 0;
        while(true){
            ++inning;
            final Score score = Score.calculate(answer, input.next());
            if(score.isGameSet()) // isGameSet은 기존에 없었으나 추가하였음. strike 가 3개 이면 true를 반환
                return GameRecord.report(inning, answer);
        }
    }
}
```

### 새로운 기능 추가에 대한 요구사항 발생
- 앞서의 코드를 잘 사용하다가 기능 추가를 요청 받았다. next()를 통해 answer와 query 리스트를 삽입하였다. answer를 먼저 추가하고 next()는 온전히 query를 위한 기능으로 수정하도록 요청 받았다. 
- 이러한 요구사항을 위한 테스트 코드와 구현 코드는 아래와 같다. 

```java
public class BaseballGameTest {
    @Test
    @DisplayName("초기화 때 answer를 삽입한다.")
    void set_answer_when_init(){
        // given
        input.add(asList(1,2,3)); // 첫 번째 이닝

        BaseballGame game = new BaseballGame(input, asList(1,2,3)); // 초기화 때 정답을 삽입한다.

        // when
        GameRecord gameRecord = game.play();

        // then
        assertThat(gameRecord.answer()).containsExactlyElementsOf(asList(1,2,3));
        assertThat(gameRecord.lastInning()).isEqualTo(1);
    }
}

public class BaseballGame{
    // 생성자 하나를 추가한다.
    public BaseballGame(FakeInputCommand input, List<Integer> answer) { 
        this.input = input;
        this.answer = new ArrayList(answer);
    }
}
```

- 다른 코드에 대한 영향 없이 BaseballGame만 수정하여 반영할 수 있었다. input, calculate 등 메서드에 영향이 없다.
- 테스트 코드를 통해 코드를 변경하더라도 이전과 같이 정상 동작함을 보장받았다. 

## 내가 느낀 테스트 주도 개발의 장점들
### 클라이언트 친화적, 읽기 쉬운 코드
- 내가 느낀 TDD의 최고의 장점은 public과 private의 분리와 클라이언트를 배려한 코드에 있다고 생각한다. 

```java
InputCommand input = new InputCommand();
BaseballGame game = new BaseballGame(input);
GameRecord gameRecord = game.play();
```

- 클라이언트 입장에서 어떻게 사용하는지 아주 명확하게 드러난다. 그리고 개발자 입장에서는 이렇게 드러난 메서드에 대해서만 유지보수를 하면 된다. 이러한 명료함이 TDD의 아주 큰 장점이라 생각한다. 
- 가끔은(사실 자주), 내가 작성한 코드를 내가 읽을 때, 어떤 의도로 어떤 방식으로 작성했는지 잊어버리는 경우가 너무 많다. 나의 코드의 애독자는 다른 사람이 아닌 나 자신이다. 내가 읽기 쉽고 간단한 형태로 코드를 구현하는 것은 언제나 좋다. 

### 대역을 통한 집중력 있는 테스트
- 테스트를 할 대상에 집중할 수 있다는 점도 무척 큰 장점이다. 
- 만약 레거시 코드의 Scanner를 유지한 상태에서 테스트 코드를 생성한다고 가정하자. 테스트를 할 때마다 Scanner System.in 을 통해 커맨드로 값을 입력해야 한다. 커맨드에 숫자를 적다가 지쳐서 테스트를 더 이상 하고 싶지 않게 될 것이다.
- BaseballGame의 관심사는 InputCommand.next() 를 통해 숫자 3개를 잘 받는 것에 있다. Scanner가 커맨드에서 어떻게 입력되는지는 관심사가 아니다. 그러므로 Fake 객체를 통해 next()를 통해 숫자만 잘 나오도록 만들 수 있게 코드를 구현하는 것은, 중요한 관심사인 BaseballGame 에 집중하게 만드는 효과를 가진다.
- 이러한 대역 객체를 만들 수 있었던 이유는 public API가 명확하게 정리된 덕분이다. 앞서의 클라이언트에 친화적인 코드이기 때문에 쉽게 InputCommand를 교체할 수 있었다. 

## TDD 구현을 위한 팁과 방식
- 책을 읽고 배운 내용들을 간략하게 정리하였다. 

### 대역
- 앞서 Fake 객체를 만든 것처럼, 테스트를 위하여 만든 가상의 데이터, 통신, DB 따위를 대역이라 한다. 외부의 조건을 마련하는 것보다, 외부의 가상의 조건을 상정한 채 테스트를 수행하는 것이 현실적이며 빠르며 안전하다. 
- 대역의 종류는 아래와 같다. 
    - stub : 구현을 단순한 것으로 대체하고 응답한다. 특정 메서드가 있고 boolean을 리턴하는데, 그냥 항상 true로 반환하는 식이다.
    - fake : 메서드가 동작을 하지만 실제 운영에서는 사용하지 않는다. DB-JDBC 대신 Map을 사용하는 리포지토리가 fake이다.
    - spy : 호출된 내역을 기록하거나 결과값을 반환한다. 특정 테스트를 진행함에 있어서, 특정 메서드를 호출하였는지, 호출의 결과값이 무엇인지를 확인할 때 사용한다. 
    - mock : 앞서의 대역을 구현하지 않고 라이브러리로 해소한다.  Mockito를 활용한다.
- 간단한 내용을 다루거나 레거시 코드를 리팩토링하기 어려운 경우, mock으로 간단하게 처리한다. 그 이외에는 명확하고 간단한 테스트코드 작성을 위하여 대역을 구현하는 방식을 추천한다.

### 테스트의 범위와 종류
- 단위(유닛) - 통합 - 기능 테스트로 분류한다. 상황에 따라 분류 방식은 다를 수 있지만, 대체로
  - 단위테스트는 개별 코드나 컴퍼넌트가 동작하는지를 확인한다. 필요에 따라 스텁이나 목을 사용한다. 
  - 통합테스트는 특정 기능을 수행하기 위한 클래스와 외부 인자 등에 대하여 통합적으로 수행하는 테스트이다.
  - 기능테스트는 사용자 입장에서 어플리케이션을 테스트하는 형태이다.
  - 통합테스트가 내부 코드를 통해 수행하는 것과 달리 기능 테스트는 직접 어플리케이션을 다루는 방식으로 이뤄진다.

### 좋은 테스트 코드 설계는?
- 테스트코드 역시 유지보수의 대상이다. 관리가 쉽고 잘 깨지지 않는 테스트를 구현해야 한다. 
- 변수나 필드를 사용해서 복잡하게 기대값을 표현하지 않는다. 정확하고 명확하게 표현하는 것이 더 낫다.
- 테스트 하나는 하나의 내용만을 검증한다.
- 모의 객체를 구현할 때, 정확한 값보다 범용적인 값이 낫다. `"value"` 보다 `any()`가 더 낫다.
- BeforeEach를 통한 과도한 셋업을 하지 않는다. 모든 테스트에 영향을 미치기 때문에 관리가 어렵다. 셋업을 이해하기 위한 시간이 길어질 수 있다.
- 과도하게 구현을 검증하지 않는다. 특히 내부검증 로직을 무리하게 검증하지 않는다. 내부 구현이 바뀌면 테스트가 깨질 수 있기 때문이다. 접근 제한자가 public인 코드를 테스트한다. 만약 내부 구현을 검증해야 하거나 가짜 구현 객체를 만들기 어려운 경우 mock을 사용한다. 레거시 코드를 다루는 예시는 아래와 같다.

```java
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.matches;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.mock;

public class EmailServiceTest {
  @Test
  void test() {
    // given
    EmailService emailService = new EmailService();
    UserDao userDao = mock(UserDao.class);
    emailService.setUserDao(userDao); // 레거시 코드가 빈을 필드 주입할 경우, 그냥 setter를 만들어서 dao를 주입하였다.
    given(userDao.countById(anyString())).willReturn(1); // 한편, dao를 테스트코드로 만드는 것조차 어려울 수 있다. 가짜로 구현하기 어려우므로, mock으로 처리한다. 어떤 값을 넣더라도 1을 리턴하므로 이는 stub이다.

    // when
    final String email = "user.id@naver.com";
    emailService.changeEmail("userId", email);

    // then
    then(userDao).should().updateEmail(anyString(), matches(email)); // updateEmail을 호출하는지를 확인한다. 해당 코드는 spy에 해당한다.
  }
}
```