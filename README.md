ArbitrageGuard
==============

* * * * *

🤖 ML-Driven Arbitrage Bot Contract
-----------------------------------

This document provides a comprehensive overview and technical specification for the **ArbitrageGuard** smart contract. This contract governs an automated, machine learning-driven arbitrage trading bot, facilitating secure fund management, trade execution, performance tracking, and crucial safety mechanisms on the blockchain.

### 💡 Core Functionality

The contract's primary role is to execute arbitrage trades proposed by off-chain ML models. It ensures that trades adhere to predefined risk management policies (e.g., maximum trade size, minimum confidence score, cooldown period) before logging the results and updating performance metrics for the active ML model.

### 🛡️ Safety and Governance Features

-   **Circuit Breaker:** Automatically pauses all trading activity if cumulative losses exceed a predefined threshold (20% of capital), protecting investor funds.

-   **Trade Cooldown:** Enforces a minimum block delay (10 blocks) between trades to prevent excessive high-frequency trading and potential network congestion.

-   **Confidence Threshold:** Trades must meet a minimum confidence score (70%) from the ML model to be considered for execution.

-   **Max Trade Size:** Limits the capital exposed in any single trade (10% of total funds).

-   **Owner Governance:** Exclusive functions for the contract owner to manage bot operations (pause/resume), authorize trade operators, and update the active ML model version.

-   **Operator Authorization:** Only pre-approved addresses can call the core trade execution function.

* * * * *

⚙️ Technical Details (Clarity Smart Contract)
---------------------------------------------

### Constants and Error Codes

| Constant | Value | Description |
| --- | --- | --- |
| `contract-owner` | `tx-sender` | The principal who deploys the contract. |
| `min-confidence-score` | `u70` | Minimum confidence score (70%) required for a trade. |
| `max-trade-percentage` | `u10` | Maximum percentage of `total-funds` allowed per trade (10%). |
| `circuit-breaker-threshold` | `u20` | Loss percentage (20% of capital) that triggers the circuit breaker. |
| `trade-cooldown-blocks` | `u10` | Minimum blocks between trade executions. |
| `err-owner-only` | `u100` | Caller is not the contract owner. |
| `err-insufficient-funds` | `u101` | Insufficient funds for trade or withdrawal. |
| `err-unauthorized` | `u102` | Caller is not an authorized operator. |
| `err-circuit-breaker-active` | `u104` | Trading is paused due to the circuit breaker. |
| `err-invalid-confidence` | `u105` | ML confidence score is below the minimum threshold. |
| `err-max-trade-exceeded` | `u106` | Trade amount exceeds the maximum percentage. |
| `err-bot-paused` | `u107` | Trading is manually paused. |
| `err-cooldown-active` | `u108` | Trade cooldown period has not elapsed. |

### Data Variables (Persistent Storage)

| Variable | Type | Initial Value | Description |
| --- | --- | --- | --- |
| `total-funds` | `uint` | `u0` | Total capital managed by the bot (STX). |
| `total-profit` | `uint` | `u0` | Cumulative gross profit across all trades. |
| `total-loss` | `uint` | `u0` | Cumulative gross loss across all trades. |
| `circuit-breaker-active` | `bool` | `false` | Status of the safety circuit breaker. |
| `bot-active` | `bool` | `true` | Manual operational status (can be paused/resumed by owner). |
| `last-trade-block` | `uint` | `u0` | The block height of the most recent trade. |
| `current-model-version` | `uint` | `u1` | The version ID of the ML model currently providing predictions. |
| `trade-count` | `uint` | `u0` | Auto-incrementing counter for trade IDs. |

### Data Maps (Persistent Key-Value Storage)

#### `authorized-operators`

| Key | Value | Description |
| --- | --- | --- |
| `principal` | `bool` | Maps an address to its authorization status (`true` if authorized). |

#### `user-deposits`

| Key | Value | Description |
| --- | --- | --- |
| `principal` | `uint` | Tracks the deposited funds (STX) for each user. |

#### `trade-history`

| Key | Value (Tuple) | Description |
| --- | --- | --- |
| `uint` (Trade ID) | `{trade-id: uint, amount: uint, predicted-profit: uint, actual-profit: int, confidence-score: uint, model-version: uint, block-height: uint, success: bool}` | Stores detailed, immutable records of every executed trade. |

#### `model-metrics`

| Key | Value (Tuple) | Description |
| --- | --- | --- |
| `uint` (Model Version) | `{version: uint, total-predictions: uint, successful-predictions: uint, average-confidence: uint, total-profit: int}` | Aggregates performance data for each ML model version. |

* * * * *

🛠️ Public Functions (API)
--------------------------

### **`execute-ml-arbitrage-trade`**

Code snippet

```
(define-public (execute-ml-arbitrage-trade
    (trade-amount uint)
    (predicted-profit uint)
    (confidence-score uint)
    (source-exchange (string-ascii 20))
    (target-exchange (string-ascii 20)))
    (response {trade-id: uint, executed: bool, profit: int, circuit-breaker-triggered: bool} (err uint))
)

```

**Description:** The primary function for executing trades. It is called by an authorized operator to submit a trade proposal from the off-chain ML bot. The function performs all necessary checks---authorization, bot status, circuit breaker status, confidence score, trade size, and cooldown---before simulating the trade outcome, updating all statistics, recording the trade, and checking for circuit breaker activation.

