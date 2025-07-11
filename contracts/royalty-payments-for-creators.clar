(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_CREATOR_NOT_FOUND (err u102))
(define-constant ERR_INSUFFICIENT_BALANCE (err u103))
(define-constant ERR_INVALID_PERCENTAGE (err u104))
(define-constant ERR_CONTENT_NOT_FOUND (err u105))
(define-constant ERR_ALREADY_EXISTS (err u106))
(define-constant ERR_PAYMENT_FAILED (err u107))
(define-constant ERR_SUBSCRIPTION_NOT_FOUND (err u108))
(define-constant ERR_SUBSCRIPTION_EXPIRED (err u109))
(define-constant ERR_SUBSCRIPTION_ALREADY_ACTIVE (err u110))

(define-map creators
  { creator: principal }
  { 
    total-earned: uint,
    content-count: uint,
    is-active: bool,
    subscription-price: uint,
    subscription-enabled: bool
  }
)

(define-map content-items
  { content-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    price: uint,
    royalty-percentage: uint,
    total-sales: uint,
    total-revenue: uint,
    is-active: bool
  }
)

(define-map sales
  { sale-id: uint }
  {
    content-id: uint,
    buyer: principal,
    creator: principal,
    sale-price: uint,
    royalty-amount: uint,
    timestamp: uint
  }
)

(define-map subscriptions
  { subscriber: principal, creator: principal }
  {
    start-time: uint,
    end-time: uint,
    price-paid: uint,
    is-active: bool
  }
)

(define-data-var next-content-id uint u1)
(define-data-var next-sale-id uint u1)
(define-data-var platform-fee-percentage uint u250)
(define-data-var total-platform-revenue uint u0)

(define-public (register-creator)
  (let ((creator tx-sender))
    (match (map-get? creators { creator: creator })
      existing-creator ERR_ALREADY_EXISTS
      (ok (map-set creators
        { creator: creator }
        {
          total-earned: u0,
          content-count: u0,
          is-active: true,
          subscription-price: u0,
          subscription-enabled: false
        }
      ))
    )
  )
)

(define-public (create-content (title (string-ascii 100)) (price uint) (royalty-percentage uint))
  (let (
    (creator tx-sender)
    (content-id (var-get next-content-id))
  )
    (asserts! (> price u0) ERR_INVALID_AMOUNT)
    (asserts! (<= royalty-percentage u10000) ERR_INVALID_PERCENTAGE)
    (asserts! (is-some (map-get? creators { creator: creator })) ERR_CREATOR_NOT_FOUND)
    
    (map-set content-items
      { content-id: content-id }
      {
        creator: creator,
        title: title,
        price: price,
        royalty-percentage: royalty-percentage,
        total-sales: u0,
        total-revenue: u0,
        is-active: true
      }
    )
    
    (map-set creators
      { creator: creator }
      (merge 
        (unwrap-panic (map-get? creators { creator: creator }))
        { content-count: (+ (get content-count (unwrap-panic (map-get? creators { creator: creator }))) u1) }
      )
    )
    
    (var-set next-content-id (+ content-id u1))
    (ok content-id)
  )
)

(define-public (purchase-content (content-id uint))
  (let (
    (buyer tx-sender)
    (content (unwrap! (map-get? content-items { content-id: content-id }) ERR_CONTENT_NOT_FOUND))
    (creator (get creator content))
    (price (get price content))
    (royalty-percentage (get royalty-percentage content))
    (platform-fee-percentage-val (var-get platform-fee-percentage))
    (sale-id (var-get next-sale-id))
  )
    (asserts! (get is-active content) ERR_CONTENT_NOT_FOUND)
    (asserts! (>= (stx-get-balance buyer) price) ERR_INSUFFICIENT_BALANCE)
    
    (let (
      (platform-fee (/ (* price platform-fee-percentage-val) u10000))
      (royalty-amount (/ (* price royalty-percentage) u10000))
      (creator-payment (- price platform-fee))
    )
      (try! (stx-transfer? creator-payment buyer creator))
      
      (if (> platform-fee u0)
        (try! (stx-transfer? platform-fee buyer CONTRACT_OWNER))
        true
      )
      
      (map-set sales
        { sale-id: sale-id }
        {
          content-id: content-id,
          buyer: buyer,
          creator: creator,
          sale-price: price,
          royalty-amount: royalty-amount,
          timestamp: stacks-block-height
        }
      )
      
      (map-set content-items
        { content-id: content-id }
        (merge content {
          total-sales: (+ (get total-sales content) u1),
          total-revenue: (+ (get total-revenue content) price)
        })
      )
      
      (map-set creators
        { creator: creator }
        (merge 
          (unwrap-panic (map-get? creators { creator: creator }))
          { total-earned: (+ (get total-earned (unwrap-panic (map-get? creators { creator: creator }))) creator-payment) }
        )
      )
      
      (var-set next-sale-id (+ sale-id u1))
      (var-set total-platform-revenue (+ (var-get total-platform-revenue) platform-fee))
      
      (ok sale-id)
    )
  )
)

