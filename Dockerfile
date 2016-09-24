FROM ruby
MAINTAINER Jan Mosat <mosat@weps.cz>

WORKDIR . /home/

COPY . /home/

RUN gem install typhoeus

ENTRYPOINT ruby /home/download_csv.rb