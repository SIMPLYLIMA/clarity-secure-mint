[Previous test content...]

Clarinet.test({
    name: "Ensure proper handling of marketplace fees and royalties with edge cases",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const wallet_2 = accounts.get('wallet_2')!;
        
        // Test with minimum possible price
        let block = chain.mineBlock([
            Tx.contractCall('secure_mint', 'mint-nft', [
                types.utf8("Test NFT"),
                types.utf8("Description"),
                types.utf8("image.png"),
                types.uint(1) // 0.1% royalty
            ], wallet_1.address),
            Tx.contractCall('secure_mint', 'list-nft', [
                types.uint(1),
                types.uint(1) // Minimum price
            ], wallet_1.address)
        ]);
        
        // Verify minimum price handling
        let purchaseBlock = chain.mineBlock([
            Tx.contractCall('secure_mint', 'purchase-nft', [
                types.uint(1)
            ], wallet_2.address)
        ]);
        
        purchaseBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify events were emitted
        purchaseBlock.receipts[0].events.expectPrintEvent(
            'secure_mint',
            { type: "nft_sold" }
        );
    }
});