(define-public (resell-content (content-id uint) (resale-price uint))
  (let (
    (seller tx-sender)
    (content (unwrap! (map-get? content-items { content-id: content-id }) ERR_CONTENT_NOT_FOUND))
    (original-creator (get creator content))
    (royalty-percentage (get royalty-percentage content))
    (platform-fee-percentage-val (var-get platform-fee-percentage))
    (sale-id (var-get next-sale-id))
  )
    (asserts! (> resale-price u0) ERR_INVALID_AMOUNT)
    (asserts! (get is-active content) ERR_CONTENT_NOT_FOUND)
    
    (let (
      (platform-fee (/ (* resale-price platform-fee-percentage-val) u10000))
      (royalty-amount (/ (* resale-price royalty-percentage) u10000))
      (seller-amount (- (- resale-price platform-fee) royalty-amount))
    )
      (try! (stx-transfer? seller-amount seller original-creator))
      (try! (stx-transfer? royalty-amount seller original-creator))
      
      (if (> platform-fee u0)
        (try! (stx-transfer? platform-fee seller CONTRACT_OWNER))
        true
      )
      
      (map-set sales
        { sale-id: sale-id }
        {
          content-id: content-id,
          buyer: seller,
          creator: original-creator,
          sale-price: resale-price,
          royalty-amount: royalty-amount,
          timestamp: stacks-block-height
        }
      )
      
      (map-set content-items
        { content-id: content-id }
        (merge content {
          total-sales: (+ (get total-sales content) u1),
          total-revenue: (+ (get total-revenue content) resale-price)
        })
      )
      
      (map-set creators
        { creator: original-creator }
        (merge 
          (unwrap-panic (map-get? creators { creator: original-creator }))
          { total-earned: (+ (get total-earned (unwrap-panic (map-get? creators { creator: original-creator }))) (+ seller-amount royalty-amount)) }
        )
      )
      
      (var-set next-sale-id (+ sale-id u1))
      (var-set total-platform-revenue (+ (var-get total-platform-revenue) platform-fee))
      
      (ok sale-id)
    )
  )
)

(define-public (update-platform-fee (new-fee-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-fee-percentage u1000) ERR_INVALID_PERCENTAGE)
    (var-set platform-fee-percentage new-fee-percentage)
    (ok true)
  )
)

(define-public (deactivate-content (content-id uint))
  (let ((content (unwrap! (map-get? content-items { content-id: content-id }) ERR_CONTENT_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get creator content)) ERR_NOT_AUTHORIZED)
    (map-set content-items
      { content-id: content-id }
      (merge content { is-active: false })
    )
    (ok true)
  )
)

(define-read-only (get-creator-info (creator principal))
  (map-get? creators { creator: creator })
)

(define-read-only (get-content-info (content-id uint))
  (map-get? content-items { content-id: content-id })
)

(define-read-only (get-sale-info (sale-id uint))
  (map-get? sales { sale-id: sale-id })
)

(define-read-only (get-platform-stats)
  {
    platform-fee-percentage: (var-get platform-fee-percentage),
    total-platform-revenue: (var-get total-platform-revenue),
    next-content-id: (var-get next-content-id),
    next-sale-id: (var-get next-sale-id)
  }
)

