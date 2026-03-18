module ExternalSync
  class BaseStrategy
    def fetch_all
      raise NotImplementedError, "#{self.class} must implement fetch_all"
    end

    def create_list(params)
      raise NotImplementedError, "#{self.class} must implement create_list"
    end

    def update_list(external_id, params)
      raise NotImplementedError, "#{self.class} must implement update_list"
    end

    def delete_list(external_id)
      raise NotImplementedError, "#{self.class} must implement delete_list"
    end

    def create_item(external_list_id, params)
      raise NotImplementedError, "#{self.class} must implement create_item"
    end

    def update_item(external_list_id, external_item_id, params)
      raise NotImplementedError, "#{self.class} must implement update_item"
    end

    def delete_item(external_list_id, external_item_id)
      raise NotImplementedError, "#{self.class} must implement delete_item"
    end
  end
end
