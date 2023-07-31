FROM ubuntu:latest

EXPOSE 8080

WORKDIR /app

COPY ./main main

CMD [ "./main" ]