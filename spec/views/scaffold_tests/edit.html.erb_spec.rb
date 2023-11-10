require 'rails_helper'

RSpec.describe "scaffold_tests/edit", type: :view do
  before(:each) do
    @scaffold_test = assign(:scaffold_test, ScaffoldTest.create!())
  end

  it "renders the edit scaffold_test form" do
    render

    assert_select "form[action=?][method=?]", scaffold_test_path(@scaffold_test), "post" do
    end
  end
end
