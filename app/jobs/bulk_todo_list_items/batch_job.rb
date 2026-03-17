module BulkTodoListItems
  class BatchJob < ApplicationJob
    queue_as :default

    def perform(op_id:, item_ids:)
      op = BulkOperation.find(op_id)
      return if op.finished? || op.failed?

      scope = TodoListItem.where(todo_list_id: op.todo_list_id, id: item_ids)

      processed = case op.action
      when "delete_all"
        scope.delete_all
      when "mark_all_done"
        scope.update_all(status: TodoListItem.statuses.fetch("closed"), updated_at: Time.current)
      else
        raise ArgumentError, "Unknown action: #{op.action}"
      end

      op.with_lock do
        op.processed_count += processed.to_i
        if op.processed_count >= op.total_count
          op.state = "finished"
          op.finished_at = Time.current
        end
        op.save!
      end

      # Update UI: list/items + progress bar
      TodoList.broadcast_lists!
      op.broadcast!
    rescue => e
      op&.update!(state: "failed", error_message: e.message, finished_at: Time.current)
      op&.broadcast!
      raise
    end
  end
end
