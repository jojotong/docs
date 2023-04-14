# k8s 安装设计

## 开源工具调研

| 特性/工具    | kubekey          | kubespray         | kubeadm | sealos            | sealer            | kubeoperator     | rancher/rke/rke2 | kind        | kubeasz   | kainstall     | kops | minikube |
| ------------ | ---------------- | ----------------- | ------- | ----------------- | ----------------- | ---------------- | ---------------- | ----------- | --------- | ------------- | ---- | -------- |
| k8s官方      | X                | √                 | √       | x                 | x                 | x                | x                | √           | x         | x             | √    | √        |
| 高可用       | √                | √                 | √       | √                 | √                 | √                | √                | √(?)        | √         | √             | √    | x        |
| os初始化     | √                | √                 | x       | √(?)              | √(?)              | √                | √                | √           | √         | √             | -    | -        |
| 架构支持[^1] | amd64/arm/arm64  | amd64/arm/arm64   | -       | amd64/arm64       | amd64/arm64       | amd64/arm64      | amd64            | amd64/arm64 | -         | -             | -    | -        |
| os支持       | [大多数linux][1] | [大多数linux][2]  | -       | [大多数linux][3]  | 同sealos          | [大多数linux][4] | [大多数linux][5] | -           | -         | -             | -    | -        |
| 开发语言     | go               | ansible           | go      | go                | go                | go+ansible       | go               | go          | ansible   | shell         | go   | go       |
| 原理         | go+kubeadm       | ansible+kubeadm   | go      | go+kubeadm        | go+kubeadm        | go+ansible       | go               | go+kubeadm  | 纯ansible | shell+kubeadm | -    | -        |
| 离线安装     | √                | √（需搭建私有库） | √(部分) | √                 | √                 | √(不全)          | x                | √           | √         | √             | -    | -        |
| 二开复杂度   | 较简单           | 一般              | 复杂    | 一般              | 一般              | 复杂             | 较复杂           | -           | 一般      | 复杂          | -    | -        |
| 社区活跃度   | 一般             | 高                | 高      | 高                | 一般              | 低               | 一般             | 高          | 高        | 低            | -    | -        |
| 扩/缩容      | √                | √                 | √       | √                 | √                 | √                | √                | x           | √         | √             | √    | x        |
| 附加组件支持 | √ (helm)         | √                 | x       | √ (cluster image) | √ (cluster image) | ×                | √（yaml）        | x           | √         | √             | -    | -        |
| 安装时间     | 快               | 慢                | 快      | 快                | 快                | 慢               | 快               | 快          | 慢        | 快            | -    | -        |
| k8s版本      | 同kubeadm[^2]    | 同kubeadm         | v1.27   | v1.25             | v1.22             | v1.22            | v1.25            | 同kubeadm   | v1.26     | v1.27         | -    | -        |
| 打分(满分10) | 9                | 8                 | 6       | 8                 | 7                 | 6                | 8                | -           | 7         | 5             | -    | -        |


[^1]: 架构支持实际上还受限于一些安装的组件，比如网络插件：

    - amd64: Cluster using only x86/amd64 CPUs
    - arm64: Cluster using only arm64 CPUs
    - amd64 + arm64: Cluster with a mix of x86/amd64 and arm64 CPUs

    | kube_network_plugin | amd64 | arm64 | amd64 + arm64 |
    | ------------------- | ----- | ----- | ------------- |
    | Calico              | Y     | Y     | Y             |
    | Weave               | Y     | Y     | Y             |
    | Flannel             | Y     | N     | N             |
    | Canal               | Y     | N     | N             |
    | Cilium              | Y     | Y     | N             |
    | Contib              | Y     | N     | N             |
    | kube-router         | Y     | N     | N             |

[^2]: kubekey文档中只支持到v1.25，但经过实测，如果不胡乱修改配置如`kubernetes.featureGates`，是可以与kubeadm保持一致的，例如`v1.25`中，移除了`TTLAfterFinished`，此时配置便会报错

注：打分评判标准并不是这些开源软件的优秀成都，而是综合优秀程度+我们的需求匹配度，我们比较关注以下几点:
- 高可用
- 扩/缩容
- 离线安装
- 依赖环境的复杂度
- 支持多种os
- 支持多种CPU架构
- 支持多种容器运行时
- 二次开发的难度

### kubekey

项目地址: <https://github.com/kubesphere/kubekey>

实践文档: [kubekey安装实践](kubekey/kubekey.md)

缺点：
1. 由于执行的命令都是写死在代码里的，修改安装/卸载等流程之后，需要重新编译`kk`命令(若在poc时，以防万一我们还需要把go的编译环境打包，或者是使用容器)
2. 下载地址(k8s组件以及deb/rpm包)也是写死在代码的(最好通过配置文件配置)
3. 文档不够完善

### sealos

项目地址：<https://github.com/labring/sealos>

实践文档: [sealos安装实践](sealos/sealos.md)

缺点:
1. 不是专门做k8s安装的
2. 文档不仅不够完善，且缺乏逻辑
3. 报错信息简单，难以定位问题，需要阅读源码
4. 代码复杂且乱，社区会加入很多不符合我们需求的功能，不便维护

### sealer

项目地址: <https://github.com/sealerio/sealer>

在k8s安装层面基本与sealos一致，但有些许不同。

根据<https://github.com/labring/sealos/issues/641>, 在sealer设计之初，它可以用来在sealos安装k8s之上，通过`kubefile`实现各种软件的自定义镜像，便于离线部署。但实际上，现在的sealos也实现了这一部分功能,其他的话，sealer可能更倾向于`build and share`，便于共享自定义的镜像。

