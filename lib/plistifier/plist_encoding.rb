require "cfpropertylist/rbCFPropertyList"

module Plistifier #:nodoc:
  module PlistEncoding

    attr_accessor :plist_item_options
    
    def to_plist(options = {})
      plist_options = {
        :converter_method => :to_plist_item,
        :convert_unknown_to_string => true
      }
      to_hash(options).to_plist(plist_options)
    end

    def to_plist_item
      to_hash(plist_item_options)
    end
    
    def to_hash(options = {})
      hashifier = PlistHashifier.new(self, options)
      hashifier.to_hash
    end

    class PlistHashifier #:nodoc:
      attr_reader :options

      def initialize(record, options = {})
        @record, @options = record, options.dup
      end

      # Outputs AR record instance method as a hash that can be easily
      # encoded as Plist.
      def to_hash
        hash = {}

        hash.merge!(simple_attributes)
        hash.merge!(method_attributes)
        hash.merge!(association_attributes)

        hash
      end
      
      # Returns 1st level attributes as a hash.
      def simple_attributes
        attribute_names = @record.attribute_names

        if options[:only]
          options.delete(:except)
          attribute_names = attribute_names & Array(options[:only]).collect(&:to_s)
        else
          options[:except] = Array(options[:except]) | Array(@record.class.inheritance_column)
          attribute_names = attribute_names - options[:except].collect(&:to_s)
        end

        attribute_names.reject! { |n| binary_attribute?(n) } # Don't Plist-ify binary fields!


        attrs = {}
        attribute_names.each do |name|
          attrs[name] = @record.read_attribute(name)
        end
        attrs
      end

      # Returns 1st level methods as a hash.
      def method_attributes
        Array(options[:methods]).inject({}) do |method_attributes, name|
          method_attributes.merge!({ name.to_s => @record.send(name.to_s) }) if @record.respond_to?(name.to_s)
          method_attributes
        end
      end

      # Returns 1st level associations as a hash. Recursively "hashifies"
      # associations so that nth level associations are converted to Plist as well.
      def association_attributes
        hash = {}

        if include_associations = options.delete(:include)
          base_only_or_except = { :except => options[:except],
                                  :only => options[:only] }

          include_has_options = include_associations.is_a?(Hash)

          for association in include_has_options ? include_associations.keys : Array(include_associations)
            association_options = include_has_options ? include_associations[association] : base_only_or_except

            opts = options.merge(association_options)

            case @record.class.reflect_on_association(association).macro
            when :has_many, :has_and_belongs_to_many
              records = @record.send(association).to_a
              unless records.empty?
                hash[association] = records.collect { |r| PlistHashifier.new(r, opts).to_hash }
              end
            when :has_one, :belongs_to
              if record = @record.send(association)
                hash[association] = PlistHashifier.new(record, opts).to_hash
              end
            end
          end

          options[:include] = include_associations
        end

        hash
      end

      protected

        def binary_attribute?(name)
          !@record.class.serialized_attributes.has_key?(name) && @record.class.columns_hash[name].type == :binary
        end
    end

  end
end

ActiveRecord::Base.send(:include, Plistifier::PlistEncoding)