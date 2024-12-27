import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure can mint NFT",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('secure_mint', 'mint-nft', [
                types.utf8("Test NFT"),
                types.utf8("A test NFT description"),
                types.utf8("https://test.com/image.png")
            ], wallet_1.address)
        ]);
        
        // Assert successful mint
        block.receipts[0].result.expectOk().expectUint(1);
        
        // Verify metadata
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
    name: "Ensure can transfer NFT",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const wallet_2 = accounts.get('wallet_2')!;
        
        // First mint an NFT
        let block = chain.mineBlock([
            Tx.contractCall('secure_mint', 'mint-nft', [
                types.utf8("Test NFT"),
                types.utf8("A test NFT description"),
                types.utf8("https://test.com/image.png")
            ], wallet_1.address)
        ]);
        
        // Now transfer it
        let transferBlock = chain.mineBlock([
            Tx.contractCall('secure_mint', 'transfer-nft', [
                types.uint(1),
                types.principal(wallet_2.address)
            ], wallet_1.address)
        ]);
        
        transferBlock.receipts[0].result.expectOk().expectBool(true);
        
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
    name: "Ensure cannot mint duplicate token ID",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        
        // First mint
        chain.mineBlock([
            Tx.contractCall('secure_mint', 'mint-nft', [
                types.utf8("Test NFT 1"),
                types.utf8("First NFT"),
                types.utf8("https://test.com/1.png")
            ], wallet_1.address)
        ]);
        
        // Attempt duplicate mint
        let block = chain.mineBlock([
            Tx.contractCall('secure_mint', 'mint-nft', [
                types.utf8("Test NFT 1"),
                types.utf8("First NFT"),
                types.utf8("https://test.com/1.png")
            ], wallet_1.address)
        ]);
        
        // Should fail
        block.receipts[0].result.expectOk().expectUint(2);
    }
});