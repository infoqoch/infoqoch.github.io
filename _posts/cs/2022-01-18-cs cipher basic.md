---
layout: post
author: infoqoch
title: 단방향, 양방향 암호화 기초
categories: [cs]
tags: [cs, cipher, java]
---

## 들어가며
- 단방향, 양방향 암호화는 익숙하게 사용했다. 비밀번호를 암호화할 때 bcrypt를 사용하고 양방향 암호화 때 aes256을 사용하는 것은 일종의 기본 소양과도 같았다.
- 하지만 AES를 사용할 때, iv가 무엇인지 모른채 사용하였고, 'AES/CBC/PKCS5Padding'가 무엇인지 모른채 사용해왔다.
- 이러한 양방향, 단방향의 아주 기초적인 수준을 정리하는 글이며, 구체적인 내용은 참조한 링크를 참고하기를 바란다. 

> https://d2.naver.com/helloworld/318732
> https://xmobile.tistory.com/entry/Android-AES-%EB%8C%80%EC%B9%AD%ED%82%A4-%EC%95%94%ED%98%B8%ED%99%94-%EC%82%AC%EC%9A%A9%ED%95%B4%EB%B3%B4%EA%B8%B0

## 단방향 암호화와 해싱

### 단어 정리
- plain text : 단순 텍스트, 메시지 : 암호화 대상
- digest : 다이제스트 : 암호화의 결과

### 단방향 암호화란?
- 해싱을 통하여 메시지를 다이제스트로 만드는 기술이다. 
- 단방향 암호화는 메시지가 같으면 다이제스트의 결과가 같음을 보장한다. 
- 다만 메시지가 유사하다고 다이제스트가 유사하지 않다. 대부분의 암호화의 기술은 문자열이 유사하더라도 다이제스트는 완전하게 다르게 생성하여 유추하기 어렵게 한다. 
- 비밀번호에 자주 사용한다. 클라이언트는 자신의 비밀번호를 알지만, 서버는 그 비밀번호가 무엇인지를 알아서는 안된다. 클라이언트가 비밀번호를 입력하면, 서버는 해당 값을 다이제스트로 만들어, 이전에 등록한 다이제스트를 비교한다. 일치하면 비밀번호가 맞다고 판단한다. 
  
### 단방향 암호와의 문제 : 인식 가능성(recognizability) 
- 메시지에 따른 다이제스트는 동일하다. 이로 인한 해킹의 위험성이 있다. 다양한 메시지와 다양한 다이제스트를 확보하면 해당 로직을 유추할 수 있다. 이러한 다이제스트 목록을 레인보우 테이블이라 하며, 이를 레인보우 공격이라 한다. 

### 단방향 암호와의 문제 : 해싱의 좋은 성능
- 단방향 암호화는 해쉬 함수로 만들어졌으며, 해시함수는 빠른 조회를 위하여 만들어진 알고리즘이다. 
- 이러한 해싱의 좋은 성능 덕분에 해킹으로부터 위험하다. 왜냐하면 그 빠른 성능을 통해 암호와의 로직을 빠르게 찾을 수 있다. 레인보우 공격에 취약하다.

### 단방향의 단점 보완 : 솔팅
- 무의미한 문자열과 메시지를 혼합한다. 이를 통하여 메시지와 다이제스트를 알고 있더라도 그것을 추측하기 어렵게 만든다. 

### 단방향의 단점 보완 : 키스트레칭
- 해쉬함수의 빠른 수행을 하지 못하도록 만든다. 
- 다이제스트의 다이제스트를 반복적으로 생성하도록 만든다.
- 다이제스트의 생성 시간을 억지로 늘린다. 대체로 0.2초라고 한다. 이를 억지 기법 공격(brute-force attack)이라 한다. 

