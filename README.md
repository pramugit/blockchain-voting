# VoteChain — Decentralized Voting and Governance System

Blockchain Fundamentals group assignment — Section 3, Option B.

## What's in this project

```
votechain/
├── contracts/
│   └── VoteChain.sol          # The smart contract (Solidity ^0.8.19)
├── test/
│   └── VoteChain.test.js      # 9 Hardhat/Chai unit tests
├── scripts/
│   └── deploy.js              # Deploys VoteChain to whichever network you target
├── frontend/
│   └── index.html             # Single-file DApp UI (MetaMask + ethers.js, no build step)
├── hardhat.config.js
├── package.json
├── .env.example                # Copy to .env and fill in your own values
└── .gitignore
```

## Requirements coverage

| Requirement | Where it's implemented |
|---|---|
| Authorised users create elections | `createElection()`, guarded by `onlyOrganiser` |
| Verified addresses vote | `registerVoter()` whitelist + `onlyEligible` modifier |
| No duplicate voting | `hasVoted` mapping checked in `castVote()` |
| Vote changeable before deadline | Separate `changeVote()` function, guarded by `withinPeriod` |
| Immutable, auditable record | Every action is an on-chain tx; `VoteCast`/`VoteChanged`/`ElectionCreated` events |
| Automatic results | `getResults()` — a free view function, no manual counting |
| Wallet integration | `frontend/index.html` connects via MetaMask's injected provider |

## Setup

```bash
npm install
```

## Run the tests

```bash
npm test
```

You should see 9 passing tests covering the happy path, unauthorised access, duplicate votes, vote changes, independent elections, and the voting deadline.

## Deploy to Sepolia

1. Copy `.env.example` to `.env` and fill in:
   - `SEPOLIA_RPC_URL` — free from [alchemy.com](https://alchemy.com) or [infura.io](https://infura.io)
   - `PRIVATE_KEY` — from MetaMask (use a testnet-only account)
   - `ETHERSCAN_API_KEY` — free from [etherscan.io](https://etherscan.io)
2. Get free Sepolia ETH from [sepoliafaucet.com](https://sepoliafaucet.com)
3. Deploy:
   ```bash
   npm run deploy:sepolia
   ```
4. Copy the printed contract address.
5. Verify it on Etherscan:
   ```bash
   npx hardhat verify --network sepolia YOUR_CONTRACT_ADDRESS
   ```

## Run the frontend

1. Open `frontend/index.html` in a text editor and replace `CONTRACT_ADDRESS` with your deployed address.
2. Open `frontend/index.html` directly in a browser with the MetaMask extension installed (or serve it with any static server, e.g. `npx http-server frontend`).
3. Click **Connect MetaMask**, confirm you're on Sepolia, and use the four sections to create an election, register voters, vote, and view live results.

No React build step is required — this is a plain HTML/JS file using ethers.js from a CDN, which keeps it simple to run and inspect. It calls the same contract functions a React version would; porting it to React later (per the module's suggested stack) means moving this same logic into components without changing the contract at all.

## Never commit `.env`

It contains your private key. `.gitignore` already excludes it — double-check with `git status` before your first commit.

## Discussion topics (see the full technical report for detail)

- **Smart contract security** — access control via modifiers; no external calls in `castVote`/`changeVote`, so no re-entrancy path; known limitation: `choiceOf` is not privacy-preserving.
- **Gas fees** — vote functions run in constant time regardless of voter count.
- **Scalability** — fine for class/club-scale elections; would need Layer-2 for national scale.
- **Decentralised trust** — the organiser role is an acknowledged centralisation point for eligibility, but counting is publicly verifiable by anyone via `getResults()`.
