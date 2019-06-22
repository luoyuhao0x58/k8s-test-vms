# K8S测试环境快速搭建

## 机器架构

目前直接创建三台机器，一台是control-plane，两台是普通节点，三个节点都可以部署pod。

网络使用calico


## 依赖

安装：

- [virtualbox](https://www.virtualbox.org/)
- [vagrant](https://www.vagrantup.com/)
  - [vagrant-reload](https://github.com/aidanns/vagrant-reload)
  - [vagrant-hostmanager](https://github.com/devopsgroup-io/vagrant-hostmanager)

```shell
# macOS安装示例

brew cask install virtualbox
brew cask install vagrant

# 安装vagrant使用的插件
vagrant plugin install vagrant-reload
vagrant plugin install vagrant-hostmanager
```

## 使用

```shell
# 一条指令，创建三台机器并部署k8s集群
vagrant up
```

```shell
vagrant ssh  # 登陆control-plane节点
kubectl cluster-info  # 查看集群
kubectl get pods -A  # 查看calico是否已经准备好，需要一点时间
kubectl get nodes  # 查看集群是否已经准备好
```

```shell
# 删除k8s集群，集群机器变成单独只安装完了依赖的状态
vagrant provision --provision-with remove-kubernetes-cluster
```

```shell
# 删除机器并清理创建的文件
vagrant destroy -f
rm -rf .vagrant
```
