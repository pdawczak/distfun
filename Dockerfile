FROM amazonlinux:2.0.20200406.0

ENV LANG=C.UTF-8

RUN yum update -y
RUN yum install -y deltarpm
RUN yum groupinstall -y "Development Tools"
RUN yum install -y \
    gcc \
    gcc-c++ \
    make \
    libxslt \
    fop \
    ncurses-devel \
    openssl-devel \
    *openjdk-devel \
    unixODBC \
    unixODBC-devel \
    zip \
    git \
    python \
    wget \
    tar
RUN yum clean all
RUN rm -rf /var/cache/yum

# Install node
RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash - \
          && yum install -y nodejs

# Install Erlang
RUN set -xe \
        && ERL_ARCH="http://erlang.org/download/otp_src_23.0.tar.gz" \
        && ERL_TOP="/usr/src/erlang" \
        && wget -O otp_src.tar.gz "$ERL_ARCH" \
        && mkdir -vp $ERL_TOP \
        && tar -xzf otp_src.tar.gz -C $ERL_TOP --strip-components=1 \
        && rm otp_src.tar.gz \
        && ( cd $ERL_TOP \
                && ./configure \
                && make \
                && make install )

# Install Elixir
RUN set -xe \
        && ELIXIR_ARCH="https://github.com/elixir-lang/elixir/releases/download/v1.10.3/Precompiled.zip" \
        && ELIXIR_TOP="/usr/src/elixir" \
        && mkdir -vp $ELIXIR_TOP \
        && wget -O elixir_src.zip $ELIXIR_ARCH \
        && unzip elixir_src.zip -d $ELIXIR_TOP \
        && rm elixir_src.zip

# Configure Elixir executables
ENV PATH="$PATH:/usr/src/elixir/bin"

WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config

RUN SECRET_KEY_BASE="" mix do deps.get, deps.compile

COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy

COPY lib lib
COPY rel rel

COPY _tools/build.sh build.sh

CMD ./build.sh
