# kubeoperator实践

## 安装/卸载
都在界面上完成，实现原理：

通过`server`以grpc调用`kobe`API, 在`kobe`中执行ansible安装/管理集群，安装完成后，以`kubepi`管理集群资源

集群安装步骤：
```go
func NewClusterAdm() *ClusterAdm {
	ca := new(ClusterAdm)
	ca.createHandlers = []Handler{
		ca.EnsureInitTaskStart,
		ca.EnsurePrepareBaseSystemConfig,
		ca.EnsurePrepareContainerRuntime,
		ca.EnsurePrepareKubernetesComponent,
		ca.EnsurePrepareLoadBalancer,
		ca.EnsurePrepareCertificates,
		ca.EnsureInitEtcd,
		ca.EnsureInitMaster,
		ca.EnsureInitWorker,
		ca.EnsureInitNetwork,
		ca.EnsureInitHelm,
		ca.EnsureInitMetricsServer,
		ca.EnsureInitIngressController,
		ca.EnsurePostInit,
	}
    ...
}
```

调用`kobe`: 
```go
func RunPlaybookAndGetResult(b kobe.Interface, playbookName, tag string, writer io.Writer) error {
	taskId, err := b.RunPlaybook(playbookName, tag)
	var result kobe.Result
	if err != nil {
		return err
	}
	// 读取 ansible 执行日志
	if writer != nil {
		go func() {
			err = b.Watch(writer, taskId)
			if err != nil {
				logger.Log.Error(err)
			}
		}()
	}
	timeout := viper.GetInt("job.timeout")
	if timeout < DefaultPhaseTimeoutMinute {
		timeout = DefaultPhaseTimeoutMinute
	}
	err = wait.Poll(PhaseInterval, time.Duration(timeout)*time.Minute, func() (done bool, err error) {
		res, err := b.GetResult(taskId)
		if err != nil {
			return true, err
		}
    ...
    }
```


## 问题
1. 如已有containerd会安装失败
   ```log
   PLAY [kube-master,kube-worker,new-worker] **************************************

   TASK [Gathering Facts] *********************************************************
   ok: [slt-master-1]

   TASK [prepare/docker : Get whether Containerd has been installed] **************
   changed: [slt-master-1]

   TASK [prepare/docker : Error message] ******************************************
   fatal: [slt-master-1]: FAILED! => {"changed": false, "msg": "Containerd already installed!"}

   PLAY RECAP *********************************************************************
   slt-master-1               : ok=2    changed=1    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0   
   ```
2. 依赖deltarpm
   ```log
      TASK [load-balancer : CentOS | Install haproxy] ********************************
   fatal: [slt-master-1]: FAILED! => {"changed": false, "changes": {"installed": ["haproxy"]}, "msg": "http://192.168.8.162:8081/repository/centos-base/7/os/x86_64/Packages/haproxy-1.5.18-9.el7.x86_64.rpm: [Errno 14] HTTP Error 500 - Internal Server Error\nTrying other mirror.\n\n\nError downloading packages:\n  haproxy-1.5.18-9.el7.x86_64: [Errno 256] No more mirrors to try.\n\n", "rc": 1, "results": ["Loaded plugins: priorities\nResolving Dependencies\n--> Running transaction check\n---> Package haproxy.x86_64 0:1.5.18-9.el7 will be installed\n--> Finished Dependency Resolution\n\nDependencies Resolved\n\n================================================================================\n Package        Arch          Version                Repository            Size\n================================================================================\nInstalling:\n haproxy        x86_64        1.5.18-9.el7           Centos-Extras        834 k\n\nTransaction Summary\n================================================================================\nInstall  1 Package\n\nTotal download size: 834 k\nInstalled size: 2.6 M\nDownloading packages:\nDelta RPMs disabled because /usr/bin/applydeltarpm not installed.\n"]}
   ```
3. 
yum install deltarpm -y
