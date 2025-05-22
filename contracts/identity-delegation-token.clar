;; Identity Delegation Token Contract
;; Tokenizes delegation relationships for easier management

(define-non-fungible-token delegation-token uint)

;; Counter for token IDs
(define-data-var token-id-counter uint u0)

;; Map to store token metadata
(define-map token-metadata
  uint
  {
    delegator: principal,
    delegate: principal,
    created-at: uint
  })

;; Map to track tokens by delegation relationship
(define-map delegation-to-token
  { delegator: principal, delegate: principal }
  uint)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-EXISTS u101)
(define-constant ERR-NOT-FOUND u102)

;; Mint a new delegation token
(define-public (mint-delegation-token (delegate principal))
  (let
    (
      (new-id (+ (var-get token-id-counter) u1))
      (delegation-key { delegator: tx-sender, delegate: delegate })
    )

    ;; Check if delegation exists and is active
    (asserts! (contract-call? .delegation-authorization is-delegated tx-sender delegate) (err ERR-NOT-FOUND))

    ;; Check if token already exists for this delegation
    (asserts! (is-none (map-get? delegation-to-token delegation-key)) (err ERR-ALREADY-EXISTS))

    ;; Mint the token
    (try! (nft-mint? delegation-token new-id tx-sender))

    ;; Update metadata
    (map-set token-metadata new-id
      {
        delegator: tx-sender,
        delegate: delegate,
        created-at: block-height
      })

    ;; Update delegation-to-token mapping
    (map-set delegation-to-token delegation-key new-id)

    ;; Update counter
    (var-set token-id-counter new-id)

    (ok new-id)))

;; Get token metadata
(define-read-only (get-token-metadata (token-id uint))
  (map-get? token-metadata token-id))

;; Get token ID for a delegation
(define-read-only (get-token-for-delegation (delegator principal) (delegate principal))
  (map-get? delegation-to-token { delegator: delegator, delegate: delegate }))

;; Burn token when delegation is revoked
(define-public (burn-delegation-token (token-id uint))
  (let ((token-owner (unwrap! (nft-get-owner? delegation-token token-id) (err ERR-NOT-FOUND)))
        (metadata (unwrap! (map-get? token-metadata token-id) (err ERR-NOT-FOUND))))

    ;; Only token owner can burn
    (asserts! (is-eq tx-sender token-owner) (err ERR-NOT-AUTHORIZED))

    ;; Burn the token
    (try! (nft-burn? delegation-token token-id token-owner))

    ;; Clean up metadata
    (map-delete token-metadata token-id)

    ;; Clean up delegation-to-token mapping
    (map-delete delegation-to-token { delegator: (get delegator metadata), delegate: (get delegate metadata) })

    (ok true)))
