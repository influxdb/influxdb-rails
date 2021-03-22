FROM opensuse/leap:15.2

ENV NOKOGIRI_USE_SYSTEM_LIBRARIES 1
RUN useradd -g users -p rails -d /home/rails -m rails
RUN echo 'rails ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

RUN zypper -n addrepo -f https://dl.yarnpkg.com/rpm/yarn.repo; zypper --gpg-auto-import-keys refresh
RUN zypper -n install --no-recommends ruby2.5-devel nodejs10 make gcc-c++ timezone sudo pkg-config sqlite3-devel libxml2-devel libxslt-devel yarn git-core curl
RUN zypper -n clean -a
RUN gem install --no-format-executable --no-document rails -v '~> 6'

USER rails
WORKDIR /home/rails

RUN rails new thingiverse;

WORKDIR /home/rails/thingiverse
RUN rails g scaffold thing name:string amount:integer
RUN echo 'gem "influxdb-rails", :git => "https://github.com/influxdata/influxdb-rails/", :branch => "master"' >> Gemfile
RUN bundle install; rails webpacker:install; rake db:migrate
RUN sed -i '2i \  root to: "things#index"' config/routes.rb
RUN bundle exec rails generate influxdb
RUN sed -i '2i \  config.client.hosts = "influx"' config/initializers/influxdb_rails.rb
CMD bundle exec rails server -b 0.0.0.0 -p 4000
