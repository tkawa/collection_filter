require "collection_filter/version"

module CollectionFilter
  module Helpers
    module FormHelper
      def filter_form_for(record, options = {}, &proc)
        object = record.is_a?(Array) ? record.last : record
        object = convert_to_model(object)
        object.instance_variable_set(:@_filter_form, true)
        url_for_record = Array.wrap(record).map {|o|
          class_name = o.class.to_s
          class_name.end_with?('Filter') ? class_name.sub(/Filter$/, '').underscore.pluralize.to_sym : o
        }
        options[:url] ||= polymorphic_path(url_for_record)
        options[:html] ||= {}
        options[:html].reverse_merge!(
          :class  => options[:as] || dom_class(object),
          :id     => options[:as] || [options[:namespace], dom_class(object)].compact.join("_").presence,
          :method => :get
        )
        options[:builder] ||= CollectionFilter::Helpers::FormBuilder
        form_for(record, options, &proc)
      end

      #def filter_fields_for(record_name, record_object = nil, options = {}, &block)
      #  object.instance_variable_set(:@_filter_form, true)
      #  fields_for(record_name, record_object, options, &block)
      #end
    end

    module InstanceTagExt
      def self.included(base)
        base.send :alias_method_chain, :tag_name, :filter
      end

      private
      def tag_name_with_filter
        if @object.instance_variable_defined?(:@_filter_form) && @object.instance_variable_get(:@_filter_form)
          sanitized_method_name
        else
          tag_name_without_filter
        end
      end
    end

    class FormBuilder < ActionView::Helpers::FormBuilder
      def button(value=nil, options={})
        value, options = nil, value if value.is_a?(Hash)
        options[:name] ||= nil
        super
      end

      private
      def submit_default_value
        object = convert_to_model(@object)
        key    = :submit

        model = if object.class.respond_to?(:model_name)
          object.class.model_name.human
        else
          @object_name.to_s.humanize
        end

        defaults = []
        defaults << :"helpers.submit.#{object_name}.#{key}"
        defaults << :"helpers.submit.#{key}"
        defaults << "#{key.to_s.humanize} #{model}"

        I18n.t(defaults.shift, :model => model, :default => defaults)
      end
    end
  end

  module Filter
    extend ActiveSupport::Concern
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include ActiveRecord::AttributeAssignment
    #include ActiveModel::MassAssignmentSecurity

    def initialize(attributes=nil, options={})
      assign_attributes(attributes, options)
    end

    def persisted?
      false
    end
  end

  class Railtie < Rails::Railtie
    initializer 'collection_filter' do
      ActiveSupport.on_load :action_view do
        ActionView::Base.send :include, CollectionFilter::Helpers::FormHelper
        ActionView::Helpers::InstanceTag.send :include, CollectionFilter::Helpers::InstanceTagExt
      end
    end
  end
end
