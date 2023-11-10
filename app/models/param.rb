class Param < ApplicationRecord
  belongs_to :contest
  belongs_to :data_source
end
