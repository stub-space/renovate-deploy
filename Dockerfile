FROM docker.io/ubuntu:24.04
RUN apt update
RUN apt upgrade -y
RUN apt install curl -y
RUN apt install openssl -y

CMD ["sh"]
