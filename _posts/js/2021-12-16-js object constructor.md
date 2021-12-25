---
layout: post
author: infoqoch
title: js 생성자를 통한 객체 생성과 조작
last_modified_at: 
categories: [js]
tags: [js]
---


## 객체
### 선언과 조작
- JS의 객체 선언은 매우 간단하다.

```js
let kim = new Object();
kim.age = 12;
kim.name = '김길동'

console.log(kim);
```

- 아래는 더 쉽다.

```js
let kim = {
  name:'김길동',
  age:20
}
    
console.log(kim);
```

- 객체의 각각의 값을 properties라고 한다. properties의 입력과 삭제, 수정은 다음과 같다.


```js
kim.city = '서울';
kim.age = 15;
delete kim.age;

console.log(kim)
```

### 매서드
- 객체의 함수를 매서드라 한다.
- 객체의 프로퍼티스를 사용하기 위해서는 반드시 this 를 사용해야 한다. this를 사용하지 않는 경우 전역변수를 사용한다.

```js
let kim = {
  name:'김길동',
  age:20,
  print : function(){
    console.log(`저의 이름은 ${this.name}이며 나이는 ${this.age}입니다.`)
  }
}

kim.print()
```

```js
const kim = {
  name:'김길동',
  age:20,
  print : function(){
    console.log('저의 이름은 '+ name +'입니다.') // "저의 이름은 JS Bin Output 입니다." // jsbin.com 을 사용중이며 name 이 전역변수로 있는 것 같다. 
    console.log('나이는 ' + age + '입니다.') // ReferenceError: age is not defined

  }
}

kim.print()

```

## 생성자와 객체
### 생성자 함수의 구현
- 자바의 생성자처럼 객체를 생성하기 위한 일종의 틀을 만들 수 있다. 

```js
function User(name, age){
    this.name = name;
    this.age = age;
    this.sayName = function(){
    console.log(`Hello, ${this.name}`)
    }
}

const user1 = new User("kim", 12);
const user2 = new User("lee", 15);

console.log(user1, user2);
user1.sayName();
user2.sayName();
```

### 객채 복제
- 참조변수의 복사는 객체 복사가 아니다.

```js
function User(name, age){
    this.name = name;
    this.age = age;
}

let user = new User("kim", 12);

let copyRef = user;
copyRef.age = 15;

console.log(user)
console.log(copyRef)

```
- 실제 데이타를 복제하려면 Object.assign 을 사용한다.
- 필드값을 넣을 수 있다.

```js

function User(name, age){
    this.name = name;
    this.age = age;
}

let user = new User("kim", 12);

let cloneUser = Object.assign({}, user);
cloneUser.age = 15;

console.log(user)
console.log(cloneUser)


let cloneUser2 = Object.assign({birthday : '1999-01-01'}, user);
cloneUser2.age = 15;

console.log(user)
console.log(cloneUser2)

```

### 객체 합치기
- 첫 번째 매개변수로 다른 객체의 프로퍼티스가 붙는다.

```js
const user = {
    name : 'Mike'
}

const info1 = {
    age : 12
}

const info2 = {
    birthday : '1999-01-01'
}

Object.assign(user, info1, info2)
console.log(user)

```

### 객체의 keys 와 values 추출
- keys와 values를 추출한다.
- entries는 key와 value를 배열로 반환한다.

```js
function User(name, age){
    this.name = name;
    this.age = age;
}

const user = new User('Kim', 12);

const keys = Object.keys(user);
console.log(keys)

const values = Object.values(user);
console.log(values)

const entries = Object.entries(user);
console.log(entries)
```

```js
const user = {
    name : 'kim',
    age : 12,
}

const entries =  Object.entries(user);
console.log(entries)
// 리스트 형태로 변경
// [["name", "kim"], ["age", 12]]

const fromEntries =  Object.fromEntries(entries);
console.log(fromEntries)
// 리스트를 객체로 변경
// [object Object] {
//   age: 12,
//   name: "kim"
// }

```