# docker run 添加端口转发后没有ports
```bash
[root@xxx-03 ~]# docker run -d -p 8222:80 harbor.telecom-ai.com.cn/library/nginx:latest
56cd9e39b9a0da255656c8eefd235940862dae0409360f6b3716d3052f695036
[root@xxx-03 ~]# docker ps
CONTAINER ID   IMAGE                                           COMMAND                  CREATED         STATUS        PORTS     NAMES
56cd9e39b9a0   harbor.telecom-ai.com.cn/library/nginx:latest   "/docker-entrypoint.…"   2 seconds ago   Up 1 second             focused_moser
```

原因，缺失bridge网络，默认 none
```bash
[root@xxx-03 ~]# docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
13a6d2683384   host      host      local
b55890e5bfa4   none      null      local
```

手动 `docker network create new-bridge` 创建，运行时指定，推测跟强行重装了docker, daemon.json不兼容有关。

# nvidia runtime 与 runc 版本不兼容导致 containerd报错
现象：
```
Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create containerd task: failed to create shim task: OCI runtime create failed: json: cannot  │
│ unmarshal object into Go struct field Process.process.capabilities of type []string: unknown
```

![企业微信截图_17268171144201](https://github.com/user-attachments/assets/3f7b7d05-976f-48e8-b49a-5c3e71499065)

```
nvidia-container-runtime -h
NAME:
   runc - Open Container Initiative runtime

runc is a command line client for running applications packaged according to
the Open Container Initiative (OCI) format and is a compliant implementation of the
Open Container Initiative specification.

runc integrates well with existing process supervisors to provide a production
container runtime environment for applications. It can be used with your
existing process monitoring tools and the container will be spawned as a
direct child of the process supervisor.

Containers are configured using bundles. A bundle for a container is a directory
that includes a specification file named "config.json" and a root filesystem.
The root filesystem contains the contents of the container.

To start a new instance of a container:

    # runc run [ -b bundle ] <container-id>

Where "<container-id>" is your name for the instance of the container that you
are starting. The name you provide for the container instance must be unique on
your host. Providing the bundle directory using "-b" is optional. The default
value for "bundle" is the current directory.

USAGE:
   docker-runc [global options] command [command options] [arguments...]
   
VERSION:
   1.0.0-rc2
commit: COMMIT_NO
spec: 1.0.0-rc2-dev
```

思路：
![企业微信截图_17268170799664](https://github.com/user-attachments/assets/82c8a278-dcc5-4136-b631-df37527b26a8)

解决方案
1. 停止docker
2. 升级docker的二进制
3. 删除 docker-runc
4. 启动docker

或者改nvidia runtime 配置也行。











[root@minion-03 ~]# nvidia-container-runtime -v
runc version 1.0.0-rc2
commit: COMMIT_NO
spec: 1.0.0-rc2-dev
[root@minion-03 ~]# /usr/bin/nvidia-container-runtime -v
runc version 1.0.0-rc2
commit: COMMIT_NO
spec: 1.0.0-rc2-dev
