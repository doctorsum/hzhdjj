#!/bin/bash

git clone https://github.com/novnc/noVNC.git /home/user/noVNC
git clone https://github.com/novnc/websockify /home/user/noVNC/utils/websockify

chmod +x /home/user/noVNC/utils/novnc_proxy
chmod +x /home/user/noVNC/utils/websockify/run

vncserver :0 && \
/home/user/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 0.0.0.0:7860