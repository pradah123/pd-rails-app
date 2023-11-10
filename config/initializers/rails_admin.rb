require 'i18n'

I18n.default_locale = :en

class RailsAdmin::Config::Fields::Types::Timestamptz < RailsAdmin::Config::Fields::Base
  RailsAdmin::Config::Fields::Types::register(self)
end

RailsAdmin.config do |config|
  config.asset_source = :webpacker
  config.parent_controller = '::ApplicationController'  
  config.main_app_name = ['Biosmart Admin', '']
  config.default_items_per_page = 100
  config.default_associated_collection_limit = 1000

  config.actions do
    dashboard
    index
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app 
  end

  config.excluded_models = %i(
    ActionText::RichText
    ActiveStorage::Attachment
    ActiveStorage::Blob
    ActiveStorage::VariantRecord
    GbifObservationsMatview
    ParticipationSpeciesMatview
    ParticipationObserverSpeciesMatview
    RegionsObservationsMatview
    SpeciesGroupedByDayMatview
    ObserverSpeciesGroupedByDayMatview
    SpeciesMatview
    SpeciesByRegionsMatview
    TotalObservationsMetricsMatview
    TaxonObservationsMonthlyCountMatview
    ApiRequestLog
    Observation
  )

  config.navigation_static_label = ''
  config.navigation_static_links = { 'Go to the Top Page' => '/' }

  config.authorize_with do
    unless @user && @user.admin?
      redirect_to '/'
    end  
  end

end
