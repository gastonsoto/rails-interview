module ExternalSync
  class SyncService
    def initialize(user, strategy)
      @user = user
      @strategy = strategy
      @provider_name = strategy.class.name.demodulize.underscore.gsub('_strategy', '')
    end

    def sync!
      Rails.logger.info "[ExternalSync] Starting sync for User: #{@user.id}, Provider: #{@provider_name}"

      # 1. Pull changes from remote (Create/Update local)
      remote_lists = @strategy.fetch_all
      sync_remote_to_local(remote_lists)

      # 2. Push local changes to remote
      push_local_changes_to_remote

      Rails.logger.info "[ExternalSync] Finished sync for User: #{@user.id}"
    rescue => e
      Rails.logger.error "[ExternalSync] Sync failed: #{e.message}"
      Rails.logger.debug e.backtrace.join("\n")
      raise
    end

    private

    def sync_remote_to_local(remote_lists)
      remote_ids = remote_lists.map { |l| l["id"].to_s }
      
      # Handle remote deletions: Only delete locally if it WAS linked and is now missing
      @user.todo_lists.where(provider: @provider_name)
           .where.not(external_id: nil)
           .where.not(external_id: remote_ids)
           .destroy_all

      remote_lists.each do |remote_list|
        list = @user.todo_lists.find_or_initialize_by(external_id: remote_list["id"].to_s, provider: @provider_name)
        
        remote_updated_at = remote_list["updated_at"] ? Time.parse(remote_list["updated_at"]) : Time.at(0)

        if list.new_record? || list.last_synced_at.nil? || remote_updated_at > list.last_synced_at
           list.name = remote_list["name"]
           # Set last_synced_at slightly ahead to avoid immediate re-push in the same scan
           list.save!
           list.update_column(:last_synced_at, Time.current + 1.second)
        end

        sync_items_to_local(list, remote_list["items"] || [])
      end
    end

    def sync_items_to_local(list, remote_items)
      item_ids = remote_items.map { |i| i["id"].to_s }
      
      # Remote items missing from local
      list.todo_list_items.where.not(external_id: nil).where.not(external_id: item_ids).destroy_all

      remote_items.each do |remote_item|
        item = list.todo_list_items.find_or_initialize_by(external_id: remote_item["id"].to_s)
        
        remote_item_updated_at = remote_item["updated_at"] ? Time.parse(remote_item["updated_at"]) : Time.at(0)

        if item.new_record? || item.updated_at < remote_item_updated_at
          item.description = remote_item["description"]
          item.status = remote_item["completed"] ? :closed : :active
          item.save!
        end
      end
    end

    def push_local_changes_to_remote
      # Push new lists or lists modified since last sync
      @user.todo_lists.where(provider: @provider_name).where("last_synced_at IS NULL OR updated_at > last_synced_at").each do |list|
        begin
          if list.external_id.present?
            @strategy.update_list(list.external_id, { name: list.name })
          else
            items_params = list.todo_list_items.map { |i| { source_id: i.id.to_s, description: i.description, completed: i.closed? } }
            result = @strategy.create_list({ source_id: list.id.to_s, name: list.name, items: items_params })
            list.update_columns(external_id: result["id"].to_s)
          end
          list.update_column(:last_synced_at, Time.current)
        rescue => e
          Rails.logger.error "[ExternalSync] Failed to push list #{list.id}: #{e.message}"
        end
      end

      # Push item updates
      @user.todo_lists.where(provider: @provider_name).where.not(external_id: nil).each do |list|
        list.todo_list_items.where("updated_at > ?", list.last_synced_at || Time.at(0)).each do |item|
          begin
            if item.external_id.present?
              @strategy.update_item(list.external_id, item.external_id, { description: item.description, completed: item.closed? })
            end
            # We don't have per-item last_synced_at, but the list one covers it
          rescue => e
            Rails.logger.error "[ExternalSync] Failed to push item #{item.id}: #{e.message}"
          end
        end
      end
    end
  end
end
