require 'rails_helper'
require_relative '../../lib/region/neighboring_region.rb'

# Use shared example to test for both 5x and 12.5x region
describe "Region", type: :model do
  before(:each) {
    @region = double(Region)
    allow(@region).to receive(:name) { 'Region 1'}
    allow(@region).to receive(:id).and_return(1)
    allow(@region).to receive(:size).and_return(nil)

    allow(@region).to receive(:raw_polygon_json)
      .and_return('[{"type":"Polygon","coordinates":[[151.2003886086161,-33.855717948177315],[151.20421399138388,-33.855717948177315],[151.20421399138388,-33.85889465182268],[151.2003886086161,-33.85889465182268],[151.2003886086161,-33.855717948177315]]}]') 
    puts @region.raw_polygon_json

    allow(@region).to receive_message_chain(:neighboring_regions, :where, :first)
      .and_return(nil)
  }
  context "#create_neighboring_regions", create_nr: true do
    before(:each) {
      allow(@region).to receive(:scaled_bbox_geojson)
        .and_return([{"type":"Polygon","coordinates":[[151.2003886086161,-33.855717948177315],[151.20421399138388,-33.855717948177315],[151.20421399138388,-33.85889465182268],[151.2003886086161,-33.85889465182268],[151.2003886086161,-33.855717948177315]]}])
      @nr = NeighboringRegion.new(@region, nil, 5)
    }
    let(:get_region) { @nr.get_region() }
    it "missing arguments error" do
      expect { NeighboringRegion.new(@region) }.to raise_error(ArgumentError)
    end
    it ":initialize(base_region, current_region = nil, size)" do
      expect(@nr).to be_a NeighboringRegion
      expect(@nr.size).to be 5
    end
    it ":get_region should return Region object" do
      expect(get_region).to be_a Region
    end

    it ":get_region size validation" do
      expect(get_region.size).to be 5.0
    end
    it ":get_region name validation" , match_name: true do
      # expect(@nr.get_region().name).to match(@region.name)
      puts get_region.name
      expect(get_region.name.to_s).to match(/^#{@region.name}\s*5X$/)
    end
    it ":validate region count after nr creation" do
      expect { get_region.save }.to change(Region, :count).by(1)
    end
  end

  context "update_neighboring_region" do
    before(:each) {
      @current_region = instance_double("Region", name: "Region 5x", size: 5, 
                                                  base_region_id: @region.id)
      @nr = NeighboringRegion.new(@region, @current_region, 7.5)
    }
    it ":initialize(base_region, current_region, size)" do
      puts @current_region.size
      expect(@nr).to be_a NeighboringRegion
      expect(@nr.size).to be 7.5
      expect(@nr.name).to match(/7.5/)
    end
  end
end
