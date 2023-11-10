class AddBioscoreConstants < ActiveRecord::Migration[7.0]
  def change
    Constant.create! name: 'observations_per_species_constant', value: 1
    Constant.create! name: 'observations_per_person_constant', value: 1
    Constant.create! name: 'average_observations_score_constant', value: 1
    Constant.create! name: 'average_observations_score', value: 20
    Constant.create! name: 'locality_observations_constant', value: 1
    Constant.create! name: 'locality_species_constant', value: 1
    Constant.create! name: 'locality_people_constant', value: 1
    Constant.create! name: 'greater_region_observations_constant', value: 1
    Constant.create! name: 'greater_region_species_constant', value: 1
    Constant.create! name: 'greater_region_people_constant', value: 1
    Constant.create! name: 'current_year_observations_constant', value: 1
    Constant.create! name: 'current_year_species_constant', value: 1
    Constant.create! name: 'current_year_people_constant', value: 1
    Constant.create! name: 'observations_trend_constant', value: 1
    Constant.create! name: 'species_trend_constant', value: 1
    Constant.create! name: 'activity_trend_constant', value: 1
    Constant.create! name: 'active_proportion_constant', value: 1
  end
end
