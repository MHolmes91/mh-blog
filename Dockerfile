FROM hugomods/hugo:0.159.2

WORKDIR /src

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN hugo mod get && hugo --gc --minify
