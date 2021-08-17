# frozen_string_literal: true

class EasyStalk::MethodDelegator
  def self.delegate(message, to:)
    signature = new(message, to).load

    if signature.any?
      to.call(**signature)
    else
      to.call
    end
  end

  def self.serialize(message, format:)
    new(message, format).dump
  end

  attr_reader :message
  attr_reader :receiver

  def initialize(message, receiver)
    @message = message
    @receiver = receiver
  end

  def dump
    receiver.parameters.each_with_object({}) do |(constraint, argument), payload|
      case constraint
      when :key
        payload[argument] = data[argument] if data.key?(argument)
      when :keyreq
        payload[argument] = data.fetch(argument)
      when :keyrest
        payload.merge!(data)
      when :block, :opt, :req
        raise ArgumentError, "cannot serialize payload into #{constraint} #{argument}"
      else
        raise NotImplementedError
      end
    end
  end

  def load
    payload = message.dup

    receiver.parameters.each_with_object({}) do |(constraint, argument), signature|
      case constraint
      when :key
        signature[argument] = payload.delete(argument.to_s) if payload.key?(argument.to_s)
      when :keyreq
        signature[argument] = payload.delete(argument.to_s)
      when :keyrest
        signature.merge!(payload.inject({}) { |a, (k, v)| a.merge(k.to_sym => v) })
      when :block, :opt, :req
        raise ArgumentError, "cannot deserialize payload into #{constraint} #{argument}"
      else
        raise NotImplementedError, "unsupported argument constraint: #{constraint}"
      end
    end
  end
end