### Adaptive Key Derivation Functions 
- 솔팅과 키스트레칭을 수행하여 해킹을 어렵게 만드는 함수를 Adaptive Key Derivation Functions 라 한다. 이것을 구현한 방식은 다양하며 그 용도는 아래와 같다.
- PBKDF2-HMAC-SHA-256/SHA-512 : 써드파트에 의존하지 않는 경우
- bcrypt : 강력한 패스워드 암호화가 필요할 경우
- scrypt : 보안에 매우 신경쓰며 동시에 큰 비용을 감수할 수 있을 경우

## 대칭키 암호와 AES256

### EBC, CBC
- 전자 코드북(electronic codebook, ECB)은 메시지를 분할하여 각각 암호화하는 방식이다. 모든 블록이 같은 암호화키를 사용하기 때문에 보안에 취약하다.
- 암호 블록 체인 (cipher-block chaining, CBC)은 이전 블록의 암호와 결과와 XOR 된다. 하지만 이것 역시도 첫 번째 블록이 동일하다면 다음의 값도 동일하기 때문에, 첫 번째 블록을 잘 초기화 해야 한다. 이러한 초기화를 위하여 사용되는 것이 초기화 벡터이며 이를 IV라 한다. 그러므로 CBC 방식에서 IV는 필수이다. 
- 암호화는 대부분 CBC를 사용한다. 

### PKCS5Padding
- 블록의 사이즈가 채워지지 않은 경우, 이를 채워주는 기능이라 한다.

## 나아가며
- AES/CBC/PKCS5Padding 가 무엇인지를 이해할 수 있었다. IV의 용도가 무엇인지 알 수 있엇다. 그러나 아주 간단한 수준으로 이해했기 때문에 부족함이 많다. 
- 일단, 업무에서 AES256을 사용하지만, 사실 IV 값이 자주 수정되지 않는다. 사실상 대칭키를 교환하는 방식으로만 진행된다. 실제로 보안이 매우 중요한, 혹은 보안에 신경쓰는 회사에서는 이를 어떻게 처리하는지 궁금하다. IV를 주기적으로 변경하는 것일까? 

## AES 코드

```java
import org.apache.commons.lang3.StringUtils;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;

public class Aes256Cipher {

    public static String encode(String key, String iv, String plainText) throws Exception {
        if(StringUtils.isBlank(plainText))
            throw new IllegalArgumentException("값을 입력해야 합니다.");

        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
        cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key.getBytes(), "AES"), new IvParameterSpec(iv.getBytes("UTF-8")));

        return new String(Base64.getEncoder().encode(cipher.doFinal(plainText.getBytes("UTF-8"))));
    }

    public static String decode(String key, String iv, String digest) throws Exception {
        if(StringUtils.isBlank(digest))
            throw new IllegalArgumentException("값을 입력해야 합니다.");

        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
        cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key.getBytes(), "AES"), new IvParameterSpec(iv.getBytes("UTF-8")));

        return new String(cipher.doFinal(Base64.getDecoder().decode(digest.getBytes())), "UTF-8");
    }

}
```


```java
import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.Test;

import java.util.Locale;
import java.util.UUID;

class Aes256CipherTest {
    @Test
    void 테스트_encode_encode() throws Exception {
        for(int i=1; i<100; i++) {
            final String key = UUID.randomUUID().toString().replace("-", "").substring(0, 32).toUpperCase(Locale.ROOT);
            final String iv = UUID.randomUUID().toString().replace("-", "").substring(0, 16).toUpperCase(Locale.ROOT);
            System.out.println("key : " + key);
            System.out.println("iv : " + iv);
            System.out.println("========");

            StringBuilder sb = new StringBuilder();
            for(int j=0; j<i; j++){
                sb.append(UUID.randomUUID().toString().replace("-", ""));
            }
            final String given = sb.toString();

            final String digest = Aes256Cipher.encode(key, iv, given);
            System.out.println(digest);

            final String then = Aes256Cipher.decode(key, iv, digest);
            System.out.println(then);

            Assertions.assertThat(then).isEqualTo(given);
        }
    }
}
```
