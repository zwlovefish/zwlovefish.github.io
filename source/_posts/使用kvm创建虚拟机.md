---
title: 使用kvm创建虚拟机
date: 2026-09-02 22:57:00
tags:
  - KVM
  - Linux
  - 虚拟化
  - Windows
categories: 随笔
---

之前一直用 VirtualBox，最近在 Ubuntu 24.04 上换成了 KVM，性能确实好很多，接近物理机。这篇文章记录一下 KVM 的完整安装配置流程，并以安装 Windows 11 为例演示如何创建虚拟机（Win11 的坑不少：UEFI、TPM、virtio 驱动、强制联网检查，一个都不能少）。

<!--more-->

# 一、环境要求

- Ubuntu 24.04 LTS
- CPU 支持虚拟化（Intel VT-x / AMD-V）
- 建议 4GB+ 内存

# 二、安装 KVM

## 1. 检查 CPU 支持

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
# 输出大于 0 表示支持
```

## 2. 安装 KVM 及管理工具

```bash
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager -y
```

## 3. 添加用户权限

```bash
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER
# 注销重新登录生效
```

## 4. 启动服务

```bash
sudo systemctl enable --now libvirtd
```

## 5. 验证安装

```bash
lsmod | grep kvm
# 应显示 kvm_intel 或 kvm_amd
```

# 三、配置存储

```bash
# 创建虚拟机存储目录并设置权限
sudo mkdir -p /var/lib/libvirt/images
sudo chown libvirt-qemu:libvirt-qemu /var/lib/libvirt/images

# 添加 KVM 存储池
sudo virsh pool-define-as default --type dir --target /var/lib/libvirt/images
sudo virsh pool-autostart default
sudo virsh pool-start default
```

# 四、网络配置（可选）

**NAT 网络**（默认已配置）：虚拟机通过宿主机上网，无需额外配置。

**桥接网络**：让虚拟机获取独立 IP，宿主机和虚拟机在局域网内平起平坐。我装 Win11 就是为了让局域网其他设备能直接访问它，所以配置了桥接：

```bash
# 安装桥接工具
sudo apt install bridge-utils -y

# 创建桥接配置（根据实际网卡名调整，我的网卡是 enp0s3）
sudo nmcli connection add type bridge ifname br0
sudo nmcli connection add type ethernet slave-type bridge con-name bridge-br0 ifname enp0s3 master br0
sudo nmcli connection up br0
```

> ⚠️ 如果是 SSH 远程操作，执行前请确认桥接后的网络仍然连通，否则可能把自己锁在门外。

# 五、创建虚拟机：以安装 Windows 11 为例

## 1. 准备镜像

需要两个 ISO：

- **Windows 11 安装镜像**（如 `Win11_25H2_Chinese_Simplified_x64_v2.iso`）
- **virtio-win 驱动镜像**（[下载地址](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/)）：Windows 默认不认 virtio 磁盘/网卡，必须借助它加载驱动，性能才能拉满

## 2. 创建磁盘镜像

```bash
# Win11 磁盘至少 64GB
sudo qemu-img create -f qcow2 /home/zhoujianwei/libvirt-images/win11.qcow2 64G
```

> qcow2 是精简格式，64G 只是上限，实际占用随使用量增长。

## 3. virt-install 创建虚拟机

```bash
sudo virt-install \
  --name win11 \
  --ram 16384 \
  --vcpus 8 \
  --cpu host-passthrough \
  --os-variant win11 \
  --machine q35 \
  --boot uefi \
  --disk path=/home/zhoujianwei/libvirt-images/win11.qcow2,format=qcow2,bus=virtio \
  --cdrom /home/zhoujianwei/libvirt-images/Win11_25H2_Chinese_Simplified_x64_v2.iso \
  --disk /home/zhoujianwei/libvirt-images/virtio-win-0.1.285.iso,device=cdrom \
  --network bridge=br0,model=virtio \
  --graphics vnc,listen=0.0.0.0,password=123456 \
  --video qxl \
  --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
  --noautoconsole
