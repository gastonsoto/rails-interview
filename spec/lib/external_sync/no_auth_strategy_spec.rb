require 'rails_helper'

RSpec.describe ExternalSync::NoAuthStrategy do
  let(:strategy) { described_class.new }
  let(:base_url) { "http://localhost:3000" }

  describe '#fetch_all' do
    it 'returns all todo lists' do
      stub_request(:get, "#{base_url}/todolists")
        .to_return(status: 200, body: [{ id: "1", name: "List 1", items: [] }].to_json, headers: { 'Content-Type' => 'application/json' })

      result = strategy.fetch_all
      expect(result).to eq([{ "id" => "1", "name" => "List 1", "items" => [] }])
    end
  end

  describe '#create_list' do
    it 'posts a new list with source_id' do
      params = { source_id: "5", name: "New List", items: [] }
      stub_request(:post, "#{base_url}/todolists")
        .with(body: params.to_json)
        .to_return(status: 201, body: { id: "2", source_id: "5", name: "New List", items: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = strategy.create_list(params)
      expect(result["source_id"]).to eq("5")
    end
  end

  describe '#update_list' do
    it 'patches a list name' do
      params = { name: "Updated Name" }
      stub_request(:patch, "#{base_url}/todolists/1")
        .with(body: params.to_json)
        .to_return(status: 200, body: { id: "1", name: "Updated Name" }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = strategy.update_list("1", params)
      expect(result["name"]).to eq("Updated Name")
    end
  end

  describe '#delete_list' do
    it 'deletes a list' do
      stub_request(:delete, "#{base_url}/todolists/1")
        .to_return(status: 204)

      expect { strategy.delete_list("1") }.not_to raise_error
    end
  end

  describe '#update_item' do
    it 'patches a todo item' do
      params = { description: "Updated Item", completed: true }
      stub_request(:patch, "#{base_url}/todolists/1/todoitems/10")
        .with(body: params.to_json)
        .to_return(status: 200, body: { id: "10", description: "Updated Item", completed: true }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = strategy.update_item("1", "10", params)
      expect(result["completed"]).to be true
    end
  end

  describe '#delete_item' do
    it 'deletes a todo item' do
      stub_request(:delete, "#{base_url}/todolists/1/todoitems/10")
        .to_return(status: 204)

      expect { strategy.delete_item("1", "10") }.not_to raise_error
    end
  end
end
