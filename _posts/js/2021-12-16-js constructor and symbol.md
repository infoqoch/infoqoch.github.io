---
layout: post
author: infoqoch
title: js 생성자를 통한 객체 생성과 조작, 심볼릭
last_modified_at: 
categories: [js]
tags: [js]
---

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
console.lob(entries) // 에러

```

- entries 에서 에러가 발생한다.
- this를 window로 받아드린다. 이 부분은 차후 학습이 필요해 보인다.

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

## 심볼 Symbol
- 심볼은 유일한 식별자임을 보장한다.
- 심볼을 선언하고 그 값을 특정 객체의 변수나 메서드로 주입 가능하다.
- 심볼은 keys 나 values 등을 추출하는 메서드를 통해 검출되지 않는다. 그러므로 기존에 존재하는 객체를 유지하며 원하는 값이나 기능을 넣을 수 있다. 
- 특히, 객체는 생성 이후 프로퍼티를 넣을 수 있지만, 메서드는 넣을 수 없다. 심볼에 메서드를 대입하고, 그 값을 객체에 주입할 수 있다. 그러므로 기존의 코드를 수정하기 어렵거나 혹은 외부 라이브러리로 사용하며, 메서드의 추가가 필요한 경우, 효과적으로 사용할 수 있다. 

```js
function User(name, age){
    this.name = name;
    this.age = age;
}

const user = new User('Kim', 12);

// 메서드를 주입할 수 없다. 
// user.hello() = function(){
//   console.log("hi");
// }

const hello = Symbol('method to greet');
user.hello = function(){
    console.log("hi");
}

user.hello();
```