FROM ginuerzh/hugo:0.40.1 AS hugo

WORKDIR /src

ADD . .

RUN hugo 

FROM nginx:1.18-alpine

COPY --from=hugo /src/public /usr/share/nginx/html
