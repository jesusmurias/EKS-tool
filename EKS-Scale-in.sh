eksctl scale  nodegroup --cluster=EO-cCM --name CCD --nodes=0 --region=eu-north-1 --profile SSO-Consumer-admin-032443079205
eksctl scale  nodegroup --cluster=EO-cCM --name CCD2 --nodes=0 --region=eu-north-1 --profile SSO-Consumer-admin-032443079205
sleep 30
eksctl get nodegroup --cluster EO-cCM --region eu-north-1 --name CCD --profile SSO-Consumer-admin-032443079205
eksctl get nodegroup --cluster EO-cCM --region eu-north-1 --name CCD2 --profile SSO-Consumer-admin-032443079205
