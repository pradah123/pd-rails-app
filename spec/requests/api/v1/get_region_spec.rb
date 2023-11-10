require 'rails_helper'
# Need to put following code in spec_helper

# config.before(:each, type: :request) do
#   host! "localhost:4000"
# end
# config.before(:all, type: :request) do
#   host! "localhost:4000"
# end

RSpec.describe 'Regions', type: :request do
  describe 'GET /index' do
    before(:all) do
      @region = Region.create(name: 'Test', subscription: "seeded", display_flag: "true")
      get "/api/v1/region/#{@region.id}"
      @body = JSON.parse(response.body)
    end
    it 'returns status code 200' do
      expect(response).to have_http_status(:success)
    end

    it "shall return region" do
      expect(@body["id"]).to eq(@region.id)
      puts JSON.parse(response.body)
    end

    it "validates subscription" do
      expect(@body["subscription"]).to eq "seeded"
    end

    it "check for invalid subscription" do
      expect(@body["subscription"]).not_to eq "public-seeded"
    end

    it "validates display_flag" do
      expect(@body["display_flag"]).to be true
    end
  end
end