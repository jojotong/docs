# 应用编排调研&设计

## 调研
| provider   | 形式                                                                                                                                    | 缺点                                                   |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| 华为云     | 定义一个应用模板，通过`input`定义输入参数，作为基于模板创建应用堆栈时的可变部分                                                         | 没有将各种配置抽象为一层统一的配置资源，缺乏自定义支持 |
| 腾讯云     | 应用于服务编排工作流，偏向工作流，感觉不是针对k8s、容器环境                                                                             | 不合我们需求                                           |
| 阿里云     | 制定一个应用编排(一组yaml文件)，编排文件使用k8s原生资源 + go template形式编写                                                           | 同华为云                                               |
| 火山引擎   | 提供两套：1. k8s yaml编排，同阿里云；2. OAM应用编排，通过预置应用模板(模板也可修改，yaml模式)，添加组件配置、环境变量、运维插件部署应用 |                                                        |
| kubesphere | 原生k8s 资源部署                                                                                                                        | 没做应用级抽象                                         |
| rainbond   | 源码构建、docker构建、k8s编排等                                                                                                         | 应用级抽象不够                                         |
| kubevela   | OAM                                                                                                                                     |                                                        |

### 华为云
```yaml
# 应用模板所基于的类型定义版本
tosca_definitions_version: huaweicloud_tosca_version_1_0
# 输入参数定义
inputs: 
  app-name:
    default: magento
    description: '应用名称##Application name'
    label: magento
  magento-EIP:
    description: 'magento服务对外暴露访问地址##External access address of the Magento service'
    label: magento
  magento-EPORT:
    default: 32080
    description: 'magento服务对外监听端口##External listening port of the Magento service'
    label: magento
    type: integer
    ... ...
# 映射表定义
mappings:
  region_map:  #定义不同region镜像和规格的映射
    cn-east-2:
      magento-image: '10.125.17.64:20202/aos-samples/magento:1.9.1.0'
      mysql-image: '10.125.17.64:20202/aos-samples/mysql:latest'
    ... ...
#应用拓扑定义
node_templates:
  magento:  #元素名称
    metadata:
      Designer:
        id: e66e332a-3466-4638-9896-f7d2e93a1ae3
    properties:  #元素属性
      k8sManifest:
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          labels:
            app:
              get_input: app-name
          name:
            get_input: app-name
        ... ...
    requirements:  #元素依赖
      - dependency:
          node: mysql-service
      - dependency:
          node: mysql-conf
      - dependency:
          node: magento-config
    type: HuaweiCloud.CCE.Deployment  #元素类型
    ... ...
# 输出参数定义
outputs:
  ingress-admin_password:
    description: Password of super user.
    value: magentorocks1
  magento-addr:
    description: Access URL for magento service.
    value:
      concat:
        - 'http://'
        - get_input: magento-EIP
        - ':'
        - get_input: magento-EPORT
  magento-admin_username:
    description: Super user name.
    value: admin
```

