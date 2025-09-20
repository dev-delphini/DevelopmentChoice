# DevelopmentChoice

A decentralized user feedback system for application improvements and new feature selection built on the Stacks blockchain using Clarity smart contracts.

## Description

DevelopmentChoice enables communities to submit, vote on, and prioritize development proposals for applications and platforms. Users can submit proposals for new features, improvements, or bug fixes, while the community votes to determine which development priorities should be addressed first.

## Features

- **Proposal Submission**: Users can submit detailed proposals for features, improvements, or bug fixes
- **Community Voting**: Transparent voting system where users can vote for or against proposals
- **Proposal Types**: Support for three categories of proposals:
  - New Features (Type 1)
  - Application Improvements (Type 2)
  - Bug Fixes (Type 3)
- **Time-Limited Voting**: Proposals have a 24-hour voting period (144 blocks)
- **Economic Model**: Proposal submission requires a 1 STX fee to prevent spam
- **User Statistics**: Track user engagement including proposals created and votes cast
- **Automatic Expiration**: Proposals automatically expire after the voting period

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Testing Framework**: Vitest with Clarinet SDK
- **Node Version**: Compatible with latest Clarinet

## Installation

### Prerequisites

1. Install [Clarinet](https://github.com/hirosystems/clarinet)
2. Install Node.js (v16 or higher)
3. Install npm or yarn

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd DevelopmentChoice
```

2. Navigate to the contract directory:
```bash
cd DevelopmentChoice_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### Deploying the Contract

```bash
clarinet deployments generate --devnet
clarinet deployments apply --devnet
```

### Contract Interaction Examples

#### Submit a New Feature Proposal

```clarity
(contract-call? .DevelopmentChoice submit-proposal
  "Mobile App Support"
  "Add native mobile application support for iOS and Android platforms"
  u1) ;; Feature proposal type
```

#### Vote on a Proposal

```clarity
;; Vote FOR proposal ID 1
(contract-call? .DevelopmentChoice vote-on-proposal u1 true)

;; Vote AGAINST proposal ID 1
(contract-call? .DevelopmentChoice vote-on-proposal u1 false)
```

#### Get Proposal Details

```clarity
(contract-call? .DevelopmentChoice get-proposal u1)
```

#### Check Proposal Results

```clarity
(contract-call? .DevelopmentChoice get-proposal-results u1)
```

## Contract Functions Documentation

### Public Functions

#### `submit-proposal`
Submits a new development proposal to the system.

**Parameters:**
- `title` (string-ascii 100): Proposal title
- `description` (string-ascii 500): Detailed description
- `proposal-type` (uint): Type of proposal (1=Feature, 2=Improvement, 3=Bug Fix)

**Cost:** 1 STX (1,000,000 microSTX)

**Returns:** Proposal ID on success

#### `vote-on-proposal`
Casts a vote on an active proposal.

**Parameters:**
- `proposal-id` (uint): ID of the proposal to vote on
- `vote-for` (bool): true for supporting, false for opposing

**Requirements:**
- Proposal must be active and not expired
- User cannot vote twice on the same proposal

#### `close-proposal`
Deactivates an expired proposal (callable by anyone).

**Parameters:**
- `proposal-id` (uint): ID of the proposal to close

### Read-Only Functions

#### `get-proposal`
Retrieves complete proposal information.

#### `get-user-vote`
Gets a specific user's vote on a proposal.

#### `get-user-stats`
Returns user statistics (proposals created, votes cast).

#### `get-total-proposals`
Returns the total number of proposals submitted.

#### `is-proposal-active`
Checks if a proposal is still accepting votes.

#### `get-proposal-results`
Returns voting results and summary for a proposal.

## Testing

Run the test suite:

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

## Deployment Guide

### Devnet Deployment

1. Generate deployment plan:
```bash
clarinet deployments generate --devnet
```

2. Apply deployment:
```bash
clarinet deployments apply --devnet
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Generate deployment plan:
```bash
clarinet deployments generate --testnet
```

3. Apply deployment:
```bash
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Ensure thorough testing on testnet
3. Generate deployment plan:
```bash
clarinet deployments generate --mainnet
```

4. Apply deployment:
```bash
clarinet deployments apply --mainnet
```

## Security Notes

### Economic Security
- **Proposal Fee**: 1 STX fee prevents spam submissions
- **No Double Voting**: Contract enforces one vote per user per proposal
- **Time Limits**: 24-hour voting periods prevent indefinite proposals

### Access Control
- **Open Participation**: Any user can submit proposals and vote
- **Owner Benefits**: Contract owner receives proposal fees
- **No Admin Override**: No centralized control over voting outcomes

### Data Integrity
- **Immutable Records**: All votes and proposals are permanently recorded
- **Transparent Results**: All voting data is publicly accessible
- **Automatic Expiration**: Proposals cannot be manipulated after expiration

### Best Practices
- Test thoroughly on devnet and testnet before mainnet deployment
- Monitor proposal fees and adjust if necessary for network conditions
- Consider proposal moderation mechanisms for inappropriate content
- Implement front-end validation to enhance user experience

## Error Codes

- `u100` - ERR_NOT_AUTHORIZED: Insufficient permissions
- `u101` - ERR_PROPOSAL_NOT_FOUND: Proposal does not exist
- `u102` - ERR_ALREADY_VOTED: User has already voted on this proposal
- `u103` - ERR_INVALID_PROPOSAL_TYPE: Invalid proposal type specified
- `u104` - ERR_PROPOSAL_EXPIRED: Proposal voting period has ended
- `u105` - ERR_INSUFFICIENT_FUNDS: Not enough STX for proposal fee

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.