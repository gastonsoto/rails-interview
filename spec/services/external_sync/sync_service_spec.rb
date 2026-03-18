require 'rails_helper'

RSpec.describe ExternalSync::SyncService do
  let(:user) { User.create!(email: "test@example.com", password: "password") }
  let(:strategy) { instance_double(ExternalSync::NoAuthStrategy) }
  let(:service) { described_class.new(user, strategy) }

  before do
    allow(strategy.class).to receive(:name).and_return("ExternalSync::NoAuthStrategy")
  end

  describe '#sync!' do
    context 'pulling from remote' do
      it 'creates local records from remote data' do
        remote_data = [
          {
            "id" => "ext_1",
            "name" => "Remote List",
            "updated_at" => Time.current.to_s,
            "items" => [
              { "id" => "ext_item_1", "description" => "Item 1", "completed" => false, "updated_at" => Time.current.to_s }
            ]
          }
        ]
        allow(strategy).to receive(:fetch_all).and_return(remote_data)
        # Pulling a record shouldn't immediately trigger a push if timestamps are handled correctly
        # but the service calls both. We need to allow the push check.
        # Since last_synced_at will be >= updated_at, no strategy call should happen for this list.

        expect { service.sync! }.to change { user.todo_lists.count }.by(1)
          .and change { TodoListItem.count }.by(1)

        list = user.todo_lists.first
        expect(list.external_id).to eq("ext_1")
        expect(list.todo_list_items.first.external_id).to eq("ext_item_1")
      end

      it 'updates local records if remote is newer' do
        list = user.todo_lists.create!(name: "Old Name", external_id: "ext_1", provider: "no_auth", last_synced_at: 1.day.ago)
        
        remote_data = [
          {
            "id" => "ext_1",
            "name" => "New Name",
            "updated_at" => Time.current.to_s,
            "items" => []
          }
        ]
        allow(strategy).to receive(:fetch_all).and_return(remote_data)

        service.sync!
        expect(list.reload.name).to eq("New Name")
      end

      it 'removes local records missing from remote' do
        user.todo_lists.create!(name: "Ghost List", external_id: "ext_ghost", provider: "no_auth")
        
        allow(strategy).to receive(:fetch_all).and_return([])

        expect { service.sync! }.to change { user.todo_lists.count }.by(-1)
      end
    end

    context 'pushing to remote' do
      it 'creates remote record for new local list' do
        list = user.todo_lists.create!(name: "Local New", provider: "no_auth")
        item = list.todo_list_items.create!(description: "New Item", status: :active)
        
        allow(strategy).to receive(:fetch_all).and_return([])
        expect(strategy).to receive(:create_list).with(hash_including(
          source_id: list.id.to_s,
          name: "Local New",
          items: array_including(hash_including(source_id: item.id.to_s, description: "New Item", completed: false))
        )).and_return({ "id" => "ext_new", "items" => [] })

        service.sync!
        expect(list.reload.external_id).to eq("ext_new")
      end

      it 'updates remote record for modified local list' do
        list = user.todo_lists.create!(name: "Modified Local", external_id: "ext_1", provider: "no_auth", last_synced_at: 1.day.ago)
        list.update!(name: "Updated Local") # triggers updated_at > last_synced_at

        allow(strategy).to receive(:fetch_all).and_return([{ "id" => "ext_1", "name" => "Updated Local", "items" => [] }])
        expect(strategy).to receive(:update_list).with("ext_1", { name: "Updated Local" })

        service.sync!
      end
    end
  end
end
