# frozen_string_literal: true

require 'restroom/relation'

module Restroom
  class Context
    STRUCTURE  = %i[children host parent key].freeze
    ATTRIBUTES = %i[resource model id response_filter].freeze
    INHERITABLE = %i[response_filter].freeze

    attr_reader(*STRUCTURE)
    attr_accessor(*ATTRIBUTES)

    INHERITABLE.each do |attr|
      define_method attr do |value = nil|
        return instance_variable_set("@#{attr}", value) if value
        instance_variable_get("@#{attr}") || @parent.send(attr)
      end
    end

    def initialize(host: nil, parent:, key: nil, **args, &block)
      @children = []
      @id = :id

      args.each { |k, v| send "#{k}=", v }
      instance_eval(&block) if block_given?

      @key = key
      @resource ||= key
      @model ||= classify_resource(@resource)
      @host = host || model # TODO: guess model from key
      @parent = parent

      @model.send(:attr_accessor, :restroom_parent) if @model

      @host.include Relation
      @children.each do |child|
        @host.add_relation(child.key, child)
      end
    end

    def classify_resource(resource)
      resource.to_s.classify.constantize if resource
    end

    def exposes(key, **args, &block)
      @children << self.class.new(key: key, parent: self, **args, &block)
    end

    def dump
      dumper(self, 0)
    end

    def dumper(context, depth)
      puts "#{'  ' * depth}#{context} - host: #{context.host}, " \
        "parent: #{context.parent}, class: #{context.model}, id: #{context.id}"
      context.children.each do |child|
        dumper(child, depth + 1)
      end
    end
  end
end
