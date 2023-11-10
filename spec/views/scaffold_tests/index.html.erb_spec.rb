require 'rails_helper'

RSpec.describe "scaffold_tests/index", type: :view do
  before(:each) do
    assign(:scaffold_tests, [
      ScaffoldTest.create!(),
      ScaffoldTest.create!()
    ])
  end

  it "renders a list of scaffold_tests" do
    render
  end
end
