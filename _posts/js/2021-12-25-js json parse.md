---
layout: post
author: infoqoch
title: js - json parse
categories: [js]
tags: [js, json]
---

## JSON 이란?
- json 은 JavaScript Object Notation 의 줄임말로, 자바스크립트의 데이터 정의 방식을 의미한다. 
- JSON은 xml 보다 덜 복잡하고 csv 보다 좀 더 복잡한 내용을 구현하는 절충안으로 활용된다.
  
## js memory의 객체와 JSON 간 변환
- json - js 의 변환은 eval이나 JSON 으로 수행한다. 
- eval 은 json(혹은 js) 문법으로 구현된 문자열을 js 메모리에 로딩하는 매서드이다. 보통 eval 보다는 JSON.parse 나 JSON.sringify를 주로 사용한다. 
- 다만, 파싱과정에서 JSON의 값을 엄밀하게 검증한다. js의 객체를 생성할 때 키 값을 작성할 때 큰 따옴표가 없어도 되나, JSON 을 파싱할 때는 문자열의 경우 숫자를 제외한 키, 벨류에 대해서는 엄격하게 큰 따옴표로 감싸야 한다. 
- 여담으로, 키에 띄어쓰기가 있을 경우 js 인 메모리에서도 큰따옴표로 감싸야 한다. 그러니까,  `data['comming from']` 은 가능하지만 `data.coming from`은 불가능하다.

```js
const kim = {name:'kim', age:10};
console.log(kim.age)

const data = [
  {name:'kim', age:10},
  {name:'lee', age:50},
  {name:'choi', age:20}
];

console.log(data[1].age);


eval('var place = "korea";');
// eval('let place = "korea";'); // error
console.log(place);

const dataStr = "[{name:'kim', age:10},{name:'lee', age:50},{name:'choi', age:20}]"
const data2 = eval(dataStr)
console.log(data2[0].name)


const customer = {"coming from" : "china", name : kim};
console.log(customer["coming from"])
// console.log(customer.coming_from) // undefined
// console.log(customer."coming_from") // unexpected string

var data3 = [{name:'kim', age:10},{name:'lee', age:50},{name:'choi', age:20}]

// JSON.parse("[{name:'kim', age:10},{name:'lee', age:50},{name:'choi', age:20}]");  // error // data3 은 js 상에서 객체로 잘 전환된다. 그러나 그것을 문자열로 할 경우, 큰 따옴표로 분리가 되지 않아, 파싱이 정상 작동하지 않는다.
const json = JSON.stringify(data)
console.log(json) // "[{"name":"kim","age":10},{"name":"lee","age":50},{"name":"choi","age":20}]" //  json으로 변환할 때, 따옴표로 엄격하게 작성됨을 확인할 수 있다. 

const obj = JSON.parse(json);
console.log(obj[0].name)
```
