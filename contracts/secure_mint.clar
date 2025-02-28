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
(define-constant err-math-overflow (err u107))

;; Data Variables
(define-data-var last-token-id uint u0)
(define-data-var marketplace-fee uint u25) ;; 2.5% fee stored as basis points

;; Define NFT token
(define-non-fungible-token secure-nft uint)

;; Data Maps
[Previous maps remain unchanged...]

;; Events
(define-public (print-mint-event (token-id uint) (recipient principal))
  (print { type: "nft_minted", token-id: token-id, recipient: recipient })
  (ok true))

(define-public (print-transfer-event (token-id uint) (sender principal) (recipient principal))
  (print { type: "nft_transferred", token-id: token-id, sender: sender, recipient: recipient })
  (ok true))

(define-public (print-sale-event (token-id uint) (price uint) (seller principal) (buyer principal))
  (print { type: "nft_sold", token-id: token-id, price: price, seller: seller, buyer: buyer })
  (ok true))

;; Private Functions
[Previous private functions remain unchanged...]

;; Modified purchase-nft function with reentrancy protection
(define-public (purchase-nft (token-id uint))
    (let (
        (listing (unwrap! (map-get? marketplace-listings token-id) err-listing-not-found))
        (price (get price listing))
        (seller (get seller listing))
        (marketplace-cut (/ (* price (var-get marketplace-fee)) u1000))
        (seller-amount (- price marketplace-cut))
    )
        (asserts! (get active listing) err-listing-not-found)
        
        ;; Clear listing first (Checks-Effects)
        (map-delete marketplace-listings token-id)
        
        ;; Update ownership (Effects)
        (try! (transfer-token token-id seller tx-sender))
        
        ;; Handle payments last (Interactions)
        (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
        (try! (as-contract (stx-transfer? seller-amount tx-sender seller)))
        (try! (pay-royalties token-id price))
        
        ;; Emit event
        (try! (print-sale-event token-id price seller tx-sender))
        
        (ok true)
    ))

[Remaining functions unchanged...]
