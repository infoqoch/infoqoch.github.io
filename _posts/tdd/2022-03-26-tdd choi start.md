---
layout: post
author: infoqoch
title: tdd, 테스트 주도 개발 시작하기
categories: [tdd]
tags: [tdd, java]
---

## 들어가며, 절차지향적 개발에 대한 소박한 경험들
- 나는 현재 일년 안되는 경력을 가진 초보 개발자이다. mybatis를 사용하며 절차지향적인 개발을 하고 있다. 
- 절차지향적 개발은 DB와 쿼리에 매우 의존적이다. 특히 select 쿼리를 짜는데 있어서 해당 쿼리에 이미 개발자가 원하는 의도가 다 들어간다. 그리고 그 데이터를 받는 객체의 이름은 DTO로서, 해당 객체는 어떤 기능도 가지지 않고 그저 데이터를 전달하는 목표만을 부여받는다. 
- 객체가 DTO 수준으로 역할를 부여받듯, MVC 패턴 역시 DTO로 전락한다. 컨트롤러는 jsp나 api로 데이터를 전달하거나 전달받는 역할, 데이터를 검증하는 역할로 한정된다. 서비스는 컨트롤러나 리포지토리 한 쪽에서만 처리하기 애매해거나 다수의 컨트롤러에서 사용할 만한 공통 메서드를 처리하는 수준으로 역할이 한정되었다. 자바 역시 db의 통신을 위해 존재하는 dto로서의 기능으로 위상이 추락한다. 물론 스레드, 스케줄러, 외부 api와의 통신을 위해 자바에 대한 지식이 필요하다. 하지만 이러한 기능인 자바의 라이브러리를 활용하는 것뿐이지, 객체지향 개발이나 개발의 새로운 패러다임과는 크게 관계가 없다. 
- 최근 나는 김영한 개발자님의 JPA에 대한 강의를 다시 듣고 학습했다. 1년 전에 공부했을 때는 나는 jpa가 왜 객체지향적인 개발인지 이해하지 못했다. mybatis와 무슨 차이가 있는지를 몰랐다. 경력이 아주 조금 있다고, jpa를 공부하면서, 절차지향적 개발과 객체지향적 개발의 차이가 무엇인지를 어렴풋이 느끼게 되었다.  
- JPA가 객체지향적인 개발을 가능케 하는 이유는 (내 소박한 의견으로는) 영속성 컨텍스트에 있다고 생각한다. 영속성 컨텍스트에 소속된 객체는 어디에 있든 영속성을 보장받는다. 객체와 컬렉션을 우리는 jvm.getHeap.save() 메서드에 넣지 않는다. 우리는 더 이상 객체의 영속성에 신경쓰지 않고 자유롭게 개발한다. 절차지향적 개발의 객체인 dto는 리포지토리에서 컨트롤러로 혹은 컨트롤러에서 리포지토리로의 일방향적 방향이 있고 개발자는 이 방향성에서 벗어날 수 없다. JPA 덕분에 이러한 방향성에서 자유롭다. 자바의 코드를 잘 구현하는 것에 초점을 맞출 수밖에 없다. 이로 인하여 나는 자연스럽게 좋은 개발을 위한 고민을 하게 되었다. 
- TDD를 학습하게 된 계기는 김영한 개발자님이 강의를 할 때 테스트 코드를 여러번 작성했기 때문이고 나는 이를 잘 써먹었기 때문이다. TDD는 객체지향적 개발을 하는 것과 관계 없이 유용한 경우가 많다. 적절한 데이터를 삽입하고 적절하게 롤백만 해준다면 통합 테스트만 사용하더라도 개발이 정말 편리하기 때문이다. 그런데 객체지향과 TDD간 관계는 자주 들었고, 혼자 어설프게 테스트 코드를 짜는 수준에서 업그레이드 하고 싶었기 때문이다.
- 가장 유명한 책인 켄트백의 TDD를 읽으려고 하였으나, 최범균 개발자님의 입문서가 있기 때문에 먼저 읽었다. 지금 느끼는 것은 매우 잘한 선택이라 생각한다. 여기서 이야기 한 것들을 잘 실천하다 좀 더 레벨업이 필요하다고 느낄 때 그 때 켄트백의 책을 도전하면 될 것 같다.
- 책에서 읽은 경험과 간단한 코드를 아래에 간략하게 정리하고자 한다. 
- 테스트 주도 개발이 왜 "테스트" 주도 개발인지 알 수 있었다. 

