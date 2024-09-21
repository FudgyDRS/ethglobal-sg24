#!/bin/bash

# Check if an RPC URL is provided as an argument
if [ -z "$1" ]; then
  echo "Error: RPC URL is required as an argument."
  echo "Usage: $0 <RPC_URL>"
  exit 1
fi

# Set the RPC URL from the command-line argument
ETHEREUM_HOLESKY_RPC=$1

# Fetch current tip fee (gas price) in Wei from RPC
response=$(curl -s -X POST "$ETHEREUM_HOLESKY_RPC" \
-H "Content-Type: application/json" \
-d '{"jsonrpc":"2.0","method":"eth_maxPriorityFeePerGas","params":[],"id":1}')

# Check if the response is valid
if [ $? -ne 0 ]; then
  echo "Error: Failed to fetch tip fee from RPC."
  exit 1
fi

# Extract the tip fee from the response
tip_fee_hex=$(echo "$response" | jq -r '.result')

# Convert hex to decimal (Wei)
tip_fee_wei=$(printf "%d\n" "$tip_fee_hex")

# Run forge script to check base fee
forge_output=$(forge script ./script/CheckGas.s.sol:CheckGas \
  --rpc-url "$ETHEREUM_HOLESKY_RPC" \
  --private-key "$(cat ./.secret)" \
  --gas-price 20000000000 \
  --legacy \
  --gas-limit 5617584 \
  --broadcast)

# Check if the forge script ran successfully
if [ $? -ne 0 ]; then
  echo "Error: Forge script failed."
  exit 1
fi

# Extract base fee from the forge script output
base_fee=$(echo "$forge_output" | grep "current base fee:" | awk '{print $NF}')

# Check if base fee is empty
if [ -z "$base_fee" ]; then
  echo "Error: Base fee not found in forge script output."
  exit 1
fi

# Convert base fee from Gwei to Wei
base_fee_wei=$(echo "$base_fee * 1000000000" | bc)

# Calculate total gas price in Wei
total_gas_price_wei=$(echo "$base_fee_wei + $tip_fee_wei" | bc)

# Convert total gas price from Wei to Gwei
total_gas_price_gwei=$(echo "scale=9; $total_gas_price_wei / 1000000000" | bc)

echo "Tip fee (in Wei): $tip_fee_wei"
echo "Base fee (in Wei): $base_fee_wei"
echo "Total gas price (in Wei): $total_gas_price_wei"
echo "Total gas price (in Gwei): $total_gas_price_gwei"
