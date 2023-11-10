require "rails_helper"


describe "Create Region", type: :request do
  describe "Failure scenarios" do
    context "1. with missing 'description'" do
      before(:all) do
        # @region = Region.create(name: "Region1", subscription: "seeded", display_flag: "false")
        @region = {
          name: "Region 1",
          subscription: "seeded",
          display_flag: "false",
          api_hash: "c3ab8ff13720e8ad9047dd39466b3c8974e592c2fa383d4a3960714caef0c4f2"
        }
        post '/api/v1/region', params:
                              {
                                region: { api_hash: @region[:api_hash],
                                          name: @region[:name],
                                          subscription: @region[:subscription],
                                          display_flag: @region[:display_flag]
                                }
                              }
        @body = JSON.parse(response.body)
      end

      # it { is_expected.to respond_with 200 }
      # Above line works with shoulda-matchers gem only

      it "shall return http status 200" do
        expect(response).to have_http_status(:success)
      end
      it "'status' field should have value 'fail'" do
        expect(@body["status"]).to eq "fail"
      end
      it "shall fail with missing description" do
        expect(@body["message"]).to match(/description is missing/)
      end
    end

    context "2. with blank api_hash value" do
      before(:all) do
        @region = {
          name: "Region 1",
          subscription: "seeded",
          display_flag: "false",
          description: "Region 1",
          api_hash: ""
        }
        post '/api/v1/region', params:
                              {
                                region: { api_hash: @region[:api_hash],
                                          name: @region[:name],
                                          description: @region[:description],
                                          subscription: @region[:subscription],
                                          display_flag: @region[:display_flag]
                                }
                              }
        @body = JSON.parse(response.body)
      end
        
      it "shall return http status 200" do
        expect(response).to have_http_status(:success)
      end
      it "'status' field should have value 'fail'" do
        expect(@body["status"]).to eq "fail"
      end
      it "shall fail with message 'api_hash must be filled'" do
        expect(@body["status"]).to eq "fail"
        expect(@body["message"]).to match(/api_hash must be filled/)
      end
    end
  end

  describe "Success scenario" do
    context "1. Create region with name, description, subscription and display_flag" do
      before(:all) do
        # @region = Region.create(name: "Region1", description: "Region1", subscription: "seeded", display_flag: "false")
        @region = {
          name: "Region 1",
          subscription: "seeded",
          display_flag: "false",
          description: "Region 1",
          api_hash: "c3ab8ff13720e8ad9047dd39466b3c8974e592c2fa383d4a3960714caef0c4f2"
        }
        post '/api/v1/region', params:
                              {
                                region: { 
                                          name: @region[:name],
                                          description: @region[:description],
                                          subscription: @region[:subscription],
                                          display_flag: @region[:display_flag] 
                                        },
                                api_hash: @region[:api_hash]
                              }
        @body = JSON.parse(response.body)
      end

      it "shall have status 200" do
        expect(response).to have_http_status(:success)
      end

      it "shall create region" do
        expect(Region.find_by_id(@body["data"]["region_id"])).to be_instance_of Region
        expect(Region.find_by_id(@body["data"]["region_id"])).not_to be nil
        expect(@body["data"]["region_id"]).not_to be nil
        expect(@body["data"]["region_id"]).to be > 0

        # Regions count will change by 3 because of neighboring_regions creation
        # Subregions are not created because raw_polygon_json is not passed
        expect {
          post '/api/v1/region', params:
                              {
                                region: { 
                                  name: @region[:name],
                                  description: @region[:description],
                                  subscription: @region[:subscription],
                                  display_flag: @region[:display_flag] },
                                api_hash: @region[:api_hash]
                              }
        }.to change(Region, :count).by(3).and \
             change(Subregion, :count).by(0)
      end
      it "validates region name" do
        puts @body
        puts @region[:name]
        expect(Region.find_by_id(@body["data"]["region_id"]).name).to eq @region[:name]
      end

      it "shall create two neighboring regions" do
        expect(Region.find_by_id(@body["data"]["region_id"]).neighboring_regions.count).to be > 0
      end
    end
  end
end



# delete "/api/v1/region/#{@body["data"]["region_id"]}", params:
#                                                                {
#                                                                   api_hash: @region[:api_hash]
#                                                                }
