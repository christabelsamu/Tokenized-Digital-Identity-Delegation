;; Delegation Authorization Contract
;; Records permission grants between identities

(define-data-var admin principal tx-sender)

;; Structure to store delegation details
(define-map delegations
  { delegator: principal, delegate: principal }
  { active: bool, created-at: uint })

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-EXISTS u101)
(define-constant ERR-NOT-FOUND u102)

;; Grant delegation permission
(define-public (grant-delegation (delegate principal))
  (let ((delegation-key { delegator: tx-sender, delegate: delegate }))
    (asserts! (is-none (map-get? delegations delegation-key)) (err ERR-ALREADY-EXISTS))
    (map-set delegations
      delegation-key
      { active: true, created-at: block-height })
    (ok true)))

;; Check if delegation exists and is active
(define-read-only (is-delegated (delegator principal) (delegate principal))
  (match (map-get? delegations { delegator: delegator, delegate: delegate })
    delegation (get active delegation)
    false))

;; Get delegation details
(define-read-only (get-delegation (delegator principal) (delegate principal))
  (map-get? delegations { delegator: delegator, delegate: delegate }))
