(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u102))
(define-constant ERR-CAMPAIGN-INACTIVE (err u103))
(define-constant ERR-ALREADY-REGISTERED (err u104))
(define-constant ERR-NOT-REGISTERED (err u105))
(define-constant ERR-INSUFFICIENT-FUNDS (err u106))
(define-constant ERR-WITHDRAWAL-FAILED (err u107))

(define-data-var contract-owner principal tx-sender)
(define-data-var campaign-counter uint u0)
(define-data-var total-donations uint u0)

(define-map ngos
    principal
    {
        name: (string-ascii 100),
        description: (string-ascii 500),
        wallet: principal,
        verified: bool,
        registration-block: uint,
        total-raised: uint,
    }
)

(define-map campaigns
    uint
    {
        ngo: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        target-amount: uint,
        current-amount: uint,
        start-block: uint,
        end-block: uint,
        active: bool,
        category: (string-ascii 50),
    }
)

(define-map donations
    {
        donor: principal,
        campaign-id: uint,
    }
    {
        amount: uint,
        block-height: uint,
        anonymous: bool,
    }
)

(define-map donor-totals
    principal
    uint
)
(define-map campaign-donor-counts
    uint
    uint
)

(define-map ngo-campaigns
    principal
    (list 50 uint)
)

(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

(define-read-only (get-ngo-info (ngo principal))
    (map-get? ngos ngo)
)

(define-read-only (get-campaign-info (campaign-id uint))
    (map-get? campaigns campaign-id)
)

(define-read-only (get-donation-info
        (donor principal)
        (campaign-id uint)
    )
    (map-get? donations {
        donor: donor,
        campaign-id: campaign-id,
    })
)

(define-read-only (get-total-donations)
    (var-get total-donations)
)

(define-read-only (get-donor-total (donor principal))
    (default-to u0 (map-get? donor-totals donor))
)

(define-read-only (get-campaign-donor-count (campaign-id uint))
    (default-to u0 (map-get? campaign-donor-counts campaign-id))
)

(define-read-only (get-ngo-campaigns (ngo principal))
    (default-to (list) (map-get? ngo-campaigns ngo))
)

(define-read-only (is-campaign-active (campaign-id uint))
    (match (map-get? campaigns campaign-id)
        campaign (and
            (get active campaign)
            (<= (get start-block campaign) stacks-block-height)
            (>= (get end-block campaign) stacks-block-height)
        )
        false
    )
)

(define-read-only (get-campaign-progress (campaign-id uint))
    (match (map-get? campaigns campaign-id)
        campaign (let (
                (current (get current-amount campaign))
                (target (get target-amount campaign))
            )
            (some {
                current-amount: current,
                target-amount: target,
                percentage: (if (> target u0)
                    (/ (* current u100) target)
                    u0
                ),
                remaining: (if (> target current)
                    (- target current)
                    u0
                ),
            })
        )
        none
    )
)

(define-public (register-ngo
        (name (string-ascii 100))
        (description (string-ascii 500))
        (wallet principal)
    )
    (let ((sender tx-sender))
        (asserts! (is-none (map-get? ngos sender)) ERR-ALREADY-REGISTERED)
        (asserts! (> (len name) u0) ERR-INVALID-AMOUNT)
        (asserts! (> (len description) u0) ERR-INVALID-AMOUNT)
        (map-set ngos sender {
            name: name,
            description: description,
            wallet: wallet,
            verified: false,
            registration-block: stacks-block-height,
            total-raised: u0,
        })
        (ok true)
    )
)

(define-public (verify-ngo (ngo principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
        (asserts! (is-some (map-get? ngos ngo)) ERR-NOT-REGISTERED)
        (map-set ngos ngo
            (merge (unwrap-panic (map-get? ngos ngo)) { verified: true })
        )
        (ok true)
    )
)

(define-public (create-campaign
        (title (string-ascii 100))
        (description (string-ascii 500))
        (target-amount uint)
        (duration-blocks uint)
        (category (string-ascii 50))
    )
    (let (
            (sender tx-sender)
            (campaign-id (+ (var-get campaign-counter) u1))
            (current-campaigns (get-ngo-campaigns sender))
        )
        (asserts! (is-some (map-get? ngos sender)) ERR-NOT-REGISTERED)
        (asserts! (> target-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (> duration-blocks u0) ERR-INVALID-AMOUNT)
        (asserts! (> (len title) u0) ERR-INVALID-AMOUNT)

        (map-set campaigns campaign-id {
            ngo: sender,
            title: title,
            description: description,
            target-amount: target-amount,
            current-amount: u0,
            start-block: stacks-block-height,
            end-block: (+ stacks-block-height duration-blocks),
            active: true,
            category: category,
        })

        (map-set ngo-campaigns sender
            (unwrap-panic (as-max-len? (append current-campaigns campaign-id) u50))
        )
        (var-set campaign-counter campaign-id)
        (ok campaign-id)
    )
)

(define-public (donate
        (campaign-id uint)
        (amount uint)
        (anonymous bool)
    )
    (let (
            (sender tx-sender)
            (campaign (unwrap! (map-get? campaigns campaign-id) ERR-CAMPAIGN-NOT-FOUND))
            (ngo-addr (get ngo campaign))
            (current-donation (get-donation-info sender campaign-id))
            (existing-amount (if (is-some current-donation)
                (get amount (unwrap-panic current-donation))
                u0
            ))
            (new-total-amount (+ existing-amount amount))
            (new-campaign-amount (+ (get current-amount campaign) amount))
            (current-donor-total (get-donor-total sender))
            (current-donor-count (get-campaign-donor-count campaign-id))
        )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (is-campaign-active campaign-id) ERR-CAMPAIGN-INACTIVE)

        (try! (stx-transfer? amount sender
            (get wallet (unwrap-panic (map-get? ngos ngo-addr)))
        ))

        (map-set donations {
            donor: sender,
            campaign-id: campaign-id,
        } {
            amount: new-total-amount,
            block-height: stacks-block-height,
            anonymous: anonymous,
        })

        (map-set campaigns campaign-id
            (merge campaign { current-amount: new-campaign-amount })
        )
        (map-set donor-totals sender (+ current-donor-total amount))

        (if (is-none current-donation)
            (map-set campaign-donor-counts campaign-id (+ current-donor-count u1))
            true
        )

        (map-set ngos ngo-addr
            (merge (unwrap-panic (map-get? ngos ngo-addr)) { total-raised: (+ (get total-raised (unwrap-panic (map-get? ngos ngo-addr))) amount) })
        )

        (var-set total-donations (+ (var-get total-donations) amount))
        (ok true)
    )
)

(define-public (close-campaign (campaign-id uint))
    (let (
            (sender tx-sender)
            (campaign (unwrap! (map-get? campaigns campaign-id) ERR-CAMPAIGN-NOT-FOUND))
        )
        (asserts! (is-eq sender (get ngo campaign)) ERR-UNAUTHORIZED)
        (map-set campaigns campaign-id (merge campaign { active: false }))
        (ok true)
    )
)

(define-public (update-contract-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)
    )
)

(define-public (extend-campaign
        (campaign-id uint)
        (additional-blocks uint)
    )
    (let (
            (sender tx-sender)
            (campaign (unwrap! (map-get? campaigns campaign-id) ERR-CAMPAIGN-NOT-FOUND))
        )
        (asserts! (is-eq sender (get ngo campaign)) ERR-UNAUTHORIZED)
        (asserts! (get active campaign) ERR-CAMPAIGN-INACTIVE)
        (asserts! (> additional-blocks u0) ERR-INVALID-AMOUNT)

        (map-set campaigns campaign-id
            (merge campaign { end-block: (+ (get end-block campaign) additional-blocks) })
        )
        (ok true)
    )
)

(define-read-only (get-active-campaigns)
    (filter is-campaign-active-by-id
        (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19
            u20)
    )
)

(define-read-only (is-campaign-active-by-id (campaign-id uint))
    (is-campaign-active campaign-id)
)

(define-read-only (get-campaign-stats)
    {
        total-campaigns: (var-get campaign-counter),
        total-donations: (var-get total-donations),
        active-campaigns: (len (get-active-campaigns)),
    }
)
