# Docker Notes

Notes to help make 

List/remove an image

```{shell}
docker images -a
docker rmi {{Image ID}}
```

Make a new image

```{shell}
docker build -t my-python-app ./app
```

list/stop/remove a container

```{shell}
docker ps -a
docker kill {{Container ID}}
docker rm {{Container ID}}
```

Shell into a container that has [Python][python] installed

```{shell}
docker run -it python:3
```