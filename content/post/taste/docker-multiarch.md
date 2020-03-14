+++
date = "2020-03-14T14:33:00+08:00"
tags = ["taste"]
title = "自动化构建多平台Docker镜像"
subtitle = ""
url = "/taste/docker-multiarch"
+++

## 背景

这段时间一直在(被)折腾k8s和istio，为了搭建这个平台也是费尽心思，从硬件到软件全程的折腾。

首先是硬件的选择，为了能7X24小时不间断工作，且省点电费，台式机是指望不上了，噪音大，功耗高，不方便扩展。于是就将目标转向单片机，最终的方案是1片4GB的树莓派4B用作k8s master节点，外加2块2GB+32GB的z3735f工控nano主板作为worker节点，全部下来成本大概在1000RMB左右。

为什么不全部使用树莓派？一方面成本较高，4GB版本大概要400元左右，2GB版本也要200多，相较于一些微型x86板子要贵不少。这不是重点，重点在于ARM不是主流，像istio目前还不支持arm (envoy的锅)，所以x86的板子是必要的。

## 问题

硬件环节已经就绪，接下来就是软件了。如果只是简单的用一下的话，到这里就可以结束了，因为这个平台已经可以满足大部分的需求了。

但由于x86的两块板子内存比较小，性能也较差，其中一块还时不时的会死机，如果所有pods都跑在上面，岂不是白白浪费了树莓派？首先想到的是能不能把istio的部分组件给移到树莓派上，例如jaeger，prometheus，这些是用Go写的，应该问题不大。不过看了下jaeger的官方docker库中，并没有提供arm版，那就只能自己动手了。

## Docker build(x)

Docker官方是支持多平台构建的，一种是通过[Manifest List](https://docs.docker.com/registry/spec/manifest-v2-2/)来手动构建，另一种是通过新的[buildx](https://docs.docker.com/buildx/working-with-buildx/)。后一种方法其实也是利用了第一种方法，只不过把这个构建过程自动化了。

第一种方法比较的繁琐，后面应该会被buildx取代，这里就不做过多的介绍，感兴趣的可以参考[这篇blog](https://medium.com/@mauridb/docker-multi-architecture-images-365a44c26be6)和[官方文档](https://docs.docker.com/registry/spec/manifest-v2-2/)，这里主要说一下buildx方式的使用。

关键的流程(Linux)：

```
# 注意：buildx需要docker 19.03+版本。

# buildx现在还是实验功能，需要客户端开启。
$ export DOCKER_CLI_EXPERIMENTAL=enabled

# 查看buildx版本。
$ docker buildx version
github.com/docker/buildx v0.3.1-tp-docker 6db68d029599c6710a32aa7adcba8e5a344795a7

# buildx多平台构建依赖QEMU。
$ docker run --rm --privileged docker/binfmt:66f9012c56a8316f9244ffd7622d7c21c1f6f28d

# 创建并使用新的构建器，默认的构建器(default)不支持多平台构建。
$ docker buildx create --use --name multiarch

# buildx使用方式与build类似，通过platform参数指定需要的目标平台。
docker buildx build --platform=linux/arm,linux/arm64,linux/amd64 .
```
具体的使用细节可以参考官方的[blog](https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/)和[文档](https://docs.docker.com/buildx/working-with-buildx/)。

## Github Actions

有了构建的工具，下一步就是想办法简化这个流程，不能每次都去手动构建吧，一方面很麻烦，另一方面由于网络问题，会让整个构建流程慢如蜗牛。

Docker有自己的官方构建平台DockerHub，可以通过绑定github来实现自动化镜像构建，但目前还不支持多平台，话说ubuntu的snapcraft在这点要领先了。不过后面等buildx成熟了，应该会集成到DockerHub上，到时候就会很方便了。

DockerHub不行，只能另寻他法。后来在网上搜到了一个github action: [Docker Buildx](https://github.com/marketplace/actions/docker-buildx)是可以支持docker buildx的。Github Actions是github官方推出的CI/CD服务。
为了测试buildx功能，专门写了一个[demo](https://github.com/ginuerzh/docker-buildx-multiarch)用来自动构建各个分支和Tags，workerflow是参考[crazy-max/diun](https://github.com/crazy-max/diun/blob/master/.github/workflows/build.yml)项目修改的。

## 尾声

在使用过程中也遇到了一些小问题。buildx在构建过程中拉取镜像时似乎不会使用自定义Registry源，也不会使用代理，所以导致本地构建会卡在镜像拉取上。另外buildx不支持在非x86平台上构建，至少我在树莓派上没有成功(姿势不对?)。Github Actions的自动构建在buildx这一步会有失败的几率，重新构建一下就可以了。

到此一切似乎都行的通，后面就是去构建实际的项目了，这是后话了。

## 后记

最近终于把用了两三年的小米路由器给换掉了，可能是现在设备多了，较之前越来越不稳定了，动不动就给我断网。这个路由器自带DDNS功能，这样就可以通过DMZ和NAT端口映射再配合DDNS把这个k8s集群开放出去，在外面也能使用了。

## 参考文章

[Image Manifest V 2, Schema 2](https://docs.docker.com/registry/spec/manifest-v2-2/)

[Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)

[Docker Multi-Architecture Images](https://medium.com/@mauridb/docker-multi-architecture-images-365a44c26be6)

[Getting started with Docker for Arm on Linux](https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/)

[Using multi-arch Docker images to support apps on any architecture](https://mirailabs.io/blog/multiarch-docker-with-buildx/)

GitHub Action [Docker Buildx](https://github.com/marketplace/actions/docker-buildx)

[ginuerzh/docker-buildx-multiarch](https://github.com/ginuerzh/docker-buildx-multiarch)
