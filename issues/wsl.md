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
