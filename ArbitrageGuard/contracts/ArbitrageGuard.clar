;; ML-Driven Arbitrage Bot Contract
;; This smart contract manages an automated arbitrage trading bot that uses machine learning
;; predictions to identify and execute profitable trades across different exchanges/pools.
;; It includes safety mechanisms, performance tracking, and model governance.

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-funds (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-trade-threshold-not-met (err u103))
(define-constant err-circuit-breaker-active (err u104))
(define-constant err-invalid-confidence (err u105))
(define-constant err-max-trade-exceeded (err u106))
(define-constant err-bot-paused (err u107))
(define-constant err-cooldown-active (err u108))

;; Minimum confidence score required for trade execution (70%)
(define-constant min-confidence-score u70)
;; Maximum single trade as percentage of total funds (10%)
(define-constant max-trade-percentage u10)
;; Circuit breaker loss threshold (20% of capital)
(define-constant circuit-breaker-threshold u20)
;; Cooldown period between trades (10 blocks)
(define-constant trade-cooldown-blocks u10)

;; data maps and vars

;; Tracks the total funds managed by the bot
(define-data-var total-funds uint u0)

;; Tracks total profits generated
(define-data-var total-profit uint u0)

;; Tracks total losses incurred
(define-data-var total-loss uint u0)

;; Circuit breaker status
(define-data-var circuit-breaker-active bool false)

;; Bot operational status
(define-data-var bot-active bool true)

;; Last trade block height
(define-data-var last-trade-block uint u0)

;; ML model version currently in use
(define-data-var current-model-version uint u1)

;; Total number of trades executed
(define-data-var trade-count uint u0)

;; Map of authorized ML model operators
(define-map authorized-operators principal bool)

;; Map tracking individual trade records
(define-map trade-history 
    uint 
    {
        trade-id: uint,
        amount: uint,
        predicted-profit: uint,
        actual-profit: int,
        confidence-score: uint,
        model-version: uint,
        block-height: uint,
        success: bool
    }
)

;; Map tracking ML model performance metrics
(define-map model-metrics
    uint
    {
        version: uint,
        total-predictions: uint,
        successful-predictions: uint,
        average-confidence: uint,
        total-profit: int
    }
)

;; Map of user fund deposits
(define-map user-deposits principal uint)

;; private functions

;; Calculates the percentage of one value relative to another
(define-private (calculate-percentage (value uint) (total uint))
    (/ (* value u100) total)
)

;; Checks if the circuit breaker should be triggered
(define-private (should-trigger-circuit-breaker)
    (let
        (
            (current-funds (var-get total-funds))
            (losses (var-get total-loss))
        )
        (if (> current-funds u0)
            (>= (calculate-percentage losses current-funds) circuit-breaker-threshold)
            false
        )
    )
)

;; Updates model performance metrics after trade execution
(define-private (update-model-metrics (model-ver uint) (success bool) (confidence uint) (profit int))
    (let
        (
            (current-metrics (default-to 
                {version: model-ver, total-predictions: u0, successful-predictions: u0, average-confidence: u0, total-profit: 0}
                (map-get? model-metrics model-ver)
            ))
        )
        (map-set model-metrics model-ver
            {
                version: model-ver,
                total-predictions: (+ (get total-predictions current-metrics) u1),
                successful-predictions: (if success 
                    (+ (get successful-predictions current-metrics) u1)
                    (get successful-predictions current-metrics)
                ),
                average-confidence: (/ (+ (* (get average-confidence current-metrics) (get total-predictions current-metrics)) confidence)
                                       (+ (get total-predictions current-metrics) u1)),
                total-profit: (+ (get total-profit current-metrics) profit)
            }
        )
    )
)

;; Validates trade parameters before execution
(define-private (validate-trade-params (amount uint) (confidence uint))
    (and
        (var-get bot-active)
        (not (var-get circuit-breaker-active))
        (>= confidence min-confidence-score)
        (<= (calculate-percentage amount (var-get total-funds)) max-trade-percentage)
        (>= (var-get total-funds) amount)
        (>= block-height (+ (var-get last-trade-block) trade-cooldown-blocks))
    )
)

;; public functions

;; Deposits funds into the bot for trading
(define-public (deposit-funds (amount uint))
    (let
        (
            (current-deposit (default-to u0 (map-get? user-deposits tx-sender)))
        )
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set user-deposits tx-sender (+ current-deposit amount))
        (var-set total-funds (+ (var-get total-funds) amount))
        (ok true)
    )
)

;; Withdraws funds from the bot (only if not locked in trades)
(define-public (withdraw-funds (amount uint))
    (let
        (
            (user-balance (default-to u0 (map-get? user-deposits tx-sender)))
        )
        (asserts! (>= user-balance amount) err-insufficient-funds)
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        (map-set user-deposits tx-sender (- user-balance amount))
        (var-set total-funds (- (var-get total-funds) amount))
        (ok true)
    )
)

;; Authorizes an operator to execute ML-based trades
(define-public (authorize-operator (operator principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set authorized-operators operator true)
        (ok true)
    )
)

;; Revokes operator authorization
(define-public (revoke-operator (operator principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set authorized-operators operator false)
        (ok true)
    )
)

;; Pauses bot operations (emergency stop)
(define-public (pause-bot)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set bot-active false)
        (ok true)
    )
)

;; Resumes bot operations
(define-public (resume-bot)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set bot-active true)
        (var-set circuit-breaker-active false)
        (ok true)
    )
)

;; Updates the ML model version
(define-public (update-model-version (new-version uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set current-model-version new-version)
        (ok true)
    )
)


