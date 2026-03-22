# frozen_string_literal: true

class CreditAccount < ApplicationRecord
  belongs_to :customer
  belongs_to :business
  has_many :credit_transactions, dependent: :destroy

  validates :customer_id, uniqueness: { scope: :business_id }
  validates :balance, numericality: { greater_than_or_equal_to: 0 }

  def credit!(amount, transaction_type:, description:, appointment: nil, performed_by: nil, metadata: {})
    transaction do
      credit_transactions.create!(
        amount: amount,
        transaction_type: transaction_type,
        description: description,
        appointment: appointment,
        performed_by_user: performed_by,
        metadata: metadata
      )
      increment!(:balance, amount)
    end
  end

  def debit!(amount, transaction_type:, description:, appointment: nil, performed_by: nil, metadata: {})
    raise "Saldo insuficiente" if balance < amount
    transaction do
      credit_transactions.create!(
        amount: -amount,
        transaction_type: transaction_type,
        description: description,
        appointment: appointment,
        performed_by_user: performed_by,
        metadata: metadata
      )
      decrement!(:balance, amount)
    end
  end
end
