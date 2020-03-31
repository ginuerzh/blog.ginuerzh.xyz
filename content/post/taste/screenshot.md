+++
date = "2020-03-31T11:57:00+08:00"
tags = ["taste"]
title = "构建云原生在线网页截屏服务"
subtitle = ""
url = "/taste/screenshot"
+++

## 遗物

以前做项目的时候做过一个网页截屏功能，简单来说就是根据链接给出对应网页内容的截图。为什么需要这个功能呢？这要从需求细节说起。

在移动端一般可以通过手机自带的截屏功能来截取网页图片，但如果想让截图内容与实际网页内容差异化，这种方式就不可行了。例如我想截取一篇文章分享给朋友，但文章可能比较长，无法截取完整，需要在截图中显示内容概要而不是完整的内容，同时可以在每个截图里放上二维码，通过扫码可以看到具体的内容。此时一个在线网页截屏服务就很有必要了。

之前就想到，这其实是很通用的服务，只是最后做完了也就没有再去摆弄了，最近忽然想起来了，索性重新构建一下，算是总结吧。

## Headless Chrome

也是通过这个功能让我了解到Chrome的[headless](https://developers.google.com/web/updates/2017/04/headless-chrome)模式，及其所提供的开发工具，其中就包括截屏功能。所谓的headless，意思就是没有GUI，既可以把它当作命令行工具直接使用，也可以单独作为一个服务，通过API与其交互。

例如：

命令行模式：

```
chrome --headless --disable-gpu --screenshot https://www.google.com/
```

上面的命令直接可以截取google.com的页面保存为`screenshot.png`文件。

服务模式：

```
chrome --headless --disable-gpu --remote-debugging-port=9222
```

在服务模式下，可以通过9222端口与其通讯。

```
curl http://127.0.0.1:9222/json/version
```

会输出类似与下面的JSON信息

```
{
   "Browser": "HeadlessChrome/79.0.3945.130",
   "Protocol-Version": "1.3",
   "User-Agent": "Mozilla/5.0 (X11; Linux armv7l) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/79.0.3945.130 Safari/537.36",
   "V8-Version": "7.9.317.33",
   "WebKit-Version": "537.36 (@e22de67c28798d98833a7137c0e22876237fc40a)",
   "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/browser/94cf07a5-b271-49fc-b100-613ac0041e5b"
}
```
然后就可以通过`webSocketDebuggerUrl`中给的URL来做具体的事情了。

详细的API文档可以访问：[https://chromedevtools.github.io/devtools-protocol/](https://chromedevtools.github.io/devtools-protocol/)

Chrome提供的功能非常多，这里只使用到其截屏(Screenshot)和打印PDF(PrintToPDF)功能。

由于不需要GUI，完全可以把它放到容器里运行，这样就简化了很多，也方便后面的部署。

我根据[Zenika/alpine-chrome](https://github.com/Zenika/alpine-chrome)这个库的Dockerfile文件构建了一个[alpine-chrome](https://hub.docker.com/r/zenika/alpine-chrome/)镜像，主要是增加了字体库(font-noto, font-noto-cjk, font-noto-emoji)对中文和表情符的支持。

## chromedp

开发方面比较有名的是官方[Puppeteer](https://github.com/puppeteer/puppeteer) NodeJS库，但我主要用的是Go，还好Go也有相应的库[chromedp](https://github.com/chromedp/chromedp)。

至于两种模式的选择，由于是要做成服务，而不是工具，使用服务模式就很自然了。

当中遇到的两个值得注意的问题也在这里提一提：

> Websocket API

chrome在启动时会自动生成一个动态API地址类似于：

```
ws://127.0.0.1:9222/devtools/browser/94cf07a5-b271-49fc-b100-613ac0041e5b
```

后面的`94cf07a5-b271-49fc-b100-613ac0041e5b`部分是一个动态生成的GUID，目前也没有找到方法来手动指定。

好在chrome也提供了API来获取这个地址([issue#940](https://github.com/puppeteer/puppeteer/issues/940))，就是上面提到的`/json/version` API返回信息中的`webSocketDebuggerUrl`字段，这样就不需要提前知道这个地址了。

这个动态地址也会给部署带来问题，后面会提到。

> Host Header

还是接口问题，如果发送给chrome的请求中`Host`头部设置的不是localhost或IP的话，例如`http://chrome:9222/json/version`，chrome会报错：

```
Host header is specified and is not an IP address or localhost
```

也就是说，chrome要求Host要么不设，要么就必须是localhost或具体的IP。

根据[issue#505](https://github.com/chromedp/chromedp/issues/505)中提到的方法可以规避这个问题，具体做法就是把请求中的Host头设置为localhost，然后在返回的websocket链接中再把localhost替换成原本的地址(好在websocket接口没有这个限制)。

具体代码放在[ginuerzh/screenshot](https://github.com/ginuerzh/screenshot)。

## 部署

一切就绪，接下来就可以部署了，因为都做成了Docker镜像，所以直接用docker或docker-compose运行就可以了。

俗话说双拳难敌四手，一个不能动态扩容的服务不是一个好服务，但在扩容之前，还要解决一个问题。上面提到过，chrome给的websocket接口地址是动态的，如果简单的对chrome容器进行扩容，每个容器的地址都是不一样的，而`/json/version`和websocket请求是分开的两个请求，这样就不能保证你的请求发送给了对应的chrome实例。

这个时候k8s就发挥作用了，把screenshot服务与chrome放在同一个pod中，部署方式由M:N变成1:1，这样即不用暴露chrome服务，每个screenshot服务也不用考虑会连错chrome实例。

可以通过以下操作进行测试：

```
$ kubectl apply -f https://raw.githubusercontent.com/ginuerzh/screenshot/master/k8s.yaml
$ kubectl port-forward svc/screenshot --address 0.0.0.0 -n screenshot 8080:8080
```

然后在浏览器中打开

```
http://localhost:8080/screenshot?url=https://bing.com&mobile=1
```
就可以看到截取到的bing.com网页了。