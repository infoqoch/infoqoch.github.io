---
layout: post
author: infoqoch
title: HTTP 프로토콜의 계층(Layer)
categories: [network]
tags: [network, http]
---


## 들어가며
- HTTP(S) 프로토콜은 TCP/IP 프로토콜 중 하나이다. 정확하게는 TCP/IP 프로토콜에 HTTP 클라이언트(어플리케이션 계층)이 추가된 형태이다.

<table>
  <tr>
    <td colspan="2">클라이언트</td>
  </tr>
  <tr>
    <td>어플리케이션계층</td>
    <td>HTTP클라이언트</td>
  </tr>
    <tr>
    <td>(https)보안 계층</td>
    <td>TLS/SSL</td>
  </tr>
  <tr>
    <td>트랜스포트 계층</td>
    <td>TCP</td>
  </tr>
    <tr>
    <td>네트워크 계층</td>
    <td>IP</td>
  </tr>
  <tr>
    <td>링크 계층 + 물리 계층</td>
    <td>네트워크</td>
  </tr>
</table>


1. HTTP 어플리케이션
- 서버와 클라이언트로 볼 수 있다. 각각은 request와 response를 통해 HTTP 메시지를 송수신한다. 

2. TCP
- TCP는 상대방과의 신뢰성 있는 흐름 제어의 요구 속에서 탄생한 통신 규약이다.
- 송신측의 TCP는 메시지를 조각내어 패킷으로 만들고, 각 패킷에 일련번호를 부여한다. 송신 TCP는 전달할 내용을 수신 TCP에 전달하고, 패킷을 보내며, 그 패킷이 제대로 수신되었는지를 확인한다. 
- 이러한 일련의 과정을 쓰리 웨이 핸드쉐이킹(three way handshaking)이라고 한다. 이를 통해 데이터 송수신의 신뢰성을 보장한다. 
- TCP는 데이타의 수발신을 위하여 핸드쉐이킹 외에 지연 시작(slow-start), 트랜잭션의 지연 등 다양한 전략을 가지고 있다. 

3. IP
IP는 TCP가 조각낸 패킷을 실제로 전달하는 역할이다. 패킷을 전달하기 위해서는 host(url 혹은 ip주소)와 port번호를 통해 IP주소를 찾아내고 마지막으로 MAC주소를 확인해야 한다. host url을 가지고 있다면, DNS서버에 접속하여 ip주소를 찾고, ARP(Address Resolution Protocol)을 통해 IP주소를 통해 서버의 MAC주소를 찾아낸다. 


> 출처 : 
> - "그림으로 배우는 Http network basic", 우에노 센
> - "http 완벽가이드", 데이빗 고울리 외
