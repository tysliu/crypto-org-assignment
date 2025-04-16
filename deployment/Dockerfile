FROM alpine:3.14

RUN apk add --no-cache ca-certificates jq curl bash lz4 tar

WORKDIR /tmp

ENV CHAIN_MAIND_VERSION="4.2.14"
ENV BINARY_URL="https://github.com/crypto-org-chain/chain-main/releases/download/v${CHAIN_MAIND_VERSION}/chain-main_${CHAIN_MAIND_VERSION}_Linux_x86_64.tar.gz"

# Download and install the chain-maind binary
RUN curl -L ${BINARY_URL} -o chain-main.tar.gz \
    && tar -xzf chain-main.tar.gz \
    && mv bin/chain-maind /usr/local/bin/ \
    && chmod +x /usr/local/bin/chain-maind \
    && rm -rf /tmp/*

# Create directories
RUN mkdir -p /crypto-chain/config /crypto-chain/data

WORKDIR /crypto-chain

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 26656 26657 1317 9090

ENTRYPOINT ["entrypoint.sh"]
CMD ["start"]