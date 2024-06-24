FROM ubuntu:22.04

ARG USERNAME=odoo
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# -x 打印命令
# -o pipefail 确保全部命令成功
SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# 设置语言环境
ENV LANG en_US.UTF-8

# 安装依赖
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    # sed -i 's/archive.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list && \
    # sed -i 's/cn.archive.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    git \
    openssh-server \
    fail2ban \
    python3-pip \
    python3-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libsasl2-dev \
    libldap2-dev \
    build-essential \
    libssl-dev \
    libffi-dev \
    libmysqlclient-dev \
    libpq-dev \
    libjpeg8-dev \
    liblcms2-dev \
    libblas-dev \
    libatlas-base-dev \
    curl \
    python3-venv \
    python3.10-venv \
    fontconfig \
    libxrender1 \
    xfonts-75dpi \
    xfonts-base \
    gnupg \
    node-less \
    npm \
    && curl -o wkhtmltox.deb -sSL \
    https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb \
    # https://hongtai-idi.com/upload/wkhtmltox_0.12.6.1-3.jammy_amd64.deb \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g rtlcss && npm cache clean --force
# RUN npm install -g rtlcss --registry=https://registry.npmmirror.com && npm cache clean --force

# 安装 pg 客户端
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV ODOO_VERSION 17.0

WORKDIR /home/odoo/publish/apps/odoo/src

COPY ./src/requirements.txt .

RUN pip3 install --no-cache-dir --default-timeout=100 -r requirements.txt
# RUN pip3 install --no-cache-dir --default-timeout=100 -r requirements.txt -i "https://mirrors.aliyun.com/pypi/simple"

EXPOSE 8069 8071 8072

USER $USERNAME

CMD ["python3","odoo-bin", "-c", "../odoo.conf"]
