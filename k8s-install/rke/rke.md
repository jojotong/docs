```bash
docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher
```

```bash
curl -fL https://192.168.8.162/system-agent-install.sh | sudo  sh -s - --server https://192.168.8.162 --label 'cattle.io/os=linux' --token 2ghs6mhhn57m2hk95rbk7qxcbth7qfxnxs7gn8w4n5gxxtb5hqv8kc --ca-checksum eee748b24639a79d09cad84a74da27a93b03145d2eb95712a08e3957fed3e4b0 --etcd --controlplane --worker
```

# rke安装实践

## 在线安装
rke不能自动初始化os，因此一些必要的初始化操作及docker安装都需手动执行             

```barh
$ rke config --name cluster.yaml
[+] Cluster Level SSH Private Key Path [~/.ssh/id_rsa]: 
[+] Number of Hosts [1]: 1
[+] SSH Address of host (1) [none]: 192.168.8.163
[+] SSH Port of host (1) [22]: 
[+] SSH Private Key Path of host (192.168.8.163) [none]: 
[-] You have entered empty SSH key path, trying fetch from SSH key parameter
[+] SSH Private Key of host (192.168.8.163) [none]: 
[-] You have entered empty SSH key, defaulting to cluster level SSH key: ~/.ssh/id_rsa
[+] SSH User of host (192.168.8.163) [ubuntu]: root
[+] Is host (192.168.8.163) a Control Plane host (y/n)? [y]: y
[+] Is host (192.168.8.163) a Worker host (y/n)? [n]: y
[+] Is host (192.168.8.163) an etcd host (y/n)? [n]: y
[+] Override Hostname of host (192.168.8.163) [none]: rke-master1
[+] Internal IP of host (192.168.8.163) [none]: 
[+] Docker socket path on host (192.168.8.163) [/var/run/docker.sock]: 
[+] Network Plugin Type (flannel, calico, weave, canal, aci) [canal]: calico
[+] Authentication Strategy [x509]: 
[+] Authorization Mode (rbac, none) [rbac]: 
[+] Kubernetes Docker image [rancher/hyperkube:v1.25.6-rancher4]: 
[+] Cluster domain [cluster.local]: 
[+] Service Cluster IP Range [10.43.0.0/16]: 
[+] Enable PodSecurityPolicy [n]: 
[+] Cluster Network CIDR [10.42.0.0/16]: 
[+] Cluster DNS Service IP [10.43.0.10]: 
[+] Add addon manifest URLs or YAML files [no]: 
# 视情况修改cluster.yaml文件
$ rke up --config cluster.yaml
```

## 离线安装
rke虽然不支持离线安装，但由于它的所有工具的安装包括os配置修改都通过docker镜像实现，如：
- rancher/rke-tools: 提供一系列工具来初始化os及安装必要的软件包
- rancher/hyperkube: k8s镜像

如果我们要做离线安装，为rke制作的离线包需要包括以下内容
1. docker离线安装包及工具
2. 镜像分发工具或者registry仓库搭建
3. 如果有自定义的步骤，可能需要修改`rke-tool`镜像
4. 其他的同在线安装

## 卸载
```bash
rke remove --config cluster.yaml
```
但是卸载得不够彻底，像`nginx-ingress-controller`，`metrics-server`等容器还在。


## 实测问题
1. 没有安装docker，以及centos 不能使用root用户ssh
```bash
$ rke up --config cluster.yaml 
INFO[0000] Running RKE version: v1.4.4                  
INFO[0000] Initiating Kubernetes cluster                
INFO[0000] [certificates] GenerateServingCertificate is disabled, checking if there are unused kubelet certificates 
INFO[0000] [certificates] Generating admin certificates and kubeconfig 
INFO[0000] Successfully Deployed state file at [./cluster.rkestate] 
INFO[0000] Building Kubernetes cluster                  
INFO[0000] [dialer] Setup tunnel for host [192.168.8.163] 
WARN[0000] Failed to set up SSH tunneling for host [192.168.8.163]: Can't retrieve Docker Info: error during connect: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/info": Unable to access the Docker socket (/var/run/docker.sock). Please check if the configured user can execute `docker ps` on the node, and if the SSH server version is at least version 6.7 or higher. If you are using RedHat/CentOS, you can't use the user `root`. Please refer to the documentation for more instructions. Error: ssh: rejected: administratively prohibited (open failed) 
WARN[0000] Removing host [192.168.8.163] from node lists 
FATA[0000] Cluster must have at least one etcd plane host: failed to connect to the following etcd host(s) [192.168.8.163] 
```

解决方法：
- 安装docker
```bash
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl start docker
```
- 新建用户
```bash
useradd slt
usermod -aG docker slt
passwd slt
```

2. docker版本问题
```
FATA[0000] Unsupported Docker version found [23.0.3] on host [192.168.8.163], supported versions are [1.13.x 17.03.x 17.06.x 17.09.x 18.06.x 18.09.x 19.03.x 20.10.x] 
```

卸载然后重装docker
```
yum install docker-ce-18.09.1 docker-ce-cli-18.09.1 containerd.io docker-buildx-plugin docker-compose-plugin
```

3. docker权限
```
WARN[0000] Failed to set up SSH tunneling for host [192.168.8.163]: Can't retrieve Docker Info: error during connect: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/info": Unable to access the Docker socket (/var/run/docker.sock). Please check if the configured user can execute `docker ps` on the node, and if the SSH server version is at least version 6.7 or higher. If you are using RedHat/CentOS, you can't use the user `root`. Please refer to the documentation for more instructions. Error: ssh: rejected: administratively prohibited (open failed) 
```

需要创建`/etc/docker/daemon.json`
```
{
    "group": "dockerroot"
}
```

参考文档: 
- <https://rke.docs.rancher.com/os#red-hat-enterprise-linux-rhel--oracle-linux-ol--centos>
- <https://bugzilla.redhat.com/show_bug.cgi?id=1527565>