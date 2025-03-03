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
(define-constant err-invalid-price (err u108))
(define-constant err-zero-address (err u109))

;; Price constraints
(define-constant minimum-price u1)
(define-constant maximum-price u1000000000000)

;; Data Variables
(define-data-var last-token-id uint u0)
(define-data-var marketplace-fee uint u25) ;; 2.5% fee stored as basis points

;; Define NFT token
(define-non-fungible-token secure-nft uint)

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

(define-public (print-listing-event (token-id uint) (price uint) (seller principal))
  (print { type: "nft_listed", token-id: token-id, price: price, seller: seller })
  (ok true))

(define-public (print-unlisting-event (token-id uint) (seller principal))
  (print { type: "nft_unlisted", token-id: token-id, seller: seller })
  (ok true))

;; Modified purchase-nft function with enhanced security
(define-public (purchase-nft (token-id uint))
    (let (
        (listing (unwrap! (map-get? marketplace-listings token-id) err-listing-not-found))
        (price (get price listing))
        (seller (get seller listing))
    )
        ;; Validate inputs
        (asserts! (get active listing) err-listing-not-found)
        (asserts! (is-some seller) err-zero-address)
        (asserts! (<= price maximum-price) err-invalid-price)
        
        ;; Calculate fees
        (let (
            (marketplace-cut (/ (* price (var-get marketplace-fee)) u1000))
            (seller-amount (- price marketplace-cut))
        )
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
        )
    ))

;; Modified listing function with price validation
(define-public (list-nft (token-id uint) (price uint))
    (let ((owner (unwrap! (get-owner token-id) err-token-not-found)))
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (>= price minimum-price) err-invalid-price)
        (asserts! (<= price maximum-price) err-invalid-price)
        
        (map-set marketplace-listings token-id
            { price: price, seller: tx-sender, active: true })
        
        (try! (print-listing-event token-id price tx-sender))
        (ok true)
    ))
