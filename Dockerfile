# FROM ginuerzh/hugo:0.40.1 AS hugo
# WORKDIR /src
# ADD . .
# RUN hugo 

FROM nginx:alpine
# COPY --from=hugo /src/public /usr/share/nginx/html
COPY public /usr/share/nginx/html
