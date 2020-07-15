# RFAPI v2 升级指南

> *Because there should be no non-Chinese developers using this library before, this guide is not available in English.*

v1 到 v2 几乎全部重写，内部变化很大，但是实际项目需要调整的地方应该不多。

如果只是用到请求发送、取消这样的基本功能，甚至无需修改。

## 主要类型变化

`RFAPI` 的父类由 `NSOperationQueue` 变为 `NSObject`。如果之前用到了 NSOperationQueue 的方法，只能都移除了。`maxConcurrentOperationCount` 可以改用 NSURLSessionConfiguration 的 `HTTPMaximumConnectionsPerHost` 属性设置。

请求方法返回的请求对象类型从 `AFHTTPRequestOperation` 变为 `RFAPITask`，暴露的属性有减少。

`RFAPIControl` 被移除，取而代之的类是 `RFAPIRequestConext`，必须修改的地方并不多：

* `message` 属性更名为 `activityMessage`；
* 移除的属性都没用到，`RFAPIRequestConext` 新增的属性也无需修改；
* 不再支持从字典创建，这个正常用得极少。

缓存管理移除了，但这个系统只在 iOS 7 之前工作，正常的项目应该影响不到。

## Define 和 DefineManager

`RFAPIDefine` 的 `responseClass` 类型由 class 改为 string，其他在外部看来没有变化。

`RFAPIDefineManager` 现在直接使用 define 对象，不再使用字典作为存储。`defaultRule` 更名为 `defaultDefine`，修改立即生效，无需再手动调用 `setNeedsUpdateDefaultRule` 方法。之前对 define 字段进行修改的方法被移除，直接对 define 对象进行修改即可。`setDefinesWithRulesInfo:` 现在支持分组。

在 DEBUG 环境（准确的说是 RFDEBUG 为真且 NSAssert 启用）下编译的 RFAPI，在 define 处理时会进行一些额外检查，帮助你正确使用，Release 环境这些检查不会执行。

## 请求创建

v1 请求有两个方法，正常请求和表单上传请求，正常请求有兼容实现，可无需修改（但是推荐改成新的方法）。

表单上传只能用新的请求方法，不再需要 `RFHTTPRequestFormData`，直接设置 request context 的 formData 即可。

## responseProcessingQueue

变为 `processingQueue`，默认的队列由主线程队列变为私有的并行队列。

## Swift

如果之前在 Swift 中子类了 `RFAPI`，可能需要调整方法名，需要重写的方法有了更合适的命名。

## 国际化

v1 的错误信息是硬编码在代码中的，且是中文；现在可以在 app 中默认的 Localizable.strings 定义。 
