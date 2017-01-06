FROM docker-registry.aus.optiver.com/servicedelivery/el7-development:latest

RUN yum groupinstall -y "development tools"
RUN yum install -y docker which iotop nethogs sysstat aspell aspell-en jq protobuf-vim golang-vim \
	openssl-libs openssl-static wireshark java-1.8.0-openjdk-devel java-1.8.0-openjdk wget curl telnet \
	python-devel python-pip libxml2-devel libxslt-devel \
	cmake ccache distcc protobuf protobuf-c protobuf-python protobuf-compiler valgrind clang-devel clang clang-analyzer

ENV export PATH=/usr/lib64/ccache:$PATH

RUN yum install -y http://artifactory.aus.optiver.com/artifactory/dev/trd/courier-1.1.0-1.x86_64.rpm

RUN curl -O https://artifactory.aus.optiver.com/artifactory/thirdparty/golang/go1.7.1.linux-amd64.tar.gz && \
	tar -C /usr/local -xzf go1.7.1.linux-amd64.tar.gz && \
	rm -rf go1.7.1.linux-amd64.tar.gz
ENV GOTOOLS="${HOME}/3rd-party-tools/gotools"
ENV GOPATH="${GOTOOLS}"
ENV PATH=$PATH:/usr/local/go/bin:${GOTOOLS}/bin

RUN curl -O https://artifactory.aus.optiver.com/artifactory/dev/trd/drone_linux_amd64.tar.gz && \
	tar -C /usr/local/bin -xzf drone_linux_amd64.tar.gz && \
	rm drone_linux_amd64.tar.gz

RUN pip install -U -i http://devpi.aus.optiver.com/optiver/prod/+simple/ --trusted-host devpi.aus.optiver.com pip wheel setuptools
RUN pip install -U -i http://devpi.aus.optiver.com/optiver/prod/+simple/ --trusted-host devpi.aus.optiver.com \
	protobuf==2.5.0 twisted argparse 'lxml<3.4' \
	invoke docker-compose devpi pylint \
	optitest optimockservers exchange-simulator bop_boilerplate


ARG GIT_REV
ARG GIT_REPO
ARG BUILD_USER
ARG BUILD_NUMBER
ARG BUILD_MODIFIED_FILES
LABEL git_revision=$GIT_REV git_repo=$GIT_REPO build_user=$BUILD_USER build_number=$BUILD_NUMBER build_modified_files=$BUILD_MODIFIED_FILES
