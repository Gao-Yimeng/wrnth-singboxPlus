FROM alpine:3.20

RUN apk add --no-cache wget tar busybox-extras

WORKDIR /app

COPY NOTICE.txt .

RUN wget https://github.com/SagerNet/sing-box/releases/download/v1.13.13/sing-box-1.13.13-linux-amd64.tar.gz && \
    tar -zxvf sing-box-1.13.13-linux-amd64.tar.gz && \
    mv sing-box-1.13.13-linux-amd64/sing-box ./ && \
    rm -rf sing-box-1.13.13-linux-amd64*

COPY config.json .

RUN mkdir -p /www && echo "OK" > /www/index.html

EXPOSE 8080

CMD sh -c 'busybox httpd -f -p 8081 -h /www & ./sing-box run -c config.json'
