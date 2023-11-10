require 'rails_helper'

RSpec.describe "scaffold_tests/new", type: :view do
  before(:each) do
    assign(:scaffold_test, ScaffoldTest.new())
  end

  it "renders new scaffold_test form" do
    render

    assert_select "form[action=?][method=?]", scaffold_tests_path, "post" do
    end
  end
end
