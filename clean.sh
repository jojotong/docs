docker ps -a | awk '{print $1}' | xargs docker rm

yum remove docker \
           docker-client \
           docker-client-latest \
           docker-common \
           docker-latest \
           docker-latest-logrotate \
           docker-logrotate \
           docker-selinux \
           docker-engine-selinux \
           docker-engine

yum remove docker-ce \
           docker-ce-cli \    
           containerd

systemctl stop docker
rm -f /usr/lib/systemd/system/docker.service
rm -rf /etc/systemd/system/docker.service.d
rm -rf /etc/systemd/system/docker.service
rm -rf /var/lib/docker
rm -rf /var/run/docker
rm -rf /usr/local/docker
rm -rf /etc/docker
rm -rf /usr/bin/docker* /usr/bin/containerd* /usr/bin/runc /usr/bin/ctr
