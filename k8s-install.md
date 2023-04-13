# k8s 安装调研
在初始化的linux服务器上安装k8s

| 特性-工具    | kubekey    | kubespray         | kubeadm | kops | minikube | sealos            | sealer            | kind | kubeoperator | rancher/rke   | kubeasz | kainstall     |
| ------------ | ---------- | ----------------- | ------- | ---- | -------- | ----------------- | ----------------- | ---- | ------------ | ------------- | ------- | ------------- |
| k8s官方      | X          | √                 | √       | √    | √        | x                 | x                 | x    | x            | x             | x       | x             |
| 高可用       | √          | √                 | √       | √    | x        | √                 | √                 | x    |              | √             |         |               |
| os初始化     | √          | √                 | x       |      |          | √(?)              | √(?)              |      |              | x(依赖docker) |         | √             |
| 开发语言     | go         | ansible           | go      |      |          | go                | go                |      |              | go            |         | shell         |
| 原理         | go+kubeadm | ansible+kubeadm   | go      |      |          | go+kubeadm        | go+kubeadm        |      |              | go            |         | shell+kubeadm |
| 离线安装     | √          | √（需搭建私有库） | √(部分) |      |          | √                 | √                 |      |              | x             |         |               |
| 社区活跃度   | 一般       | 高                | 高      |      |          | 高                | 一般              |      |              | 一般          |         |               |
| 可扩展性     | 高         | 高                | 低      |      |          | 高                | 高                |      |              | 高            |         |               |
| 附加组件支持 | √ (helm)   | √                 | x       |      |          | √ (cluster image) | √ (cluster image) |      |              | √（yaml）     |         |               |
| 安装时间     | 快         | 慢                | 快      |      |          | 快                | 快                |      |              | 快            |         |               |
| k8s版本      | 同kubeadm  | 同kubeadm         | v1.26   |      |          | v1.25             | v1.22             |      |              | v1.25.6       |         |               |
| 打分(满分10) | 9          | 8                 | 5       |      |          | 8                 | 7                 |      |              | 8             |         |               |

注：打分评判标准并不是这些开源软件的优秀成都，而是综合优秀程度+我们的需求匹配度，我们比较关注以下几点:
- 高可用
- 离线安装
- 依赖环境的复杂度
- 支持多种os
- 支持多种CPU架构
- 支持多种容器运行时
- 二次开发的难度
- 可扩展性

## kubekey

项目地址: <https://github.com/kubesphere/kubekey>

实践文档: [kubekey安装实践](kubekey/kubekey.md)

缺点：
1. 由于执行的命令都是写死在代码里的，修改安装/卸载等流程之后，需要重新编译`kk`命令(若在poc时，以防万一我们还需要把go的编译环境打包，或者是使用容器)
2. 下载地址(k8s组件以及deb/rpm包)也是写死在代码的(最好通过配置文件配置)
3. 文档不够完善

## sealos

项目地址：<https://github.com/labring/sealos>

实践文档: [sealos安装实践](sealos/sealos.md)

缺点:
1. 不是专门做k8s安装的
2. 文档不仅不够完善，且缺乏逻辑
3. 报错信息简单，难以定位问题，需要阅读源码
4. 代码复杂且乱，社区会加入很多不符合我们需求的功能，不便维护

## sealer

项目地址: <https://github.com/sealerio/sealer>

在k8s安装层面基本与sealos一致，但有些许不同。

根据<https://github.com/labring/sealos/issues/641>, 在sealer设计之初，它可以用来在sealos安装k8s之上，通过`kubefile`实现各种软件的自定义镜像，便于离线部署。但实际上，现在的sealos也实现了这一部分功能,其他的话，sealer可能更倾向于`build and share`，便于共享自定义的镜像。

## kubespray

项目地址: <https://github.com/kubernetes-sigs/kubespray>

实践文档: [kubespray安装实践](kubespray/kubespray.md)

缺点:
1. ansible环境搭建比较复杂，虽说可以通过容器安装，但也需要安装容器环境，也是个麻烦事儿。尤其是arm支持性较差
2. 安装较慢
3. 离线安装步骤繁多，较麻烦
4. ansible 

## rancher/rke
由于rancher部署自定义k8s集群时，实际上使用的是rke，所以我们这里只讨论rke工具。

**rke不使用kubeadm配管集群**

项目地址: <https://github.com/rancher/rke>
实践文档：[rke安装实践](rke/rke.md)


## kops    
己内部实现的自动化配置和编排功能，与其支持的特定的云平台的独有特性紧密关联(如AWS)，所以在其他一些通用的平台上不太灵活。
如果在可预见的未来我们只使用一个平台，那么它可能是一个更好的选择。


## kubeadm
提供了k8s集群生命周期管理的领域知识，包括自托管、动态服务发现等，说白话就是，kubeadm提供了官方对k8s集群部署、配置、管理的最佳实践

## kind

## minikube

## kubeOperator


注:
- 1. kubekey文档中只支持到v1.25，但经过实测，如果不胡乱修改配置如`kubernetes.featureGates`，是可以与kubeadm保持一致的，例如`v1.25`中，移除了`TTLAfterFinished`，此时配置便会报错