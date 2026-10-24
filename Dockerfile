ARG IMAGE=intersystemsdc/irishealth-community:2020.3.0.200.0-zpm
ARG IMAGE=intersystemsdc/iris-community:2020.4.0.547.0-zpm
ARG IMAGE=containers.intersystems.com/intersystems/iris:2021.1.0.215.0
ARG IMAGE=intersystemsdc/irishealth-community
ARG IMAGE=intersystemsdc/iris-community
ARG IMAGE=intersystemsdc/iris-community:preview
ARG IMAGE=intersystems/iris-community:latest-cd
FROM $IMAGE

WORKDIR /home/irisowner/dev

## install git
## USER root
##RUN apt update && apt-get -y install git
##USER ${ISC_PACKAGE_MGRUSER}

ARG TESTS=0
ARG MODULE="dc-sample"
ARG NAMESPACE="IRISAPP"

## Embedded Python environment
ENV IRISUSERNAME "_SYSTEM"
ENV IRISPASSWORD "SYS"
ENV IRISNAMESPACE $NAMESPACE
ENV PYTHON_PATH=/usr/irissys/bin/
ENV PATH "/usr/irissys/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/irisowner/bin"

COPY .iris_init /home/irisowner/.iris_init
RUN wget https://pm.community.intersystems.com/packages/zpm/latest/installer -O /tmp/zpm.xml

USER root
RUN mkdir -p /data/IRISAPP_DATA/ /data/IRISAPP_DATA/irisapp_dataenstemp /data/IRISAPP_DATA/irisapp_datasecondary && \
    chown irisowner:irisowner /data/ -R
USER ${ISC_PACKAGE_MGRUSER}


RUN --mount=type=bind,src=.,dst=. \
    iris start IRIS && \
    iris merge iris ./merge.cpf && \
	iris session IRIS < iris.script && \
    ([ $TESTS -eq 0 ] || iris session iris -U $NAMESPACE "##class(%ZPM.PackageManager).Shell(\"test $MODULE -v -only\",1,1)") && \
    iris stop IRIS quietly
