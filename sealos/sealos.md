# sealos安装实践
sealos 是一个以 kubernetes 为内核的云操作系统发行版。它不仅可以安装k8s，也可以通过类似的方式安装其他运行在k8s之上的应用程序。

有别于kubekey，sealos更不仅仅关注于集群安装，安装k8s只是它理念中的基础设施部分，它更侧重于管理我们整个云环境。通过它，我们可以以集中得配管多个k8s集群，并在上面运行、卸载我们想要的程序（在线/离线都行）。

sealos社区提供了[cluster-image](https://github.com/labring-actions/cluster-image)仓库以支持丰富的应用，我们按照它的配管方式定制我们的应用。

核心逻辑大致如下：
1. registry module 根据 registry 的配置拉起 registry
2. 根据 CloudImage Name 在所有节点拉取集群镜像
3. 启动 k8s 和 guest
4. kubelet 自动拉起其它镜像
5. 可以利用运行时自身能力去判断多架构并拉取对应架构的镜像

```go
func (c *CreateProcessor) GetPipeLine() ([]func(cluster *v2.Cluster) error, error) {
	var todoList []func(cluster *v2.Cluster) error
	todoList = append(todoList,
		// c.GetPhasePluginFunc(plugin.PhaseOriginally),
		c.Check,
		c.PreProcess,
		c.RunConfig,
		c.MountRootfs,
		c.MirrorRegistry,
		c.Bootstrap,
		// c.GetPhasePluginFunc(plugin.PhasePreInit),
		c.Init,
		c.Join,
		// c.GetPhasePluginFunc(plugin.PhasePreGuest),
		c.RunGuest,
		// c.GetPhasePluginFunc(plugin.PhasePostInstall),
	)

	return todoList, nil
}
```

## 在线安装
```bash
sealos run labring/kubernetes:v1.25.0 --single
```

## 离线安装
首先在有网络的环境中 save 安装包
```bash
$ sealos pull labring/kubernetes:v1.25.0
$ sealos save -o kubernetes.tar labring/kubernetes:v1.25.0
```

拷贝 kubernetes.tar 到离线环境, 使用 load 命令导入镜像即可：
```bash
$ sealos load -i kubernetes.tar
```
剩下的安装方式与在线安装一致。

因为sealos设计有镜像仓库，它会在每个集群部署，我们在离线安装之前，只需要把我们要安装的镜像（k8s或者应用程序镜像都行）导入目标集群。

## 卸载
```bash
sealos reset --cluster slt
```
我得吐槽一下，一会儿`-c`参数可以，一会儿又不行，玩文字游戏呢这是。

## 实测问题

1. 单节点安装时
   ```bash
   sealos run labring/kubernetes:v1.25.0 --single
   ```

   报错:
   ```log
   [kubelet-check] Initial timeout of 40s passed.

   Unfortunately, an error has occurred:
           timed out waiting for the condition

   This error is likely caused by:
           - The kubelet is not running
           - The kubelet is unhealthy due to a misconfiguration of the node in some way (required cgroups disabled)

   If you are on a systemd-powered system, you can try to troubleshoot the error with the following commands:
           - 'systemctl status kubelet'
           - 'journalctl -xeu kubelet'

   Additionally, a control plane component may have crashed or exited when started by the container runtime.
   To troubleshoot, list all containers using your preferred container runtimes CLI.
   Here is one example how you may list all running Kubernetes containers by using crictl:
           - 'crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps -a | grep kube | grep -v pause'
           Once you have found the failing container, you can inspect its logs with:
           - 'crictl --runtime-endpoint unix:///run/containerd/containerd.sock logs CONTAINERID'
   error execution phase wait-control-plane: couldn't initialize a Kubernetes cluster
   To see the stack trace of this error execute with --v=5 or higher
   ```

   kubelet日志:
   ```log
   Apr 11 10:12:05 node1 kubelet[53207]: E0411 10:12:05.743820   53207 kubelet.go:2373] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
   Apr 11 10:12:10 node1 kubelet[53207]: E0411 10:12:10.745130   53207 kubelet.go:2373] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
   Apr 11 10:12:15 node1 kubelet[53207]: E0411 10:12:15.747488   53207 kubelet.go:2373] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
   ```

   原因为没有安装calico，编写`clusterfile.yaml`，执行`sealos reset`后重新安装:
   ```bash
   sealos apply -f sealos/clusterfile.yaml
   ```


## 一些疑问
1. sealos的kubenetes镜像怎么制作的
2. sealos在安裝k8s镜像时，也能进行一些os初始化以及cri安装，是通过<https://sealos.io/zh-Hans/docs/design/rootfs>实现的，也就是在k8s镜像中，我们当然可以通过重新制作k8s镜像来完成更多的操作，但是我没找到它怎么制作原始k8s镜像的