# windows deepin 双系统 删除 deepin
1. 删除deepin 引导， [easyuefi](https://www.easyuefi.com/thanks-install.html)
2. windows 磁盘管理删除卷

ref. <https://wiki.deepin.org/zh/%E5%BE%85%E5%88%86%E7%B1%BB/04_%E6%8C%89%E5%90%AF%E5%8A%A8%E9%A1%BA%E5%BA%8F%E5%88%92%E5%88%86/04_%E7%B3%BB%E7%BB%9F%E5%85%B3%E6%9C%BA%E5%90%8E/%E7%B3%BB%E7%BB%9F%E5%8D%B8%E8%BD%BD>


# 
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










[root@minion-03 ~]# nvidia-container-runtime -v
runc version 1.0.0-rc2
commit: COMMIT_NO
spec: 1.0.0-rc2-dev
[root@minion-03 ~]# /usr/bin/nvidia-container-runtime -v
runc version 1.0.0-rc2
commit: COMMIT_NO
spec: 1.0.0-rc2-dev


   
