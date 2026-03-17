# frozen_string_literal: true

namespace :encryption do
  desc "Encrypt existing plaintext payment data in businesses table"
  task encrypt_existing_payments: :environment do
    count = 0
    Business.find_each do |business|
      has_payment = business.nequi_phone.present? ||
                    business.daviplata_phone.present? ||
                    business.bancolombia_account.present?
      next unless has_payment

      # Re-saving triggers Active Record Encryption on the fields
      business.save!(validate: false)
      count += 1
    end

    puts "Encrypted payment data for #{count} businesses."
  end
end
