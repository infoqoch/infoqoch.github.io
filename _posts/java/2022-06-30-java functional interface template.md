---
layout: post
author: infoqoch
title: 자바 함수형 인터페이스를 template pattern으로 구현하여 특정 로직 강제하기
categories: [java]
tags: [java, design pattern]
---

# 특정 로직 흐름을 명시하고 강제할 필요가 있다. 이를 if문으로 해소할 경우 복잡해진다.
- 회원의 등급이 두 개가 있다. 슈퍼 어드민 - 일반 어드민
- 일반 어드민은 자신이 작성한 글을 수정할 수 있지만 남이 작성한 글을 수정할 수 없다. 슈퍼 어드민은 누가 쓴 글이든 수정할 수 있다. 
- 이 경우 코드로 작성하면 어떻게 될까?

```java
public class AdminServiceV1Test {

    @Test
    void test(){
        // 어드민이 super와 그외 어드민 두 개가 있다.
        Admin supers = new Admin("super", SUPER);
        Admin lee = new Admin("lee", BASIC);
        Admin kim = new Admin("kim", BASIC);

        // 작성된 글이 있고 기본 어드민의 kim이 작성했다.
        Article article = new Article(324l, "공지사항", "내일 잠시 점검이 있을 예정입니다.", "kim");

        // 앞서의 글을 변경하고 싶다. 변경하고자 하는 내용은 아래와 같다.
        ArticleModifyRequest request = new ArticleModifyRequest(324l, "공지사항[수정]", "점검이 이번 주까지 연장될 예정입니다.");

        // 현재 세션에 어떤 어드민이 있는지 모른다.
        Admin admin = supers;

        // 해당 어드민이 super이면 삭제할 수 있고 그렇지 않으면 아이디가 일치해야 가능하다.
        modifyArticle(request, admin);


    }

    private void modifyArticle(ArticleModifyRequest request, Admin admin) {
        Article article = articleRepository.findById(request.no);
        if(admin.type == SUPER) {
            article.modify(request, admin);
        }else if(admin.id == article.reg) {
            article.modify(request, admin);
        }else{
            throw new IllegalArgumentException("정상 회원이 아닙니다.");
        }
    }
}
```

- modifyArticle를 보면 if문이 세 개가 사용됨을 확인할 수 있다.  super admin의 여부 - id 일치의 여부 - 그 외.
- 이러한 if문은 계속 반복될 수밖에 없다. 서비스를 관리할 때 게시글 이외의 상품 목록, 카테고리, 주문 등 다양한 관리를 필요로 하고, 이러한 권한 문제를 위와 같은 형태로 동일하게 풀고 싶을 수 있기 때문이다.
- if 문 단 하나로 끝낼 수 있던 로직이었으면 이런 고민을 하지 않았을 텐데, if문이 세 단계로 이뤄져 있기 때문에 어떻게 해소할지 고민이 많았다. 
- 이를 탬플릿 패턴과 함수형 인터페이스로 해소할 수 있었다. 


# 함수형 인터페이스를 탬플릿 패턴으로
## 요구사항
- if문은 세 개의 흐름으로 이뤄져 있다. super admin의 여부 - id 일치의 여부 - 그 외
- 어플리케이션 내부의 여러 상황에서 앞서의 흐름이 반복될 것으로 보인다. 만약 if문으로 직접 작성할 경우 실수가 발생할 수 있다. 위와 같은 흐름을 강제시킬 방법이 필요.
- 흐름을 강제하더라도 실제 구현은 유연해야 함. 

## 해소
- 탬플릿 패턴을 통해 if문의 흐름을 미리 구현한다.
- 함수형 인터페이스를 활용하여 다양한 상황에서 자유롭게 구현할 수 있도록 하였다.
- 함수형 인터페이스를 Builder 패턴을 통해 구현하여, 불변 객체로 구현하였다. 

