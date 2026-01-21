# SuperAltcoin Prediction Market

A decentralized prediction market smart contract built on the Stacks blockchain using Clarity. SuperAltcoin enables users to bet on whether specific cryptocurrencies will remain in the top 100 by market capitalization.

## Overview

SuperAltcoin creates a trustless betting platform where users can stake STX tokens on their predictions about cryptocurrency market rankings. Winners receive proportional payouts from the total pool of bets.

## Features

- **Create Markets**: Contract owner can create prediction markets for any cryptocurrency
- **Place Bets**: Users bet on whether a coin will stay in or drop out of top 100
- **Automated Payouts**: Winners receive proportional shares based on pool distribution
- **Trustless Resolution**: Owner resolves markets with verifiable outcomes
- **Minimum Bet Protection**: 100 STX minimum prevents spam bets

## How It Works

### Market Lifecycle

1. **Market Creation**: Owner creates a market specifying the coin name and duration in blocks
2. **Betting Period**: Users place bets choosing either "YES" (stays in top 100) or "NO" (drops out)
3. **Market Close**: No more bets accepted after the end block is reached
4. **Resolution**: Owner resolves the market with the actual outcome
5. **Claims**: Winners claim their proportional share of the total pool

### Payout Calculation

Winners split the entire pool (both YES and NO bets) proportionally:

```
Your Payout = (Your Bet Amount × Total Pool) / Winning Pool Total
```

**Example:**
- Total YES bets: 1,000 STX
- Total NO bets: 500 STX
- Your bet: 200 STX on YES
- Outcome: Coin stayed in top 100 (YES wins)
- Your payout: (200 × 1,500) / 1,000 = 300 STX (50% profit)

## Contract Functions

### Read-Only Functions

#### `get-market`
```clarity
(get-market (market-id uint))
```
Returns market details including coin name, end block, resolution status, and bet totals.

#### `get-bet`
```clarity
(get-bet (market-id uint) (bettor principal))
```
Returns bet details for a specific bettor in a market.

#### `get-market-count`
```clarity
(get-market-count)
```
Returns the total number of markets created.

#### `calculate-payout`
```clarity
(calculate-payout (market-id uint) (bettor principal))
```
Calculates potential payout for a bettor if the market is resolved.

### Public Functions

#### `create-market`
```clarity
(create-market (coin-name (string-ascii 20)) (duration-blocks uint))
```
**Owner only**. Creates a new prediction market.

**Parameters:**
- `coin-name`: Name of the cryptocurrency (max 20 characters)
- `duration-blocks`: Number of blocks until market closes

**Returns:** Market ID

#### `place-bet`
```clarity
(place-bet (market-id uint) (bet-yes bool) (amount uint))
```
Places a bet on a market.

**Parameters:**
- `market-id`: ID of the market to bet on
- `bet-yes`: `true` for YES (stays in top 100), `false` for NO
- `amount`: Bet amount in microSTX (minimum 100 STX = 100000000 microSTX)

**Requirements:**
- Market must be open (before end block)
- User cannot have existing bet in this market
- Amount must be at least 100 STX

#### `resolve-market`
```clarity
(resolve-market (market-id uint) (stayed-in-top100 bool))
```
**Owner only**. Resolves a market with the outcome.

**Parameters:**
- `market-id`: ID of the market to resolve
- `stayed-in-top100`: `true` if coin stayed in top 100, `false` otherwise

**Requirements:**
- Market must be past end block
- Market must not already be resolved

#### `claim-winnings`
```clarity
(claim-winnings (market-id uint))
```
Claims winnings from a resolved market.

**Parameters:**
- `market-id`: ID of the market to claim from

**Requirements:**
- Market must be resolved
- User must have won their bet
- User must not have already claimed

## Usage Example

### Creating a Market
```clarity
;; Create market for "DOGE" with 1000 block duration
(contract-call? .superaltcoin create-market "DOGE" u1000)
;; Returns: (ok u1)
```

### Placing a Bet
```clarity
;; Bet 200 STX that DOGE stays in top 100
(contract-call? .superaltcoin place-bet u1 true u200000000)
;; Returns: (ok true)
```

### Resolving a Market
```clarity
;; Resolve market - DOGE stayed in top 100
(contract-call? .superaltcoin resolve-market u1 true)
;; Returns: (ok true)
```

### Claiming Winnings
```clarity
;; Claim your winnings
(contract-call? .superaltcoin claim-winnings u1)
;; Returns: (ok true) and transfers STX
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-owner-only` | Only contract owner can call this function |
| u101 | `err-not-found` | Market or bet not found |
| u102 | `err-already-exists` | Market already resolved or bet already placed |
| u103 | `err-market-closed` | Market has closed, no more bets accepted |
| u104 | `err-market-open` | Market not yet resolved |
| u105 | `err-insufficient-funds` | Bet amount below minimum or no winnings |
| u106 | `err-already-claimed` | Winnings already claimed |

## Constants

- **Minimum Bet**: 100 STX (100000000 microSTX)
- **Contract Owner**: Set at deployment (tx-sender)

## Security Considerations

- Only the contract owner can create and resolve markets
- Users cannot bet twice on the same market
- Bets are locked after market end block
- Winnings can only be claimed once
- All funds are held in contract until claimed

## Data Structures

### Market
```clarity
{
  coin-name: (string-ascii 20),
  end-block: uint,
  is-resolved: bool,
  stayed-in-top100: bool,
  total-yes-bets: uint,
  total-no-bets: uint
}
```

### Bet
```clarity
{
  amount: uint,
  bet-yes: bool,
  has-claimed: bool
}
```

## Deployment

1. Deploy the contract to Stacks blockchain
2. The deploying address becomes the contract owner
3. Owner can immediately start creating markets

## Future Enhancements

Potential improvements for future versions:

- Multiple oracle support for decentralized resolution
- Time-weighted betting (earlier bets get bonus multipliers)
- Partial withdrawals before resolution
- Market categories and tags
- Reputation system for accurate predictions
- Automated market resolution via price oracles

## License

This smart contract is provided as-is for educational and commercial use.

## Support

For issues or questions about the SuperAltcoin contract, please refer to the Stacks blockchain documentation at https://docs.stacks.co