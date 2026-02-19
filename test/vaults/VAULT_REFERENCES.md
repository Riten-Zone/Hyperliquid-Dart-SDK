# Vault References

## Vault Address Mapping

Quick reference mapping of vault names to addresses and leaders. The APR can be varied, this is only an example:

| Vault Name | Vault Address | Leader | Past Month Return | Commission |
|------------|---------------|--------|----------------|------------|
| Hyperliquid Provider (HLP) | `0xdfc24b077bc1425ad1dea75bcb6f8158e10df303` | `0x677d831aef5328190852e24f13c46cac05f984e7` | ~73% APR | 0% |
| [ Systemic Strategies ] ♾️ HyperGrowth ♾️ | `0xd6e56265890b76413d1d527eb9b75e334c0c5b42` | `0x2b804617c6f63c040377e95bb276811747006f4b` | ~547% APR | 10% |
|Growi HF| `0x1e37a337ed460039d1b15bd3bc489de789768d5e` | `0x2b804617c6f63c040377e95bb276811747006f4b` | ~547% APR | 10% |

---

## Known Vaults on Hyperliquid Mainnet

### 1. Hyperliquid Provider (HLP)
- **Vault Address**: `0xdfc24b077bc1425ad1dea75bcb6f8158e10df303`
- **Leader**: `0x677d831aef5328190852e24f13c46cac05f984e7`
- **Type**: Parent vault with 7 child vaults
- **TVL**: ~$374M (as of Feb 2026)
- **Monthly Return**: ~73%
- **Commission**: 0%
- **Description**: Community-owned vault providing liquidity to Hyperliquid through multiple market making strategies, performs liquidations, and accrues platform fees.

**Child Vaults**:
1. `0x010461c14e146ac35fe42271bdc1134ee31c703a`
2. `0x2e3d94f0562703b25c83308a05046ddaf9a8dd14`
3. `0x2ed5c4484ea3ff8b57d5f2fb152a40d9f2b68308`
4. `0x31ca8395cf837de08b24da3f660e77761dfb974b`
5. `0x469f690213c467c39a23efacfd2816896009d7d8`
6. `0x5e177e5e39c0f4e421f5865a6d8beed8d921cb70`
7. `0xb0a55f13d22f66e6d495ac98113841b2326e9540`

---

### 2. [ Systemic Strategies ] ♾️ HyperGrowth ♾️
- **Vault Address**: `0xd6e56265890b76413d1d527eb9b75e334c0c5b42`
- **Leader**: `0x2b804617c6f63c040377e95bb276811747006f4b`
- **Type**: Normal vault (part of Systemic Strategies family)
- **Monthly Return**: ~547% (as of Feb 2026)
- **Commission**: 10%
- **Followers**: 100+ (top 100 by equity)
- **Description**: High-growth strategy vault by Systemic Strategies

**Other Vaults by Same Leader**:
- [ Systemic Strategies ] L/S Grids: `0x07fd993f0fa3a185f7207adccd29f7a87404689d`
- *(Leader manages 3 vaults total)*

---

## Testing with Real Vaults

### Method 1: Generalized Vault Explorer (Recommended)

Explore ANY vault with full details (TVL history, PnL, followers, etc.):

```bash
# HLP Vault
export TEST_VAULT_ADDRESS=0xdfc24b077bc1425ad1dea75bcb6f8158e10df303
export TEST_VAULT_LEADER=0x677d831aef5328190852e24f13c46cac05f984e7
dart run explore_vault.dart

# Systemic Strategies HyperGrowth
export TEST_VAULT_ADDRESS=0xd6e56265890b76413d1d527eb9b75e334c0c5b42
export TEST_VAULT_LEADER=0x2b804617c6f63c040377e95bb276811747006f4b
dart run explore_vault.dart
```

