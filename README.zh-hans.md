# RFAPI

<!-- markdownlint-disable MD033 inline html -->

[![Build Status](https://img.shields.io/travis/RFUI/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://travis-ci.com/RFUI/RFAPI)
[![Codecov](https://img.shields.io/codecov/c/github/RFUI/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://codecov.io/gh/RFUI/RFAPI)
[![CocoaPods](https://img.shields.io/cocoapods/v/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://cocoapods.org/pods/RFAPI)

<base href="//github.com/RFUI/RFAPI/blob/develop/" />

<small>[English :us:](README.md) *简体中文*</small>

RFAPI 是一个专为 API 请求而设计的网络请求库。它是基于 AFNetworking 的 URL session 封装。

[v2 迁移指南](Documents/migration_guide_v2.md)。RFAPI v1 需要 AFNetworking v2 版本，仍可在 `v1` 分支获取。

## 特色

* 通过规则创建请求和处理响应，不再需要在代码中拼接 URL，不再需要手动解析 model、添加额外的错误处理逻辑；
* 请求进程可与加载进度、UI 控件状态绑定；
* 漂亮的请求方法，比链式调用可读性更好，易于扩展；
* 通过具体和分类两种字符串标识符获取、取消请求，这样在不同的上下文环境中无需传递请求对象即可控制请求；
* Model 自动解析支持不同的库；
* 多种请求完成回调，方便各种使用场景，集中错误处理，自动错误处理。

## 劣势

RFAPI 最大的问题是太老了。v1 设计和 95% 的实现是在 2014 年完成的，之后有点小修小补谈不上变化，用了多年。虽然好的设计并不过时，但是相关技术栈都更新了。假如还是用 NSOperation 管理请求，没有 URL session，没有 Swift，没有 Codable，它是不过时。

2019 年末开始着手 v2 的升级，首要目标是支持 AFNetworking v3，在尽量维持与旧版的兼容的前提下，顺带实现一下新的接口设计，改进 Swift 下的使用体验。无法彻底革新意味着：

* 主类专为重载的接口在 Swift 下很难用，它们是专为 Objective-C 设计的，Objective-C 下灵活的设计转到 Swfit 里变得很奇怪；
* 不支持 Codable，Swift 专有特性支持起来麻烦；
* URL session 特性目前利用不充分，目前仅实现了数据任务，下载、上传任务还未支持；
* 下载特性未来如果支持也是有限的，选下载器请看其他库。

未来对 Alamofire 进行封装会开另一个项目，这个库不会用 Swift 重写。

## 使用

### CocoaPods 集成

因为依赖较多，只支持通过 CocoaPods 集成，SPM、Carthage 无支持计划。

```ruby
pod 'RFAPI'
```

使用最新版本请指定 develop 分支：

```ruby
pod 'RFAPI',
    :git => 'https://github.com/RFUI/RFAPI.git',
    :branch => 'develop'
```

### 定义接口

和多数网络库不同，你不可以直接用 URL 发起请求，需要先创建 define 对象来描述如何发起请求并处理响应。

```swift
let define = RFAPIDefine()
define.name = RFAPIName(rawValue: "TopicListRecommended")
define.path = "https://exapmle.com/api/v2/topics/recommended"
define.method = "GET"
define.needsAuthorization = true
define.responseExpectType = .objects
define.responseClass = "TopicEntity"
```

通常应当设置一个默认的规则，这样定义其他规则时只需要写与默认规则不同的。设置默认规则示例：

```swift
let api = ... // RFAPI 实例
let defaultDefine = RFAPIDefine()
defaultDefine.baseURL = URL(string: "https://exapmle.com/")
defaultDefine.pathPrefix = "api/v2/"
defaultDefine.method = "GET"
defaultDefine.needsAuthorization = true
api.defineManager.defaultDefine = defaultDefine
```

有了默认规则后，上面的接口定义可以简化为：

```swift
let define = RFAPIDefine()
define.name = RFAPIName(rawValue: "TopicListRecommended")
define.path = "topics/recommended"
define.responseExpectType = .objects
define.responseClass = "TopicEntity"
```

更推荐的方式是从配置文件中加载规则，你可以从本地文件中载入规则（如 json、plist），甚至可以从服务器获取配置。示例：

```json
{
  "DEFAULT": {
    "Base": "https://exapmle.com/",
    "Path Prefix": "api/v2/",
    "Method": "GET",
    "Authorization": true
  },
  "TopicListRecommended": {
    "Path": "topics/recommended",
    "Response Type": 3,
    "Response Class": "TopicEntity"
  },
  "UserLogin": {
    "Method": "POST",
    "Path": "user/login",
    "Authorization": false,
    "Response Type": 2,
    "Response Class": "LoginResponseEntity"
  },
  ...
}
```

文件配置应是 `[String : [String : Any]]` 类型的字典，key 是接口名，`DEFAULT` 是默认规则。有了配置文件，可以载入到 define manager 中，之后就可以通过接口名直接发起请求了，示例：

```swift
let rules = ... // 载入的配置
let api = ...   // RFAPI 实例
defineManager.setDefinesWithRulesInfo(rules)
```

默认请求和响应的内容格式都是 JSON 的，如果需要全局修改可以调整 define manager 的 `defaultRequestSerializer` 和 `defaultResponseSerializer` 属性；如需调整个别接口，可以在接口定义中指定 serializer 的类型。示例：

```json
{
  "FormUpload": {
    "Method": "POST",
    "Path": "commom/formupload",
    "Serializer": "AFHTTPRequestSerializer",
    "Response Serializer": "AFPropertyListResponseSerializer",
    "Response Type": 1
  }
}
```

其他配置文件的例子：[演示项目的配置](https://github.com/RFUI/RFAPI/blob/develop/Example/iOS-Swift/TestAPIDefine.plist)，[iOS Project Template/APIDefine.plist](https://github.com/BB9z/iOS-Project-Template/blob/master/App/Networking/APIDefine.plist)

### 创建请求

发起请求时可以直接传 define 对象；如果规则已在 define manager 中定义，可以直接传接口名。通过 context 对象传递所有其他参数。

```swift
let api = ... // RFAPI 实例
api.request(name: "TopicListRecommended") { c in
    c.parameters = ["page": 1, "page_size": 20]
    c.loadMessage = "列表加载中"
    c.success { _, rsp in
        guard let topics = rsp as? [TopicEntity] else { fatalError() }
        ...
    }
}
```

更多用法见 [Cookbook](Documents/Cookbook.md)

### 特殊设定

* 取消不当做错误进行处理

    请求被取消时，错误回调不会被调用；错误回调也不会有 `NSURLErrorCancelled` 错误。

    但是在 finished 和 complation 回调中你可通过 RFAPITask 对象获取 `NSURLErrorCancelled` 错误。

* 多数参数是作为可变量传递的

    除了与 define 相关的属性，大部分通过 context 传递的参数都不会被额外拷贝。传递可变数组、字典、字符串等可变量并在请求创建后进行修改是你的自由，RFAPI 允许你这么做并认为你知道自己在做什么。

### 国际化

RFAPI 支持内部信息的国际化，你需要把本地化 strings 放在主 bundle 默认的 table 中。

示例：

* [en](Example/iOS-Swift/en.lproj/Localizable.strings)
* [zh-Hans](Example/iOS-Swift/zh-Hans.lproj/Localizable.strings)
