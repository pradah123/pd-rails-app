class ApiRequestLog < ApplicationRecord
  # 
  # this class contains logging information related to
  # api fetching, used in the old fetching code only
  #
  belongs_to :data_source, optional: true
end
