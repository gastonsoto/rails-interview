require "faraday"
require "json"

module ExternalSync
  class NoAuthStrategy < BaseStrategy
    BASE_URL = "http://localhost:3000"

    def initialize
      @conn = Faraday.new(url: BASE_URL) do |f|
        f.request :json
        f.response :json
        f.adapter Faraday.default_adapter
      end
    end

    def fetch_all
      response = @conn.get("/todolists")
      handle_response(response)
    end

    def create_list(params)
      response = @conn.post("/todolists", params)
      handle_response(response)
    end

    def update_list(external_id, params)
      response = @conn.patch("/todolists/#{external_id}", params)
      handle_response(response)
    end

    def delete_list(external_id)
      response = @conn.delete("/todolists/#{external_id}")
      handle_response(response)
    end

    def create_item(external_list_id, params)
      raise NotImplementedError, "Standalone item creation not supported by this API schema. Use list creation/update."
    end

    def update_item(external_list_id, external_item_id, params)
      # UpdateTodoItemBody: { description: string, completed: boolean }
      response = @conn.patch("/todolists/#{external_list_id}/todoitems/#{external_item_id}", params)
      handle_response(response)
    end

    def delete_item(external_list_id, external_item_id)
      response = @conn.delete("/todolists/#{external_list_id}/todoitems/#{external_item_id}")
      handle_response(response)
    end

    private

    def handle_response(response)
      if response.success?
        response.body
      else
        error_message = response.body.is_a?(Hash) ? response.body["error"] : "Unknown error"
        raise ExternalSync::ApiError.new(error_message, response.status)
      end
    end
  end

  class ApiError < StandardError
    attr_reader :status
    def initialize(message, status)
      @status = status
      super("#{message} (Status: #{status})")
    end
  end
end
