#!/bin/bash
set -e

# Default values
NODE_HOME=${NODE_HOME:-/crypto-chain}
CHAIN_ID=${CHAIN_ID:-crypto-org-chain-mainnet-1}
SEEDS=${SEEDS:-"87c3adb7d8f649c51eebe0d3335d8f9e28c362f2@seed-0.crypto.org:26656,e1d7ff02b78044795371bff704cf45875dd9c8e9@seed-1.crypto.org:26656,2c55809558a4e491e9995962e10c026eb9014655@seed-2.crypto.org:26656"}
GENESIS_URL=${GENESIS_URL:-"https://raw.githubusercontent.com/crypto-org-chain/mainnet/main/crypto-org-chain-mainnet-1/genesis.json"}
GENESIS_SHA256=${GENESIS_SHA256:-"d299dcfee6ae29ca280006eaa065799552b88b978e423f9ec3d8ab531873d882"}
QUICKSYNC_URL=${QUICKSYNC_URL:-"https://dl2.quicksync.io/crypto-org-chain-mainnet-1-default.20250415.2140.tar.lz4"}

# Function to initialize the node
init_node() {
    if [ ! -f "$NODE_HOME/config/genesis.json" ]; then
        echo "Initializing node..."
        chain-maind init --chain-id "$CHAIN_ID" node --home "$NODE_HOME"

        # Download genesis file
        echo "Downloading genesis file..."
        curl -s "$GENESIS_URL" > "$NODE_HOME/config/genesis.json.download"

        # Verify genesis file checksum
        echo "Verifying genesis file integrity..."
        DOWNLOADED_SHA256=$(sha256sum "$NODE_HOME/config/genesis.json.download" | awk '{print $1}')

        if [ "$DOWNLOADED_SHA256" != "$GENESIS_SHA256" ]; then
            echo "ERROR: Genesis file checksum verification failed!"
            echo "Expected: $GENESIS_SHA256"
            echo "Received: $DOWNLOADED_SHA256"
            exit 1
        else
            echo "Genesis file checksum verification successful."
            mv "$NODE_HOME/config/genesis.json.download" "$NODE_HOME/config/genesis.json"
        fi
    else
        echo "Node already initialized."
    fi

    # Configure node
    echo "Configuring node..."
    # Set seeds
    sed -i "s/^seeds =.*/seeds = \"$SEEDS\"/" "$NODE_HOME/config/config.toml"

    # Configure RPC and API endpoints
    sed -i 's/^laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/' ${CONFIG_DIR}/config.toml
    sed -i 's/^enable = false/enable = true/' ${CONFIG_DIR}/app.toml
    sed -i 's/^address = "tcp:\/\/localhost:1317"/address = "tcp:\/\/0.0.0.0:1317"/' ${CONFIG_DIR}/app.toml

    # Enable Prometheus metrics
    sed -i 's/^prometheus =.*/prometheus = true/' "$NODE_HOME/config/config.toml"
    # Set minimum gas prices
    sed -i 's/^minimum-gas-prices =.*/minimum-gas-prices = "0.025basecro"/' "$NODE_HOME/config/app.toml"
}

# Function to download and apply quicksync data
quicksync_only() {
    if [ ! -d "$NODE_HOME/data/application.db" ]; then
        echo "Downloading quicksync data..."
        mkdir -p "$NODE_HOME/data"
        curl -L "$QUICKSYNC_URL" | lz4 -dc - | tar xf - -C "$NODE_HOME"
        echo "Quicksync data download complete."
    else
        echo "QuickSync data already exists."
    fi
}

# Function to start the node
start_node() {
    echo "Starting Crypto.org node..."
    chain-maind start --home "$NODE_HOME"
}

# Main execution based on command
case "$1" in
    init)
        init_node
        ;;
    quicksync-only)
        init_node
        quicksync_only
        ;;
    start)
        # Check if data exists, if not, perform quicksync
        if [ ! -d "$NODE_HOME/data/application.db" ]; then
            quicksync_only
        fi
        start_node
        ;;
    *)
        exec "$@"
        ;;
esac