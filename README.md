# 💝 Transparent NGO Donation Tracker

A blockchain-based donation tracking system that provides complete transparency for NGO fundraising campaigns on the Stacks blockchain.

## 🌟 Features

- **🏢 NGO Registration**: Secure registration system for non-profit organizations
- **✅ Verification System**: Admin verification process for registered NGOs
- **🎯 Campaign Management**: Create and manage targeted fundraising campaigns
- **💰 Transparent Donations**: All donations are recorded on-chain with optional anonymity
- **📊 Real-time Tracking**: Live campaign progress tracking and statistics
- **🔒 Secure Transfers**: Direct STX transfers to verified NGO wallets
- **⏰ Time-based Campaigns**: Set campaign duration with automatic expiry

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing
- Node.js (for running tests)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Transparent-NGO-Donation-Tracker
```

2. Install dependencies:
```bash
npm install
```

3. Check contract compilation:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## 📋 Contract Functions

### 🏢 NGO Management

#### `register-ngo`
Register a new NGO with the platform.
```clarity
(contract-call? .contract register-ngo "NGO Name" "Description" 'SP1234...WALLET)
```

#### `verify-ngo`
Admin function to verify a registered NGO.
```clarity
(contract-call? .contract verify-ngo 'SP1234...NGO-PRINCIPAL)
```

### 🎯 Campaign Management

#### `create-campaign`
Create a new fundraising campaign.
```clarity
(contract-call? .contract create-campaign "Campaign Title" "Description" u1000000 u2016 "education")
```

#### `close-campaign`
Close an active campaign (NGO only).
```clarity
(contract-call? .contract close-campaign u1)
```

#### `extend-campaign`
Extend campaign duration (NGO only).
```clarity
(contract-call? .contract extend-campaign u1 u1008)
```

### 💰 Donations

#### `donate`
Make a donation to an active campaign.
```clarity
(contract-call? .contract donate u1 u100000 false)
```
- `campaign-id`: Target campaign ID
- `amount`: Donation amount in microSTX
- `anonymous`: Whether to hide donor identity

### 📊 Data Queries

#### Campaign Information
```clarity
(contract-call? .contract get-campaign-info u1)
(contract-call? .contract get-campaign-progress u1)
(contract-call? .contract is-campaign-active u1)
```

#### NGO Information
```clarity
(contract-call? .contract get-ngo-info 'SP1234...NGO-PRINCIPAL)
(contract-call? .contract get-ngo-campaigns 'SP1234...NGO-PRINCIPAL)
```

#### Donation Tracking
```clarity
(contract-call? .contract get-donation-info 'SP1234...DONOR u1)
(contract-call? .contract get-donor-total 'SP1234...DONOR)
```

#### Platform Statistics
```clarity
(contract-call? .contract get-campaign-stats)
(contract-call? .contract get-total-donations)
```

## 🔧 Development

### Local Testing
Use Clarinet console for interactive testing:
```bash
clarinet console
```

### Contract Deployment
Deploy to testnet/mainnet using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

## 🛡️ Security Features

- **Access Control**: Owner-only functions for verification
- **Input Validation**: Comprehensive parameter checking
- **State Management**: Proper tracking of donations and campaigns
- **Error Handling**: Descriptive error codes for all edge cases

## 📈 Use Cases

- **🎓 Education**: School funding campaigns
- **🏥 Healthcare**: Medical aid fundraising
- **🌍 Environment**: Conservation projects
- **🏠 Disaster Relief**: Emergency response funding
- **💡 Innovation**: Technology for social good

## 🔐 Error Codes

| Code | Description |
|------| ----------- |
| u100 | Unauthorized access |
| u101 | Invalid amount or parameter |
| u102 | Campaign not found |
| u103 | Campaign inactive |
| u104 | Already registered |
| u105 | Not registered |
| u106 | Insufficient funds |
| u107 | Withdrawal failed |



## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

Built with ❤️ for transparent charitable giving on the Stacks blockchain.




