module CollectionFilter
  class ParametersModel < ActionController::Parameters
    extend ActiveModel::Naming
    include ActiveModel::Validations

    def validate(hash)
      hash.each do |attr, validations|
        self.class.send(:validates, attr, validations)
      end
      self
    end

    def method_missing(name, *args, &blk)
      if key?(name) && args.empty? && blk.nil?
        self[name]
      elsif match = name.to_s.match(/(.+)=$/)
        self[match[1]] = args.first
      else
        super
      end
    end

    def respond_to_missing?(symbol, include_private)
      key?(symbol) ? true : super
    end

    def to_model
      self
    end

    def persisted?
      false
    end
  end
end
