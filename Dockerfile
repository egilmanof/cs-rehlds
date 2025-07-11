FROM ubuntu:22.04 AS builder

ARG RCON_PASSWORD
ARG MAXPLAYERS
ARG MAP
ARG SV_REGION

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget ca-certificates tar \
    git cmake build-essential \
    zlib1g-dev zlib1g-dev:i386 \
    lib32gcc-s1 gcc-multilib g++-multilib \
    libc6-dev-i386 libstdc++6:i386 \
    libcurl4-gnutls-dev:i386 \
    libssl3:i386 \
    sed \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /steamcmd && cd /steamcmd && \
    wget -q "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" && \
    tar -xzf steamcmd_linux.tar.gz && \
    rm steamcmd_linux.tar.gz

RUN git clone https://github.com/rehlds/rehlds.git /rehlds && \
    cd /rehlds && \
    git checkout $(git describe --tags $(git rev-list --tags --max-count=1)) && \
    git submodule update --init --recursive && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DHLDS_PLATFORM=linux && \
    make -j$(nproc)

RUN mkdir -p /app/server && \
    /steamcmd/steamcmd.sh +force_install_dir /app/server +login anonymous +app_set_config 90 mod cstrike +app_update 90 validate +quit

RUN cp -r /rehlds/build/* /app/server/ && \
    chmod +x /app/server/hlds_linux

RUN mkdir -p /root/.steam/sdk32 && \
    cp /steamcmd/linux32/steamclient.so /root/.steam/sdk32/ && \
    cp /steamcmd/linux32/steamclient.so /app/server/

RUN mkdir -p /app/server/cstrike
COPY ./configs /app/server/cstrike/

RUN sed -i "s/^rcon_password \".*\"/rcon_password \"${RCON_PASSWORD}\"/" /app/server/cstrike/server.cfg && \
    sed -i "s/^maxplayers .*/maxplayers ${MAXPLAYERS}/" /app/server/cstrike/server.cfg && \
    sed -i "s/^sv_region .*/sv_region ${SV_REGION}/" /app/server/cstrike/server.cfg

FROM ubuntu:22.04

ENV MAXPLAYERS=32
ENV MAP=de_dust2
ENV RCON_PASSWORD="SECURE_PASSWORD_123!"
ENV SV_REGION=255

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    lib32gcc-s1 libc6-i386 libstdc++6:i386 \
    libcurl4-gnutls-dev:i386 \
    libssl3:i386 \
    lib32z1 \
    libtinfo5:i386 \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app /app
COPY --from=builder /root/.steam /root/.steam

ENV LD_LIBRARY_PATH="/app/server:/root/.steam/sdk32"
WORKDIR /app/server

EXPOSE 27015/tcp 27015/udp

CMD ["sh", "-c", "./hlds_linux -game cstrike -autoupdate -strictportbind -ip 0.0.0.0 -port 27015 +map ${MAP} +maxplayers ${MAXPLAYERS} +sv_region ${SV_REGION} +rcon_password ${RCON_PASSWORD} +exec server.cfg"]