helm repo add jqcharts https://jinquan0.github.io/helm-charts
helm repo update
helm repo list
helm search repo jqcharts/solar
## 拉取chart到本地，需要修改values.yaml
helm pull jqcharts/solar
tar -xvf solar-0.x.0.tgz

### logstash ETL instance
helm install logetl-test-jinquan-0 jqcharts/logetl --namespace infra --create-namespace \
  --set replicaCount=1 \
  --set etl.Name=mytest0 \
  --set etl.Kafka.Topic=test-jinquan-0 \
  --set etl.Kafka.ConsumerGroup=jinquan \
  --set etl.ElasticSearch.Index=test-jinquan-0-%{+yyyy.MM}


### rockylinux: 不做nodeAffinity
helm upgrade -i rockylinux jqcharts/rockylinux --namespace myapp \
  --create-namespace \
  --set awsEC2Affinity.enabled=false \
  --set ingress.enabled=false \
  --set image.tag="8.6-clnts-build4"

### rockylinux: 指定调度到 具备标签 eks.amazonaws.com/capacityType = ON_DEMAND 的节点
helm upgrade -i rockylinux-ondemand jqcharts/rockylinux --namespace myapp \
  --create-namespace \
  --set awsEC2Affinity.matchKey=eks.amazonaws.com/capacityType \
  --set awsEC2Affinity.matchValue=ON_DEMAND \
  --set ingress.enabled=false \
  --set image.tag="8.6-clnts-build4"


### Solar: 无ingress, 无数据持久化
helm install solar . --namespace myapp \
  --create-namespace \
  --set awsEC2Affinity.enabled=false \
  --set ingress.enabled=false \
  --set appConfig.enabled=true \
  --set liveProbe.enabled=false

### Solar: 指定目标MySQL数据库
helm install solar jqcharts/solar --namespace myapp \
  --create-namespace \
  --set image.tag="2.1-master-build30" \
  --set awsEC2Affinity.enabled=false \
  --set ingress.enabled=false \
  --set liveProbe.enabled=false \
  --set appConfig.enabled=true \
  --set appConfig.Mysql.Host=\"EngineLB-3e73fd6a3c003cc1.elb.cn-northwest-1.amazonaws.com.cn\" \
  --set appConfig.Mysql.Port=\"3307\" \
  --set appConfig.Mysql.User=\"root\" \
  --set appConfig.Mysql.Pass=\"root\" \
  --set appConfig.Mysql.Sslca=\"none\" \
  --set appConfig.Mysql.DB=\"test\"

### Solar:  部署无数据持久化的应用
helm upgrade -i solar . --namespace myapp \
  --set awsEC2Affinity.enabled=false \
  --set appConfig.enabled=true \
  --set liveProbe.enabled=false \
  --set image.repository=registry.cn-hangzhou.aliyuncs.com/jinquan711/solar-system \
  --set image.tag="2.1-master-build30" \
  --set ingress.albsubnets[0].id=subnet-04b55239c3ca6fa44,ingress.albsubnets[1].id=subnet-0c8ab305b476722ae,ingress.albsubnets[2].id=subnet-0ba834929a282e111 \
  --set ingress.albcert=arn:aws-cn:iam::523497193792:server-certificate/wildcard_supor_com_2022 \
  --set ingress.albgroup="is" \
  --set ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=Prefix,ingress.hosts[0].host=cdp-solar.supor.com


### Solar: 部署数据持久化的应用
helm upgrade -i demo1 . --namespace myapp \
  --set awsEC2Affinity.enabled=false \
  --set appConfig.enabled=true \
  --set liveProbe.enabled=false \
  --set efsId=fs-0e02dec118454b10f \
  --set podStaticPvc.enabled=true,podStaticPvc.capacity=5Mi \
  --set ingress.albsubnets[0].id=subnet-04b55239c3ca6fa44,ingress.albsubnets[1].id=subnet-0c8ab305b476722ae,ingress.albsubnets[2].id=subnet-0ba834929a282e111 \
  --set ingress.albcert=arn:aws-cn:iam::523497193792:server-certificate/wildcard_supor_com_2022 \
  --set ingress.albgroup="is" \
  --set ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=Prefix,ingress.hosts[0].host=is-demo1.supor.com

# echo-server 拉取测试web页面
kubectl exec -ti pod/demo1-awsecho-xxxxxxxxxx-***** -n myapp -- git clone https://github.com/jinquan0/is-demo-html.git "/app/assets/"


## 灰度发布 canary-demo服务
helm install canary . --namespace myapp --create-namespace --set fullnameOverride=canary