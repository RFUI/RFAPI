# RFAPI

<!-- markdownlint-disable MD033 inline html -->

[![Build Status](https://img.shields.io/travis/RFUI/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://travis-ci.com/RFUI/RFAPI)
[![Codecov](https://img.shields.io/codecov/c/github/RFUI/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://codecov.io/gh/RFUI/RFAPI)
[![CocoaPods](https://img.shields.io/cocoapods/v/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://cocoapods.org/pods/RFAPI)

<base href="//github.com/RFUI/RFAPI/blob/develop/" />

<small>[English :us:](README.md) *简体中文*</small>

RFAPI 是一个专为 API 请求而设计的网络请求库。

[v2 迁移指南](Documents/migration_guide_v2.md)。RFAPI v1 需要 AFNetworking v2 版本，仍可在 `v1` 分支获取。

## 特色

* 漂亮的请求方法，比链式调用可读性更好，易于扩展；
* 通过规则创建请求和处理响应，不再需要在代码中拼接 URL，不再需要手动解析 model、并额外的错误处理逻辑；
* 通过具体和分类两种字符串标识符获取、取消请求，这样在不同的上下文环境中无需传递请求对象即可控制请求；
* Model 自动解析支持不同的库，


## CocoaPods Install

```ruby
pod 'RFAPI'
```

使用最新版本请指定 develop 分支：

```ruby
pod 'RFAPI',
    :git => 'https://github.com/RFUI/RFAPI.git',
    :branch => 'develop'
```

## 使用

### 基本概念

在正式介绍 RFAPI 使用前，有必要先了解几个概念。

* RFAPIDefine

    和多数网络库不同，你不可以直接用一个 URL 对象发起请求。RFAPI 中，你需要创建 define 对象来描述如何发起请求并处理响应。

    推荐从配置文件载入 define 规则。

* RFAPIRequestConext

    创建请求时除了 define 对象，通过 context 对象传递所有其他参数。

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
