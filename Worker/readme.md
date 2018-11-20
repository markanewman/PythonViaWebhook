--- list/remove an image --

docker images -a
docker rmi {{Image ID}}

--- make a new image --- 

cd "C:\Users\mnewman\Desktop\Docker"
docker build -t my-python-console ./console
docker build -t my-python-app ./app

--- list/stop/remove a container---

docker ps -a
docker kill {{Container ID}}
docker rm {{Container ID}}

--- shell into a container ---

docker run -it python:3
docker run -it my-python-console
docker run -it my-python-app

docker start {{Container ID}}


-----------
https://blogs.technet.microsoft.com/uktechnet/2018/04/04/run-your-python-script-on-demand-with-azure-container-instances-and-azure-logic-apps/