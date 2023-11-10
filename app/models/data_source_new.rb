#
# in order to leave the old fetching code in place for the moment,
# the data source new class was created, but can replace data source
# once it has been fully tested.
#

#
# this is the base class for data sources.
# 
# each api has a data source class which inherits from
# this class
#

class DataSourceNew < ApplicationRecord
  #has_and_belongs_to_many :participations
  #has_many :observations
  has_many :subregions
  #has_many :api_request_logs

  # 
  # this method is called from FetchForSubregionJob
  #

  def fetch_and_store_observations subregion
    store fetch(subregion)
  end

  #
  # this is the method which should be filled out in each
  # child class, giving the specifics of each api call
  #

  def fetch
    []
  end  
  
  #
  # this code takes in observations data
  # and creates or updates the observations
  # it is common between the apis, and so resides in the base class.
  #
  # the details are encapsulated in the observations class
  # as makes logical sense.
  #

  def store observations
    Observation.store observations
  end  


  rails_admin do
    list do
      field :id
      field :type
      field :name
      field :created_at              
    end
    edit do
      field :name
    end
    show do
      field :id
      field :name
      field :created_at
    end
  end 

end
