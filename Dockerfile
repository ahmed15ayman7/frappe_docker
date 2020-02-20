# Frappe Bench Dockerfile

FROM debian:buster-slim
LABEL author=frappé

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales \
  && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set locale en_us.UTF-8 for mariadb and general locale data
ENV PYTHONIOENCODING=utf-8
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install all neccesary packages (note: python-minimal is required by nodejs, less is needed by MariaDB monitor)
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-suggests --no-install-recommends \
  build-essential cron curl git less libffi-dev liblcms2-dev libldap2-dev libmariadbclient-dev libsasl2-dev libssl-dev libtiff5-dev \
  libwebp-dev mariadb-client iputils-ping python-minimal python3-dev python3-pip python3-setuptools python3-tk redis-tools rlwrap \
  software-properties-common sudo tk8.6-dev vim xfonts-75dpi xfonts-base wget wkhtmltopdf fonts-cantarell \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && curl https://deb.nodesource.com/node_12.x/pool/main/n/nodejs/nodejs_12.16.1-1nodesource1_amd64.deb > node.deb \
  && dpkg -i node.deb \
  && rm node.deb \
  && npm install -g yarn

# Install wkhtmltox correctly
RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb
RUN dpkg -i wkhtmltox_0.12.5-1.buster_amd64.deb && rm wkhtmltox_0.12.5-1.buster_amd64.deb

# Add frappe user and setup sudo
RUN groupadd -g 500 frappe \
  && useradd -ms /bin/bash -u 500 -g 500 -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/frappe \
  && chown -R 500:500 /home/frappe

# Install bench
RUN pip3 install -e git+https://github.com/frappe/bench.git#egg=bench --no-cache

USER frappe

# Add some bench files
COPY --chown=frappe:frappe ./frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

EXPOSE 8000 9000 6787

VOLUME [ "/home/frappe/frappe-bench" ]
