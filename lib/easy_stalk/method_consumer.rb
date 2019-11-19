# frozen_string_literal: true

module EasyStalk::MethodConsumer
  InvalidArgument = Class.new(StandardError)

  def self.included(descendant)
    descendant.extend ClassMethods

    super
  end

  module ClassMethods
    def serialize(data)
      instance_method(:call).parameters.each_with_object({}) do |(constraint, argument), payload|
        case constraint
        when :key, :req
          payload[argument] = data[argument] if data.key?(argument)
        when :keyreq
          payload[argument] = data.fetch(argument)
        when :keyrest
          payload.merge!(data)
        when :block, :opt
          raise InvalidArgument, "cannot serialize payload into #{constraint} #{argument}"
        else
          raise NotImplementedError
        end
      end
    end
  end

  def consume
    positional, named = deserialize
    call(*positional, **named)
  end

  def deserialize
    body = job.body.dup

    positional = []
    named =
      method(:call).parameters.each_with_object({}) do |(constraint, argument), signature|
        case constraint
        when :key
          signature[argument] = body.delete(argument.to_s) if body.key?(argument.to_s)
        when :keyreq
          signature[argument] = body.delete(argument.to_s)
        when :keyrest
          signature.merge!(body.inject({}) { |a, (k, v)| a.merge(k.to_sym => v) })
        when :req
          positional << body.delete(argument.to_s)
        when :block, :opt
          raise InvalidArgument, "cannot deserialize payload into #{constraint} #{argument}"
        else
          raise NotImplementedError
        end
      end

    [positional, named]
  end
end
