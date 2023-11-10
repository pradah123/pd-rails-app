class AddInatBioscoreConstant < ActiveRecord::Migration[7.0]
  def change
    Constant.create! name: 'inat_bioscore_for_research_grade', value: 50
  end
end
