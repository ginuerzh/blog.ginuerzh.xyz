+++
date = "2022-08-06T23:55:00+08:00"
tags = ["taste"]
title = "Google相册的私有云替代方案"
subtitle = ""
url = "/taste/photoprism"
+++

目前我所有的照片和视频都是存在Google相册中，十几年的积累，大概有个几万张，最近想把照片备份一下，虽然绝大多数可能没有多少价值，但如果丢失也是挺可惜的。后来一想，既然都导出来了，干脆直接自己托管一个类似于Google相册的系统，岂不美哉。

一个系统要想好用省心是需要考虑很多因素，各个组件要可靠可信，组件之间也要有很好的协调性。

### 硬件平台

早前入手了一块Raspberry Pi 4G板子，做为服务器放在角落里长期跑一些应用。还有一台2016年组装的PC，去年刚全面升级，AMD R5 3600，16GB，500GB M.2 SSD，外加一张古董级的RX560显卡(没错，我是AMD阵营的)，现在基本上处于吃灰状态，正好可以拿过来当主力工作负载。本来想再入手一台N5105的小主机，至少功耗小很多，但奈何PC的性能更强劲啊，不用也是浪费。

Pi上本来就一直跑着k3s，外接了一个4TB的HDD和一个1TB的SSD，现在把PC也接进来，Pi依然做为k3s的主节点，PC作为工作节点。Pi中之前所有跑的应用全部迁移到PC上，同时把两块硬盘也移到PC上来，这样SSD存储应用数据，HDD用来作为数据备份盘。

虽然我这里使用的是Kubernetes作为部署平台，但后面的内容基本上和平台没有多大关系，不管是直接部署还是通过Docker等其他手段部署，没有多大区别，这里主要详述手段和工具。

### 照片管理

对于一个私有相册系统，照片管理肯定是核心部件。就我个人来说，要求也不是很多，导入导出方便，最好是直接管理原始文件而不做过多改动，这样方便数据备份和平台更换，如果再智能一些就更好了。

在网上找了一圈，最后选择了[PhotoPrism](https://photoprism.app/)，号称基于TensorFlow的最接近于Google相册的照片管理工具，可以通过这个[Demo](https://demo-zh.photoprism.app/browse)自己感受一下。

官方只提供了Docker版本安装说明，如果想直接部署可能要稍微费点劲。

### 数据同步

PhotoPrism本身提供了WebDAV的方式来导入数据，本方案是私有云服务，假设整个系统处于内网环境中，而且对于大多数人来说也不太可能有公网IP(我就没有)，因此除了在局域网中可以通过WebDAV或其他方式来导数据，在其他地方就做不到了，这个限制太大了，如果不能实时同步，那还不如用回Google相册。

我的数据同步是使用[Syncthing](https://syncthing.net/)软件来实现的，去中心化的文件同步工具。同步策略如下:

在手机上通过Syncthing将相机文件夹以**仅发送**的方式同步给PC的Syncthing服务，PC上以**仅接受**的方式接收数据，再将数据存到SSD盘中的某个文件夹中。

我是采用Photoprism的[Import](https://docs.photoprism.app/user-guide/library/import/)方式导入数据。将上面的数据文件夹作为Photoprism的import目录，再运行一个定时任务，周期性的执行`photoprism copy`命令将数据由import目录同步到originals目录并进行索引(如果是通过WebDAV的方式，会自动触发Photoprism的导入操作，因此不用再单独跑定时任务)。这里之所以使用copy而不是move，是因为Syncthing在接收端删除数据后还会再将数据同步过去，因此这里数据由发送端来控制，当手机上的数据删除后，import文件夹的数据也会跟着清理掉。

### 数据备份

到目前为止数据只在SSD盘中保存一份，如果硬盘损毁，以上的工作也就没有意义了，所以数据备份也是必不可少的环节。这一部的方案就有很多了，因为数据是直接以文件的方式存在Photoprism的originals目录，因此直接备份这个目录就行了，另外还有数据库也要备份。

我目前采用的备份策略是[Rclone](https://rclone.org/)加[MinIO](https://min.io/)，Minio的数据放在HDD盘中，通过Rclone将数据copy到Minio中。

这里因为是k3s平台，因此直接通过CronJob来实现，首先运行一个初始化容器执行`photoprism -i - a -f`将数据库和albums导出来(默认存放在photoprism的storage文件夹中)，再运行两个rclone容器，执行`rclone copy`命令分别将originals和storage文件夹copy到Minio中。

之所以采用Minio是因为Photoprism计划以后可能会[支持备份到S3](https://docs.photoprism.app/getting-started/advanced/scalability/)。

### 外网访问

整个系统已经正常运转起来了，最后还要解决外网访问的问题，毕竟独乐乐不如众乐乐，只能在内网访问多无聊！如果你有公网IP可以略过。

这里采用的是Cloudflare提供的[Tunnel](https://www.cloudflare.com/zh-cn/products/tunnel/)服务，将内网服务暴露到外网再通过域名访问，所以这里的前提条件是要有一个自己的域名并托管在Cloudflare平台。这个方法的一个缺点是访问速度较慢，毕竟绕了一圈。

至此如果不出意外，整个系统可以完全自动化的运转起来了，基本不需要人工干预，虽然无法达到Google相册的体验效果，但数据在手，总归心里踏实一些，只能这样安慰一下自己了！




