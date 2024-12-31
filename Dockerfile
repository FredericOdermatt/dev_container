# syntax=docker/dockerfile:1.4
FROM ubuntu:24.04

# Locales
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
RUN apt-get update && apt-get install -y locales && locale-gen en_US.UTF-8
ENV XDG_CONFIG_HOME=/home/devuser/.config

# Create a user with a home directory
RUN useradd -ms /bin/bash devuser

# Common packages
RUN apt-get update && apt-get install -y \
      build-essential \
      ca-certificates \
      curl \
      git  \
      iputils-ping \
      jq \
      libncurses5-dev \
      libevent-dev \
      net-tools \
      netcat-openbsd \
      rubygems \
      ruby-dev \
      silversearcher-ag \
      socat \
      software-properties-common \
      tmux \
      tzdata \
      vim \
      wget \
      zsh 

RUN  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin


# Add Docker's official GPG key
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
RUN chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update
RUN apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

RUN chsh -s /usr/bin/zsh devuser

RUN --mount=type=secret,id=github_token \
    bash -c 'git clone https://$(cat /run/secrets/github_token)@github.com/FredericOdermatt/my_dotfiles.git /home/devuser/.chezmoi && \
             chown -R devuser:devuser /home/devuser/.chezmoi'

USER devuser
WORKDIR /home/devuser
RUN chezmoi init --apply /home/devuser/.chezmoi
RUN ln -s -f .tmux/.tmux.conf
RUN cp /home/devuser/.tmux/.tmux.conf.local /home/devuser/

ENTRYPOINT ["/usr/bin/zsh"]
