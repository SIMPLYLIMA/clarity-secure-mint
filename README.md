# SecureMint

A secure and tamper-proof NFT minting platform built on Stacks blockchain with integrated marketplace functionality and royalty support.

## Features

- Secure minting of NFTs with ownership verification
- Prevention of duplicate mints
- Ownership transfer capabilities 
- Metadata storage for NFT attributes
- Admin controls for platform management
- Integrated NFT marketplace with listing and purchasing
- Creator royalties on secondary sales
- Configurable marketplace fees

## Usage

The contract can be interacted with using the following functions:

### Core NFT Functions
- mint-nft: Mint a new NFT with metadata and royalty settings
- transfer-nft: Transfer ownership of an NFT
- get-nft-data: Retrieve NFT metadata
- get-owner: Get current owner of an NFT

### Marketplace Functions
- list-nft: List an NFT for sale with a specified price
- unlist-nft: Remove an NFT listing from the marketplace
- purchase-nft: Purchase a listed NFT
- get-listing: Get details of an NFT listing

### Admin Functions
- set-marketplace-fee: Update the marketplace fee percentage

## Marketplace Features

The integrated marketplace allows NFT owners to:
- List their NFTs for sale
- Set custom prices
- Receive automatic royalty payments on secondary sales
- Benefit from secure ownership transfers

## Royalty System

- Creators can set royalty percentages (up to 10%) during minting
- Royalties are automatically distributed on marketplace sales
- Transparent and immutable royalty tracking

## Fee Structure

- Marketplace fee: 2.5% of sale price
- Creator royalties: Set during minting (max 10%)
- Remaining amount goes to the seller