### kubevela 
![](https://www.plantuml.com/plantuml/png/SoWkIImgAStDuKfEB4fHy7VqVRf-vukD2nMgkHI083evFxSWFoyrhoGMmYyfIipCAoc6yWhoSpAJAw6SyloYxBIS_F9OhbekhkYdkwOydxBY-Pvfp_ec9HOK0DKbbcJcvyM2fDRDUpcpzMNpYkTxDq6K0KMvu3OfwDefuD3DXKCSf0NJL2w7rBmKeDS0)

#### helm
```yaml
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: helm-redis
spec:
  components:
    - name: redis
      type: helm
      properties:
        repoType: "helm"
        url: "https://charts.bitnami.com/bitnami"
        chart: "redis"
        version: "16.8.5"
        values:
          master:
            persistence:
              size: 16Gi
          replica:
            persistence:
              size: 16Gi
```

#### k8s yaml
```yaml
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: app-with-k8s-objects
  namespace: default
spec:
  components:
    - name: k8s-demo-service
      properties:
        objects:
          - apiVersion: apps/v1
            kind: Deployment
            metadata:
              name: nginx
            spec:
              replicas: 2
              selector:
                matchLabels:
                  app: nginx
              strategy:
                type: Recreate
              template:
                metadata:
                  labels:
                    app: nginx
                spec:
                  containers:
                    - image: nginx
                      name: nginx
                      ports:
                        - containerPort: 80
          - apiVersion: v1
            kind: Service
            metadata:
              annotations:
                service.beta.kubernetes.io/aws-load-balancer-type: nlb
              labels:
                app: nginx
              name: nginx
              namespace: default
            spec:
              externalTrafficPolicy: Local
              ports:
                - name: http
                  port: 80
                  protocol: TCP
                  targetPort: 80
              selector:
                app: nginx
              type: LoadBalancer
      type: k8s-objects
  policies:
    - name: topology-default
      type: topology
      properties:
        clusters: ['local']
        namespace: default
    - name: topology-production
      type: topology
      properties:
        clusters: ['local']
        namespace: production
  workflow:
    steps:
      - name: deploy2default
        properties:
          policies: ['topology-default']
        type: deploy
      - name: suspend
        type: suspend
      - name: deploy2production
        properties:
          policies: ['topology-production']
        type: deploy
```

#### 自定义应用
1. 定制 component、traints
2. 编排 application
<https://kubevela.io/zh/docs/tutorials/custom-image-delivery>

## 疑问: 
1. 应用是否要求从源码构建，也就是CI部分
2. 应用部署时是根据模板做可视化，那应用模板是否要求可视化，还是yaml模式？
3.  应用模板存哪里? mysql还是git？如果是git，我们需要部署一个git 服务，后面有需要也可以做gitops
4.  第一步做到什么程度，通过我们预置的应用模板，能手动部署（部署时根据模板修改部署参数）至目标环境即可？

## 设计

### 编排模式
1. 基于helm charts的应用编排

   ![](https://www.plantuml.com/plantuml/png/PP7DIlD058RtSnK7kix-etn8qOKR1S5bsyMO3AOqcKecKKI4LgNjngPeMr0NKYYObQqLgua_lHWxa-Gkd9XIgkw6UUTvptEO7BEnPJkcWR1gLom8EvveFWD2AhOqu457NeHlFT6wuFuZTqTmX000D6pZ7Sm8hEaIttGOSKp8R9Le-JlEYzOTRqxa-o9aDagxkhrk4KBHiUmrAeu6vNyilgc77mF8R9SFLms7p8lpCecUpaJGvaC_UkWN4sOkfLX9axAoF3GBqexNhxW_4IqlhjRK96C8BGpWl-BiAJ-PQFZAtLwwtMUrje-b09C7fkh4n0Kwc_P5RPXqlep5xILl157Vu-VTFoQBALcOJUz5n-VkYUYE2bIuxLamY4-zy7syBADebGCgmLzhPY6kNaVJXauC4rIZHAWDAPnAeXoXclobBm00)

2. 基于制品的应用编排
   
   ![](https://www.plantuml.com/plantuml/png/PPBVoz9G7CRlpr_n1M_gOhotCI9UwgARWg2hyFNYj1roEJVP3wGYS6WgaXh-43AX5b6x23GZqwdvp-oSRVz5PqvazUxoUVOytyyUTcbQsB3iiegmPEa6X2EFjNy3GX8sPA3-Y0lXRi9w0xhvIViBU8M0FpAsy5Di4hXNvF67jadiCkGUALhfQETPxnjjh_Zx1SWzK9uLhVi68HfwZL0-qOSEctLfn-NkqNX2L5MlygEgRijGkcN67vhXdo-GUrnwSLUroUbgdZlHhmRptz7v9lhX5fB24x5W96U4EraY4JWwRRwdcnNhUN7DYGTjdam9mcaZharvMae29a9dPhWjs1NXtw9elgNzIPfCLmaEBdFcLrfIlbwoZqFQyYFNeztnDQHpimZ1kXFiFaLVdRZkXVibXpXrldrpfTrugLJOf1LiLnVFiN5HnGQNRsR0petP4KMWYsOgHFllhFivMFlnU4RhVPIDodfLuyd_9XI1Zn0TMaMYba5I5Q9PaAAbNuakYIRpt-Cl)

### 应用部署

对于`控制台->k8s资源对象`的应用部署实现逻辑，暂时有以下选择：
- 直接通过`helm client` 部署
  
  1. 创建：在收到前端传来的`values.json`内容之后，直接在代码中调helm clients实现`helm install`
  2. 升级：需要从`helm storage driver`中解析出目标应用的配置(helm v3版本在secret里)，再结合`values.shema.json`渲染出表单，再实现`helm upgrade`
  3. 删除：实现`helm uninstall`

- 通过`kubevela helm component`部署

  1. 创建：在收到前端传来的`values.json`内容之后，在代码中调 kubevela client实现`vela up`
  2. 升级：同创建
  3. 删除：实现`vela delete`

对比：

|                   | helm client                            | kubevela helm component                                              |
| ----------------- | -------------------------------------- | -------------------------------------------------------------------- |
| 优点              | 不依赖第三方工具，简单                 | 声明式部署，便于维护应用编排文件，扩展性强，抽象程度高，插件生态丰富 |
| 缺点              | 扩展性差，非声明式，查看应用配置较麻烦 | 依赖kubevela、fluxcd，增加了系统复杂度                               |
| 开发复杂度（1-5） | 3                                      | 4                                                                    |
| 运维复杂度（1-5） | 3                                      | 4                                                                    |
| 可扩展性 (1-5)    | 2                                      | 4                                                                    |

### charts与schema管理

1. 搭建helm charts仓库

   使用 ChartMuseum 搭建我们的中央 charts仓库

2. 制作应用的charts包

   为在应用部署时，让前端根据charts动态生成表单，我们需要按照 <https://helm.sh/docs/topics/charts/#schema-files> 规范， 编写`values.schema.json`文件。eg:
   ```json
   {
     "$schema": "https://json-schema.org/draft-07/schema#",
     "properties": {
       "image": {
         "description": "Container Image",
         "properties": {
           "repo": {
             "type": "string"
           },
           "tag": {
             "type": "string"
           }
         },
         "type": "object"
       },
       "name": {
         "description": "Service name",
         "type": "string"
       },
       "port": {
         "description": "Port",
         "minimum": 0,
         "type": "integer"
       },
       "protocol": {
         "type": "string"
       }
     },
     "required": [
       "protocol",
       "port"
     ],
     "title": "Values",
     "type": "object"
   }
   ```
   
3. 提交
   
   在前端通过schema校验完用户配置之后，需要同步内容至`values.json`文件，再提交部署。

