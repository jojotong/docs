# vmware 虚拟机内存气泡占用过大

现象：
系统内存使用过高，查看 /var/log/messages: 

```log
Oct 10 15:09:09 10 avahi-daemon[897]: Withdrawing workstation service for ens192.
Oct 10 15:09:09 10 journal: Failed to create service browser: Too many objects
Oct 10 15:09:09 10 avahi-daemon[897]: Withdrawing workstation service for lo.
Oct 10 15:09:09 10 journal: Failed to create service browser: Too many objects
Oct 10 15:09:09 10 avahi-daemon[897]: Withdrawing workstation service for tunl0.
Oct 10 15:09:09 10 journal: Failed to create service browser: Too many objects
Oct 10 15:09:09 10 avahi-daemon[897]: Withdrawing workstation service for dummy0.
```

解决：
![](https://raw.githubusercontent.com/jojotong/resources/main/%E4%BC%81%E4%B8%9A%E5%BE%AE%E4%BF%A1%E6%88%AA%E5%9B%BE_16969225837753.png)

ref:
- https://communities.vmware.com/t5/VMware-Fusion-Discussions/VMware-Fusion-7-and-VMware-Tools-Memory-Leak-in-Debian-Guest/td-p/2673328