FROM ubuntu:latest
RUN apt-get -y update && apt-get install -y
RUN apt-get -y install clang
COPY . /usr/src/dockertest
WORKDIR /usr/src/dockertest
RUN clang++ -o main.out main.cpp
CMD ["./main.out"]
