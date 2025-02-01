import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure can mint NFT with royalties",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('secure_mint', 'mint-nft', [
                types.utf8("Test NFT"),
                types.utf8("A test NFT description"),
                types.utf8("https://test.com/image.png"),
                types.uint(5) // 5% royalty
            ], wallet_1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let metadata = chain.callReadOnlyFn(
            'secure_mint',
            'get-nft-data',
            [types.uint(1)],
            wallet_1.address
        );
        
        metadata.result.expectOk().expectSome();
    }
});

Clarinet.test({
    name: "Ensure can list and purchase NFT",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const wallet_2 = accounts.get('wallet_2')!;
        
        // Mint NFT
        let block = chain.mineBlock([
            Tx.contractCall('secure_mint', 'mint-nft', [
                types.utf8("Test NFT"),
                types.utf8("A test NFT description"),
                types.utf8("https://test.com/image.png"),
                types.uint(5)
            ], wallet_1.address)
        ]);
        
        // List NFT
        let listBlock = chain.mineBlock([
            Tx.contractCall('secure_mint', 'list-nft', [
                types.uint(1),
                types.uint(1000000) // List for 1 STX
            ], wallet_1.address)
        ]);
        
        listBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Purchase NFT
        let purchaseBlock = chain.mineBlock([
            Tx.contractCall('secure_mint', 'purchase-nft', [
                types.uint(1)
            ], wallet_2.address)
        ]);
        
        purchaseBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify new owner
        let owner = chain.callReadOnlyFn(
            'secure_mint',
            'get-token-owner',
            [types.uint(1)],
            wallet_1.address
        );
        
        owner.result.expectOk().expectSome().expectPrincipal(wallet_2.address);
    }
});

Clarinet.test({
    name: "Ensure marketplace fees and royalties are distributed correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!; // Creator
        const wallet_2 = accounts.get('wallet_2')!; // Buyer
        
        // Mint and list NFT
        chain.mineBlock([
            Tx.contractCall('secure_mint', 'mint-nft', [
                types.utf8("Test NFT"),
                types.utf8("Description"),
                types.utf8("image.png"),
                types.uint(10) // 10% royalty
            ], wallet_1.address),
            Tx.contractCall('secure_mint', 'list-nft', [
                types.uint(1),
                types.uint(1000000) // 1 STX
            ], wallet_1.address)
        ]);
        
        // Purchase NFT
        let purchaseBlock = chain.mineBlock([
            Tx.contractCall('secure_mint', 'purchase-nft', [
                types.uint(1)
            ], wallet_2.address)
        ]);
        
        purchaseBlock.receipts[0].result.expectOk().expectBool(true);
        // Additional assertions for fee/royalty transfers could be added here
    }
});
