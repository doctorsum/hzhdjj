FROM kalilinux/kali-rolling:latest

ENV DEBIAN_FRONTEND=noninteractive \
	TZ=Europe/Paris
ARG JUPYTER_TOKEN
# Remove any third-party apt sources to avoid issues with expiring keys.
# Install some basic utilities
RUN rm -f /etc/apt/sources.list.d/*.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    aria2 \
    iproute2 \
    libkmod2 \
    libkmod-dev \
    expect \
    kmod \
    sudo \
    git \
    iptables \
    wget \
    procps \
    expect \
    python3 \
    python3-pip \
    git-lfs \
    isc-dhcp-client \ 
    zip \
    unzip \
    htop \
    vim \
    nano \
    bzip2 \
    libx11-6 \
    build-essential \
    libsndfile-dev \
    software-properties-common \
 && rm -rf /var/lib/apt/lists/*

#RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

RUN apt-get full-upgrade -y 
RUN apt full-upgrade -y
RUN apt update 
RUN apt upgrade -y
RUN apt install kali-desktop-xfce -y
RUN apt install kali-linux-default -y
RUN wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt-get install ./chrome-remote-desktop_current_amd64.deb -y
RUN apt-get install ./google-chrome-stable_current_amd64.deb -y
RUN apt-get install flatpak -y
RUN apt-get install tigervnc-standalone-server -y
# Create a working directory
WORKDIR /app

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos '' --shell /bin/bash user \
 && chown -R user:user /app
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER user

# All users can use /home/user as their home directory
ENV HOME=/home/user
RUN mkdir $HOME/.cache \
 && chmod -R 777 $HOME

# Set up the Conda environment
ENV CONDA_AUTO_UPDATE_CONDA=false \
    PATH=$HOME/miniconda/bin:$PATH
RUN curl -sLo ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh \
 && chmod +x ~/miniconda.sh \
 && ~/miniconda.sh -b -p ~/miniconda \
 && rm ~/miniconda.sh \
 && conda clean -ya

WORKDIR $HOME/app

#######################################
# Start root user section
#######################################

USER root

# User Debian packages
## Security warning : Potential user code executed as root (build time)
RUN --mount=target=/root/packages.txt,source=packages.txt \
    apt-get update && \
    xargs -r -a /root/packages.txt apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=target=/root/on_startup.sh,source=on_startup.sh,readwrite \
	bash /root/on_startup.sh

RUN mkdir /data && chown user:user /data

#######################################
# End root user section
#######################################

USER user

# Python packages
RUN --mount=target=requirements.txt,source=requirements.txt \
    pip install --no-cache-dir --upgrade -r requirements.txt

# Copy the current directory contents into the container at $HOME/app setting the owner to the user
COPY --chown=user . $HOME/app

RUN chmod +x start_server.sh

COPY --chown=user login.html /home/user/miniconda/lib/python3.9/site-packages/jupyter_server/templates/login.html

ENV PYTHONUNBUFFERED=1 \
	GRADIO_ALLOW_FLAGGING=never \
	GRADIO_NUM_PORTS=1 \
	GRADIO_SERVER_NAME=0.0.0.0 \
	GRADIO_THEME=huggingface \
	SYSTEM=spaces \
	SHELL=/bin/bash

USER user
RUN mkdir -p /home/user/.vnc

RUN echo "#!/bin/bash" > passo

RUN echo "expect <<EOF" >> passo

RUN echo "spawn vncpasswd" >> passo

RUN echo 'expect \"Password:\" { send \"$env(JUPYTER_TOKEN)\r\" }' >> passo

RUN echo 'expect \"Verify:\" { send \"$env(JUPYTER_TOKEN)\r\" }' >> passo

RUN echo 'expect \"Would you like to enter a view-only password (y/n)?\" { send \"n\r\" }' >> passo

RUN echo 'expect eof' >> passo

RUN echo 'EOF' >> passo

RUN chmod +x passo

RUN ./passo
RUN pip3 install numpy
# Copy the current directory contents into the container at $HOME/app setting the owner to the user
COPY --chown=user . $HOME/app

RUN chmod +x start_server.sh
CMD ["./start_server.sh"]
