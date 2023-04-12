- [kubekey 安装实践](#kubekey-安装实践)
  - [在线安装](#在线安装)
    - [初始化操作系统，安装依赖](#初始化操作系统安装依赖)
    - [安装集群](#安装集群)
  - [离线安装](#离线安装)
    - [制作离线安装包](#制作离线安装包)
    - [安装集群](#安装集群-1)
  - [实测问题](#实测问题)
  - [卸载](#卸载)
  - [附录](#附录)

# kubekey 安装实践
kubekey是go开发的一款专职做k8s安装的工具，支持以下特性:
- [x] 单节点
- [x] 高可用
- [x] 离线安装
- [x] 集群扩展
- [x] 集群升级
- [x] 架构: arm/amd64
- [x] os: ubuntu/debian/centos/llmalinux
- [x] addons 插件部署 
  
它的安装流程主要分为两步：
1. 代码调用一系列命令完成os检验、os配置修改、依赖软件安装
2. 通过kubeadm安装、管理k8s集群
   
## 在线安装

### 初始化操作系统，安装依赖
```
./bin/kk init os -f bin/config-sample.yaml
```

或者在config文件中配置`system`模块，配置后，`skipConfigureOS`默认为`false`:
```yaml
  system:
    skipConfigureOS: false # If true, do not pre-configure the host OS (e.g. kernel modules, /etc/hosts, sysctl.conf, NTP servers, etc). You will have to set these things up via other methods before using KubeKey.
```

### 安装集群
```
./bin/kk create cluster -f bin/config-sample.yaml
```

## 离线安装
<https://github.com/kubesphere/kubekey/blob/master/docs/manifest_and_artifact.md>

### 制作离线安装包
1. 导出离线配置
  ```bash
  ./bin/kk create manifest --kubeconfig ~/.kube/config -f bin/manifest-sample.yaml
  ```

2. 制作离线包
  ```bash
  ./bin/kk artifact export -m bin/manifest-sample.yaml
  ```

### 安装集群
  ```bash
  ./bin/kk create cluster -f bin/config-sample.yaml -a kubekey-artifact.tar.gz --with-packages
  ```

## 实测问题
1. 初次安装etcd无法连接，清理之后重试恢复
2. 在线安装时，每次会重新下载kubectl、kubelet、kubeadm、容器镜像等依赖，而不是先检查本地文件
3. 在线安装时，如果本地终端走了代理，SaveKubeConfigModule会报错，因为当前终端无法http内网访问目标集群
   ```log
   14:11:47 CST [SaveKubeConfigModule] Save kube config as a configmap
   14:11:57 CST message: [LocalHost]
   Get "https://192.168.8.163:6443/api/v1/namespaces/kubekey-system": net/http: TLS handshake timeout
   14:11:57 CST retry: [LocalHost]
   14:12:17 CST message: [LocalHost]
   Get "https://192.168.8.163:6443/api/v1/namespaces/kubekey-system": net/http: TLS handshake timeout
   14:12:17 CST retry: [LocalHost]
   14:12:32 CST message: [LocalHost]
   Get "https://192.168.8.163:6443/api/v1/namespaces/kubekey-system": net/http: TLS handshake timeout
   14:12:32 CST retry: [LocalHost]
   14:12:47 CST message: [LocalHost]
   Get "https://192.168.8.163:6443/api/v1/namespaces/kubekey-system": net/http: TLS handshake timeout
   14:12:47 CST retry: [LocalHost]
   14:13:08 CST message: [LocalHost]
   Get "https://192.168.8.163:6443/api/v1/namespaces/kubekey-system": net/http: TLS handshake timeout
   14:13:08 CST failed: [LocalHost]
   error: Pipeline[CreateClusterPipeline] execute failed: Module[SaveKubeConfigModule] exec failed: 
   failed: [LocalHost] [SaveKubeConfig] exec failed after 5 retries: Get "https://192.168.8.163:6443/api/v1/namespaces/kubekey-system": net/http: TLS handshake timeout
   ```
4. 通过manifest导出artifact时，如果没指定`operatingSystems.repository.iso.url`，无法导出os相关离线包，且没有报错。这时，在离线安装集群时，如果指定了`--with-packages`，就会报错

## 卸载
```
./bin/kk delete cluster -f config.yaml --all
```
`-all`参数表示`Delete total cri conficutation and data directories`

查看代码可知，删除流程包括以下步骤:
1. kubeadm reset
2. 卸载容器运行时
3. 卸载一些系统组件
   - ResetNetworkConfig
   - UninstallETCD
   - RemoveFiles
   - DaemonReload
4. 卸载证书续签组件
5. 卸载VIP模块

```go
func NewDeleteClusterPipeline(runtime *common.KubeRuntime) error {
	m := []module.Module{
		&precheck.GreetingsModule{},
		&confirm.DeleteClusterConfirmModule{},
		&kubernetes.ResetClusterModule{},
		&container.UninstallContainerModule{Skip: !runtime.Arg.DeleteCRI},
		&os.ClearOSEnvironmentModule{},
		&certs.UninstallAutoRenewCertsModule{},
		&loadbalancer.DeleteVIPModule{Skip: !runtime.Cluster.ControlPlaneEndpoint.IsInternalLBEnabledVip()},
	}

	p := pipeline.Pipeline{
		Name:    "DeleteClusterPipeline",
		Modules: m,
		Runtime: runtime,
	}
	if err := p.Start(); err != nil {
		return err
	}
	return nil
}
```

总体而言，算是比较负责的清理。

## 附录
- [config-sample.yaml](config-sample%2Cyaml)
- [manifest-sample.yaml](manifest-sample.yaml)