# ZFPlayer

## 与[原始版本](https://github.com/renzifeng/ZFPlayer)的区别

> 经过
>
> TL;DR
> 
> 2016 年初的时候，当时的项目需要加视频的功能，我就在 GitHub 上找 AVPlayer 的壳，调研一番选的 ZFPlayer。当时 ZFPlayer 刚出不到一个月，0.0.5 版本，实现上有点问题但好说，改改能用。
>
> 但我认为 renzifeng 的实现在设计上走错了。在提了几个实现问题的 PR 后，我决定在自己的分支上重写。
>
> 作为一个通用组件，什么应该由组件提供、什么应该写在 demo 里、什么需要用户来实现，renzifeng 当时没有想明白。比如全屏功能，player 是 view 级别的组件，让它管理自己内部的布局可以，而自身的 frame、导航栏显隐之类的是 view controller 的职责。每个 app 的 UI 都是定制的，是否显示导航、是否有底栏、是否需要额外的空间、甚至是不是需要全屏模式……很多都不一样，作为一个 view 你不可能把所有的这些变化都考虑进来，组件做好组件该做的事，该由 app 来实现的交给 app 来做。
>
> 像全屏模式、列表模式，提供一个 demo 给用户一个参考是很好的，写进组件就越俎代庖了，走歪了——控件自己容易出 bug 不说，要在 app 里加正确的处理还得看控件里怎么写得，去做适配……一直走到现在发展成什么样子，看 issues 里一堆抱怨就知道了。

特性：

* 合理的 AVPlayer 封装，简单、纯粹，没有杂七杂八的功能；
* UI 与播放控制分离；
* 一对多的状态通知，便于 view、view controller 可以分别监听控制；
* 经过千万级产品的考验，在多个项目集成，功能稳定，设计已达到预期。

**不会**提供：

* 列表模式
* 边播边放
* 下载

## 通过 CocoaPods 安装

```ruby
pod 'ZFPlayer', :git => 'https://github.com/BB9z/ZFPlayer.git'
```

UI 部分并没有包含，你可以拷贝 demo 中的资源并修改以符合自己的项目要求，同时你可能需要重载 Control view 或自己写播放器的 UI。

如需全屏模式请参考 demo 中的 view controller，恰当的处理应当 view controller 来负责。
