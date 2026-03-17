# frozen_string_literal: true

begin
  require "redis"
rescue LoadError
  Rails.logger.warn("[SlotLockService] Redis gem not available — slot locking disabled")
end

module Bookings
  # Manages temporary Redis-based locks on time slots while users
  # fill out the booking form. Prevents two users from booking
  # the same slot simultaneously.
  #
  # Gracefully degrades: if Redis is unavailable, all methods
  # return safe defaults (no locks) so the booking flow still works.
  # All errors are logged for debugging.
  class SlotLockService
    LOCK_TTL = 5.minutes.to_i # 5 minute hold

    def self.redis
      return nil unless defined?(::Redis)

      @redis ||= ::Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    rescue StandardError => e
      Rails.logger.error("[SlotLockService] Redis connection failed: #{e.message}")
      nil
    end

    def self.lock(business_id:, employee_id:, date:, time:)
      return nil unless redis

      key   = slot_key(business_id, employee_id, date, time)
      token = SecureRandom.hex(16)
      locked = redis.set(key, token, nx: true, ex: LOCK_TTL)
      Rails.logger.info("[SlotLockService] Lock #{locked ? 'acquired' : 'denied'}: #{key}")
      locked ? token : nil
    rescue StandardError => e
      Rails.logger.error("[SlotLockService] Lock failed for #{business_id}/#{employee_id}/#{date}/#{time}: #{e.message}")
      nil
    end

    def self.unlock(business_id:, employee_id:, date:, time:, token:)
      return unless redis

      key     = slot_key(business_id, employee_id, date, time)
      current = redis.get(key)
      if current == token
        redis.del(key)
        Rails.logger.info("[SlotLockService] Unlocked: #{key}")
      end
    rescue StandardError => e
      Rails.logger.error("[SlotLockService] Unlock failed for #{business_id}/#{employee_id}/#{date}/#{time}: #{e.message}")
    end

    def self.locked?(business_id:, employee_id:, date:, time:)
      return false unless redis

      result = redis.exists?(slot_key(business_id, employee_id, date, time))
      result
    rescue StandardError => e
      Rails.logger.error("[SlotLockService] Lock check failed for #{business_id}/#{employee_id}/#{date}/#{time}: #{e.message}")
      false
    end

    def self.slot_key(business_id, employee_id, date, time)
      "slot_lock:#{business_id}:#{employee_id}:#{date}:#{time}"
    end
    private_class_method :slot_key
  end
end
