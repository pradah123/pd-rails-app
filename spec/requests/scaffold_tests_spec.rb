require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to test the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator. If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails. There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.

RSpec.describe "/scaffold_tests", type: :request do
  
  # This should return the minimal set of attributes required to create a valid
  # ScaffoldTest. As you add validations to ScaffoldTest, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  describe "GET /index" do
    it "renders a successful response" do
      ScaffoldTest.create! valid_attributes
      get scaffold_tests_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      scaffold_test = ScaffoldTest.create! valid_attributes
      get scaffold_test_url(scaffold_test)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_scaffold_test_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      scaffold_test = ScaffoldTest.create! valid_attributes
      get edit_scaffold_test_url(scaffold_test)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new ScaffoldTest" do
        expect {
          post scaffold_tests_url, params: { scaffold_test: valid_attributes }
        }.to change(ScaffoldTest, :count).by(1)
      end

      it "redirects to the created scaffold_test" do
        post scaffold_tests_url, params: { scaffold_test: valid_attributes }
        expect(response).to redirect_to(scaffold_test_url(ScaffoldTest.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new ScaffoldTest" do
        expect {
          post scaffold_tests_url, params: { scaffold_test: invalid_attributes }
        }.to change(ScaffoldTest, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post scaffold_tests_url, params: { scaffold_test: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested scaffold_test" do
        scaffold_test = ScaffoldTest.create! valid_attributes
        patch scaffold_test_url(scaffold_test), params: { scaffold_test: new_attributes }
        scaffold_test.reload
        skip("Add assertions for updated state")
      end

      it "redirects to the scaffold_test" do
        scaffold_test = ScaffoldTest.create! valid_attributes
        patch scaffold_test_url(scaffold_test), params: { scaffold_test: new_attributes }
        scaffold_test.reload
        expect(response).to redirect_to(scaffold_test_url(scaffold_test))
      end
    end

    context "with invalid parameters" do
      it "renders a successful response (i.e. to display the 'edit' template)" do
        scaffold_test = ScaffoldTest.create! valid_attributes
        patch scaffold_test_url(scaffold_test), params: { scaffold_test: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested scaffold_test" do
      scaffold_test = ScaffoldTest.create! valid_attributes
      expect {
        delete scaffold_test_url(scaffold_test)
      }.to change(ScaffoldTest, :count).by(-1)
    end

    it "redirects to the scaffold_tests list" do
      scaffold_test = ScaffoldTest.create! valid_attributes
      delete scaffold_test_url(scaffold_test)
      expect(response).to redirect_to(scaffold_tests_url)
    end
  end
end
