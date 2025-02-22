# syntax=docker/dockerfile:1.4
ARG DEVUSER=devuser
# Add build arguments for installation modes
ARG INSTALL_VSCODE=false
ARG INSTALL_NVIM=false

FROM ubuntu:24.04
ENV DEVUSER=devuser
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV XDG_CONFIG_HOME=/home/${DEVUSER}/.config

# Install locales
RUN apt-get update && \
    apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Common packages
RUN apt-get update && \
      apt-get install -y --no-install-recommends \
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
      sudo \
      tmux \
      tzdata \
      vim \
      wget \
      zsh && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/*

# Neovim installation (conditional)
ARG INSTALL_NVIM
RUN if [ "$INSTALL_NVIM" = "true" ]; then \
      add-apt-repository ppa:neovim-ppa/unstable -y && \
      apt-get update && \
      apt-get install -y --no-install-recommends \
          make \
          gcc \
          ripgrep \
          unzip \
          git \
          xclip \
          neovim && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* ; \
    fi

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Create a user with a home directory
RUN useradd -ms /bin/bash ${DEVUSER}
RUN usermod -aG sudo ${DEVUSER}  # requires sudo package
RUN chown -R ${DEVUSER}:${DEVUSER} /home/${DEVUSER}

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
    bash -c 'git clone https://$(cat /run/secrets/chezmoi_read_token)@github.com/FredericOdermatt/my_dotfiles.git /home/${DEVUSER}/.chezmoi && \
             chown -R ${DEVUSER}:${DEVUSER} /home/${DEVUSER}/.chezmoi'

USER ${DEVUSER}
WORKDIR /home/${DEVUSER}

# Install Oh My Zsh
RUN RUNZSH=no CHSH=yes KEEP_ZSHRC=yes bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Powerlevel10k theme and Zsh plugins
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/${DEVUSER}/.oh-my-zsh/custom/themes/powerlevel10k && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/${DEVUSER}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git /home/${DEVUSER}/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone https://github.com/agkozak/zsh-z /home/${DEVUSER}/.oh-my-zsh/custom/plugins/zsh-z

# Apply chezmoi configuration
RUN chezmoi init --apply /home/${DEVUSER}/.chezmoi

# Symlink and copy tmux config
RUN ln -s -f .tmux/.tmux.conf
RUN cp /home/${DEVUSER}/.tmux/.tmux.conf.local /home/${DEVUSER}/

# Install VS Code server (conditional)
ARG INSTALL_VSCODE
RUN if [ "$INSTALL_VSCODE" = "true" ]; then \
      curl -fsSL https://update.code.visualstudio.com/latest/server-linux-x64/stable -o /tmp/vscode-server.tar.gz && \
      mkdir -p /home/${DEVUSER}/.vscode-server/bin && \
      tar -xzf /tmp/vscode-server.tar.gz -C /home/${DEVUSER}/.vscode-server/bin && \
      rm /tmp/vscode-server.tar.gz ; \
    fi

# Install nvim plugins (conditional)
ARG INSTALL_NVIM
RUN if [ "$INSTALL_NVIM" = "true" ]; then \
      nvim --headless +':Lazy! sync' +qa ; \
    fi

ENTRYPOINT ["tmux", "new", "-A", "-s", "main"]