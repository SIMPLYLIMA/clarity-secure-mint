;; SecureMint - Secure NFT Minting Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-exists (err u102))
(define-constant err-token-not-found (err u103))

;; Data Variables
(define-data-var last-token-id uint u0)

;; Define NFT token
(define-non-fungible-token secure-nft uint)

;; Data Maps
(define-map token-metadata uint 
    {
        name: (string-utf8 256),
        description: (string-utf8 1024),
        image-uri: (string-utf8 256),
        created-at: uint
    }
)

(define-map token-ownership uint principal)

;; Private Functions
(define-private (is-owner (token-id uint))
    (is-eq (some tx-sender) (map-get? token-ownership token-id))
)

;; Public Functions
(define-public (mint-nft (name (string-utf8 256)) 
                        (description (string-utf8 1024))
                        (image-uri (string-utf8 256)))
    (let
        (
            (token-id (+ (var-get last-token-id) u1))
        )
        (asserts! (is-none (nft-get-owner? secure-nft token-id)) err-token-exists)
        
        ;; Mint token
        (try! (nft-mint? secure-nft token-id tx-sender))
        
        ;; Store metadata
        (map-set token-metadata token-id
            {
                name: name,
                description: description,
                image-uri: image-uri,
                created-at: block-height
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
        (try! (nft-transfer? secure-nft token-id tx-sender recipient))
        (map-set token-ownership token-id recipient)
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