### kubespray

项目地址: <https://github.com/kubernetes-sigs/kubespray>

实践文档: [kubespray安装实践](kubespray/kubespray.md)

缺点:
1. ansible环境搭建比较复杂，虽说可以通过容器安装，但也需要安装容器环境，也是个麻烦事儿。尤其是arm支持性较差
2. 安装较慢
3. 离线安装步骤繁多，较麻烦
4. ansible 

### rancher/rke/rke2
由于rancher部署自定义k8s集群时，实际上使用的是rke，所以我们这里只讨论rke工具。

项目地址: 
- <https://github.com/rancher/rke>
- <https://github.com/rancher/rke2>

根据文档: https://docs.rke2.io/zh/#%E4%B8%8E-rke-%E6%88%96-k3s-%E7%9A%84%E5%B7%AE%E5%88%AB

rke2与rke的主要区别在部署k8s的时候，不再强制要求节点上有docker，而是通过在节点上安装`rke2-agent`，通过`systemd`启动。其他方面并无本质区别。

实践文档：[rke安装实践](rke/rke.md)

缺点:
1. rke不使用kubeadm配管集群
2. 部分os无法使用root用户
3. 离线安装支持性不佳
4. addon插件通过原生yaml而不是helm方式支持
5. rke1强制要求docker, 而rke2还不成熟
6. 不支持arm

### kubeOperator

项目地址: <https://github.com/KubeOperator/KubeOperator>
安装文档 [kubeoperator安装实践](kubeoperator/kubeoperator.md)

缺点:
1. 只能通过kubeoperator界面安装，而kubeoperator需要通过docker安装，其无法离线安装docker
2. 安装k8s这块用的自建[ansible脚本](https://github.com/KubeOperator/ansible)，而不是基于kubeadm
3. 安装脚本不够智能，依赖多

**不过，我们可以借鉴它的架构来做多集群管理。**

### kops    
己内部实现的自动化配置和编排功能，与其支持的特定的云平台的独有特性紧密关联(如AWS)，所以在其他一些通用的平台上不太灵活。

### kubeadm
提供了k8s集群生命周期管理的领域知识，包括自托管、动态服务发现等，说白话就是，kubeadm提供了官方对k8s集群部署、配置、管理的最佳实践

### kind
k8s in docker，不能用于生产，但可做轻量化便捷部署、演示。

### minikube
在本地创建VM然后部署k8s，不能用于生产。

## 基于kubekey的k8s安装方案
根据我们上面的调研结果，`kubekey`应该是目前最合适的工具，因此我们在这里讨论基于`kubekey`做二次开发的方案。

可以视需求情况分三步走:

![](https://www.plantuml.com/plantuml/png/XLHTJnfR57tdLvpalfamLz5uRtmoz-K-t9kqIP-QQfe1fZW11WA3ZNt2MX3a0ubA_81M52of2FH318RHFtFsd9ad_qAtda6qgItXXJdhhBNschMPZwfYH0tAYZSeXebNYie-nJ7nuez_8vAaF9S2WT3hHG8V1dIG9_wOM_9BAuJjlrjG_7z72RJIvd72AFMDQihXcC1h_yk-9VMVG4nQ9ApPfBsuSLQ_7kwpWsz6laxrAxRT8F_PD5QrpmvQryFiWWAf2WAXzPxbEmX1CMkzQBPNKOdS25a7INPPut84XL3fcN-5wnYRPw0DZD8wrRf6EGSRLTXhtB8QwLtMgjuIqCkAULv2EbDl8mwo2SS4VbwIc3kcg36dQrAOd76AGU_iZDChkQE270tP28-agA6eyo_xD18EtZ-5H9Tg9K4GVkhAsYd3Me5gMp3OUjGI1utKn83i2VtfKUIvvMd1XL_xu2PyfnYMer9aMOhCBKy9hbbX-ZSk8DMbUfcTQ6nmnTCRJsw_JIUVRpGUba5-9NfK0MiX-DwG7y0yBaG57yUEpOmhmPl4Ip78ybBOd7Iu2zaIDpw2OHEilOIrrc3w5zexm-YWKCHkO5FwNNhLWbeELV347VCzlCdP-4tZV9KrChOhV0If91HrgjMebhSIEQQtU6lCjWQ5aetZZsWlO-ewb3jGYVyA3Hk7aAWRgIBLckRw9xZuR9NZvibDSQsZ2jHi9_ZphkrmyjOVyeZG_mg53e_eIKHKVAELIVDqeD0sFoPn5kmBsqpUMmC-y5DPyMDGmpWcGtWfa9ngTRAagc5iMhuEXMFGZs1Ou1JsRMwSB-tKtMv2kN6ttrGxPeUhM5dZGiC1EJlnX891KV4Isij3EiTEssmdQrME7l2va8zROfacEytWt8Y5pJp2-MwYHxEpnhR7QloLEEObnMl_3Nq7)



[1]: https://github.com/kubesphere/kubekey#linux-distributions "kubekey"
[2]: https://github.com/kubernetes-sigs/kubespray#supported-linux-distributions "kubespray"
[3]: https://sealos.io/zh-Hans/docs/getting-started/prerequisites "sealos"
[4]: https://kubeoperator.io/docs/installation/install/#_2 "kubeoperator"
[5]: https://docs.rke2.io/zh/install/requirements#%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F "rke2"