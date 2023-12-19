#  通过networkmanager配置DNS

```
nmcli connection modify enp4s0 ipv4.dns "114.114.114.114 8.8.8.8 8.8.4.4"
service NetworkManager restart
```

ref. 
- https://serverfault.com/questions/810636/how-to-manage-dns-in-networkmanager-via-console-nmcli

# 通过resolvectl

global: 
修改文件：/etc/systemd/resolved.conf
执行：
``` 
systemctl restart systemd-resolved.service
```

针对网卡：
```
resolvectl dns 2 8.8.8.8
```