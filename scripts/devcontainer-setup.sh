#!/bin/bash
set -e

echo "🚀 Setting up devcontainer..."

# Fix for git dubious ownership issue in Codespaces
git config --global --add safe.directory /workspaces/fetch-icp-integration

# Install Azle CLI
echo "🔗 Installing Azle CLI..."
npm install -g azle@latest

# Install npm dependencies
echo "📦 Installing npm dependencies..."
cd ic && npm install
cd ..

# Set up dfx identity for codespace
echo "🔑 Setting up dfx identity..."
dfx identity new codespace_dev --storage-mode=plaintext || echo "Identity may already exist"
dfx identity use codespace_dev      
dfx start --background             
dfx stop

# Fix missing pkill on dfx build
apt-get install -y procps

# Set up Fetch Uagents
apt install -y python3-pip
apt install -y python3-venv
python3 -m venv .venv
source .venv/bin/activate
pip install uagents

echo "✅ Devcontainer setup complete!"