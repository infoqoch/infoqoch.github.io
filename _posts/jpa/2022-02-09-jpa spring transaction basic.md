---
layout: post
author: infoqoch
title: jpa, 스프링에서의 트랜잭션과 영속성 처리
categories: [jpa]
tags: [jpa, spring]
---

## 트랜잭션과 영속성 컨텍스트
- jpa는 영속성 컨텍스트의 생명주기와 트랜잭션의 생명주기가 일치한다.
- 그러므로 readonly 를 제외한 서비스의 메서드에 대해서는 `@Transactional` 어너테이션을 사용해야 한다. 
- 테스트코드에서도 마찬가지로 영속성 컨텍스트를 유지하려면 트랜잭셔널 어너테이션을 붙여야 한다. 
- 아래의 소스코드와 테스트코드로 확인해보자.


## 소스코드

```java
@Repository
@RequiredArgsConstructor
public class MemberRepository {

//    @PersistenceContext
//    private EntityManager em;

    private final EntityManager em;

    public void save(Member member) {
        em.persist(member);
    }

    public Member findOne(Long id) {
        return em.find(Member.class, id);
    }

    public List<Member> findAll() {
        return em.createQuery("select m from Member m", Member.class)
                .getResultList();
    }

    public List<Member> findByName(String name) {
        return em.createQuery("select m from Member m where m.name = :name", Member.class)
                .setParameter("name", name)
                .getResultList();
    }
}

@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class MemberService {

    private final MemberRepository memberRepository;

    @Transactional
    public Long join(Member member) {
        validateDuplicateMember(member);
        memberRepository.save(member);
        return member.getId();
    }

    private void validateDuplicateMember(Member member) {
        final List<Member> result = memberRepository.findByName(member.getName());
        if (!result.isEmpty())
            throw new IllegalStateException("이미 존재하는 회원입니다.");
    }

    //회원 전체 조회
    public List<Member> findMembers() {
        return memberRepository.findAll();
    }

    public Member findOne(Long memberId) {
        return memberRepository.findOne(memberId);
    }
}

```

## 테스트코드

### 엔티티의 영속화와 트랜잭션
- 테스트를 작성하며 롤백이 없으면, 영속성에 넣은 객체에 대한 쿼리는 어떻게 발생할까? 
- 참고로 테스트 코드에서 주의해야할 점은 @Transactional 을 붙여야 한다. 해당 어너테이션을 붙이지 않으면 memberService 내부의 트랜잭션이 분리되어 있기 때문에, 다른 영속성으로부터 생성된 객체이며, 그 결과 두 개의 객체는 동일성을 인정받지 못한다.
  
```java
@SpringBootTest
@Transactional 
class MemberServiceTest {

    @Autowired
    MemberService memberService;
    @Autowired
    MemberRepository memberRepository;

    @Test
    void 회원가입_v1(){
        //given
        Member member = new Member();
        member.setName("choi");

        // when
        final Long join = memberService.join(member);

        // then
        Assertions.assertThat(memberRepository.findOne(member.getId())).isEqualTo(member);
    }
}
```

- 위의 테스트코드는 정상 동작한다.
- 하지만 insert 쿼리가 발생하지 않는다? 왜 그럴까.
- 이 것은 앞서의 트랜잭션과 연결된다. 동일한 영속성 컨텍스트 내부에서 insert는 커밋 시점에서 진행된다. 그 말은 커밋 직전에 db로부터 호출한 동일한 레코드(객체)는 사실 영속성 컨텍스트에 삽입된 객체를 그냥 꺼내주는 것에 불과하다. 그러니까 insert가 필요하지 않다.
- 더 나아가 @Rollback(false)로 명시하지 않으면 기본 값은 롤백 true 가 된다. 이 말은 commit 이 아닌 rollback이 수행됨을 의미하며, insert가 수행되지 않음을 의미한다. 
- 그러므로 만약 insert 쿼리를 확인하고자 한다면 @Rollback(false)를 붙이거나 em.flush를 해야 한다. 전자는 실제로 DB에 삽입되며, 후자의 경우 db에 삽입되지만 rollback은 진행되기 때문에 결과적으로 DB에 삽입되지 않는다.

```java
    @Test
    @Rollback(false)
    void 회원가입_v1(){
        // ... 중략 ...
    }
```

```java
    @Autowired
    EntityManager em;
    
    @Test
    void 회원가입_v1(){
        memberService.join(member); // em.persist(member);
        em.flush(); // 이 때 insert 쿼리가 날라간다.
        memberService.findOne(member.getId()); // em.find(1L);
    }
```
