helm repo add jqcharts https://jinquan0.github.io/helm-charts
helm repo list
helm search repo jqcharts/jqecho
## 拉取chart到本地，需要修改values.yaml
helm pull jqcharts/awsecho
tar -xvf awsecho-0.1.0.tgz

vi values.yaml
## 根据实际场景调整value参数
efsId: fs-******8c9453d774f
alb.ingress.kubernetes.io/certificate-arn: arn:aws-cn:iam::************:server-certificate/wildcard_supor_com_2022
alb.ingress.kubernetes.io/subnets: subnet-******467280f03e4,subnet-******c419b73be01,subnet-******5dc58822ea8


## 部署多个应用
helm upgrade -i solar . --namespace myapp \
  --set image.repository=docker.io/jinquan711/solar-system \
  --set image.tag="1.2" \
  --set ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=Prefix,ingress.hosts[0].host=cdp-solar.supor.com

helm upgrade -i demo0 . --namespace myapp \
  --set podStaticPvc.enabled=true,podStaticPvc.capacity=5Mi \
  --set ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=Prefix,ingress.hosts[0].host=cdp-demo0.supor.com

helm upgrade -i demo1 . --namespace myapp \
  --set podStaticPvc.enabled=true,podStaticPvc.capacity=5Mi \
  --set ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=Prefix,ingress.hosts[0].host=cdp-demo1.supor.com

helm upgrade -i demo2 . --namespace myapp \
  --set podStaticPvc.enabled=true,podStaticPvc.capacity=5Mi \
  --set ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=Prefix,ingress.hosts[0].host=cdp-demo2.supor.com
