require "collection_filter/version"
require "ostruct"

module CollectionFilter
  module Helpers
    module FormHelper
      def filter_form_for(filter = nil, options = {}, &proc)
        @filter_object ||= CollectionFilter::SimpleFilter.new(filter || _filter_params, controller_name)
        options[:url] ||= polymorphic_path(@filter_object._record_name)
        options[:html] ||= {}
        options[:html].reverse_merge!(
          :class  => options[:as] || @filter_object._name,
          :id     => options[:as] || [options[:namespace], @filter_object._name].compact.join("_").presence,
          :method => :get
        )
        options[:as] ||= @filter_object._name
        options[:builder] ||= CollectionFilter::Helpers::FormBuilder
        form_for(@filter_object, options, &proc)
      end

      def filter_form(options = {}, &proc)
        filter_form_for(nil, options, &proc)
      end

      def filter_fields_for(filter = nil, options = {}, &block)
        @filter_object ||= CollectionFilter::SimpleFilter.new(filter || _filter_params, controller_name)
        fields_for(@filter_object._name, @filter_object, options, &block)
      end

      def filter_fields(options = {}, &block)
        filter_fields_for(nil, options, &block)
      end

      private
      def _filter_params
        respond_to?(:filter_params) ? filter_params : params
      end
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

  class SimpleFilter < OpenStruct
    alias :initialize_for_open_struct :initialize
    include CollectionFilter::Filter

    def initialize(params, controller_name)
      if params.is_a?(Hash)
        initialize_for_open_struct(params)
      else
        initialize_for_open_struct
        @_delegate_object = params
      end
      @_controller_name = controller_name.to_s
      @_filter_form = true
    end

    def _record_name
      @_controller_name.sub(/Controller$/, '').underscore.to_sym
    end

    def _name
      @_delegate_object ? @_delegate_object.class.to_s.underscore.to_sym : "#{_record_name}_filter"
    end

    def method_missing(name, *args)
      super
    rescue NameError
      @_delegate_object.send(name, *args)
    end

    def respond_to_missing?(symbol, include_private)
      super || @_delegate_object.respond_to_missing?(symbol, include_private)
    end
  end

  module ParametersExt
    def default(hash = nil)
      return super unless hash.is_a?(Hash)
      hash.each do |key, value|
        self[key] = self[key].presence || value
      end
      self
    end
  end

  class Railtie < Rails::Railtie
    initializer 'collection_filter' do
      ActiveSupport.on_load :action_view do
        ActionView::Base.send :include, CollectionFilter::Helpers::FormHelper
        ActionView::Helpers::InstanceTag.send :include, CollectionFilter::Helpers::InstanceTagExt
      end

      ActiveSupport.on_load :action_controller do
        if defined? ActionController::Parameters
          ActionController::Parameters.send :include, CollectionFilter::ParametersExt
        end
      end
    end
  end
end
