---
layout: post
author: infoqoch
title: js 유용한 매서드나 라이브러리
categories: [js]
tags: [js]
---

## 들어가며
- js 에는 다양한 매서드나 라이브러리를 지원하며 그 기능은 자바스프링과 달리 매우 간편하고 쉽게 구현 가능하다. 
- 특히 화살표, 스트림 등 함수형 기능이 매우 다양해서 자바 8을 사용하는 것만 같았다. 무척 편하고 빨랐다. 왜 생산성이 좋다는지를 이번 내용을 공부하며 알 수 있었다. 
- 뭔가 특별해 보이는 매서드를 위주로 정리했다(ㅎㅎ..)

## 수학
### toFixed()
- 소숫점을 구한다.
- 결괏값을 string 으로 반환한다.

```js
const v = 123.456;
console.log(v);

const under2point =  v.toFixed(2);
console.log(under2point);
console.log(typeof under2point); // "string"
console.log(typeof Number(under2point)); // "number"
```

## 문자열
### 문자열 추출
- 문자열 추출은 slice, substring, substr 등 유사한 이름으로 다양하다. 이를 정리했다.
  
```js
const s = "안녕하세요? 반가워요.";

const sliced = s.slice(2,8); // 2~8까지 추출한다.
console.log(sliced);

const subString =  s.substring(8,2);// 2~8까지 추출한다.
console.log(subString);

const substr = s.substr(2,8);
console.log(substr); // 2부터 8개를 추출한다.
```

## 배열
### concat
- 배열을 합친다.
- 이전에 내 기억으로 배열을 합칠 때 리스트와 리스트를 합치면 각각의 값이 하나의 리스트로 합쳐지지 않고 리스트 간 합쳐지는 것으로 기억한다. 그러나 이 매서드를 쓰면 그렇지 않다. 무척 유용할 것 같다. 

```js
let arr = ['a','b'];
arr = arr.concat(['c','d']);
arr = arr.concat([1,2,3],4,[5,6,7]);

console.log(arr); // ["a", "b", "c", "d", 1, 2, 3, 4, 5, 6, 7]
```

### splice
- 배열을 조작한다. 
- 인자가 하나일 경우 해당 인덱스 이후를 삭제한다.
- 인자가 두 개일 경우 첫 번째 인자를 인덱스로 하여 두 번째 인덱스를 갯수로 하여 삭제한다. 
- 인자가 세 개 일 경우 인자가 두 개일 경우를 수행한 후 그 위치에 세 번째 인자의 값을 삽입한다. 
  - 두 번째 인자가 0일 경우 삭제하지 않고 추가만 한다. 

```js
let list = ["hello", "world", "hi"]; // ["hello", "world", "hi"]

list.splice(1,1); // ["hello", "hi"]

list.splice(1,0,"good"); // ["hello", "good", "hi"]

list.splice(2); // ["hello", "good"]
```

### forEach
- 대부분 카멜케이스 없이 언더스코어로 매서드를 하던데, 이것은 카멜로 꼭 써야 한다. 그렇지 않으면 에러를 만든다.
- 매개변수는 순서대로 각각 값, 순서, 본체 이다.

```js
let ids = ['KIM', 'GOODGUY', 'HAPPY'];

ids.forEach((item, idx, arr)=>{
   console.log(`[${idx}]${item} out of ${arr}`)
});
```

### find
-  특정 조건에 맞는 값을 찾는다.

```js
let ids = ['KIM', 'GOODGUY', 'HAPPY'];

const returnTrue = ids.find((item) => {return item == 'KIM'});
console.log(returnTrue); // "KIM"

const returnFalse = ids.find((item) => {return item == 'kim'});
console.log(returnFalse); // undefined
```

### findIndex
- 특정 조건에 맞는 값의 배열 내 순서를 추출한다.

```js
let users = [
  {id:'kim', pwd:'1234'},
  {id:'lee', pwd:'password'},
  {id:'choi', pwd:'111111111111111'},
  {id:'kai', pwd:'a!3Cb'},
]

const idxOfLongPwdUser = users.findIndex((user)=>{
  if(user.pwd.length>10){
    return true;
  }
  return false;
})

console.log(users[idxOfLongPwdUser]) // choi // 없으면 undefined
```

### filter
- 특정 조건에 맞는 값의 리스트를 추출한다.

```js
let users = [
  {id:'kim', pwd:'1234'},
  {id:'lee', pwd:'password'},
  {id:'choi', pwd:'111111111111111'},
  {id:'kai', pwd:'a!3Cb'},
]

const notOnlyNumberPwd = users.filter(
  (user)=> {return isNaN(user.pwd)}
)

console.log(notOnlyNumberPwd) // lee, kai
```

### map
- 배열을 하나씩 탐색하여 다른 특정 객체로 반환하여 리스트를 생성한다.

```js
let users = [
  {id:'kim', pwd:'1234'},
  {id:'lee', pwd:'password'},
  {id:'choi', pwd:'111111111111111'},
  {id:'kai', pwd:'a!3Cb'},
]

const invalidUsers =  users.map(
  (user, idx)=>{
    return Object.assign({}, user, {
      isPass : (user.pwd.length>8)
    })
  });

console.log(invalidUsers)
```

### sort()
- 정렬한다.
  
```js
let users = [
  {id:'kim', pwd:'1234'},
  {id:'lee', pwd:'password'},
  {id:'choi', pwd:'111111111111111'},
  {id:'kai', pwd:'a!3Cb'},
]

const sortByPwdLength = users.sort((a,b)=>{
  return a.pwd.length - b.pwd.length;
});

console.log(sortByPwdLength)
```

### reduce()
- 배열을 조작하여 하나의 값으로 출력한다.
- 해당 값은 원하는 데이타타입으로 설정 가능하다.

#### 숫자

```js
let users = [
  {id:'kim', pwd:'1234'},
  {id:'lee', pwd:'password'},
  {id:'choi', pwd:'111111111111111'},
  {id:'kai', pwd:'a!3Cb'},
]


const lengthOfPwds = users.reduce((prev, cur)=>{
  return prev += cur.pwd.length;
}, 0)

console.log(lengthOfPwds);
```

#### 배열

```js
let users = [
  {id:'kim', pwd:'1234'},
  {id:'lee', pwd:'password'},
  {id:'choi', pwd:'111111111111111'},
  {id:'kai', pwd:'a!3Cb'},
]

const availableIds = users.reduce((prev, cur, users) => {
  const duplicatedIdIdx = prev.findIndex((item)=>{
    return item.includes(cur.id);
  });
  if(duplicatedIdIdx===-1){
      return prev;
  }
  prev.splice(duplicatedIdIdx, 1);
  return prev;
}, ['kim','jung','back','choi','kang'])

console.log(availableIds);
```

### 기타
- `Array.isArray(arrr)` 배열인지를 판별
- `const arr = str.split('_')` _ 으로 값을 나눠 배열 생성
- `const str = arr.join('_')` 배열의 각 값마다 _으로 구분하여 문자열 생성