## 기존의 개발 방식
- 숫자야구(https://namu.wiki/w/%EC%88%AB%EC%9E%90%EC%95%BC%EA%B5%AC) 구현을 요구사항으로 받았다. 
- 나는 개발할 때 보통 아래의 느낌으로 하였다. 

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
```

```java
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

- 마무리를 한다. 

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
- 테스트 주도 개발은 위와 같이 기능을 구현하면서 개발하는 방식이 아니다. 
- 테스트코드에 흐름을 정리한다음, 이를 하나씩 구현하는 방식이다. 
- 개발의 흐름은 아래와 같다. 

- 아래의 코드를 작성한다. 
- 기존의 코드는 Scanner를 사용하였지만, 특정 코드에 의존하지 않도록 컴퍼지션으로 구현함을 상정하며, interface를 매개변수로 한다. 

```java
public class BaseballGameTest {   
    @Test
    @DisplayName("기본 흐름")
    void base_structure(){
        BaseballInputStream input = new BaseballInputStream(); // 편의상 new로 하였지만 interface로 한다.
        BaseballGame game = new BaseballGame(input); 
        GameRecord gameRecord = game.play(); // 결과물은 GameRecord로 전달한다.
    }
}
```

- BaseballGame은 앞서 테스트 코드에 맞춰서 구현한다.
- 이전과 달리 valid는 Result에서 담당하도록 한다. 생성자는 숨기고 정적 메서드인 valid()로 객체를 생성하도록 한다.

```java
public class BaseballGame {
    private final BaseballInputStream input;
    private List<Integer> answer;

    public BaseballGame(BaseballInputStream input){
        this.input = input;

        try{
            this.answer = input.get3Nums();
        }catch (NullPointerException e){
            throw new IllegalStateException("answer의 초기화를 실패하였습니다.");
        }
    }

    public GameRecord play() {
        List<Result> innings = new ArrayList<>();
        while(true){
            List<Integer> query = input.get3Nums();

            System.out.println("입력한 예상 답은? = " + query);

            Result result = Result.valid(answer, query);
            System.out.println(result.toString());

            innings.add(result);

            if(result.getStrike()==3)
                break;
        }
        return new GameRecord(innings, answer);
    }
}


public class Result {
    private final List<Integer> query;

    private final int ball;
    private final int strike;
    private final boolean out;

    private Result(List<Integer> query, int ball, int strike, boolean out) {
        this.ball = ball;
        this.strike = strike;
        this.out = out;
        this.query = query;
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
            return new Result(query, 0, 0, true);

        return new Result(query, ball, strike, false);
    }

    @Override
    public String toString() {
        if(out)
            return "아웃!";
        return "볼 : " + getBall() + ", 스트라이크 : "+getStrike();
    }
}
```

- 먼저 valid에 대한 테스트코드를 작성한다. 

```java
public class BaseballGameResultValidTest {
    @Test
    @DisplayName("아웃")
    void valid_out(){
        // given
        final List<Integer> answer = Arrays.asList(1, 2, 3);
        final List<Integer> query = Arrays.asList(5, 8, 9);

        // when
        final Result result = Result.valid(answer, query);

        // then
        Assertions.assertThat(result.getStrike()).isEqualTo(0);
        Assertions.assertThat(result.getBall()).isEqualTo(0);
        Assertions.assertThat(result.isOut()).isTrue();
    }

    @Test
    @DisplayName("스트라이크 1 볼 1")
    void valid_strike1_ball1(){
        // given
        final List<Integer> answer = Arrays.asList(1, 2, 3);
        final List<Integer> query = Arrays.asList(1, 3, 8);

        // when
        final Result result = Result.valid(answer, query);

        // then
        Assertions.assertThat(result.getStrike()).isEqualTo(1);
        Assertions.assertThat(result.getBall()).isEqualTo(1);
        Assertions.assertThat(result.isOut()).isFalse();
    }


    @Test
    @DisplayName("볼 2")
    void valid_ball2(){
        // given
        final List<Integer> answer = Arrays.asList(1, 2, 3);
        final List<Integer> query = Arrays.asList(2, 1, 7);

        // when
        final Result result = Result.valid(answer, query);

        // then
        Assertions.assertThat(result.getStrike()).isEqualTo(0);
        Assertions.assertThat(result.getBall()).isEqualTo(2);
        Assertions.assertThat(result.isOut()).isFalse();
    }


    @Test
    @DisplayName("스트라이크 1")
    void valid_strike1(){
        // given
        final List<Integer> answer = Arrays.asList(1, 2, 3);
        final List<Integer> query = Arrays.asList(6, 2, 8);
        
        // when
        final Result result = Result.valid(answer, query);

        // then
        Assertions.assertThat(result.getStrike()).isEqualTo(1);
        Assertions.assertThat(result.getBall()).isEqualTo(0);
        Assertions.assertThat(result.isOut()).isFalse();
    }


    @Test
    @DisplayName("스트라이크 3, 게임끝")
    void valid_strike3(){
        // given
        final List<Integer> answer = Arrays.asList(1, 2, 3);

        // when
        final Result result = Result.valid(answer, answer);

        // then
        Assertions.assertThat(result.getStrike()).isEqualTo(3);
        Assertions.assertThat(result.getBall()).isEqualTo(0);
        Assertions.assertThat(result.isOut()).isFalse();
    }
}
```

- 다음으로 BaseballGame 에 대한 테스트를 작성한다.
- 하지만 테스트의 대상은 "BaseballGame"이다. 하지만 IoC와 같이 현재는 BaseballInputStream을 구현하지 않으면 BaseballGame을 테스트할 수 없다. 
- BaseballGame을 테스트할 때 BaseballInputStream을 동시에 구현하고 테스트 하는 형태로 가야할까? 이렇게 할 경우 테스트의 대상이 두 개가 되어버린다. Fake를 prefix로 하여 inputstream 객체를 구현하고, baseballgame의 테스트에 집중한다.

```java
public class BaseballGameTest {
    @Test
    @DisplayName("기본 흐름")
    void base_structure(){
        // 기본적인 구현의 흐름
        // BaseballInputStream input = new BaseballInputStream(); // 편의상 new로 하였지만 interface로 한다.
        FakeBaseballInputStream input = new FakeBaseballInputStream(); // 가짜 인풋 스트림을 구현한다.
        BaseballGame game = new BaseballGame(input);
        GameRecord gameRecord = game.play();
    }
}

public interface BaseballInputStream {
    List<Integer> get3Nums();
}

public class FakeBaseballInputStream implements BaseballInputStream {

    int idx = 0;
    List<List<Integer>> list;

    public void setFake3Nums(List<List<Integer>> list) {
        this.list = list;
    }

    @Override
    public List<Integer> get3Nums() {
        return list.get(idx++);
    }
}
```

- 그리고 테스트코드를 아래와 같이 작성한다.

```java

public class BaseballGameTest {
    FakeBaseballInputStream input;
    BaseballGame game;
    
    @Test
    @DisplayName("객체 생성 때부터 inputstream을 활용하여 값을 집어 넣음. 만약 정의가 되지 않으면 예외 발생")
    void answer_init_exception(){
        // given
        input = new FakeBaseballInputStream(); // 정의되지 않은 상태임

        // when
        Assertions.assertThatThrownBy(()->{
            game = new BaseballGame(input);
        }).isInstanceOf(IllegalStateException.class).hasMessageContaining("answer");
    }

    @Test
    @DisplayName("첫 번째 이닝에 정답을 맞춘다.")
    void done_first_inning(){
        // given
        List<List<Integer>> fake3Nums = new ArrayList<>();
        fake3Nums.add(List.of(1,2,3)); // answer
        fake3Nums.add(List.of(1,2,3)); // 첫 번째 이닝
        init(fake3Nums);

        // when
        final GameRecord gameRecord = game.play();
        Assertions.assertThat(gameRecord.getAnswer()).isEqualTo(fake3Nums.get(0));
        Assertions.assertThat(gameRecord.getInnings()).size().isEqualTo(1);
        Assertions.assertThat(gameRecord.getInnings().get(0).getStrike()).isEqualTo(3);
        Assertions.assertThat(gameRecord.getInnings().get(0).getBall()).isEqualTo(0);
        Assertions.assertThat(gameRecord.getInnings().get(0).isOut()).isFalse();
    }


    @Test
    @DisplayName("네 개의 이닝을 설정하고, 첫 번째부터 네 번째까지 이닝마다 기대하는 결과값이 나오는지 확인한다.")
    void check_innings_result(){
        // given
        List<List<Integer>> fake3Nums = new ArrayList<>();
        fake3Nums.add(List.of(1,2,3)); // answer
        fake3Nums.add(List.of(3,4,5)); // 첫 번째 이닝. 1볼
        fake3Nums.add(List.of(1,3,5)); // 두 번째 이닝. 1볼, 1스트라이크
        fake3Nums.add(List.of(6,8,9)); // 세 번째 이닝. 아웃
        fake3Nums.add(List.of(1,2,3)); // 네 번째 이닝. 끝
        init(fake3Nums);

        // when
        final GameRecord gameRecord = game.play();
        Assertions.assertThat(gameRecord.getInnings()).size().isEqualTo(4);

        Assertions.assertThat(gameRecord.getInnings().get(0).getStrike()).isEqualTo(0);
        Assertions.assertThat(gameRecord.getInnings().get(0).getBall()).isEqualTo(1);
        Assertions.assertThat(gameRecord.getInnings().get(0).isOut()).isFalse();

        Assertions.assertThat(gameRecord.getInnings().get(1).getStrike()).isEqualTo(1);
        Assertions.assertThat(gameRecord.getInnings().get(1).getBall()).isEqualTo(1);
        Assertions.assertThat(gameRecord.getInnings().get(1).isOut()).isFalse();

        Assertions.assertThat(gameRecord.getInnings().get(2).getStrike()).isEqualTo(0);
        Assertions.assertThat(gameRecord.getInnings().get(2).getBall()).isEqualTo(0);
        Assertions.assertThat(gameRecord.getInnings().get(2).isOut()).isTrue();

        Assertions.assertThat(gameRecord.getInnings().get(3).getStrike()).isEqualTo(3);
        Assertions.assertThat(gameRecord.getInnings().get(3).getBall()).isEqualTo(0);
        Assertions.assertThat(gameRecord.getInnings().get(3).isOut()).isFalse();
    }

    private void init(List<List<Integer>> fake3Nums) {
        input = new FakeBaseballInputStream(); 
        input.setFake3Nums(fake3Nums); //가짜 데이터를 입력한다.
        game = new BaseballGame(input);
    }
}
```

- 위의 코드를 통해 테스트에 완료하고 정상 동작함을 확인할 수 있다.
- 위의 형태로 배포가 되었다고 가정하자. 그리고 수개월 뒤, 추가 요구사항이 발생했다. answer를 inputstream을 통해 입력하는 것이 아니라, 처음 객체를 생성할 때부터 만드는 것을 요구받았다. play() 메서드가 동작할 때, Scanner나 bufferedReader를 사용하기를 기대했다. 
- 그럼 아래의 코드로 BaseballGame을 수정하고, 테스트 하나를 추가한 다음, 모든 테스트가 다 정상 동작함을 확인한다.

```java
public class BaseballGame {
    // 생성자를 추가한다.
    public BaseballGame(BaseballInputStream input, List<Integer> answer) {
        this.input = input;
        this.answer = answer;
    }
}
public class BaseballGameTest {
    FakeBaseballInputStream input;
    BaseballGame game;

    @Test
    @DisplayName("기존에는 answer를 inputstream에서 받아온다. 그렇게 하지 않고 List 객체를 미리 생성하여, game의 객체 생성 때 미리 입력하도록 한다.")
    void constructor_with_list_answer(){
        // given
        input = new FakeBaseballInputStream();
        List<List<Integer>> fake3Nums = new ArrayList<>();
        fake3Nums.add(List.of(1,2,3)); // answer
        fake3Nums.add(List.of(1,2,3)); // 첫 번째 이닝
        input.setFake3Nums(fake3Nums);

        // when
        List<Integer> answer = Arrays.asList(1,2,3);
        game = new BaseballGame(input, answer);
        final GameRecord gameRecord = game.play();

        // then
        Assertions.assertThat(gameRecord.getInnings()).size().isEqualTo(1);
    }
}
```

## 내가 느낀 테스트 주도 개발의 장점들
- 위의 예제 코드는 내가 나름대로 작성한 것이라, 잘 작성했는지는 ㅎㅎ.. 아무튼, 위의 방식으로 테스트 주도 개발을 하면서 느낀 장점은,
- 외부 API에 대한 명확한 정리가 된다는 점에 있다. 의식의 흐름으로 코드를 작성하고 구현하게 되면, 해당 코드를 사용할 때 클라이언트가 어떻게 코드를 바라보고 어떤 메서드를 사용할지에 대한 고려가 사라진다. 아니, 내가 나중에 내가 작성한 코드를 읽을 때도 어떤 의도로 작성했는지 그 이유조차도 잃어버리는 경우도 허다하다. 하지만 외부 API가 무엇인지에 대한 명확한 표현이 되기 때문에, 내가 나중에 나의 코드를 보더라도, 구현된 코드를 사용하는 클라이언트가 이해하기에도, 훨씬 좋은 방법임을 느꼈다. 단순하게 이것 하나만으로도 매우 큰 장점이라 생각한다. 아래의 코드를 보자. 얼마나 깔끔하고 명쾌한가? 

    ```java
    BaseballInputStream input = new BaseballInputStream();
    BaseballGame game = new BaseballGame(input); 
    GameRecord gameRecord = game.play(); 
    ```

- 다음의 장점은, 테스트의 대상에 집중할 수 있다는 것에 있다. 만약 BaseballGame을 테스트 한다면, 나머지는 Fake, Stub, Spy 등 다양한 가짜 구현체를 만들어 주입한다. 물론 이러한 주입은, 해당 객체(interface)를 매개변수로 하는 생성자나 정적 메서드가 존재하기 때문이다. 그러니까 이것이 가능하기 위해서는 앞에서 작성한 것처럼, 외부 API가 명확하게 정리된 덕분이다. 이를 기반으로 단 하나의 클래스에 대하여 아주 좁고 단순한 테스트 코드를 작성할 수 있다.
- 위의 내용을 첨언하자면, 만약 레거시 코드의 Scanner를 유지한 상태에서 테스트 코드를 생성한다고 가정하자. 이것은 주입되는 값이 아니기 때문에, 테스트를 할 때마다 Scanner System.in 을 통해 커맨드로 값을 입력해야 한다. 혹은 이를 Fake 객체로 만든다 하더라도 코드를 뒤짚고 새로 구현하는 형태로 할 수밖에 없었을 테다. 
- 실제로 나는 이러한 문제를 자주 겪었고, 이로 인하여 내가 지금까지 해왔던 테스트는 단위테스트가 아닌 통합테스트를 주로 수행해왔다. 그런데 이것은 기존의 코드를 유지한 채로 수행한다면 어쩔 수 없는 선택이었다. 
- 결론적으로 외부 API를 명확하게 설정하고, 외부 정적 라이브러리나 외부의 DB, 통신 등에 대하여 인터페이스로 정의하는 패러다임이, 테스트 주도 개발의 핵심이라는 느낌을 많이 받았다. 정말로 나에게는 좋은 경험이었다. 테스트 주도 개발과 테스트 코드의 작성이 어떤 차이인지를 알게 되었다. 

## TDD를 위한 좋은 팁들
- 책을 읽고 배운 내용들을 간략하게 정리하였다.

### 대역
- 앞서 Fake 객체를 가짜로 만든 것처럼, 테스트를 위하여 만든 가상의 데이터나 통신, DB 따위를 대역이라 한다. 외부의 조건을 마련하는 것보다, 외부의 가상의 조건을 상정한 채 테스트를 수행하는 것이 현실적이고 빠르며 롤백보다 안전하다.
- 대역은 세 가지 종류가 있다.
- stub : 구현을 단순한 것으로 대체하고 응답한다. 특정 메서드가 있고 boolean을 리턴하는데, 그냥 항상 true로 반환하는 식이다.
- fake : 메서드가 동작을 하지만 실제로 사용할 수 없다. DB 대신 map을 관계형 데이터베어스로 대체할 수 있다. 
- spy : 호출된 내역을 기록하거나 결과값을 반환한다. 특정 테스트를 진행함에 있어서, 특정 메서드를 호출하였는지, 호출의 결과값이 무엇인지를 궁금해 할 때 사용한다. 
- mock : Mockito를 통해 앞서의 대역을 구현클래스로 만드는 것이 아닌, 테스트 코드 블럭에서 간단한 방식으로 구현하는 것을 의미한다. 
- 간단한 내용을 다루거나 레거시 코드를 리팩토링하기 어려운 경우, mock으로 간단하게 처리한다. 그 이외에는 명확하고 간단한 테스트코드 작성을 위하여 대역을 구현하는 방식을 추천한다.

### 테스트의 범위와 종류
- 단위(유닛) - 통합 - 기능 테스트로 분류한다. 상황에 따라 분류 방식은 다를 수 있지만, 대체로
  - 단위테스트는 개별 코드나 컴퍼넌트가 동작하는지를 확인한다. 필요에 따라 스텁이나 목을 사용한다. 
  - 통합테스트는 특정 기능을 수행하기 위한 클래스와 외부 인자 등에 대하여 통합적으로 수행하는 테스트이다.
  - 기능테스트는 사용자 입장에서 어플리케이션을 테스트하는 형태이다.
  - 통합테스트가 내부 코드를 통해 수행하는 것과 달리 기능 테스트는 직접 어플리케이션을 다루는 방식으로 이뤄진다.

### 좋은 설계는?
- 하드코딩보단 매개변수으로 값을 주입한다.
- 의존 객체를 소스 내부에서 직접 생성하지 않고(`Scanner sc = new Scanner(System.in);`) -> 생성자나 세터로 삽입할 수 있도록 한다(`public MyClass(MyInputStream input){}`).
- 정적 클래스와 정적 메서드를 사용할 경우 감싸서(컴퍼지션) 사용한다. 
- LocalDateTime.now() 처럼 가변적인 값 역시도 외부에서 주입하는 형태로 한다. 

### 좋은 테스트 코드 설계는?
- 테스트를 한 번 놓아버린 순간 관리가 되지 않기 시작한다. 관리가 쉽고 잘 깨지지 않는 테스트를 구현해야 한다. 
- 변수나 필드를 사용해서 복잡하게 기대값을 표현하지 않는다. 정확하고 명확하게 표현하는 것이 더 낫다.
- 테스트 하나는 하나의 내용만을 검증한다.
- 모의 객체를 설정할 때 정확한 값이 아닌 범용적인 값을 사용한다. "value" 보다 anyString() 이 더 나을 수 있다. 
- BeforeEach를 통한 과도한 셋업을 하지 않는다. 모든 테스트에 영향을 미치기 때문에 위험할 수 있다. 차후 해당 테스트를 볼 때 셋업을 보는 등 이해하는데 시간이 걸릴 수 있다. 
- 과도하게 구현을 검증하지 않는다. 특히 내부검증 로직을 무리하게 검증하지 않는다. 왜냐하면 내부 구현이 바뀌면 테스트가 깨질 위험이 있기 때문이다. 삽입 내용과 그 결과에 초점을 맞춰 진행한다. 만약 내부 구현을 검증하며 동시에 가짜 구현 객체를 만들기 어려운 경우 mock을 사용한다. 그 예시는 아래와 같다.

```java
public class EmailServiceTest {
  @Test
  void test() {
    // given
    EmailService emailService = new EmailService();
    UserDao userDao = mock(UserDao.class);
    emailService.setUserDao(userDao); // 레거시 코드는 필드 주입할 수 있다. 이럴 경우 그냥 setter를 만들어서 dao를 주입할 수도 있다. 
    given(userDao.countById(anyString())).willReturn(1); // dao를 가짜로 구현하기 어려울 경우 mock으로 간단하게 처리한다. 현재의 코드는 stub이다.

    // when
    final String email = "user.id@naver.com";
    emailService.changeEmail("userId", email);

    // then
    then(userDao).should().updateEmail(anyString(), matches(email)); // updateEmail을 호출하는지를 확인한다. 해당 코드는 spy에 해당한다.
  }
}
```