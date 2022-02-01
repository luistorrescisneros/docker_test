FROM ubuntu:latest
RUN apt-get -y update && apt-get install -y
RUN apt-get -y install g++
RUN apt-get update && apt-get install make
COPY . /usr/src/dockertest
WORKDIR /usr/src/dockertest
RUN make -f Makefile
CMD ["./a.out"]