**Shows:**
- Basic info (Monthly Return, commission, followers 100+, TVL)
- Historical TVL (24h, 7d, 30d, all-time)
- Historical PnL (24h, 7d, 30d, all-time)
- Trading volume
- Top 10 followers with equity and PnL
- All vaults by the leader

### Method 2: Run Integration Tests

```bash
export TEST_VAULT_ADDRESS=0xYOUR_VAULT_ADDRESS
export TEST_VAULT_LEADER=0xLEADER_ADDRESS
dart test test/info/vault_info_test.dart
```

### Method 3: Vault-Specific Scripts

```bash
# HLP vault detailed analysis
dart run test_hlp_vault.dart
```

## Transferring Between Spot and Perp Accounts

Before depositing to vaults, you may need to transfer USDC between spot and perp accounts:

```bash
# Transfer from spot to perp (for vault deposits)
export HYPERLIQUID_PRIVATE_KEY=0xYOUR_PRIVATE_KEY
export TRANSFER_AMOUNT=10
export TO_PERP=true
dart run test_spot_perp_transfer.dart

# Transfer from perp to spot
export TO_PERP=false
dart run test_spot_perp_transfer.dart
```

**Using in code:**
```dart
// Spot → Perp
await exchange.usdClassTransfer(amount: '10', toPerp: true);

// Perp → Spot
await exchange.usdClassTransfer(amount: '10', toPerp: false);
```

---

## Depositing to Vaults & Checking Your Positions

### Testing Vault Deposits (MAINNET - Real Money!)

⚠️ **WARNING**: This deposits REAL USDC on MAINNET! Use small amounts for testing.

```bash
# Deposit $5 to a vault and verify (protocol minimum)
export HYPERLIQUID_PRIVATE_KEY=0xYOUR_PRIVATE_KEY
export TEST_VAULT_ADDRESS=0xVAULT_ADDRESS
dart run test_vault_deposit.dart
```

**What this script does:**
1. Shows vault information (name, leader, returns, commission)
2. Checks your current vault positions before deposit
3. Asks for confirmation (type "CONFIRM" to proceed)
4. Deposits $5 USDC to the vault (protocol minimum)
5. Verifies the deposit in your vault positions
6. Shows your follower state (equity, PnL, lockup period)

**Important Notes:**
- **Account Type**: Uses USDC from your **PERP account balance** (NOT spot!)
- **Protocol Minimum**: $5 USDC minimum deposit enforced by Hyperliquid
- **24-Hour Lockup**: You cannot withdraw for 24 hours after deposit
- **Leader Minimum**: Vault leaders must maintain at least 5% of total vault equity
- **Transfer if needed**: If your USDC is in spot, use `usdClassTransfer(amount: '5', toPerp: true)` first

### Checking Your Vault Positions

After depositing, you can check your positions using two methods:

**Method 1: Check all vault positions**
```dart
final info = InfoClient();
final equities = await info.userVaultEquities('0xYOUR_ADDRESS');

for (final equity in equities) {
  print('Vault ${equity.vaultAddress}: \$${equity.equity}');
}
```

**Method 2: Check specific vault with earnings**
```dart
final details = await info.vaultDetails(
  vaultAddress: '0xVAULT_ADDRESS',
  user: '0xYOUR_ADDRESS',
);

// Check if you're in the followers list (top 100 by equity)
final yourPosition = details.followers.where((f) =>
  f.user.toLowerCase() == yourAddress.toLowerCase()
).firstOrNull;

if (yourPosition != null) {
  print('Your Equity: \$${yourPosition.vaultEquity}');
  print('Recent PnL: \$${yourPosition.pnl}');
  print('All-Time PnL: \$${yourPosition.allTimePnl}');
  print('Days Following: ${yourPosition.daysFollowing}');
}
```

**Note**: You only appear in the followers list if you're in the top 100 by equity. Small positions may not show up in the list.

---

## Finding More Vaults

Visit [Hyperliquid Vaults](https://app.hyperliquid.xyz/vaults) to discover more vaults.
