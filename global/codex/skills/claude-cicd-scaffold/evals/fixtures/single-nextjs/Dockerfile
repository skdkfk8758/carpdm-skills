FROM node:20-slim AS build
WORKDIR /app
COPY package*.json ./
RUN --mount=type=secret,id=github_token \
    sh -c 'if [ -f /run/secrets/github_token ]; then \
      { echo "@team-draftype:registry=https://npm.pkg.github.com"; \
        echo "//npm.pkg.github.com/:_authToken=$(cat /run/secrets/github_token)"; } > .npmrc; \
    fi' \
    && npm ci --no-audit --no-fund
COPY . .
RUN npm run build

FROM node:20-slim AS run
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app ./
EXPOSE 3000
CMD ["npm", "start"]
