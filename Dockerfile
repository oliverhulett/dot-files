FROM docker-registry.aus.optiver.com/servicedelivery/el7-development:latest

RUN yum install -y docker which

RUN yum groupinstall -y "development tools"
RUN yum install -y wget curl telnet postgresql-server postgresql-contrib postgresql freetype-devel libpng-devel python-devel unixODBC-devel postgresql-devel libxml2-devel libxslt-devel
RUN yum install -y cmake ccache distcc protobuf protobuf-c protobuf-python protobuf-compiler valgrind protobuf-vim golang-vim jq clang-devel clang clang-analyzer
RUN yum install -y vagrant yakuake iotop nethogs sysstat aspell aspell-en cifs-utils samba samba-client openssl-libs openssl-static wireshark java-1.8.0-openjdk-devel java-1.8.0-openjdk

RUN yum install -y http://artifactory.aus.optiver.com/artifactory/dev/trd/courier-1.1.0-1.x86_64.rpm

RUN curl -O https://artifactory.aus.optiver.com/artifactory/thirdparty/golang/go1.7.1.linux-amd64.tar.gz && \
	tar -C /usr/local -xzf go1.7.1.linux-amd64.tar.gz && \
	rm -rf go1.7.1.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

RUN curl -O https://artifactory.aus.optiver.com/artifactory/dev/trd/drone_linux_amd64.tar.gz && \
	tar -C /usr/local/bin -xzf drone_linux_amd64.tar.gz && \
	rm drone_linux_amd64.tar.gz

RUN yum install -y python-pip
RUN pip install -U -i http://devpi.aus.optiver.com/optiver/prod/+simple/ --trusted-host devpi.aus.optiver.com pip wheel setuptools
RUN pip install -U -i http://devpi.aus.optiver.com/optiver/prod/+simple/ --trusted-host devpi.aus.optiver.com \
	protobuf==2.5.0 twisted sqlalchemy argparse pyodbc psycopg2==2.5.4 'lxml<3.4' \
	invoke docker-compose devpi pylint


ARG GIT_REV
ARG GIT_REPO
ARG BUILD_USER
ARG BUILD_NUMBER
ARG BUILD_MODIFIED_FILES
LABEL git_revision=$GIT_REV git_repo=$GIT_REPO build_user=$BUILD_USER build_number=$BUILD_NUMBER build_modified_files=$BUILD_MODIFIED_FILES
