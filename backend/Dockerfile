FROM oven/bun:1

WORKDIR /backend

COPY package.json bun.lock ./
RUN bun install

COPY . .
EXPOSE 3030
CMD ["bun","start"]