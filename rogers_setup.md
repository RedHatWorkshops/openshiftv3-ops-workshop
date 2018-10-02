### Rogers Workshop  

Overview of Environment  

Master: 18.191.99.4
Master URL: https://rogers.demo.osecloud.com  

Node Names:  

ip-172-31-9-185.us-east-2.compute.internal    Ready     master    1d        v1.10.0+b81c8f8  
ip-172-31-13-63.us-east-2.compute.internal    Ready     infra     23h       v1.10.0+b81c8f8  
ip-172-31-10-155.us-east-2.compute.internal   Ready     compute   23h       v1.10.0+b81c8f8 RESERVED, DO NOT USE  
ip-172-31-32-245.us-east-2.compute.internal   Ready     compute   23h       v1.10.0+b81c8f8  ocpadmin1  
ip-172-31-38-13.us-east-2.compute.internal    Ready     compute   23h       v1.10.0+b81c8f8  ocpadmin2  
ip-172-31-39-45.us-east-2.compute.internal    Ready     compute   23h       v1.10.0+b81c8f8  ocpadmin3  
ip-172-31-6-34.us-east-2.compute.internal     Ready     compute   23h       v1.10.0+b81c8f8  ocpadmin4 
ip-172-31-9-167.us-east-2.compute.internal    Ready     compute   23h       v1.10.0+b81c8f8  ocpadmin5  


There are several admininstrative accounts created on the cluster  

Please choose one of the following for your lab work

ocpadmin1:ocpadmin1  
ocpadmin2:ocpadmin2  
ocpadmin3:ocpadmin3  
ocpadmin4:ocpadmin4  
ocpadmin5:ocpadmin5  
ocpadmin6:ocpadmin6  
ocpadmin7:ocpadmin7  


Download the ocpadmin.pem file in this git repo files directory  

ensure the file permissions are 0400

```  
$ chmod 400 ocpadmin.pem  
```  

Login into the master server as your ocpadmin account  


```
ssh -i ocpadmin.pem ocpadmin1@18.191.99.4  
```  

Cockpit is installed by default by the installer  

To Login use your credentials above at the following url:  

https://rogers.demo.osecloud.com:9090  




