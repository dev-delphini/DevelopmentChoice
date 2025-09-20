
;; title: DevelopmentChoice
;; version: 1.0.0
;; summary: A user feedback system for application improvements and new feature selection
;; description: This contract allows users to submit feedback proposals for application
;;              improvements and new features, and enables community voting on these proposals.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VOTED (err u102))
(define-constant ERR_INVALID_PROPOSAL_TYPE (err u103))
(define-constant ERR_PROPOSAL_EXPIRED (err u104))
(define-constant ERR_INSUFFICIENT_FUNDS (err u105))

(define-constant CONTRACT_OWNER tx-sender)
(define-constant PROPOSAL_COST u1000000) ;; 1 STX in microSTX
(define-constant VOTING_PERIOD u144) ;; ~24 hours in blocks (assuming 10 min blocks)

;; Proposal types
(define-constant PROPOSAL_TYPE_FEATURE u1)
(define-constant PROPOSAL_TYPE_IMPROVEMENT u2)
(define-constant PROPOSAL_TYPE_BUG_FIX u3)

;; data vars
(define-data-var next-proposal-id uint u1)
(define-data-var total-proposals uint u0)

;; data maps
;; Stores proposal details
(define-map proposals
  { proposal-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposer: principal,
    proposal-type: uint,
    created-at: uint,
    expires-at: uint,
    votes-for: uint,
    votes-against: uint,
    is-active: bool
  }
)

;; Tracks user votes on proposals
(define-map user-votes
  { proposal-id: uint, voter: principal }
  { vote: bool, voted-at: uint }
)

;; Tracks user's total voting activity
(define-map user-stats
  { user: principal }
  { proposals-created: uint, votes-cast: uint }
)

;; public functions

;; Submit a new feedback proposal
(define-public (submit-proposal (title (string-ascii 100))
                               (description (string-ascii 500))
                               (proposal-type uint))
  (let ((proposal-id (var-get next-proposal-id))
        (current-block block-height))
    ;; Validate proposal type
    (asserts! (or (is-eq proposal-type PROPOSAL_TYPE_FEATURE)
                  (or (is-eq proposal-type PROPOSAL_TYPE_IMPROVEMENT)
                      (is-eq proposal-type PROPOSAL_TYPE_BUG_FIX)))
              ERR_INVALID_PROPOSAL_TYPE)

    ;; Check if user has enough STX for proposal fee
    (try! (stx-transfer? PROPOSAL_COST tx-sender CONTRACT_OWNER))

    ;; Store the proposal
    (map-set proposals
      { proposal-id: proposal-id }
      {
        title: title,
        description: description,
        proposer: tx-sender,
        proposal-type: proposal-type,
        created-at: current-block,
        expires-at: (+ current-block VOTING_PERIOD),
        votes-for: u0,
        votes-against: u0,
        is-active: true
      }
    )

    ;; Update user stats
    (map-set user-stats
      { user: tx-sender }
      (merge
        (default-to { proposals-created: u0, votes-cast: u0 }
                    (map-get? user-stats { user: tx-sender }))
        { proposals-created: (+ (get proposals-created
                                    (default-to { proposals-created: u0, votes-cast: u0 }
                                                (map-get? user-stats { user: tx-sender })))
                               u1) }
      )
    )

    ;; Increment counters
    (var-set next-proposal-id (+ proposal-id u1))
    (var-set total-proposals (+ (var-get total-proposals) u1))

    (ok proposal-id)
  )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
        (current-block block-height))

    ;; Check if proposal exists and is active
    (asserts! (get is-active proposal) ERR_PROPOSAL_NOT_FOUND)

    ;; Check if voting period has not expired
    (asserts! (<= current-block (get expires-at proposal)) ERR_PROPOSAL_EXPIRED)

    ;; Check if user has not voted yet
    (asserts! (is-none (map-get? user-votes { proposal-id: proposal-id, voter: tx-sender }))
              ERR_ALREADY_VOTED)

    ;; Record the vote
    (map-set user-votes
      { proposal-id: proposal-id, voter: tx-sender }
      { vote: vote-for, voted-at: current-block }
    )

    ;; Update proposal vote counts
    (if vote-for
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-for: (+ (get votes-for proposal) u1) })
      )
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-against: (+ (get votes-against proposal) u1) })
      )
    )

    ;; Update user stats
    (map-set user-stats
      { user: tx-sender }
      (merge
        (default-to { proposals-created: u0, votes-cast: u0 }
                    (map-get? user-stats { user: tx-sender }))
        { votes-cast: (+ (get votes-cast
                             (default-to { proposals-created: u0, votes-cast: u0 }
                                         (map-get? user-stats { user: tx-sender })))
                        u1) }
      )
    )

    (ok true)
  )
)

;; Deactivate an expired proposal (can be called by anyone)
(define-public (close-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
    ;; Check if proposal has expired
    (asserts! (> block-height (get expires-at proposal)) ERR_PROPOSAL_EXPIRED)

    ;; Deactivate the proposal
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { is-active: false })
    )

    (ok true)
  )
)

;; read only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

;; Get user's vote on a specific proposal
(define-read-only (get-user-vote (proposal-id uint) (user principal))
  (map-get? user-votes { proposal-id: proposal-id, voter: user })
)

;; Get user statistics
(define-read-only (get-user-stats (user principal))
  (default-to { proposals-created: u0, votes-cast: u0 }
              (map-get? user-stats { user: user }))
)

;; Get total number of proposals
(define-read-only (get-total-proposals)
  (var-get total-proposals)
)

;; Get next proposal ID
(define-read-only (get-next-proposal-id)
  (var-get next-proposal-id)
)

;; Check if a proposal is still active for voting
(define-read-only (is-proposal-active (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (and (get is-active proposal)
                  (<= block-height (get expires-at proposal)))
    false
  )
)

;; Get proposal results
(define-read-only (get-proposal-results (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (some {
      proposal-id: proposal-id,
      title: (get title proposal),
      votes-for: (get votes-for proposal),
      votes-against: (get votes-against proposal),
      total-votes: (+ (get votes-for proposal) (get votes-against proposal)),
      is-active: (get is-active proposal),
      expires-at: (get expires-at proposal)
    })
    none
  )
)

;; private functions
;;

