require "rails_helper"

RSpec.describe ScaffoldTestsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/scaffold_tests").to route_to("scaffold_tests#index")
    end

    it "routes to #new" do
      expect(get: "/scaffold_tests/new").to route_to("scaffold_tests#new")
    end

    it "routes to #show" do
      expect(get: "/scaffold_tests/1").to route_to("scaffold_tests#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/scaffold_tests/1/edit").to route_to("scaffold_tests#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/scaffold_tests").to route_to("scaffold_tests#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/scaffold_tests/1").to route_to("scaffold_tests#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/scaffold_tests/1").to route_to("scaffold_tests#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/scaffold_tests/1").to route_to("scaffold_tests#destroy", id: "1")
    end
  end
end
