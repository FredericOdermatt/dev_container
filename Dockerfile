# syntax=docker/dockerfile:1.4
FROM ubuntu:24.04

# Locales
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
RUN apt-get update && apt-get install -y locales && locale-gen en_US.UTF-8
ENV XDG_CONFIG_HOME=/home/devuser/.config

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
      python3 \
      python3-pip \
      python3-pygments \
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

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
 
# Create a user with a home directory
RUN useradd -ms /bin/bash devuser
RUN apt-get install -y sudo && usermod -aG sudo devuser
RUN chown -R devuser:devuser /home/devuser

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

# Clone your dotfiles with GitHub token
RUN --mount=type=secret,id=chezmoi_read_token \
    bash -c 'git clone https://$(cat /run/secrets/chezmoi_read_token)@github.com/FredericOdermatt/my_dotfiles.git /home/devuser/.chezmoi && \
             chown -R devuser:devuser /home/devuser/.chezmoi'

USER devuser
WORKDIR /home/devuser

# Install Oh My Zsh
RUN RUNZSH=no CHSH=yes KEEP_ZSHRC=yes bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Powerlevel10k theme and Zsh plugins
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/devuser/.oh-my-zsh/custom/themes/powerlevel10k && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/devuser/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git /home/devuser/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone https://github.com/agkozak/zsh-z /home/devuser/.oh-my-zsh/custom/plugins/zsh-z

# Apply chezmoi configuration
RUN chezmoi init --apply /home/devuser/.chezmoi

# Symlink and copy tmux config
RUN ln -s -f .tmux/.tmux.conf
RUN cp /home/devuser/.tmux/.tmux.conf.local /home/devuser/

# Install VS Code server
RUN curl -fsSL https://update.code.visualstudio.com/latest/server-linux-x64/stable -o /tmp/vscode-server.tar.gz && \
    mkdir -p /home/devuser/.vscode-server/bin && \
    tar -xzf /tmp/vscode-server.tar.gz -C /home/devuser/.vscode-server/bin && \
    rm /tmp/vscode-server.tar.gz

ENTRYPOINT ["tmux", "new", "-A", "-s", "main"]
