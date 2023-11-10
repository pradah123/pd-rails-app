class ObservationImage < ApplicationRecord
  belongs_to :observation, counter_cache: true
end
