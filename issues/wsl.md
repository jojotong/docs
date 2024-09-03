# root 用户
ubuntu2404.exe config --default-user root

# docker无法启动
```
failed to start daemon: Error initializing network controller: error obtaining controller instance: failed to register "bridge" driver: unable to add return rule in DOCKER-ISOLATION-STAGE-1 chain:  (iptables failed: iptables --wait -A DOCKER-ISOLATION-STAGE-1 -j RETURN: iptables v1.8.10 (nf_tables):  RULE_APPEND failed (No such file or directory): rule in chain DOCKER-ISOLATION-STAGE-1
```
解决：
> try sudo dockerd --iptables=false
> If you want to make the change permanent edit /etc/default/docker and add DOCKER_OPTS="--iptables=false". After this you can use sudo service docker start to start your docker server, or stop, restart, and check status. Using service to start docker it will also log events to /var/log/docker which might come in handy later.

https://github.com/microsoft/WSL/issues/8450#issuecomment-1138927099

# docker iptables导致创建k8s失败

kind create cluster --image=kindest/node:v1.24.17
Creating cluster "kind" ...
ERROR: failed to create cluster: failed to ensure docker network: command "docker network create -d=bridge -o com.docker.network.bridge.enable_ip_masquerade=true -o com.docker.network.driver.mtu=1500 --ipv6 --subnet fc00:f853:ccd:e793::/64 kind" failed with error: exit status 1
Command Output: Error response from daemon: Failed to Setup IP tables: Unable to enable NAT rule:  (iptables failed: ip6tables --wait -t nat -I POSTROUTING -s fc00:f853:ccd:e793::/64 ! -o br-f72d372d0e98 -j MASQUERADE: Warning: Extension MASQUERADE revision 0 not supported, missing kernel module?
ip6tables v1.8.10 (nf_tables):  CHAIN_ADD failed (No such file or directory): chain POSTROUTING
 (exit status 4))

 解决：
```bash
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
```

 https://github.com/microsoft/WSL/issues/6655#issuecomment-1142933322

 # wsl 通过外部机器ssh

在powershell 中添加端口转发

```bash
netsh interface portproxy delete v4tov4   listenaddress=192.168.125.183   listenport=9022
netsh interface portproxy add v4tov4   listenaddress=192.168.125.183   listenport=9022  connectaddress=172.21.110.5  connectport=22
```
