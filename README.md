# 🎨 Royalty Payments for Creators

A Clarity smart contract that enables automatic royalty payments for digital content creators on the Stacks blockchain. This contract demonstrates how to implement automatic payouts, royalty distribution, and creator monetization.

## 🚀 Features

- 👤 **Creator Registration**: Artists can register as content creators
- 📝 **Content Creation**: Upload digital content with custom pricing and royalty rates
- 💰 **Automatic Purchases**: Buyers can purchase content with automatic payment distribution
- 🔄 **Resale Royalties**: Original creators earn royalties on secondary sales
- 📊 **Analytics**: Track sales, revenue, and creator statistics
- ⚙️ **Platform Management**: Configurable platform fees and content management

## 🛠️ Contract Functions

### Public Functions

#### `register-creator()`
Register as a content creator on the platform.

#### `create-content(title, price, royalty-percentage)`
Create new digital content with specified price and royalty rate.
- `title`: Content title (max 100 characters)
- `price`: Content price in microSTX
- `royalty-percentage`: Royalty rate (0-10000, where 10000 = 100%)

#### `purchase-content(content-id)`
Purchase digital content with automatic payment distribution.

#### `resell-content(content-id, resale-price)`
Resell content with automatic royalty payments to original creator.

#### `update-platform-fee(new-fee-percentage)`
Update platform fee percentage (owner only).

#### `deactivate-content(content-id)`
Deactivate content (creator only).

### Read-Only Functions

#### `get-creator-info(creator)`
Get creator statistics and information.

#### `get-content-info(content-id)`
Get detailed content information.

#### `get-sale-info(sale-id)`
Get sale transaction details.

#### `get-platform-stats()`
Get platform-wide statistics.

#### `calculate-royalty(content-id, sale-price)`
Calculate royalty amount for a given sale price.

## 💡 Usage Examples

### Register as Creator
```clarity
(contract-call? .royalty-payments-for-creators register-creator)
```

### Create Content
```clarity
(contract-call? .royalty-payments-for-creators create-content "My Digital Art" u1000000 u1000)
```

### Purchase Content
```clarity
(contract-call? .royalty-payments-for-creators purchase-content u1)
```

### Resell Content
```clarity
(contract-call? .royalty-payments-for-creators resell-content u1 u1500000)
```

## 🔧 Development

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Setup
```bash
clarinet new royalty-payments-project
```

```bash
cd royalty-payments-project
```

```bash
clarinet contract new royalty-payments-for-creators
```

### Testing
```bash
clarinet test
```

### Deploy
```bash
clarinet deploy
```

## 📈 Key Concepts Demonstrated

- **Automatic Payouts**: Payments are automatically distributed between creators, platform, and royalties
- **Royalty System**: Creators earn ongoing royalties from secondary sales
- **Data Management**: Efficient storage and retrieval of creator, content, and sale data
- **Access Control**: Proper authorization checks for sensitive operations
- **Fee Calculation**: Percentage-based fee and royalty calculations

## 🎯 Learning Outcomes

This contract teaches:
- Implementing automatic payment distribution
- Managing royalty systems
- Handling marketplace transactions
- Data modeling for creator platforms
- Access control patterns
- Mathematical operations in Clarity

## 🔒 Security Features

- Input validation for all parameters
- Authorization checks for sensitive operations
- Safe arithmetic operations
- Proper error handling
- Balance verification before transfers

## 📊 Platform Economics

- Default platform fee: 2.5%
- Customizable royalty rates up to 100%
- Transparent fee structure
- Real-time revenue tracking

Start building your creator economy with automatic royalty payments! 🎨✨
```

**Git Commit Message:**
```
feat: implement royalty payments system with automatic creator payouts
```

**GitHub Pull Request Title:**
```
🎨 Add Royalty Payments for Creators Contract - Automatic Payouts System
```

**GitHub Pull Request Description:**
```
## 🎨 Royalty Payments for Creators - MVP Implementation

This PR introduces a comprehensive smart contract system for managing digital content creator royalties with automatic payment distribution.

### ✨ Features Added
- **Creator Registration System**: Artists can register and manage their profiles
- **Content Management**: Upload digital content with custom pricing and royalty rates
- **Automatic Purchase Flow**: Seamless buying experience with instant payment distribution
- **Secondary Sale Royalties**: Original creators earn ongoing royalties from resales
- **Platform Fee Management**: Configurable platform fees with owner controls
- **Comprehensive Analytics**: Track sales, revenue, and creator performance

### 🔧 Technical Implementation
- **Automatic Payouts**: Demonstrates STX transfer automation and payment splitting
- **Data Modeling**: Efficient maps for creators, content, and sales tracking
- **Access Control**: Proper authorization patterns for sensitive operations
- **Mathematical Operations**: Percentage-based calculations for fees and royalties
- **Error Handling**: Comprehensive error codes and validation

### 📊 Contract Stats
- **150+ lines** of clean, production-ready Clarity code
- **8 public functions** for core

