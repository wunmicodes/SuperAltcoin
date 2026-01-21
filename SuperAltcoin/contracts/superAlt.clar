;; SuperAltcoin - Prediction Market for Top 100 Cryptocurrencies
;; A simple betting contract for predicting if cryptocurrencies stay in top 100

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-market-closed (err u103))
(define-constant err-market-open (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-already-claimed (err u106))

;; Minimum bet amount (100 STX)
(define-constant min-bet u100000000)

;; Data Variables
(define-data-var market-counter uint u0)

;; Data Maps
(define-map markets
  uint
  {
    coin-name: (string-ascii 20),
    end-block: uint,
    is-resolved: bool,
    stayed-in-top100: bool,
    total-yes-bets: uint,
    total-no-bets: uint
  }
)

(define-map bets
  {market-id: uint, bettor: principal}
  {
    amount: uint,
    bet-yes: bool,
    has-claimed: bool
  }
)

;; Read-only functions
(define-read-only (get-market (market-id uint))
  (map-get? markets market-id)
)

(define-read-only (get-bet (market-id uint) (bettor principal))
  (map-get? bets {market-id: market-id, bettor: bettor})
)

(define-read-only (get-market-count)
  (ok (var-get market-counter))
)

(define-read-only (calculate-payout (market-id uint) (bettor principal))
  (let
    (
      (market (unwrap! (get-market market-id) err-not-found))
      (bet (unwrap! (get-bet market-id bettor) err-not-found))
      (bet-amount (get amount bet))
      (bet-yes (get bet-yes bet))
      (stayed (get stayed-in-top100 market))
      (total-yes (get total-yes-bets market))
      (total-no (get total-no-bets market))
    )
    (if (get is-resolved market)
      (if (is-eq bet-yes stayed)
        ;; Winner calculation
        (let
          (
            (winning-pool (if stayed total-yes total-no))
            (losing-pool (if stayed total-no total-yes))
            (total-pool (+ winning-pool losing-pool))
          )
          (if (is-eq winning-pool u0)
            (ok u0)
            (ok (/ (* bet-amount total-pool) winning-pool))
          )
        )
        (ok u0) ;; Loser gets nothing
      )
      err-market-open
    )
  )
)

;; Public functions
(define-public (create-market (coin-name (string-ascii 20)) (duration-blocks uint))
  (let
    (
      (market-id (+ (var-get market-counter) u1))
      (end-block (+ stacks-block-height duration-blocks))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set markets market-id
      {
        coin-name: coin-name,
        end-block: end-block,
        is-resolved: false,
        stayed-in-top100: false,
        total-yes-bets: u0,
        total-no-bets: u0
      }
    )
    (var-set market-counter market-id)
    (ok market-id)
  )
)

(define-public (place-bet (market-id uint) (bet-yes bool) (amount uint))
  (let
    (
      (market (unwrap! (get-market market-id) err-not-found))
      (existing-bet (get-bet market-id tx-sender))
    )
    (asserts! (>= amount min-bet) err-insufficient-funds)
    (asserts! (< stacks-block-height (get end-block market)) err-market-closed)
    (asserts! (is-none existing-bet) err-already-exists)
    
    ;; Transfer STX from bettor to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Record bet
    (map-set bets
      {market-id: market-id, bettor: tx-sender}
      {
        amount: amount,
        bet-yes: bet-yes,
        has-claimed: false
      }
    )
    
    ;; Update market totals
    (map-set markets market-id
      (merge market
        {
          total-yes-bets: (if bet-yes 
            (+ (get total-yes-bets market) amount)
            (get total-yes-bets market)),
          total-no-bets: (if bet-yes
            (get total-no-bets market)
            (+ (get total-no-bets market) amount))
        }
      )
    )
    (ok true)
  )
)

(define-public (resolve-market (market-id uint) (stayed-in-top100 bool))
  (let
    (
      (market (unwrap! (get-market market-id) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= stacks-block-height (get end-block market)) err-market-open)
    (asserts! (not (get is-resolved market)) err-already-exists)
    
    (map-set markets market-id
      (merge market
        {
          is-resolved: true,
          stayed-in-top100: stayed-in-top100
        }
      )
    )
    (ok true)
  )
)

(define-public (claim-winnings (market-id uint))
  (let
    (
      (market (unwrap! (get-market market-id) err-not-found))
      (bet (unwrap! (get-bet market-id tx-sender) err-not-found))
      (payout (unwrap! (calculate-payout market-id tx-sender) err-market-open))
    )
    (asserts! (get is-resolved market) err-market-open)
    (asserts! (not (get has-claimed bet)) err-already-claimed)
    (asserts! (> payout u0) err-insufficient-funds)
    
    ;; Mark as claimed
    (map-set bets
      {market-id: market-id, bettor: tx-sender}
      (merge bet {has-claimed: true})
    )
    
    ;; Transfer winnings
    (as-contract (stx-transfer? payout tx-sender tx-sender))
  )
)