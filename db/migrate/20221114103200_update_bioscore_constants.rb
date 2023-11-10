class UpdateBioscoreConstants < ActiveRecord::Migration[7.0]
  def change
    Constant.create! name: 'observations_constant', value: 1
    Constant.create! name: 'species_constant', value: 1
    Constant.create! name: 'people_constant', value: 1
    Constant.find_by_name('observations_per_species_constant').update(name: 'species_per_observation_constant')
  end
end
