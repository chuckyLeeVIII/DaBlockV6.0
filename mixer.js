const crypto = require('crypto');

class Family {
  constructor(name) {
    this.name = name;
    this.balance = 100; // Starting balance
    this.transactionPool = [];
    this.allowances = new Map();
    this.loans = new Map();
    this.twoFactorSecret = crypto.randomBytes(32).toString('hex');
  }

  setAllowance(recipient, amount, interval) {
    this.allowances.set(recipient, { amount, interval, lastPaid: Date.now() });
    console.log(`Allowance set for ${recipient}: ${amount} every ${interval} milliseconds`);
  }

  payAllowances() {
    const now = Date.now();
    for (let [recipient, allowance] of this.allowances.entries()) {
      if (now - allowance.lastPaid >= allowance.interval) {
        this.transact(recipient, allowance.amount);
        allowance.lastPaid = now;
      }
    }
  }

  requestLoan(amount, duration) {
    // Simple loan approval based on current balance
    if (this.balance >= amount * 0.1) {
      this.loans.set(crypto.randomBytes(16).toString('hex'), { amount, duration, remaining: amount });
      this.balance += amount;
      console.log(`Loan approved for ${this.name}: ${amount} for ${duration} days`);
    } else {
      console.log(`Loan request denied for ${this.name}: insufficient collateral`);
    }
  }

  repayLoan(loanId, amount) {
    if (this.loans.has(loanId)) {
      const loan = this.loans.get(loanId);
      loan.remaining -= amount;
      this.balance -= amount;
      console.log(`${this.name} repaid ${amount} for loan ${loanId}. Remaining: ${loan.remaining}`);
      if (loan.remaining <= 0) {
        this.loans.delete(loanId);
        console.log(`Loan ${loanId} fully repaid`);
      }
    } else {
      console.log(`Invalid loan ID for ${this.name}`);
    }
  }

  transact(recipient, amount, twoFactorCode) {
    if (!this.verifyTwoFactor(twoFactorCode)) {
      throw new Error('Invalid 2FA code');
    }
    if (this.balance < amount) {
      throw new Error('Insufficient balance');
    }
    this.balance -= amount;
    recipient.balance += amount;
    const transaction = { from: this.name, to: recipient.name, amount };
    this.transactionPool.push(transaction);
    console.log(`${this.name} sent ${amount} to ${recipient.name}`);
    return transaction;
  }

  verifyTwoFactor(code) {
    // Simple 2FA verification (in reality, use a proper TOTP algorithm)
    return crypto.createHash('sha256').update(this.twoFactorSecret + code).digest('hex').substr(0, 6) === code;
  }

  mine() {
    if (this.transactionPool.length > 0) {
      const reward = this.transactionPool.length * 0.1;
      this.balance += reward;
      console.log(`${this.name} mined ${reward} coins from ${this.transactionPool.length} transactions. New balance: ${this.balance}`);
      this.transactionPool = [];
    } else {
      console.log(`${this.name} has no transactions to mine.`);
    }
  }
}

class Network {
  constructor() {
    this.families = new Map();
  }

  addFamily(name) {
    const family = new Family(name);
    this.families.set(name, family);
    return family;
  }

  getFamily(name) {
    return this.families.get(name);
  }

  mineAllTransactions() {
    for (let family of this.families.values()) {
      family.mine();
    }
  }

  processAllowances() {
    for (let family of this.families.values()) {
      family.payAllowances();
    }
  }

  organizeEvent() {
    console.log("Organizing network event to equalize family values...");
    const totalValue = Array.from(this.families.values()).reduce((sum, family) => sum + family.balance, 0);
    const averageValue = totalValue / this.families.size;
    
    for (let family of this.families.values()) {
      const difference = averageValue - family.balance;
      family.balance += difference;
      console.log(`${family.name}'s balance adjusted by ${difference.toFixed(2)}. New balance: ${family.balance.toFixed(2)}`);
    }
  }
}

// Usage example
const network = new Network();

const family1 = network.addFamily("Smith");
const family2 = network.addFamily("Johnson");
const family3 = network.addFamily("Williams");

// Set up allowances
family1.setAllowance(family2, 5, 604800000); // 5 coins every week

// Request and repay loans
family3.requestLoan(50, 30);
family3.repayLoan(Array.from(family3.loans.keys())[0], 10);

// Simulate day-to-day transactions with 2FA
const twoFactorCode = crypto.createHash('sha256').update(family1.twoFactorSecret + '123456').digest('hex').substr(0, 6);
family1.transact(family2, 20, twoFactorCode);

// Process allowances
network.processAllowances();

// Mine transactions
network.mineAllTransactions();

// Organize event to equalize values
network.organizeEvent();