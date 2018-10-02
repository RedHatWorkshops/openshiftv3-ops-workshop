### Rogers Workshop  

Overview of Environment  

Master: 18.191.99.4
Master URL: https://rogers.demo.osecloud.com  


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




