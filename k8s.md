修改 hostname IP地址 hosts 
hostnamectl set-hostname master1

/etc/sysconfig/network-scripts/ifcfg-ens33
BOOTPROTO=none
ONBOOT=yes
IPADDR=192.168.64.101
PREFIX=24
GATEWAY=192.168.64.2
DNS1=119.29.29.29
systemctl restart network

在三个主机中添加hosts
vi /etc/hosts
192.168.1.5 master1
192.168.1.6 worker1
192.168.1.7 worker2

关闭firewalld
firewall-cmd --state
systemctl stop firewalld
systemctl disable firewalld

关闭SELiunx
sestatus getenforce
vim /etc/selinux/config
reboot

时间同步
yum -y install ntpdate
crontab -e
添加0 */1 * * * ntpdate time1.aliyun.com

关闭swap分区
vim /etc/fstab
注释/swap...

添加网桥过滤
vim /etc/sysctl.d/k8s.conf
添加
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
vm.swappiness=0

加载模块  modprobe br_netfilter

查看是否加载 lsmod|grep br_netfilter

加载网桥过滤配置文件 sysctl -p /etc/sysctl.d/k8s.conf

安装配置ipset及ipvsadm
yum -y install ipset ipvsadm
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#! /bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

给文件授权755
chmod 755 /etc/sysconfig/modules/ipvs.modules

执行文件
sh /etc/sysconfig/modules/ipvs.modules 

检查是否加载
lsmod | grep ip_vs_rr

安装下载指定版本的docker-ce
wget -O /etc/yum.repos.d/docker-ce.repo https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo
yum list docker-ce.x86_64 --showduplicates | sort -r
yum -y install --setopt=obsoletes=0 docker-ce-18.06.3.ce-3.el7

开机自启docker
systemctl enable docker
systemctl start docker



新增daemon.json文件
vi /etc/docker/daemon.json
{
	"exec-opts":["native.cgroupdriver=systemd"]
}
systemctl restart docker



修改kube的yum源
vim /etc/yum.repo.d/k8s.repo

[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
              https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg

yum list | grep kubeadm

安装kubeadm kubelet kubectl
yum -y install kubectl-1.18.3
yum -y install kebulet-1.18.3
yum -y install kebuadm-1.18.3



修改kubelet
vim /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"

编写脚本文件
kubeadm config images list >> image.list
修改iamge.list为脚本文件
#!/bin/bash
img_list='k8s.gcr.io/kube-apiserver:v1.18.3
k8s.gcr.io/kube-controller-manager:v1.18.3
k8s.gcr.io/kube-scheduler:v1.18.3
k8s.gcr.io/kube-proxy:v1.18.3
k8s.gcr.io/pause:3.2
k8s.gcr.io/etcd:3.4.13-0
k8s.gcr.io/coredns:1.6.7'

for img in $img_list
do
        docker pull $img

done
执行 sh image.list

或者执行脚本：
docker pull mirrorgcrio/kube-apiserver:v1.18.3
docker pull mirrorgcrio/kube-controller-manager:v1.18.3
docker pull mirrorgcrio/kube-scheduler:v1.18.3
docker pull mirrorgcrio/kube-proxy:v1.18.3
docker pull mirrorgcrio/pause:3.2
docker pull mirrorgcrio/etcd:3.4.3-0
docker pull mirrorgcrio/coredns:1.6.7


docker tag mirrorgcrio/kube-apiserver:v1.18.3 k8s.gcr.io/kube-apiserver:v1.18.3
docker tag mirrorgcrio/kube-controller-manager:v1.18.3 k8s.gcr.io/kube-controller-manager:v1.18.3
docker tag mirrorgcrio/kube-scheduler:v1.18.3 k8s.gcr.io/kube-scheduler:v1.18.3
docker tag mirrorgcrio/kube-proxy:v1.18.3 k8s.gcr.io/kube-proxy:v1.18.3
docker tag mirrorgcrio/pause:3.2 k8s.gcr.io/pause:3.2
docker tag mirrorgcrio/etcd:3.4.3-0 k8s.gcr.io/etcd:3.4.3-0
docker tag mirrorgcrio/coredns:1.6.7 k8s.gcr.io/coredns:1.6.7

docker image rm mirrorgcrio/kube-apiserver:v1.18.3
docker image rm mirrorgcrio/kube-controller-manager:v1.18.3
docker image rm mirrorgcrio/kube-scheduler:v1.18.3
docker image rm mirrorgcrio/kube-proxy:v1.18.3
docker image rm mirrorgcrio/pause:3.2
docker image rm mirrorgcrio/etcd:3.4.3-0
docker image rm mirrorgcrio/coredns:1.6.7

master节点操作
kubeadm init --kubernetes-version=1.18.3 --pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.64.100 > log.txt

安装calico
docker pull calico/cni:v3.13.3
docker pull calico/pod2daemon-flexvol:v3.13.3
docker pull calico/node:v3.13.3
docker pull calico/kube-controllers:v3.13.3

下载calico
wget https://docs.projectcalico.org/manifests/calico-etcd.yaml

master中配置calico-etcd.yaml
-name: IP行下一行面加入
-name: IP_AUTODETECTION_METHOD
value: "interface=ens.*"
添加
-name: CALICO_IPV4POOL_CIDR
value: "172.16.0.0/16"

master中配置calico-etcd.yaml
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f calico-etcd.yaml

worker中
kubeadm join .... (log.txt 中最后一行)

查看kube软件安装状态 rpm -aq | grep kube

work中拷贝master中的 .kube/config 便可以使用kubectl get nodes
mkdir .kube
scp master1:/root/.kube/config .kube



master中
集群状态kubectl get nodes // namespace // pods
集群组件kubectl get pods --namespace kube-system
集群健康kubectl get cs
集群信息kubectl cluster-info
应用yaml文件kubectl apply/create/delete -f 01-create-ns.yaml
操作namesapce命名空间kubectl create/delete ns ns1
操作pod节点kubectl delete pods pod1



01-create-namespace.yaml文件：
apiVersion: v1
kind: Namespace
metadata:
  name: test

02-create-pod.yaml文件：
apiVersion: v1
kind: Pod
metadata:
  name: pod1
spec:
  containers:
  -name: nginx-container
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    ports:
    -name: nginxport
      containerPort: 80



kubectl run nginx-app --image=nginx:latest --image-pull-policy=IfNotPresent --replicas=2
kubectl get deployment // replicaset
