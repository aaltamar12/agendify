// ============================================================
// Agendity — Demo handlers: credits (cashback, refunds, etc.)
// ============================================================

import { route } from '../router';
import { getStore, updateStore } from '../store';

// GET /api/v1/credits/summary
route('get', '/api/v1/credits/summary', () => {
  const store = getStore();
  const accounts = store.creditAccounts;
  const transactions = store.creditTransactions;

  const totalBalance = accounts.reduce((sum, a) => sum + a.balance, 0);
  const totalCashback = transactions
    .filter((t) => t.transaction_type === 'cashback')
    .reduce((sum, t) => sum + t.amount, 0);
  const totalRedemptions = transactions
    .filter((t) => t.transaction_type === 'redemption')
    .reduce((sum, t) => sum + Math.abs(t.amount), 0);
  const totalRefunds = transactions
    .filter((t) => t.transaction_type === 'refund')
    .reduce((sum, t) => sum + t.amount, 0);

  return {
    data: {
      total_balance: totalBalance,
      total_cashback_given: totalCashback,
      total_redeemed: totalRedemptions,
      total_refunded: totalRefunds,
      active_accounts: accounts.length,
      recent_transactions: transactions
        .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
        .slice(0, 10),
    },
  };
});

// GET /api/v1/customers/:id/credits
route('get', '/api/v1/customers/:id/credits', ({ params }) => {
  const customerId = Number(params.id);
  const store = getStore();

  const account = store.creditAccounts.find((a) => a.customer_id === customerId);
  const transactions = store.creditTransactions
    .filter((t) => t.customer_id === customerId)
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

  return {
    data: {
      balance: account?.balance ?? 0,
      account,
      transactions,
    },
  };
});

// GET /api/v1/customers/:id/credit_balance
route('get', '/api/v1/customers/:id/credit_balance', ({ params }) => {
  const customerId = Number(params.id);
  const store = getStore();
  const account = store.creditAccounts.find((a) => a.customer_id === customerId);

  return {
    data: {
      balance: account?.balance ?? 0,
    },
  };
});

// POST /api/v1/customers/:id/credits/adjust
route('post', '/api/v1/customers/:id/credits/adjust', ({ params, body }) => {
  const customerId = Number(params.id);
  const { amount, description } = body as { amount: number; description: string };
  const now = new Date().toISOString();
  const store = getStore();

  let account = store.creditAccounts.find((a) => a.customer_id === customerId);

  updateStore((s) => {
    if (!account) {
      account = {
        id: s.creditAccounts.length + 10,
        customer_id: customerId,
        business_id: 1,
        balance: 0,
        created_at: now,
        updated_at: now,
      };
      s.creditAccounts.push(account);
    }

    const acct = s.creditAccounts.find((a) => a.customer_id === customerId)!;
    acct.balance += amount;
    acct.updated_at = now;

    const txn = {
      id: s.creditTransactions.length + 100,
      credit_account_id: acct.id,
      customer_id: customerId,
      business_id: 1,
      amount,
      balance_after: acct.balance,
      transaction_type: 'manual_adjustment' as const,
      description: description || 'Ajuste manual',
      appointment_id: null,
      created_by_id: 1,
      created_at: now,
    };
    s.creditTransactions.push(txn);
  });

  const updatedAccount = getStore().creditAccounts.find((a) => a.customer_id === customerId);
  return { data: updatedAccount };
});

// POST /api/v1/credits/bulk_adjust
route('post', '/api/v1/credits/bulk_adjust', ({ body }) => {
  const { customer_ids, amount, description } = body as {
    customer_ids: number[];
    amount: number;
    description: string;
  };
  const now = new Date().toISOString();

  updateStore((s) => {
    for (const customerId of customer_ids) {
      let acct = s.creditAccounts.find((a) => a.customer_id === customerId);
      if (!acct) {
        acct = {
          id: s.creditAccounts.length + 10,
          customer_id: customerId,
          business_id: 1,
          balance: 0,
          created_at: now,
          updated_at: now,
        };
        s.creditAccounts.push(acct);
      }

      acct.balance += amount;
      acct.updated_at = now;

      s.creditTransactions.push({
        id: s.creditTransactions.length + 100,
        credit_account_id: acct.id,
        customer_id: customerId,
        business_id: 1,
        amount,
        balance_after: acct.balance,
        transaction_type: 'manual_adjustment',
        description: description || 'Ajuste masivo',
        appointment_id: null,
        created_by_id: 1,
        created_at: now,
      });
    }
  });

  return {
    data: {
      adjusted_count: customer_ids.length,
      amount_per_customer: amount,
    },
  };
});
