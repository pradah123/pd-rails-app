require 'rails_helper'
# require_relative '../lib/region/neighboring_region.rb'
RSpec.describe Region, type: :model do
  # For let, the object won’t be created until the first time you use it.
  let(:hash) do
    { 
      region: Region.create(name: 'prajakta', size: 5, base_region_id: 0 ),
      current_time: Time.now()
    }
    # The let! method is non-lazy, so the object will be created before any tests are run.


    
  end
  context '#create' do
    it "created region to be valid" do
      #{}@region = Region.find_by!(id: 838).first

      # expect(person).to receive(:age).and_return(18)


      #expect(Region).to receive(:find).and_return(region)
      # expect(Region.find(id)).to eq region
      # arr = [region.size, 7.5]
      puts hash[:current_time]
      puts hash[:region].id
      expect(hash[:region].name).to eq 'prajakta'
      # expect(hash[:region]).not_to be_valid
      expect(hash[:region]).to be_valid
      expect(hash[:region].subscription).to eq "seeded"
      expect(hash[:region].display_flag).to be true
      expect(Region.find_by_id(hash[:region].id)).to eq(hash[:region])
      expect(Region.find_by_id(hash[:region].id)).to eq(hash[:region])
      puts Region.count

      # expect(Region.last.id).to eq 1235
    end
  end
  context "#update_region" do
    it "updates name" do
      # hash[:region].update(name: "prajakta_home")
      puts hash[:current_time]
      puts hash[:region].id
      hash[:region].name = "prajakta_home"
      hash[:region].save
      expect(Region.find_by_id(hash[:region].id).name).to eq("prajakta_home")
      puts Region.count

      # expect(Subregion.find_by_region_id(hash[:region].id))
    end
  end
  context "#destroy_region" do
    it "shall delete the region" do
      puts hash[:current_time]
      puts hash[:region].id
      puts "Region count: #{Region.count}"
      
      expect {
        hash[:region].destroy
      }.to change(Region, :count).by(-1)

      expect(Region.find_by_id(hash[:region].id)).to be_nil
      puts "Region count after deletion: #{Region.count}"
    end
  end

  context "test regions' scores and percentiles", test: true do
    before(:all) {
      @contest_id = 12
      @regions = Contest.find_by_id(@contest_id).regions
      @regions_with_scores = Region.merge_intermediate_scores_and_percentiles(regions: @regions)
    }
    
    it "shall have regions objects", test1: true do
      expect(@regions.count).to be > 0
      expect(@regions.first).to be_a_kind_of(Region).and(have_attributes(name: 'Mossman Botanic Gardens'))
    end

    it "shall have regions", test2: true do
      expect(@regions_with_scores.count).to be > 0
    end

    it "regions shall have scores", test3: true do
      # regions = @regions.to_json
      @regions_with_scores.each do |r|
        expect(r[:species_diversity_score]).not_to be nil
        expect(r[:species_diversity_percentile]).not_to be nil
        expect(r[:species_trend]).not_to be nil
      end
    end

    it "species_diversity_score should be in decimal", test4: true do
      # regions = @regions.to_json
      @regions_with_scores.each do |r|
        expect(r[:species_diversity_score].to_s).to match(/^\d+(?:\.*\d{2}*|\.0)$/)
        expect(r[:species_diversity_percentile].to_s).to match(/^\d+(?:\.*\d{2}*|\.0)$/)
        expect(r[:species_trend].to_s).to match(/^\d+(?:\.*\d{2}*|\.0)$/)
      end
    end
  end

  context ":calculate_percentiles", context_test2: true do
    before(:all) {
      @regions = []
      @regions.push({ id: 100, name: 'test', bioscore: 1000 }, 
                    { id: 200, name: 'test2', bioscore: 500 },
                    { id: 150, name: 'test3', bioscore: 1500 })
      @bioscore_sorted_regions = @regions.sort_by! { |hsh| hsh[:bioscore] }.reverse!
    }
    let(:regions_with_bioscore_percentile) {
      Region.calculate_percentiles(regions: @bioscore_sorted_regions, 
                                   key: 'bioscore_percentile')
    }
    # let(:region_alias) { Region }

    it "missing arguments" do
      expect { Region.calculate_percentiles() }.to raise_error(ArgumentError)
    end
    it "missing argument 'regions'" do
      expect { Region.calculate_percentiles(key: 'bioscore_percentile') }
        .to raise_error(ArgumentError, "missing keyword: :regions") 
                    #  message in raise_error shall be same as thrown by ArgumentError
      
      # Following to be used in case of mock object 
      # expect(Region).to receive(:calculate_percentiles)
      #               .with(regions: @bioscore_sorted_regions, key: 'bioscore_percentile')
                    # .and_return(regions_with_bioscore)
    end
    it "missing argument 'key'" do
      expect { Region.calculate_percentiles(regions: []) }
        .to raise_error(ArgumentError, "missing keyword: :key") 
                    
    end

    it "shall return a non-empty array" do
      expect(regions_with_bioscore_percentile).to be_an_instance_of(Array) 
      expect(regions_with_bioscore_percentile.length).to be > 0 
    end
      
    it "each region shall have bioscore_percentile" do
      # regions_with_bioscore = Region.calculate_percentiles(regions: @bioscore_sorted_regions, key: 'bioscore_percentile')
      regions_with_bioscore_percentile.each do |r|
        expect(r[:bioscore_percentile]).not_to be nil
        expect(r[:bioscore_percentile].to_s).to match(/^\d+(?:\.*\d{2}*|\.0)$/)
      end
      expect(Region.calculate_percentiles(regions: @bioscore_sorted_regions, 
                                          key: 'bioscore_percentile'))
        .to match_array(regions_with_bioscore_percentile)
      puts regions_with_bioscore_percentile
    end
  end

  context "update_neighboring_regions" do
    # it "works with find_by" do
    #   expect(Foo).to receive(:find_by_name).and_return(foo)
    #   expect(Foo.find_by_name("foo")).to eq foo
    # end
  

    # let(:region) { Region.new }
    # Region.stub!(:find).with_id(id).and_return region

    # let(:size) { region&.size }
    # let(:arr) { [size, 7.5] }

    # subject { region.update_neighboring_region(arr) }
    # it "should update the size to 7.5" do
    #     # allow(Region).to receive(:find).with(838) { region }

    #     @current_plan = Region.select { |p| p.id == id }.first

    #     #test code
    #     @plan = Region.new
    #     Region.stub_chain(:select, :first).and_return(@plan)
        
    #     #   region = Region.find_by_id(838)
    #     arr = [@plan.size, 7.5]
    #     @plan.update_neighboring_region(arr)


    #     # region.update_neighboring_region([region.size, 7.5])
    #     expect(region.reload.size).to eq(7.5)
    # end
  end
end
