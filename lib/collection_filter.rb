require "collection_filter/version"

module CollectionFilter
  module Helpers
    module FormHelper
      def filter_form_for(filter = nil, options = {}, &proc)
        filter_object = filter || _filter_params
        filter_object.instance_variable_set(:@_filter_form, true)
        options[:url] ||= polymorphic_path(_record_name)
        options[:html] ||= {}
        options[:html].reverse_merge!(
          :class  => options[:as] || _filter_name(filter),
          :id     => options[:as] || [options[:namespace], _filter_name(filter)].compact.join("_").presence,
          :method => :get
        )
        options[:as] ||= _filter_name(filter)
        options[:builder] ||= CollectionFilter::Helpers::FormBuilder
        form_for(filter_object, options, &proc)
      end

      def filter_form(options = {}, &proc)
        filter_form_for(nil, options, &proc)
      end

      def filter_fields_for(filter = nil, options = {}, &block)
        filter_object = filter || _filter_params
        filter_object.instance_variable_set(:@_filter_form, true)
        fields_for(_filter_name(filter), filter_object, options, &block)
      end

      def filter_fields(options = {}, &block)
        filter_fields_for(nil, options, &block)
      end

      private
      def _filter_params
        respond_to?(:filter_params) ? filter_params : params.to_model
      end

      def _record_name
        controller_name.sub(/Controller$/, '').underscore.to_sym
      end

      def _filter_name(filter = nil)
        filter ? filter.class.to_s.underscore.to_sym : "#{_record_name}_filter"
      end
    end

    module InstanceTagExt
      extend ActiveSupport::Concern

      included do
        alias_method_chain :value, :filter
        alias_method_chain :value_before_type_cast, :filter
        alias_method_chain :tag_name, :filter
      end

      def value_with_filter(object)
        if filter_form?
          object && object[@method_name]
        else
          value_without_filter(object)
        end
      end

      def value_before_type_cast_with_filter(object)
        if filter_form?
          object &&
          object[@method_name + "_before_type_cast"] ||
          object[@method_name]
        else
          value_before_type_cast_without_filter(object)
        end
      end

      private
      def tag_name_with_filter
        if filter_form?
          sanitized_method_name
        else
          tag_name_without_filter
        end
      end

      def filter_form?
        @object.instance_variable_defined?(:@_filter_form) && @object.instance_variable_get(:@_filter_form)
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

  module ParametersExt
    def default(hash = nil)
      return super unless hash.is_a?(Hash)
      params = self.class.new(hash)
      self.each do |key, value|
        params[key] = value if value.present?
      end
      params
    end

    def to_model
      # for proper working of callback
      klass = Class.new(CollectionFilter::ParametersModel)
      klass_id = '0x%014x' % (klass.object_id << 1)
      eval <<-RUBY
        ::ParametersModel#{klass_id} = klass
      RUBY
      klass.new(self)
    end

    def validate(hash)
      self.to_model.validate(hash)
    end
  end

  class Railtie < Rails::Railtie
    initializer 'collection_filter' do
      ActiveSupport.on_load :action_view do
        ActionView::Base.send :include, CollectionFilter::Helpers::FormHelper
        ActionView::Helpers::InstanceTag.send :include, CollectionFilter::Helpers::InstanceTagExt
      end

      ActiveSupport.on_load :action_controller do
        ActionController::Parameters.send :include, CollectionFilter::ParametersExt
        require 'collection_filter/parameters_model'
      end
    end
  end
end
