FROM ubuntu:20.04
MAINTAINER .Ricardo.

ARG PROXY
WORKDIR /root

RUN apt update && apt install ca-certificates -y
RUN mv /etc/apt/sources.list /etc/apt/sources_backup.list && \
  echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse">> /etc/apt/sources.list && \
  echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse">> /etc/apt/sources.list && \
  echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse">> /etc/apt/sources.list && \
  echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse">> /etc/apt/sources.list

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
RUN apt-get update && apt-get install -y git vim tmux zsh curl wget gcc g++ cmake make net-tools telnet iputils-ping build-essential pkg-config libgtk-3-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev gfortran openexr libatlas-base-dev python3 ipython3 python3-pip python3-dev python3-numpy libtbb2 libtbb-dev openssh-server tree htop locales unzip zip unrar rar
RUN sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
  dpkg-reconfigure --frontend=noninteractive locales && \
  update-locale LANG=zh_CN.UTF-8
ENV LANG zh_CN.UTF-8
RUN apt install -y tzdata \
  && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN usermod -s /bin/zsh root && git config --global http.https://github.com.proxy ${PROXY} \
  && sh -c "$(curl -x ${PROXY} -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" \
  && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
  && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
  && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k \
  && sed -i "s/(git)/(git zsh-autosuggestions zsh-syntax-highlighting)/g" ~/.zshrc \
  && sed -i "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/g" ~/.zshrc \
  && echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc
RUN git clone https://github.com/gpakosz/.tmux.git ~/.tmux \
  && ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf \
  && sed -i "s/set -g prefix2 C-a/set -g prefix C-j/g" ~/.tmux.conf \
  && sed -i "s/bind C-a send-prefix -2/bind C-j send-prefix/g" ~/.tmux.conf \
  && sed -i "s/set -g history-limit 5000/set -g history-limit 10000/g" ~/.tmux.conf \
  && sed -i "5 i set\ -g\ mouse\ on" ~/.tmux.conf
COPY .tmux.conf.local .tmux.conf.local
RUN wget -O anaconda.sh https://repo.anaconda.com/archive/Anaconda3-2021.11-Linux-x86_64.sh \
  && bash anaconda.sh -b -p /usr/local/anaconda3 \
  && export PATH=/usr/local/anaconda3/bin:$PATH \
  && conda config --set auto_activate_base false \
  && conda create -n tr-venv python=3.6.9 pip --yes \
  && /bin/bash -c ". activate tr-venv && pip install --upgrade pip && pip install -i https://pypi.tuna.tsinghua.edu.cn/simple requests rich opencv-python httpx tqdm" \
  && echo 'PATH=/usr/local/anaconda3/bin:/usr/local/anaconda3/envs/py3/bin:$PATH' >> ~/.zshrc \
  && rm anaconda.sh && mkdir ~/.pip \
  && echo "[global]" >> ~/.pip/pip.conf \
  && echo "trusted-host = mirrors.aliyun.com" >> ~/.pip/pip.conf \
  && echo "index-url = http://mirrors.aliyun.com/pypi/simple" >> ~/.pip/pip.conf \
  && echo "extra-index-url = https://nexus-h.tianrang-inc.com/repository/pypi/simple" >> ~/.pip/pip.conf \
  && source activate && conda deactivate
ENV HTTPS_PROXY=${PROXY}
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
  && ~/.fzf/install --all
RUN apt autoremove -y \
  && apt clean -y \
  && rm -rf /var/lib/apt/lists/*
RUN mkdir /var/run/sshd && echo 'root:ricardo' | chpasswd \
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
  && echo "export VISIBLE=now" >> /etc/profile
ENV PATH=/root/.local/bin:${PATH}
RUN wget -e "HTTPS_PROXY=${PROXY}" https://github.com/neovim/neovim/releases/download/v0.7.2/nvim-linux64.deb \
  && apt install ./nvim-linux64.deb && rm ./nvim-linux64.deb \
  && curl -x ${PROXY} -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh > install_lunarvim.sh \
  && export PATH=/root/.local/bin:$PATH \
  && bash install_lunarvim.sh --no-install-dependencies && rm install_lunarvim.sh \
  && echo "alias vim=lvim"
RUN wget -e "HTTPS_PROXY=${PROXY}" -O filebrowser.tar.gz https://github.com/filebrowser/filebrowser/releases/download/v2.22.3/linux-amd64-filebrowser.tar.gz \
  && mkdir -p /usr/local/filebrowser \
  && tar zxvf filebrowser.tar.gz -C /usr/local/filebrowser/ \
  && ln -s /usr/local/filebrowser/filebrowser /usr/bin/filebrowser \
  && rm filebrowser.tar.gz
RUN wget -e "HTTPS_PROXY=${PROXY}" -O exa.zip https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip \
  && mkdir -p /usr/local/exa \
  && unzip exa.zip -d /usr/local/exa \
  && ln -s /usr/local/exa/bin/exa /usr/bin/exa \
  && echo "alias ls=exa" >> ~/.zshrc \
  && rm exa.zip
RUN echo "alias gri=\"git rebase -i\"" >> ~/.zshrc \
  && echo "alias grc=\"git rebase --continue\"" >> ~/.zshrc \
  && echo "alias gra=\"git rebase --abort\"" >> ~/.zshrc \
  && echo "alias ll=ls -al" >> ~/.zshrc
RUN ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa \
  && echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDjUY+vlMaYlXqvimKQKbFgGRLARBPCT4p0/JUVEVCxC6Q7r7LqzP53EeArPJEfmdx4uC6DiQWebhVZo8GtiM/rOJO5OPJEQxQomLQpGowgMJTAH4KIqwfa+wCsdPd3fn3VO5phR2kaRELAmRZncvFsrIzzF+nl2VKxU4hzL27mKQ== geekricardo@GeekdeMacBook-Pro.local" >> ~/.ssh/authorized_keys 
CMD ["/bin/zsh"]
