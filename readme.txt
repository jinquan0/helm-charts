helm repo add jqcharts https://jinquan0.github.io/helm-charts
helm repo update
helm repo list
helm search repo jqcharts/jqecho
## 拉取chart到本地，需要修改values.yaml
helm pull jqcharts/awsecho
tar -xvf awsecho-0.x.0.tgz

### 无ingress, 无数据持久化的应用
helm upgrade -i solar . --namespace myapp \
  --create-namespace \
  --set image.repository=docker.io/jinquan711/solar-system \
  --set image.tag="1.2"

###  部署无数据持久化的应用
helm upgrade -i solar . --namespace myapp \
  --set image.repository=docker.io/jinquan711/solar-system \
  --set image.tag="1.2" \
  --set ingress.albsubnets[0].id=subnet-04b55239c3ca6fa44,ingress.albsubnets[1].id=subnet-0c8ab305b476722ae,ingress.albsubnets[2].id=subnet-0ba834929a282e111 \
  --set ingress.albcert=arn:aws-cn:iam::523497193792:server-certificate/wildcard_supor_com_2022 \
  --set ingress.albgroup="is" \
  --set ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=Prefix,ingress.hosts[0].host=cdp-solar.supor.com


###  部署数据持久化的应用
helm upgrade -i demo1 . --namespace myapp \
  --set efsId=fs-0e02dec118454b10f \
  --set podStaticPvc.enabled=true,podStaticPvc.capacity=5Mi \
  --set ingress.albsubnets[0].id=subnet-04b55239c3ca6fa44,ingress.albsubnets[1].id=subnet-0c8ab305b476722ae,ingress.albsubnets[2].id=subnet-0ba834929a282e111 \
  --set ingress.albcert=arn:aws-cn:iam::523497193792:server-certificate/wildcard_supor_com_2022 \
  --set ingress.albgroup="is" \
  --set ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=Prefix,ingress.hosts[0].host=is-demo1.supor.com

# echo-server 拉取测试web页面
kubectl exec -ti pod/demo1-awsecho-xxxxxxxxxx-***** -n myapp -- git clone https://github.com/jinquan0/is-demo-html.git "/app/assets/"
