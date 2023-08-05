---
title: k8s安装
date: 2021-11-10 21:53:36
tags:  k8s安装,Centos 7, 开发环境
categories: k8s权威指南
---
准备一台机器：
1. centos7
2. 更换为阿里云源
3. 禁用selinux，配置文件在/etc/sysconfig/selinux，将SELINUX=enforcing替换为disabled

<!-- more -->

# 系统准备
## 安装Docker
### 安装所需的软件包
yum-utils 提供了 yum-config-manager ，并且 device mapper 存储驱动程序需要 device-mapper-persistent-data 和 lvm2
```shell
yum install -y yum-utils device-mapper-persistent-data lvm2
```
### 设置yum仓库
- 官方源(慢) yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
- 阿里云源 yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

### 查看需要的安装的版本
```shell
yum list docker-ce --showduplicates | sort -r
```
### 安装 Docker Engine-Community
\<version\>是可选的，选择的话则是指定某个版本
```shell
yum install docker-ce-<version> docker-ce-cli-<version> containerd.io
```
### 配置阿里云的yum源(由于使用google的yum源出现不能访问的情况)
在/etc/yum.repo.d目录中新建一个kubernetes.repo的文件，内容如下：
```shell
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64 Kubernetes源设为阿里
gpgcheck=0：表示对从这个源下载的rpm包不进行校验
repo_gpgcheck=0：某些安全性配置文件会在 /etc/yum.conf 内全面启用
repo_gpgcheck，以便能检验软件库的中继数据的加密签署
如果gpgcheck设为1，会进行校验，就会报错，所以这里设为0

### 开机启动docker
```shell
systemctl start docker
systemctl enable docker
```
## 安装kubelet kubeadm kubectl
```shell
yum install -y kubelet kubeadm kubectl
```
### 开机启动kubelet
kubeadm将使用kubelet服务以容器方式部署和启动Kubenetes的主要服务，所以需要设置开机启动
```shell
systemctl start kubelet
systemctl enable kubelet
```

kubeadm还需要关闭linux的交换区
```shell
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a
```
### 修改kubeadm的默认配置
一些基础命令：

init是初始化控制平面命令，join是加入结点命令
- kubeadm config print init-defaults: 输出kubeadm init命令的默认参数
- kubeadm config print join-defaults: 输出kubeadm join命令的默认参数
- kubeadm config migrate: 在新旧版本之间进行配置转换
- kubeadm config images list: 列出所需列表
- kubeadm config images pull: 拉取镜像到本地

将默认参数保存到文件中
```shell
kubeadm config print init-defaults > init-default.yaml
```
## 下载Kubernetes的相关镜像
可以使用kubeadm config images list列出所需列表

为了加快kubeadm创建集群的过程，可以预先将所需镜像下载。

先配置国内镜像源，修改docker服务的配置文件(默认在/etc/docker/daemon.json，如果没有则新建)，地址是阿里云控制台->容器镜像服务->镜像工具->镜像加速器
```shell
mkdir -p /etc/docker
cat /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://********.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker
```

然后可以通过2种方式下载相关镜像
- kubeadm: kubeadm config images pull --config=init-default.yaml
- docker: docker pull 镜像名

# 安装Master
在执行kubeadm init命令之前，可以使用kubeadm init phase preflight检查系统是否符合要求，如果检查失败则终止。

**note:**   
kubernetes默认设置cgroup(cgroupdriver)为"systemd"，而Docker服务的cgroup驱动默认值为"cgroupfs"，建议将其修改为"systemd"，与kubernetes保持一致。
在/etc/docker/daemon.json中进行设置
```shell
{
  "exec-opts":["native-cgroupdriver=systemd"]
}
```

修改init-default.yaml文件
![master的init-config](master的init-config.png)

执行kubeadm init --config=init-default.yaml

看到如下所示即成功了
![master安装成功](master安装成功.png)

接下来就可以通过kubectl命令行工具访问集群进行操作了。由于kubeadm默认使用CA证书，所以需要为kubectl配置证书才能访问Master
1. admin用户
```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
2. root用户
```shell
export KUBECONFIG=/etc/kubernetes/admin.conf
```
如果开机使用的话，在/etc/profile中加入export KUBECONFIG=/etc/kubernetes/admin.conf

<font color="red">tips：如果安装失败的可以删除/etc/kubernetes文件夹，在根据netstat(不会用的话，netstat -h查看，注意一下-p选项)依次删除占用的端口
</font>

### master也可以安装pod
```shell
kubectl taint node <node_name> node-role.kubernetes.io/master-
```

# 安装Node，并将Node加入到集群
```shell
kubeadm join 192.168.2.101:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:a5c8d43441fdf1f824088b141ac45f44c1d838ec1ec09776bd80e9ee6749e47c
```
用的就是master安装成功的内容

如需调整其他内容
```shell
kubeadm config print join-defaults > join.config.yaml
```

修改配置文件join.config.yaml:
![node配置文件](node配置文件.png)

在master上查看结点
![master上查看结点](master上查看结点.png)

在初始安装的Master结点上也启动了kubelet和kube-proxy，在默认情况下并不参与工作负载的调度。如果希望master结点也作为Node角色，则可以运行下面的命令，让master结点也成为一个Node
1. 删除Node的标签
node-role.kubernetes.io/master
2. kubectl taint nodes --all node-role.kubernetes.io/master-node/k8s untainted

# 安装CNI网络插件
在master上执行
```shell
kubectl apply -f "https://docs.projectcalico.org/manifests/calico.yaml"
```
![安装CNI插件](安装CNI插件.png)

```shell
kubectl get nodes #所有的结点是ready状态
```

# 查看集群是否工作正常状态
```shell
kubectl get pods --all-namespaces
```
集群中的pods均处于Running状态
![集群整体状态](集群整体状态.png)