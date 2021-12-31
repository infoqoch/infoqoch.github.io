---
layout: post
author: infoqoch
title: cs 컴퓨터 시스템의 구조
categories: [cs]
tags: [cs, os]
---

![컴퓨터 시스템의 구조](/assets/image/cs/2021-02-20_01.jpg)

## 1. 들어가며
- 현재 운영체제는 interrupt를 통해 이뤄진다.
- interrup를 기준으로 시스템 구조를 살펴보자. 

## 2. CPU의 작동, 구조
1) cpu의 작동
- instruction(명령 처리) : CPU가 하는 일. 프로세스가 요구하는 연산작업을 처리한다. cpu의 program counter는 프로세스가 요청하는 작업의 주소를 가리킨다. register는 그 값을 불러오고 cpu를 통해 작업을 처리하고 결괏값을 register에 임시저장한다. 이처럼 cpu가 각 주소값을 순차적으로 참조하여 처리하는 것을 instruction이라 한다.
- CPU는 매번의 instruction마다 interrupt가 있는지를 확인한다. 만약 interrupt가 있으면 CPU의 사용 권한이 프로세스에서 운영체제(커널)로 넘어간다. 이를 interrupt라고 한다. 

2) interrupt(하드웨어 인터럽트)
- timer : cpu의 독점 방지, 프로그램의 무한루프에 대비하여 timer를 가진다. timer는 cpu를 일정 시간 이상 점유하면 cpu를 빼앗고 다음 프로세스에 cpu를 넘긴다.
- I/O의 인터럽트 : I/O에서 입력이 발생하면 인터럽드가 되어 해당 값이 CPU로 이동한다.
- DMA 컨트롤러의 인터럽트

3) Trap(소프트웨어 인터럽트)
- System call : 사용자 프로그램이 I/O 디바이스의 값이 필요로 할 때 사용. I/O의 접근은 커널만 가능하다. 자발적으로 cpu를 커널에 반납한다. 커널은 CPU에 I/O의 입력을 요구. 
- Exception : 프로그램에 예외 발생. 보통 프로세스가 강제 종료된다.

4) mode bit
- 사용자 프로그램의 권한을 제한하기 위한 보호 장치. 사용자 프로그램을 언제나 신뢰할 수 없음. 
- 모니터 모드(커널모드, 시스템 모드) : mode bit의 값이 0. OS의 코드를 수행. 모든 인스트럭션 실행 가능. I/O에 접근 가능.
- 사용자 모드 : mode bit의 값이 1. 사용자 프로그램을 수행. I/O 접근 불가. 
- 사용자 프로그램이 I/O를 접근하려면, 사용자 프로그램이 OS에 시스템 콜을 보내고, OS는 Mode bit을 1로 전환하여, CPU가 I/O에 접근할 수 있도록 함. 

5) DMA Controller (Direct Memory Access Controller)
- I/O에서 다수의 인터럽트가 발생하고, 모든 인터럽트에 대해 CPU가 실시간 대응하면, CPU 사용에 있어서 오버헤드 발생. DMA가 I/O의 데이타(I/O 디바이스의 buffer의 값)를 모음. 데이타를 불출 할 때, (1) 바이트가 아닌 block 단위로 한 번에 메모리에 접근해서 저장하며 (2)처리 결과를 단 한 번의 인터럽트로 cpu에 전달. 
- 기본적으로 메모리는 CPU만 접근할 수 있으나 DMA만 특별하게 허용.

6) 인터럽트 처리 
- 인터럽트 처리 루틴(Interrupt Service Routine, 인터럽트 핸들러) : 인터럽트를 처리하기 위한 커널의 함수
- 인터럽트 백터 Interrupt vector: 해당 인터럽트를 처리하기 위한 인스터럭션이 존재하며, 그 인스터럭션에 대한 주소 값. 
- 인터럽트가 발생하면, 인터럽트 루틴에 따라 cpu가 작동함. instruction을 가져오기 위한 코드를 가리키는 주소는 백터에 저장되어 있음. 

## 3. I/O device의 구조, cpu와의 기본적인 입출력 과정 
- I/O device는 자체적인 cpu(controller)를 가짐. 
  - device를 통제. 
  - buffer(register data, memory)와 register 등을 포함. 
- cpu는 I/O에 원하는 명령(instruction)을 I/O의 register에 저장. register의 명령 아래에 디바이스로부터 데이타를 로딩하고 그 값은 자신의 buffer에 저장. controller는 cpu를 인터럽트한 후 데이타를 전송. 
- device driver : 커널의 코드 중 하나로, 커널(os)가 I/O장치를 처리하기 위한 루틴.
- firmware : I/O Controller가 자신의 device를 통제하기 위한 루틴으로서 코드. 

## 4. 동기식 입출력(Synchronous I/O)와 비동기식 입출력(Asynchromous I/O)
- 동기식 입출력 : 프로세스가 자신의 작업을 완료하기 위하여, I/O에 데이타를 read 혹은 write 작업을 수행하고 그 수행의 결과가 나와야지만 이후 작업을 진행할 수 있는 방식. 
- 비동기식 입출력 : I/O의 입출력을 요청하더라도, 그 결과를 기다릴 필요가 없다. 프로세스 내부의 다른 작업을 진행하며, 해당 입출력이 도착하면, 그때 남은 작업을 처리한다. 
- 동기식 입출력의 경우 프로세스가 I/O에 접근하여 deivce queue에 디바이스의 결과값을 기다리면, 그 동안 cpu는 놀고 있음. 이러한 cpu의 점유는 cpu의 자원의 낭비. 
- 비동기식 입출력의 경우 cpu를 점유 중인 한 프로세스가 cpu의 사용을 하지 않는 경우 cpu를 다른 프로세스가 사용하도록 방출. 이러한 cpu 통제권의 변경은 Context Switch 라고 함. 
- Synchronous read : I/O로부터 값을 읽은 후에 진행 가능한 작업. 
- Synchronous writer : I/O가 값을 저장한 후에 진행 가능한 작업.


> 출처 : http://www.kocw.net/home/search/kemView.do?kemId=1046323
이화여대 반효경 교수의 영상강의를 주요자료로 하여 운영체제를 학습하고 정리하고 있습니다. 