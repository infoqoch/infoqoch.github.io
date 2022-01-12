---
layout: post
author: infoqoch
title: js 의 dom의 기초 활용
categories: [js]
tags: [js]
---

## dom의 활용
- html을 객체화 한 document를 우리는 어떻게 출력하고 조작할까?
- document의 태그 객체는 event를 가진다. event란 누르거나(onclick), 변경되는(onchange) 등 다양한 클라이언트의 조작을 의미한다.
- 아래의 코드는 어떤 태그를 클라이언트가 클릭(onclick)할 때, prompt 로 값을 입력하고, alert으로 그 값을 출력하는 코드이다.
- 여담으로, alert과 prompt는 그것의 동작이 종료되기 전까지 그 아래의 스크립트를 읽지 않는 특징을 가진다.
  
## html 의 특정 태그에 js 코드 넣기

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <input type="button" value="클릭" onclick="var value = prompt('숫자를 입력하세요'); alert(value+'를 입력했군요!')">
</body>
</html>
```

## html 태그와 js 스크립트 블럭의 분리 

- 한편 위의 코드는 자바스크립트와 html 코드가 엉켜 있는 형태이다. 이를 좀 더 분리하면 다음과 같은 코드 가능하다.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <input type="button" value="클릭" id="click-me">
    <script>
        function printPromptValue(){
            var value = prompt('숫자를 입력하세요'); 
            alert(value+'를 입력했군요!')
        }
        var clickMe = document.querySelector('#click-me');
        clickMe.onclick = printPromptValue;
    </script>
</body>
</html>
```

## window의 onload 이벤트와 js 동작을 미루기

- 보통 스크립트 태그는 head 에 둔다. 스크립트 태그 블럭을 head 태그에 넣으면 어떻게 될까?
    
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <script>
        function printPromptValue(){
            var value = prompt('숫자를 입력하세요'); 
            alert(value+'를 입력했군요!')
        }
        var clickMe = document.querySelector('#click-me');
        clickMe.onclick = printPromptValue;
    </script>
</head>
<body>
    <input type="button" value="클릭" id="click-me">
</body>
</html>
```
- 동작하지 않는다. `Uncaught TypeError: Cannot set properties of null (setting 'onclick')` 에러가 발생한다. 왜냐하면 `click-me` 란 객체가 생성되기 전에 스크립트가 해당 객체를 호출했기 때문이다. 
- 이를 방지하기 위해서는 특정 js 코드가 html이 모두 로딩 된 후 동작함을 보장해야 한다. 이 때 window의 프로퍼티 onload 를 활용한다.
- 아래의 코드는 window 의 onload 를 init 함수로 변환하고, 그것이 호출 될 때(html 로딩이 끝날 때) 해당 함수를 수행하라는 의미이다.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <script>
        function init (){
            function printPromptValue(){
                var value = prompt('숫자를 입력하세요'); 
                alert(value+'를 입력했군요!')
            }
            var clickMe = document.querySelector('#click-me');
            clickMe.onclick = printPromptValue;
        }
        window.onload = init;
    </script>
</head>
<body>
    <input type="button" value="클릭" id="click-me">
</body>
</html>
```

- 한편, 위의 코드에서 중복되는 표현들이 있다. 함수표현식이 아닌 익명함수를 통해 코드를 단순하게 정리하자.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <script>
        window.onload = function (){
            document.querySelector('#click-me').onclick = function (){
                var value = prompt('숫자를 입력하세요'); 
                alert(value+'를 입력했군요!')
            }
        }            
    </script>
</head>
<body>
    <input type="button" value="클릭" id="click-me">
</body>
</html>
```

## 다수의 이벤트를 읽는다.
- 만약 onload 에 대입하는 함수가 여러개면 어떨까? 이 경우 onload 가장 마지막에 정의된 함수가 수행된다.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <script>
        window.onload = function (){
            document.querySelector('#click-me').onclick = function (){
                var value = prompt('숫자를 입력하세요'); 
                alert(value+'를 입력했군요!')
            }
        }                    
        window.onload = function (){
            console.log('hi!');
        }            
    </script>
</head>
<body>
    <input type="button" value="클릭" id="click-me">
</body>
</html>
```
- 이때는 addEventListener를 통해 문제를 해소할 수 있다.
- "load" 혹은 "DOMContentLoaded" 둘 중 하나를 사용 가능하다. 전자는 모든 소스가 로딩된 이후를 의미하여 후자는 DOM 트리 생성 직후를 의미한다. 

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <script>
        window.addEventListener("load", function(){
            document.querySelector('#click-me').onclick = function (){
                var value = prompt('숫자를 입력하세요'); 
                alert(value+'를 입력했군요!')
            }
        })                    
        window.addEventListener("load", function(){
            console.log('hi!');
        })                    
    </script>
</head>
<body>
    <input type="button" value="클릭" id="click-me">
</body>
</html>
```