```

几个关键参数说明：

| 参数 | 作用 |
| --- | --- |
| `--cpu host-passthrough` | CPU 直通特性给虚拟机，性能最佳 |
| `--machine q35` + `--boot uefi` | Win11 强制要求 UEFI + 安全启动，q35 是现代芯片组 |
| `--tpm backend.type=emulator...` | Win11 强制要求 TPM 2.0，用软件模拟 |
| `bus=virtio` / `model=virtio` | 磁盘和网卡都用半虚拟化驱动，性能接近原生 |
| 第二个 `--disk ...device=cdrom` | 把 virtio-win 驱动盘挂成光驱，装系统时加载驱动用 |
| `--network bridge=br0` | 接入桥接网络，虚拟机获得独立 IP |

> 💡 新手也可以直接 `virt-manager` 打开图形界面创建：选择 ISO → 分配 CPU/内存 → 创建磁盘（建议 50GB+）→ 完成。但命令行一次把 UEFI/TPM/virtio 都配好，反而省心。

## 4. 连接控制台安装系统

用 VNC 客户端连宿主机的 5900 端口（或直接在宿主机上打开 virt-manager）。

### 安装过程中加载 virtio 驱动

到选择磁盘那一步，列表会是**空的**——因为 Win11 认不出 virtio 磁盘。点"加载驱动程序"，浏览到 virtio-win 光驱，选择：

- 磁盘驱动：`viostor\w11\amd64`（新版镜像为 `vioscsi` 的按需选择）
- 网卡驱动：`NetKVM\w11\amd64`

加载后磁盘就出现了，选中继续安装。

### 绕过联网检查（不能联网继续安装的问题）

Win11 家庭版/专业版 OOBE 会强制要求联网登录微软账号。在 OOBE 界面按 **Shift + F10** 打开 cmd，输入：

```cmd
oobe\BypassNRO
```

虚拟机自动重启后，就会出现"我没有 Internet 连接"选项，可以以本地账户继续安装。

# 六、安装后的收尾

## 弹出已挂载的 ISO

装完系统后，把安装镜像和驱动镜像都弹掉：

```bash
# 先查看当前挂载的 ISO
sudo virsh domblklist win11
# 输出类似：
# 目标     源
# ------------------------------------------------
# vda      /home/zhoujianwei/libvirt-images/win11.qcow2
# sda      /home/zhoujianwei/libvirt-images/Win11.iso
# sdb      /home/zhoujianwei/libvirt-images/virtio-win.iso

# 虚拟机运行中，弹出光驱
sudo virsh change-media win11 sda --eject
sudo virsh change-media win11 sdb --eject

# 如果虚拟机已关机（shut off），用 detach-disk（需要 --config）
sudo virsh detach-disk win11 sda --config
sudo virsh detach-disk win11 sdb --config

# 验证已取消
sudo virsh domblklist win11
```

# 七、常用管理命令

```bash
# 查看所有虚拟机
sudo virsh list --all

# 启动/关闭虚拟机
sudo virsh start win11
sudo virsh shutdown win11
sudo virsh destroy win11  # 强制关闭

# 删除虚拟机（保留磁盘）
sudo virsh undefine win11

# 设置开机自启
sudo virsh autostart win11

# 编辑虚拟机配置
sudo virsh edit win11

# 查看存储池 / 存储卷
sudo virsh pool-list --all
sudo virsh vol-list default
```

# 八、性能优化与常见问题

## 性能优化

```bash
# 启用 KSM（内存合并，跑多台虚拟机时很有用）
sudo systemctl enable --now ksm
```

- CPU 设置为 `host-passthrough` 获得最佳性能（本文的 virt-install 已配置）
- Windows 虚拟机务必使用 virtio 驱动（磁盘 + 网卡）

## 常见问题

**Q: 权限错误**
将用户加入 libvirt 组后需注销重新登录：`sudo usermod -aG libvirt $USER`

**Q: 无法启动虚拟机**

```bash
# 检查服务状态
sudo systemctl status libvirtd

# 查看日志
sudo journalctl -u libvirtd -f
```

**Q: 删除虚拟机后磁盘未释放**

```bash
# 手动删除磁盘文件
sudo rm /var/lib/libvirt/images/虚拟机名.qcow2
```

# 九、总结

KVM 相比 VirtualBox 的优势：

- ✅ 完全免费开源
- ✅ 原生集成 Linux 内核
- ✅ 性能接近物理机
- ✅ 资源占用更低
- ✅ 适合服务器和生产环境

装 Win11 的几个坑再总结一遍：**UEFI 启动、TPM 2.0、virtio 驱动加载、OOBE 联网绕过**，把这四点提前处理好，整个安装过程和装普通系统没什么区别。适合场景：开发环境、服务器虚拟化、云平台、容器运行时。

> 提示：首次使用建议通过 virt-manager 图形界面操作，熟悉后再使用命令行。
