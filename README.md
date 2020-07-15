# RFAPI

<!-- markdownlint-disable MD033 inline html -->

[![Build Status](https://img.shields.io/travis/RFUI/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://travis-ci.com/RFUI/RFAPI)
[![Codecov](https://img.shields.io/codecov/c/github/RFUI/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://codecov.io/gh/RFUI/RFAPI)
[![CocoaPods](https://img.shields.io/cocoapods/v/RFAPI.svg?style=flat-square&colorA=333333&colorB=6600cc)](https://cocoapods.org/pods/RFAPI)

<base href="//github.com/RFUI/RFAPI/blob/develop/" />

<small>*English* [简体中文 :cn:](README~zh-hans.md)</small>

RFAPI is a full-featured URL session wrapper designed for API requests. It's easy to use and powerfull.

[RFAPI v2 Migration Guide](Documents/migration_guide_v2.md). The `v1` branch contains RFAPI v1 for legacy use, which requires AFNetworking v2.

## CocoaPods Install

```ruby
pod 'RFAPI'
```

Specify develop branch to install the lastest version:

```ruby
pod 'RFAPI',
    :git => 'https://github.com/RFUI/RFAPI.git',
    :branch => 'develop'
```

## Usage

### Basic concept

Before introducing how to use RFAPI, it is necessary to introduce some concepts.

* RFAPIDefine

    Unlike most network libraries, you cannot make a request with a url object. Instead, RFAPI uses API define objects to describe not only how to make requests, but also how to handle responses.

    It is recommended to load define objects from a configuration file.

* RFAPIRequestConext

    Beside APIDefine, you pass all kinds of other objects througn a request context object when making requests.

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
