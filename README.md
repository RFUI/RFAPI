# RFAPI

<!-- markdownlint-disable MD033 inline html -->

[![Build Status](https://img.shields.io/travis/RFUI/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://travis-ci.com/RFUI/RFAPI)
[![Codecov](https://img.shields.io/codecov/c/github/RFUI/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://codecov.io/gh/RFUI/RFAPI)
[![CocoaPods](https://img.shields.io/cocoapods/v/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://cocoapods.org/pods/RFAPI)

<base href="//github.com/RFUI/RFAPI/blob/develop/" />

<small>*English* [简体中文 :cn:](README~zh-hans.md)</small>

RFAPI is a network request library specially designed for API requests. It is a URL session wrapper base on AFNetworking.

## Feature

* It uses rules to create requests and process responses instead of stitching URLs in code. No more decode models manually and add additional error handling logic.
* The request process can be bound to the loading progress and UI control status.
* Beautiful request method, more readable than chain call, easy to extend.
* Obtain and cancel requests through the specific and grouped identifiers. You can control a request without passing the request object in different code contexts.
* Automatic model decoding supports different libraries.
* Multiple request completion callbacks, convenient for various usage scenarios, centralized error handling, automatic error handling.

## Disadvantage

The biggest problem of RFAPI is being too old. In 2014, the design and 95% of the implementation of v1 were completed. After that, there are only few minor changes in many years. Although good design is not outdated, the related technology stack has been updated. If you still use NSOperation to manage requests, if there is no URL session, no Swift, no Codable, then it's not outdated.

I start to upgrade it to v2 at the end of 2019. The primary goal is to support AFNetworking v3. The premise is to maintain compatibility with the old version as much as possible. A new interface design has been implemented. The user experience in Swift has been improved. It cannot be completely renovated means:

* The interface of the main class for overloading is difficult to use in Swift. They are designed for Objective-C. The flexible design of Objective-C becomes strange when transferred into Swfit.
* Codable is not supported, it is troublesome to support a Swift proprietary feature.
* The URL session feature is currently not fully utilized. Currently, only data tasks are implemented. Download and upload tasks are not supported yet.
* The download feature is limited. Please check other libraries if you needs a downloader.

In the future, encapsulation of Alamofire will open another project. This library will not be rewritten in Swift.

## Usage

## CocoaPods Install

Only integration through CocoaPods is supported due to dependent factors. There is no support plan for SPM and Carthage.

```ruby
pod 'RFAPI'
```

Specify develop branch to install the lastest version:

```ruby
pod 'RFAPI',
    :git => 'https://github.com/RFUI/RFAPI.git',
    :branch => 'develop'
```

## Define an API

Unlike most network libraries, you cannot make a request with a url object. Instead, RFAPI uses API define objects to describe not only how to make requests, but also how to handle responses.

```swift
let define = RFAPIDefine()
define.name = RFAPIName(rawValue: "TopicListRecommended")
define.path = "https://exapmle.com/api/v2/topics/recommended"
define.method = "GET"
define.needsAuthorization = true
define.responseExpectType = .objects
define.responseClass = "TopicEntity"
```

Generally, a default define should be created. After that, you only need to provide different parts from the default define when creating other defines. Example of setting default rules:

```swift
let api = ... // RFAPI instance
let defaultDefine = RFAPIDefine()
defaultDefine.baseURL = URL(string: "https://exapmle.com/")
defaultDefine.pathPrefix = "api/v2/"
defaultDefine.method = "GET"
defaultDefine.needsAuthorization = true
api.defineManager.defaultDefine = defaultDefine
```

With the default define, the above API definition can be simplified to:

```swift
let define = RFAPIDefine()
define.name = RFAPIName(rawValue: "TopicListRecommended")
define.path = "topics/recommended"
define.responseExpectType = .objects
define.responseClass = "TopicEntity"
```

The more recommended way is to load the defines from the configuration file. You can load the defines from a local file (such as json, plist), or even get the configuration from the server. eg:

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

The file configuration should be a dictionary of type `[String: [String: Any]]`, key is the API name, and `DEFAULT` is for the default define. With a configuration file, it can be loaded into the define manager, and then the request can be make directly with the API name. eg:

```swift
let rules = ... // Configuration loaded
let api = ...   // RFAPI instance
defineManager.setDefinesWithRulesInfo(rules)
```

By default, the content format of request and response are both JSON. You can modify it globally by changing the `defaultRequestSerializer` and `defaultResponseSerializer` properties of the define manager. If you need to adjust an individual API, you can specify the serializer type in the API define. eg:

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

Other configuration file examples: [Demo Project Configuration](https://github.com/RFUI/RFAPI/blob/develop/Example/iOS-Swift/TestAPIDefine.plist)，[iOS Project Template/APIDefine.plist](https://github.com/BB9z/iOS-Project-Template/blob/master/App/Networking/APIDefine.plist)

### Making requests

You can directly pass the define object when making a request; if the define has been in the define manager, you can directly pass the API name. Pass all other parameters through the context object.

```swift
let api = ... // RFAPI instance
api.request(name: "TopicListRecommended") { c in
    c.parameters = ["page": 1, "page_size": 20]
    c.loadMessage = "List Loading"
    c.success { _, rsp in
        guard let topics = rsp as? [TopicEntity] else { fatalError() }
        ...
    }
}
```

For more usage, checkout [Cookbook](Documents/Cookbook.md)

### Differences from the general

* Cancellation is not considered as failure

    When a request is cancelled, the failure callback will not be called. Also a failure callback will never be called with an `NSURLErrorCancelled` error parameter.

    But you could get an `NSURLErrorCancelled` error from a RFAPITask object in the finished or complation callback.

* Most parameters are mutable

    Except for properties related to define, most of the parameters passed through the context will not be copied. It's your free to pass mutable array, dictionary, string or any others and change these value after the request has been made. RFAPI allows you to do that and thinks you know what you are doing.

### Localization

You can localize RFAPI built-in messages by putting localizable strings into the default table of the main bundle.

Samples:

* [en](Example/iOS-Swift/en.lproj/Localizable.strings)
* [zh-Hans](Example/iOS-Swift/zh-Hans.lproj/Localizable.strings)