**Error Conditions:** `err-unauthorized`, `err-bot-paused`, `err-circuit-breaker-active`, `err-invalid-confidence`, `err-insufficient-funds`, `err-max-trade-exceeded`, `err-cooldown-active`.

### **`deposit-funds`**

Code snippet

```
(define-public (deposit-funds (amount uint)) (response bool (err uint)))

```

**Description:** Allows any user to deposit STX funds into the contract for use in trading. The funds are transferred to the contract's principal and tracked in `user-deposits` and `total-funds`.

### **`withdraw-funds`**

Code snippet

```
(define-public (withdraw-funds (amount uint)) (response bool (err uint)))

```

**Description:** Allows a user to withdraw their deposited STX funds. Asserts that the requested amount does not exceed the user's recorded balance.

**Error Condition:** `err-insufficient-funds`.

### **`authorize-operator`**

Code snippet

```
(define-public (authorize-operator (operator principal)) (response bool (err uint)))

```

**Description:** (Owner Only) Grants permission to an address to call the `execute-ml-arbitrage-trade` function.

**Error Condition:** `err-owner-only`.

### **`revoke-operator`**

Code snippet

```
(define-public (revoke-operator (operator principal)) (response bool (err uint)))

```

**Description:** (Owner Only) Removes permission from an address to execute trades.

**Error Condition:** `err-owner-only`.

### **`pause-bot`**

Code snippet

```
(define-public (pause-bot) (response bool (err uint)))

```

**Description:** (Owner Only) Manually sets `bot-active` to `false`, immediately halting all trade execution.

**Error Condition:** `err-owner-only`.

### **`resume-bot`**

Code snippet

```
(define-public (resume-bot) (response bool (err uint)))

```

**Description:** (Owner Only) Sets `bot-active` to `true` and also resets `circuit-breaker-active` to `false`, restoring trading operations.

**Error Condition:** `err-owner-only`.

### **`update-model-version`**

Code snippet

```
(define-public (update-model-version (new-version uint)) (response bool (err uint)))

```

**Description:** (Owner Only) Updates the `current-model-version` variable, ensuring subsequent trades are tracked against the new model ID in `trade-history` and `model-metrics`.

**Error Condition:** `err-owner-only`.

* * * * *

🔒 Private Functions (Internal Logic)
-------------------------------------

### **`calculate-percentage`**

Code snippet

```
(define-private (calculate-percentage (value uint) (total uint)) uint)

```

**Description:** Calculates `(value * 100) / total`. Used internally for checking trade size against `max-trade-percentage` and losses against `circuit-breaker-threshold`.

### **`should-trigger-circuit-breaker`**

Code snippet

```
(define-private (should-trigger-circuit-breaker) bool)

```

**Description:** Computes the loss percentage based on `total-loss` and `total-funds`. Returns `true` if this percentage is greater than or equal to `circuit-breaker-threshold` (`u20`).

### **`update-model-metrics`**

Code snippet

```
(define-private (update-model-metrics (model-ver uint) (success bool) (confidence uint) (profit int)) (response bool (err uint)))

```

**Description:** Updates the aggregate performance data for a specific ML model version within the `model-metrics` map. It recalculates the total trade count, successful predictions, average confidence, and total profit/loss for that version.

### **`validate-trade-params`**

Code snippet

```
(define-private (validate-trade-params (amount uint) (confidence uint)) bool)

```

**Description:** A helper function that consolidates all pre-execution checks: `bot-active`, `circuit-breaker-active`, `min-confidence-score`, `max-trade-percentage`, `total-funds` sufficiency, and `trade-cooldown-blocks`. This function, though not used in `execute-ml-arbitrage-trade` in its current form (the checks are inlined), demonstrates a logical grouping of validation rules.

* * * * *

🤝 Contribution
---------------

We welcome contributions from the Clarity and blockchain development communities. If you identify security vulnerabilities, propose efficiency improvements, or wish to extend the contract's functionality, please follow these guidelines:

1.  **Fork** the repository.

2.  Create a new feature branch (`git checkout -b feature/AmazingFeature`).

3.  Commit your changes (`git commit -m 'Add AmazingFeature'`).

4.  Push to the branch (`git push origin feature/AmazingFeature`).

5.  Open a **Pull Request**.

All contributions must adhere to the highest standards of security and clarity. New functions must be accompanied by detailed documentation and unit tests (if applicable).

* * * * *

📜 MIT License
--------------

Copyright (c) 2025 ArbitrageGuard

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

* * * * *

⚠️ Security Disclaimer
----------------------

This smart contract is provided **"as is"** and has been developed for demonstrative and educational purposes related to automated, ML-driven trading on the blockchain. While designed with multiple safety mechanisms (circuit breaker, cooldowns, authorization), it involves the handling of real assets and is subject to smart contract risks, including but not limited to:

-   **Logic Errors and Bugs:** Unforeseen flaws in the Clarity code.

-   **External Factors:** Reliance on off-chain ML predictions and external exchange/DEX protocols (simulated in this contract).

-   **Economic Exploits:** Market manipulation or price oracle attacks (if integrated).

**DO NOT DEPLOY OR FUND THIS CONTRACT IN A PRODUCTION ENVIRONMENT WITHOUT A THOROUGH, INDEPENDENT SECURITY AUDIT.** Users and deployers assume all responsibility for the risks associated with utilizing this code.
