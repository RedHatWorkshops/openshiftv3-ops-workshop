#Environment Validation

In this lab you will walk through the steps to validate the environment is working properly.

##Step #1: Create Project

1. login to web UI 
2. Click `Create Project`
3. Enter a project name
4. Click `Create`


##Step #2: Test Build and Deploy a test application

1. Once project is created, web UI will be in the `Browse Catalog` 
2. Click `PHP`
3. Click `Select` in the PHP option with the default version
4. Enter name as `phpapp`
5. Enter Git Repository URL as https://github.com/RedHatWorkshops/welcome-php.git or just click `Try it`
6. Click `Create`
7. Click ` Continue to Overview`
8. Click `Builds` --> `Builds`
9. Click onto `#1` next to phpapp
10. Click `Logs` tab
11. Watch it build and push to registry

	```
	Pushing image docker-registry.default.svc:5000/testme/testapp:latest ...
	Pushed 5/6 layers, 84% complete
	Pushed 6/6 layers, 100% complete
	Push successful
	```
12. Click on `Overview` on the left menu
13. Wait for the solid blue color show on the pod
14. Click onto the route and see if the application is up and running

