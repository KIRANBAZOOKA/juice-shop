FROM node:22 AS installer
ARG AWS_SECRET=AKIAVULNERABLE1234567890
ARG DB_PASS=JuiceShopAdmin2025!
ENV AWS_SECRET=$AWS_SECRET
ENV DB_PASS=$DB_PASS

COPY . /juice-shop
WORKDIR /juice-shop

# ✅ CREATE SECRETS HERE (node:22 has shell)
RUN mkdir -p /juice-shop/config && \
    echo "API_KEY=sk-live-vulnerable123456789" > /juice-shop/config/api_key.txt && \
    echo "GITHUB_TOKEN=ghp_vuln123EXAMPLEtoken" > /juice-shop/config/github_token.txt && \
    echo "DB_PASSWORD=$DB_PASS" > /juice-shop/config/db_pass.txt && \
    chmod 644 /juice-shop/config/*.txt

# Original Juice Shop steps (unchanged)
RUN npm i -g typescript ts-node
RUN npm install --omit=dev --unsafe-perm
RUN npm dedupe --omit=dev
RUN rm -rf frontend/node_modules
RUN rm -rf frontend/.angular
RUN rm -rf frontend/src/assets
RUN mkdir logs
RUN chown -R 65532 logs
RUN chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/
RUN chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/
RUN rm data/chatbot/botDefaultTrainingData.json || true
RUN rm ftp/legal.md || true
RUN rm i18n/*.json || true

ARG CYCLONEDX_NPM_VERSION=latest
RUN npm install -g @cyclonedx/cyclonedx-npm@$CYCLONEDX_NPM_VERSION
RUN npm run sbom

FROM gcr.io/distroless/nodejs22-debian12
ARG BUILD_DATE
ARG VCS_REF
ARG AWS_SECRET
ARG DB_PASS
ENV AWS_SECRET=$AWS_SECRET
ENV DB_PASS=$DB_PASS

LABEL org.opencontainers.image.title="Juice Shop Vulnerable Secrets"

WORKDIR /juice-shop
# ✅ COPY EVERYTHING (including secrets) from installer
COPY --from=installer --chown=65532:0 /juice-shop .
USER 65532
EXPOSE 3000
CMD ["/juice-shop/build/app.js"]
