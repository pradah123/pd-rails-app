require 'rails_helper'

RSpec.describe "scaffold_tests/show", type: :view do
  before(:each) do
    @scaffold_test = assign(:scaffold_test, ScaffoldTest.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
