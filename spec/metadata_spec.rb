require_relative "../lib/common/utils.rb"
describe "spec with variable foo", foo: 17 do
  context "and a context with variable bar", bar: 12 do
    it "can access metadata variables foo and bar" do |example|
      expect(example.metadata[:foo]).to eq 17
      expect(example.metadata[:bar]).to eq 12
      puts example.metadata
    end

    it "can use different metadata variablr in example than defined in contest or describe", :bar => 15 do |example|
      expect(example.metadata[:foo]).to eq 17
      expect(example.metadata[:bar]).to eq 15
      puts example.metadata
    end

  end
  context "file path example" do
    it "should check for valid file", file_name: "new_list.csv" do |example|
      expect(Utils.valid_file?(file_name: example.metadata[:file_name])).to be true
      expect(example.metadata[:file_name]).to eq "new_list.csv"
    end
    it "should check for invalid file", file_name: "new.csv" do |example|
      expect(Utils.valid_file?(file_name: example.metadata[:file_name])).to be false
      expect(example.metadata[:file_name]).to eq "new.csv"
    end
  end
end
