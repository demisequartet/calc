FROM tomcat:10-jdk15-openjdk-slim

RUN mkdir /webapps
RUN cd /webapps && mkdir /sample

ADD calc.jsp /usr/local/tomcat/webapps/sample/calc.jsp
ADD normalize.css /usr/local/tomcat/webapps/sample/normalize.css
ADD style.css /usr/local/tomcat/webapps/sample/style.css
ADD mysql-connector-java-8.0.22.jar /usr/local/tomcat/lib/mysql-connector-java-8.0.22.jar


# docker build -t ttta .
# docker run -d --rm -p 8888:8080 --name ttta ttta

#   http://localhost:8888/sample/calc.jsp

# docker stop ttta
