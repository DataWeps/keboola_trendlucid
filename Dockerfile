FROM quay.io/keboola/base-ruby:latest
MAINTAINER Jan Mosat <mosat@weps.cz>

RUN yum -y update && yum clean all

WORKDIR . /home/

COPY . /home/

RUN gem install typhoeus

ENTRYPOINT ruby /home/download_csv.rb
