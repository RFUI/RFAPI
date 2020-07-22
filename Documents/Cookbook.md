# RFAPI Cookbook

## URL 拼接

RFAPIDefine.path 如果是带 scheme 的完整 URL，将直接用这个 URL；否则会先与 pathPrefix 直接进行字符串拼接，并相对 baseURL 生成最终 URL。

baseURL 会依次从当前规则、默认规则、RFAPI 属性中取。baseURL host 后面如果有其他 path，应以「/」结尾，如 `http://example.com/base` 实际相当于 `http://example.com`，正确的应是 `http://example.com/base/`。

RFAPIDefine.path 支持用花括号定义参数，如 `user/{user_id}/profile`，传参时带入 `user_id: 123`，则最终 URL 会变成 `user/123/profile`。

## 传参

请求的参数通过 context 的 `parameters` 属性传入：

```swift
api.request(name: "some api") { c in
    c.parameters = ["foo": "bar", "number": 456, "bool": true]
}
```

如果整个参数是数组，通过 `RFAPIRequestArrayParameterKey` 传入：

```swift
api.request(name: "some api") { c in
    c.parameters = [RFAPIRequestArrayParameterKey: [1, 2, 3]]
}
```

如果 HTTP body 是 `multipart/form-data` 格式的，可通过 context 的 `formData` 构建数据。

```swift
api.request(name: "some api") { c in
    c.formData = { formData in
        try? formData.appendPart(withFileURL: fileUrl, name: "field1")
        formData.appendPart(withForm: someData, name: "field2")
    }
}
```

## Authentication

接口定义（RFAPIDefine） `needsAuthorization` 为 `true` 的接口会自动附加 `RFAPIDefineManager` 定义的 HTTP 头（authorizationHeader）和参数（authorizationParameters）。

设置方法为：

```swift
let api = ... // RFAPI instance
api.defineManager.authorizationHeader["Authorization"] = "Custom Credential"
api.defineManager.authorizationParameters["Custom Parameter"] = "Custom Value"
```

URLCredential 因接口未暴露暂不支持。

## 添加 HTTP header

在请求中附加 HTTP 头有多种方式：

* 如需集中式的处理，可通过重载 `RFAPI` 的 `preprocessingRequest(parametersRef:httpHeadersRef:parameters:define:context:)` 或 `finalizeSerializedRequest(_:define:context:)` 方法进行修改；
* 通过接口定义（RFAPIDefine）的 `HTTPRequestHeaders` 属性，如果接口定义中设置了该属性，会使用自己的（不会与默认定义合并），否则会使用默认定义（RFAPIDefineManager.defaultDefine）的；
* 通过 context 传入 `HTTPHeaders`，与其他方式设置的头进行合并，这种方式优先级最高，会覆盖接口定义和认证头。

## 错误处理

创建请求时可以通过 context 设置请求失败的回调（failure），除此之外，重载 `RFAPI` 的 `generalHandlerForError(_:define:task:failure:)` 方法可以集中处理错误。

[一个示例](https://github.com/BB9z/iOS-Project-Template/tree/4.1/App/Networking/API.swift#L63)：对系统错误进行包装，token 失效登出，创建请求时不定义错误处理默认报错。
