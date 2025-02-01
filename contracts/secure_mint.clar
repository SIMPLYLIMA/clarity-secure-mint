;; SecureMint - Secure NFT Minting Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-exists (err u102))
(define-constant err-token-not-found (err u103))
(define-constant err-invalid-royalty (err u104))
(define-constant err-listing-not-found (err u105))
(define-constant err-insufficient-funds (err u106))

;; Data Variables
(define-data-var last-token-id uint u0)
(define-data-var marketplace-fee uint u25) ;; 2.5% fee stored as basis points

;; Define NFT token
(define-non-fungible-token secure-nft uint)

;; Data Maps
(define-map token-metadata uint 
    {
        name: (string-utf8 256),
        description: (string-utf8 1024),
        image-uri: (string-utf8 256),
        created-at: uint,
        royalty: uint,
        creator: principal
    }
)

(define-map token-ownership uint principal)

(define-map marketplace-listings uint 
    {
        price: uint,
        seller: principal,
        active: bool
    }
)

;; Private Functions
(define-private (is-owner (token-id uint))
    (is-eq (some tx-sender) (map-get? token-ownership token-id))
)

(define-private (transfer-token (token-id uint) (sender principal) (recipient principal))
    (begin
        (try! (nft-transfer? secure-nft token-id sender recipient))
        (map-set token-ownership token-id recipient)
        (ok true)
    )
)

(define-private (pay-royalties (token-id uint) (payment uint))
    (let (
        (metadata (unwrap! (map-get? token-metadata token-id) err-token-not-found))
        (royalty-amount (/ (* payment (get royalty metadata)) u1000))
        (creator (get creator metadata))
    )
    (if (> royalty-amount u0)
        (as-contract (stx-transfer? royalty-amount tx-sender creator))
        (ok true))
    )
)

;; Public Functions
(define-public (mint-nft (name (string-utf8 256)) 
                        (description (string-utf8 1024))
                        (image-uri (string-utf8 256))
                        (royalty uint))
    (let
        (
            (token-id (+ (var-get last-token-id) u1))
        )
        (asserts! (is-none (nft-get-owner? secure-nft token-id)) err-token-exists)
        (asserts! (<= royalty u100) err-invalid-royalty)
        
        ;; Mint token
        (try! (nft-mint? secure-nft token-id tx-sender))
        
        ;; Store metadata
        (map-set token-metadata token-id
            {
                name: name,
                description: description,
                image-uri: image-uri,
                created-at: block-height,
                royalty: (* royalty u10), ;; Store as basis points
                creator: tx-sender
            }
        )
        
        ;; Set ownership
        (map-set token-ownership token-id tx-sender)
        
        ;; Update counter
        (var-set last-token-id token-id)
        
        (ok token-id)
    )
)

(define-public (transfer-nft (token-id uint) (recipient principal))
    (begin
        (asserts! (is-owner token-id) err-not-token-owner)
        (try! (transfer-token token-id tx-sender recipient))
        (ok true)
    )
)

(define-public (list-nft (token-id uint) (price uint))
    (begin
        (asserts! (is-owner token-id) err-not-token-owner)
        (map-set marketplace-listings token-id
            {
                price: price,
                seller: tx-sender,
                active: true
            }
        )
        (ok true)
    )
)

(define-public (unlist-nft (token-id uint))
    (begin
        (asserts! (is-owner token-id) err-not-token-owner)
        (map-delete marketplace-listings token-id)
        (ok true)
    )
)

(define-public (purchase-nft (token-id uint))
    (let (
        (listing (unwrap! (map-get? marketplace-listings token-id) err-listing-not-found))
        (price (get price listing))
        (seller (get seller listing))
        (marketplace-cut (/ (* price (var-get marketplace-fee)) u1000))
        (seller-amount (- price marketplace-cut))
    )
        (asserts! (get active listing) err-listing-not-found)
        
        ;; Transfer payment
        (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
        (try! (as-contract (stx-transfer? seller-amount tx-sender seller)))
        (try! (pay-royalties token-id price))
        
        ;; Transfer NFT
        (try! (transfer-token token-id seller tx-sender))
        
        ;; Clear listing
        (map-delete marketplace-listings token-id)
        
        (ok true)
    )
)

;; Admin Functions
(define-public (set-marketplace-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u100) err-invalid-royalty)
        (var-set marketplace-fee new-fee)
        (ok true)
    )
)

;; Read Only Functions
(define-read-only (get-nft-data (token-id uint))
    (ok (map-get? token-metadata token-id))
)

(define-read-only (get-token-owner (token-id uint))
    (ok (map-get? token-ownership token-id))
)

(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

(define-read-only (get-listing (token-id uint))
    (ok (map-get? marketplace-listings token-id))
)

(define-read-only (get-marketplace-fee)
    (ok (var-get marketplace-fee))
)
