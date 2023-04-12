# kubespray 安装实践

可以在bare metal和大多数云上，使用ansible作为自动化配置和编排的基础工具，对于熟悉ansible并希望跨多个平台部署k8s集群的人来说是一个选择

## 在线安装

安装ansible等依赖
```bash
pip install -r requirements.txt
```

初始化Inventory配置文件
```bash
# Copy ``inventory/sample`` as ``inventory/mycluster``
cp -rfp inventory/sample inventory/mycluster

# Update Ansible inventory file with inventory builder
declare -a IPS=(192.168.8.163)
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```

执行安装
```bash
ansible-playbook -i inventory/mycluster/hosts.yaml  --become --become-user=root cluster.yml
```