(define-read-only (calculate-royalty (content-id uint) (sale-price uint))
  (match (map-get? content-items { content-id: content-id })
    content (ok (/ (* sale-price (get royalty-percentage content)) u10000))
    ERR_CONTENT_NOT_FOUND
  )
)

(define-public (set-subscription-price (price uint))
  (let ((creator tx-sender))
    (asserts! (is-some (map-get? creators { creator: creator })) ERR_CREATOR_NOT_FOUND)
    (asserts! (> price u0) ERR_INVALID_AMOUNT)
    (map-set creators
      { creator: creator }
      (merge 
        (unwrap-panic (map-get? creators { creator: creator }))
        { subscription-price: price, subscription-enabled: true }
      )
    )
    (ok true)
  )
)

(define-public (subscribe-to-creator (creator principal))
  (let (
    (subscriber tx-sender)
    (creator-info (unwrap! (map-get? creators { creator: creator }) ERR_CREATOR_NOT_FOUND))
    (subscription-price (get subscription-price creator-info))
    (current-time stacks-block-height)
    (subscription-duration u4320)
  )
    (asserts! (get subscription-enabled creator-info) ERR_CREATOR_NOT_FOUND)
    (asserts! (> subscription-price u0) ERR_INVALID_AMOUNT)
    (asserts! (>= (stx-get-balance subscriber) subscription-price) ERR_INSUFFICIENT_BALANCE)
    
    (match (map-get? subscriptions { subscriber: subscriber, creator: creator })
      existing-subscription (asserts! (not (get is-active existing-subscription)) ERR_SUBSCRIPTION_ALREADY_ACTIVE)
      true
    )
    
    (let (
      (platform-fee (/ (* subscription-price (var-get platform-fee-percentage)) u10000))
      (creator-payment (- subscription-price platform-fee))
      (end-time (+ current-time subscription-duration))
    )
      (try! (stx-transfer? creator-payment subscriber creator))
      
      (if (> platform-fee u0)
        (try! (stx-transfer? platform-fee subscriber CONTRACT_OWNER))
        true
      )
      
      (map-set subscriptions
        { subscriber: subscriber, creator: creator }
        {
          start-time: current-time,
          end-time: end-time,
          price-paid: subscription-price,
          is-active: true
        }
      )
      
      (map-set creators
        { creator: creator }
        (merge creator-info
          { total-earned: (+ (get total-earned creator-info) creator-payment) }
        )
      )
      
      (var-set total-platform-revenue (+ (var-get total-platform-revenue) platform-fee))
      (ok true)
    )
  )
)

(define-public (cancel-subscription (creator principal))
  (let (
    (subscriber tx-sender)
    (subscription (unwrap! (map-get? subscriptions { subscriber: subscriber, creator: creator }) ERR_SUBSCRIPTION_NOT_FOUND))
  )
    (asserts! (get is-active subscription) ERR_SUBSCRIPTION_NOT_FOUND)
    (map-set subscriptions
      { subscriber: subscriber, creator: creator }
      (merge subscription { is-active: false })
    )
    (ok true)
  )
)

(define-public (access-subscription-content (content-id uint))
  (let (
    (subscriber tx-sender)
    (content (unwrap! (map-get? content-items { content-id: content-id }) ERR_CONTENT_NOT_FOUND))
    (creator (get creator content))
    (subscription (unwrap! (map-get? subscriptions { subscriber: subscriber, creator: creator }) ERR_SUBSCRIPTION_NOT_FOUND))
    (current-time stacks-block-height)
  )
    (asserts! (get is-active content) ERR_CONTENT_NOT_FOUND)
    (asserts! (get is-active subscription) ERR_SUBSCRIPTION_EXPIRED)
    (asserts! (< current-time (get end-time subscription)) ERR_SUBSCRIPTION_EXPIRED)
    (ok true)
  )
)

(define-read-only (get-subscription-info (subscriber principal) (creator principal))
  (map-get? subscriptions { subscriber: subscriber, creator: creator })
)

(define-read-only (is-subscription-active (subscriber principal) (creator principal))
  (match (map-get? subscriptions { subscriber: subscriber, creator: creator })
    subscription (and 
      (get is-active subscription)
      (< stacks-block-height (get end-time subscription))
    )
    false
  )
)