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

    def read_attribute_for_validation(key)
      self[key]
    end

    def to_model
      self
    end

    def persisted?
      false
    end
  end
end