```java
public class AdminServiceV2Test {

        static class AdminAuthorizationConsumer<E extends AdminAuth> {
        private final E target;
        private final Consumer<E> supers;
        private final Consumer<E> theSameId;
        private final Consumer<E> elses;

        public AdminAuthorizationConsumer(Builder<E> builder) {
            supers = builder.supers;
            theSameId = builder.theSameId;
            elses = builder.elses;
            target = builder.target;
        }

        // 탬플릿 패턴을 통하여 if문의 흐름 (슈퍼 여부 -> 회원 일치 여부 -> 그 외)를 강제한다.
        public void compareTo(String id) {
            if(target.isSuper()) { // 대상이 되는 객체의 super 여부를 interface 로 구현한다.
                supers.accept(target);
            }else if(target.isTheSameIdWith(id)) { // 대상이 되는 객체와 제공하는 아이디 간 일치여부를 interface 로 구현한다.
                theSameId.accept(target);
            }else { // 위의 상황이 모두 false 일 경우
                elses.accept(target);
            }
        }

        // 빌더 패턴을 통하여 불변식으로 구현하였다.
        // 스트림 형태로 함수형 인터페이스를 구현하기 때문에 실제 구현 시 보기 좋다.
        public static class Builder<E extends AdminAuth> {
            private final E target;
            private Consumer<E> supers;
            private Consumer<E> theSameId;
            private Consumer<E> elses;

            public Builder(E e) {
                this.target = e;
            }

            public Builder<E> superAdmin(Consumer<E> consumer){
                this.supers = consumer;
                return this;
            }

            public Builder<E> theSameId(Consumer<E> consumer){
                this.theSameId = consumer;
                return this;
            }

            public Builder<E> elses(Consumer<E> consumer){
                this.elses = consumer;
                return this;
            }

            public AdminAuthorizationConsumer<E> build() {
                return new AdminAuthorizationConsumer<E>(this);
            }
        }
    }

    interface AdminAuth {
        boolean isSuper();
        boolean isTheSameIdWith(String id);
    }

    static class Admin implements AdminAuth {
        private final String id;
        private final Type type;

        enum Type{
            SUPER, BASIC
        }

        Admin(String id, Type type) {
            this.id = id;
            this.type = type;
        }

        @Override
        public boolean isTheSameIdWith(String id) {
            return this.id.equals(id);
        }

        @Override
        public boolean isSuper() {
            return type == SUPER;
        }
    }

    @Test
    void test1(){
        Admin admin = new Admin("kim", BASIC);
        AdminAuthorizationConsumer<Admin> auth = new AdminAuthorizationConsumer.Builder<Admin>(admin)
                .superAdmin(a -> System.out.println("슈퍼유저!"))
                .theSameId(a -> System.out.println("아이디가 일치하네!"))
                .elses(a -> System.out.println("아이디가 불일치하네!"))
                .build();

        auth.compareTo("kim"); // 아이디가 일치하네!
    }
}
```

- 이를 아래와 같이 테스트하였다. 
- 스파이를 테스트에 활용하였다. 

```java
    @Test
    void test2() {
        assertExecute(new Admin("kim", SUPER), "abc", Result.SUPER);
        assertExecute(new Admin("kim", SUPER), "kim", Result.SUPER);
        assertExecute(new Admin("kim", BASIC), "kim", Result.SAME);
        assertExecute(new Admin("kim", BASIC), "lee", Result.ELSE);
    }

    private void assertExecute(Admin admin, String target, Result result) {
        // given
        boolean[] spy = new boolean[3];
        AdminAuthorizationConsumer<Admin> builder = new AdminAuthorizationConsumer.Builder<Admin>(admin)
                .superAdmin(a -> spy[0] = true)
                .theSameId(a -> spy[1] = true)
                .elses(a -> spy[2] = true)
                .build();

        // when
        builder.compareTo(target);

        // then
        assertThat(spy[0]).isEqualTo(result.superAdmin);
        assertThat(spy[1]).isEqualTo(result.theSameId);
        assertThat(spy[2]).isEqualTo(result.elese);
    }

    enum Result {
        SUPER(true, false, false), SAME(false, true, false), ELSE(false, false, true);

        private final boolean superAdmin;
        private final boolean theSameId;
        private final boolean elese;

        Result(boolean superAdmin, boolean theSameId, boolean elese) {
            this.superAdmin = superAdmin;
            this.theSameId = theSameId;
            this.elese = elese;
        }
    }
```