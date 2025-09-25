FROM node:18-slim AS base

WORKDIR /usr/src/wpp-server

# Evita descargar Chromium con Puppeteer si no lo necesitás en esta etapa
ENV NODE_ENV=production \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Instalación de dependencias necesarias (reemplazo de apk → apt)
RUN apt-get update && apt-get install -y \
    libvips-dev \
    libfftw3-dev \
    gcc \
    g++ \
    make \
    libc6 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY package.json ./

RUN yarn install --production --ignore-engines --pure-lockfile && \
    yarn add sharp --ignore-engines && \
    yarn cache clean

# Etapa de build separada para compilar el código
FROM base AS build

WORKDIR /usr/src/wpp-server
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

COPY package.json ./
RUN yarn install --production=false --pure-lockfile && yarn cache clean

COPY . .
RUN yarn build

# Etapa final (producción)
FROM base

WORKDIR /usr/src/wpp-server/

# Instalación de Chromium (para Puppeteer)
RUN apt-get update && apt-get install -y chromium && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY . .
COPY --from=build /usr/src/wpp-server/ /usr/src/wpp-server/

EXPOSE 21465
ENTRYPOINT ["node", "dist/server.js"]
