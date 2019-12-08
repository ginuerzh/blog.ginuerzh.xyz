+++
date = "2019-12-08T15:28:00+08:00"
tags = ["taste"]
title = "Chromebook + Raspberry Pi = Oh shit ...... 真香!"
subtitle = ""
url = "/taste/chromebook"
+++

很多年前就想买一台chromebook玩玩，今年终于入手了，一台Samsung Chromebook Plus V2。

如今的ChromeOS已经提供了(几乎)完整的Linux环境，所以作为开发机应该不是问题。
先尝试着装一下vscode，但是使用体验很捉急，整个界面字体小的可怜，也没找到调整的地方，遂放弃。
还好目前有一个叫[code-server](https://github.com/cdr/code-server)的项目可以把vscode当作服务端来运行，这样就可以直接在浏览器中使用了，这很符合ChromeOS的原则。一开始用的还是蛮顺手的，但是慢慢就出现问题了。这玩意的内存占用是真高，我的chromebook内存只有4G，最后卡的不行，只能重启，完全可以定性为内存泄露了。

最后思来想去，决定还是把VIM扒出来搏一搏。以前虽然也用，但只是用来简单的编辑文本，作为主力开发还真没尝试过。既然决定要用，就再系统的学习一下吧。这里推荐[Mastering Vim](https://www.amazon.com/Mastering-Vim-software-development-environment-ebook/dp/B07HHD55H2)这本书，比较新，也比较适合快速实战上手。

自此编辑器的问题解决了，但还有一个棘手的问题 - docker，目前貌似还不支持。

买Raspberry Pi的初衷是想搭建个k8s的开发环境，顺便也可以当作chromebook的辅助机。今年刚好出4代了，内存也大幅度提升，于是就买了一个4G版。目前它所承担的职责有：BT下载(Deluge)，DLNA多媒体服务器(minidlna)，Docker环境，代理服务器，私有云存储服务(Syncthing)。其他用处以后再慢慢探索。

你可能很好奇，不是说用来搭k8s吗？
起初，确实把k8s(其实是[k3s](https://k3s.io/))搭起来了，也用了一段时间，但后面就遇到麻烦了。由于raspberry pi是arm架构，但现在很多应用没有提供相应的docker image，虽然有些是可以自己去构建的，但有些天生不支持就没有办法了。

后来的解决办法是，又在网上淘了两块z3735f的板子，2G内存，性能虽然不高，但装个ubuntu+k3s还是绰绰有余的。这种板子有点特殊，虽然是64位处理器，但BIOS是32位的，所以原始的ubuntu ISO image是无法直接安装的，需要做些修改，具体就是利用[isorespin.sh](http://www.linuxium.com.au/how-tos/creatingpersonalizedubuntumintanddebianisosforintelminipcs)这个工具把原始镜像中的64位EFI文件替换成32位，然后就可以正常启动安装了，但最后安装grub时还是会失败，可以参考[这篇文章](https://medium.com/@realzedgoat/a-sorta-beginners-guide-to-installing-ubuntu-linux-on-32-bit-uefi-machines-d39b1d1961ec)来解决。我装的是ubuntu 18.04 desktop，server版没有测试过。

Chromebook的生产力当然不能跟Macbook/PC这种主流比，但由于其功能简单，配置较低，在某种程度上减少了很多干扰，可以让你安心做事情。更重要的是给你一次探索发现的机会。