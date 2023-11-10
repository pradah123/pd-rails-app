# frozen_string_literal: true

require 'dry/validation'
require_relative './application'
require_relative '../structs/pagination'
require_relative '../schemas/pagination'

module Service
  module Region
    # Class to encapsulate fetching sightings request
    class Fetch
      include Service::Application

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination

        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:sort_by).filled(:string, included_in?: ['id', 'bioscore'])
        optional(:sort_order).filled(:string, included_in?: ['asc', 'desc'])
      end
      
      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :sort_by, Types::Params::String.default('id')
        attribute? :sort_order, Types::Params::String.default('asc')
      end

      def execute(params)
        search_params = Params.new(params)
        fetch_regions(search_params)
      end

      private

      def fetch_regions(search_params)
        regions = ::Region.default_scoped
        if search_params.contest_id.present?
          contest = ::Contest.find_by_id(search_params.contest_id)
          return Failure('Invalid contest provided.') if contest.blank?
          regions = contest.regions
        end
        Success(regions.offset(search_params.offset)
               .limit(search_params.limit)
               .order(search_params.sort_by => search_params.sort_order))
      end
    end

    class Show
      include Service::Application

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        required(:region_id).filled(:integer, gt?: 0)
      end
      
      class Params < AppStruct::Pagination
        attribute? :region_id, Types::Params::Integer
      end

      def execute(params)
        show_params = Params.new(params)
        fetch_region(show_params.region_id)
      end

      private

      def fetch_region(region_id)
        region = ::Region.find_by_id(region_id)
        return Failure('Invalid region id provided.') if region.blank?
        Success(region)
      end
    end


    # Class to create a region through gui page or external request (API)
    class Create
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        required(:name).filled(:string)
        required(:description).filled(:string)
        required(:api_hash).filled(:string)
        optional(:contest_ids).array(:str?)
        optional(:display_flag).filled(:string, included_in?: ['true', 'false'])
      end

      class Params < AppStruct::Pagination
        attribute? :id, Types::Params::Integer
        attribute? :api_hash, Types::Params::String
        attribute? :name, Types::Params::String
        attribute? :description, Types::Params::String
        attribute? :logo_image_url, Types::Params::String
        attribute? :header_image_url, Types::Params::String
        attribute? :raw_polygon_json, Types::Params::String
        attribute? :lat_input, Types::Params::Float
        attribute? :lng_input, Types::Params::Float
        attribute? :polygon_side_length, Types::Params::Float
        attribute? :status, Types::Params::String
        attribute? :contest_ids, Types::Params::Array
        attribute? :display_flag, Types::Params::String
      end

      def execute(params)
        create_params = Params.new(params)
        params.delete(:contest_ids)
        params.delete(:api_hash)
        create_region(create_params, params)
      end

      private

      def create_region(create_params, params)
        region = params
        api_hash_constant = Constant.find_by_name('api_hash').text_value
        if create_params.api_hash != api_hash_constant
          return Failure("'api_hash' value is invalid.")
        end
        contest_ids = create_params.contest_ids
        begin
          region_obj = ::Region.find_by_id create_params.id if create_params&.id.present?
        rescue => e
          Rails.logger.info("error: #{e}")
          return Failure("Internal Error.")
        end
        if !region_obj.nil?
          return Failure("Region with id '#{create_params.id}' already exists.")
        else
          begin
            region_obj = ::Region.new params
          rescue => e
            Rails.logger.info("error: #{e}")
            return Failure("Internal Error.")
          end
          success_message = ''
          if region_obj.save
            success_message = 'Region has been added successfully. '
            contest_ids = contest_ids.reject(&:empty?).map(&:to_i)
            error_message = ''
            contest_ids.each do |contest_id|
              contest_obj = ::Contest.in_progress_or_upcoming.find_by_id(contest_id)
              if contest_obj.present?
                region_obj.add_to_contest(contest_id: contest_id)
                success_message += "Region has been added to contest '#{contest_id}'. "
              else
                error_message += "No ongoing or upcoming contest found for contest id '#{contest_id}', couldn't add region to it."
              end
            end
            r = { 'region_id': region_obj.id, 'success_message': success_message, 'warning_message': error_message }
            Success(r)
          else
            return Failure("Error occurred while creating the region.")
          end
        end
      end
    end


    # Class to update a region through gui page or external request (API)
    class Update
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        required(:api_hash).filled(:string)
        optional(:display_flag).filled(:string, included_in?: ['true', 'false'])
      end

      class Params < AppStruct::Pagination
        attribute? :id, Types::Params::Integer
        attribute? :api_hash, Types::Params::String
        attribute? :name, Types::Params::String
        attribute? :description, Types::Params::String
        attribute? :logo_image_url, Types::Params::String
        attribute? :header_image_url, Types::Params::String
        attribute? :raw_polygon_json, Types::Params::String
        attribute? :lat_input, Types::Params::Float
        attribute? :lng_input, Types::Params::Float
        attribute? :polygon_side_length, Types::Params::Float
        attribute? :status, Types::Params::String
        attribute? :contest_ids, Types::Params::Array
        attribute? :display_flag, Types::Params::String
      end

      def execute(params)
        update_params = Params.new(params)
        update_region(update_params, params)
      end

      private

      def update_region(update_params, params)
        contest_ids = params[:contest_ids] if params.key?(:contest_ids)
        api_hash_constant = Constant.find_by_name('api_hash').text_value
        if update_params.api_hash != api_hash_constant
          return Failure("'api_hash' value is invalid.")
        end
        params.delete(:contest_ids) if params.key?(:contest_ids)
        params.delete(:api_hash) if params.key?(:api_hash)
        region = params

        id = update_params.id || ''
        if id.blank?
          return Failure("Must provide 'id'.")
        end
        region_obj = ::Region.find_by_id id
        if region_obj.nil?
          return Failure("Region with id '#{id}' does not exist.")
        end

        region_obj.attributes = region
        success_message = ''
        if region_obj.save
          success_message = 'Region has been updated successfully. '
          if contest_ids.is_a?(Array)
            contest_ids = contest_ids.reject(&:empty?).map(&:to_i)
            existing_contests = region_obj.contests
                                          .where("(contests.utc_starts_at <  '#{Time.now}' OR contests.utc_starts_at >  '#{Time.now}') AND
                                              contests.last_submission_accepted_at > '#{Time.now}'")
                                          .pluck(:id)
            contests_to_add = contests_to_remove = []
            contests_to_add    = contest_ids - existing_contests
            contests_to_remove = existing_contests - contest_ids

            error_message = ''
            contests_to_add.each do |contest_id|
              contest_obj = ::Contest.in_progress_or_upcoming.find_by_id(contest_id)
              if contest_obj.present?
                region_obj.add_to_contest(contest_id: contest_id)
                success_message += "Region has been added to contest '#{contest_id}'. "
              else
                error_message += "No ongoing or upcoming contest found for contest id '#{contest_id}', couldn't add region to it."
              end
            end
            contests_to_remove.each do |contest_id|
              region_obj.participations.where(contest_id: contest_id).delete_all
              success_message += "Region has been removed from contest '#{contest_id}'. "
            end
            r = { 'success_message': success_message, 'warning_message': error_message }
          else
            r = { 'success_message': success_message }
          end
          Success(r)
        else
          return Failure("Error occurred while updating the region '#{id}'")
        end
      end
    end

    # Class to delete a region through external request (API)
    class Delete
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        required(:api_hash).filled(:string)
      end

      class Params < AppStruct::Pagination
        attribute? :id, Types::Params::Integer
        attribute? :api_hash, Types::Params::String
      end

      def execute(params)
        delete_params = Params.new(params)
        delete_region(delete_params)
      end

      private

      def delete_region(delete_params)
        api_hash_constant = Constant.find_by_name('api_hash').text_value
        if delete_params.api_hash != api_hash_constant
          return Failure("'api_hash' value is invalid.")
        end
        id = delete_params.id || ''
        if id.blank?
          return Failure("Must provide 'id'.")
        end
        region_obj = ::Region.find_by_id id
        if region_obj.nil?
          return Failure("Region with id '#{id}' does not exist.")
        end

        if region_obj.destroy
          success_message = 'Region has been deleted successfully. '
          r = { 'success_message': success_message }
          Success(r)
        else
          return Failure("Error occurred while deleting the region '#{id}'")
        end
      end
    end

    class SearchBySpecies
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination
        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:page).filled(:integer, gt?: 0)
      end

      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :contest_filter, Types::Params::String
        attribute? :search_text, Types::Params::String
        attribute? :month_filter, Types::Params::String
        attribute? :year_filter, Types::Params::String
        attribute? :page, Types::Params::Integer
      end

      def execute(params)
        search_params = Params.new(params)
        if search_params.search_text.present?
          fetch_regions_by_species(search_params)
        else
          fetch_regions(search_params)
        end
      end

      private

      def fetch_regions_by_species(search_params)
        searched_regions = regions_hash = regions = []
        taxonomy_ids = ::RegionsObservationsMatview.get_taxonomy_ids(search_text: search_params.search_text)
        if search_params.contest_id.present?
          contest_id = search_params.contest_id
        elsif search_params.contest_filter.present? && !search_params.contest_filter.blank?
          contest_id = search_params.contest_filter.to_i
        end
        month_filter = search_params.month_filter
        year_filter  = search_params.year_filter
        regions = ::TaxonObservationsMonthlyCountMatview.get_regions_by_species(search_text: search_params.search_text,
                                                                                contest_id: contest_id,
                                                                                month_filter: month_filter,
                                                                                year_filter: year_filter)
        regions.each do |r|
          region_id = r.id
          next if r.subscription == 'seeded-public' || r.display_flag == false
          species_count = ::TaxonObservationsMonthlyCountMatview.get_total_sightings_for_region(region_id: region_id,
                                                                                                taxonomy_ids: taxonomy_ids,
                                                                                                month_filter: month_filter,
                                                                                                year_filter: year_filter)
          regions_hash.push({ region: r,
                              total_sightings: species_count,
                              bioscore: r.bioscore })
        end
        sorted_regions = regions_hash.sort_by { |h| [h[:total_sightings], h[:bioscore]] }
                                     .reverse
                                     .map { |row| row[:region] }

        searched_regions = Kaminari.paginate_array(sorted_regions).page(search_params.page).per(20)
        Success(searched_regions)
      end

      def fetch_regions(search_params)
        if search_params.contest_id.present?
          contest_id = search_params.contest_id
        elsif search_params.contest_filter.present? && !search_params.contest_filter.blank?
          contest_id = search_params.contest_filter.to_i
        end
        contest_query = ''
        contest_query = "contests.id = #{contest_id}" if contest_id.present?
        regions = []
        regions = ::Region.joins(:contests)
                          .where(contest_query)
                          .where('contests.utc_starts_at < ? AND contests.last_submission_accepted_at > ?', Time.now, Time.now)
                          .where(status: 'online')
                          .where.not("regions.subscription = 'seeded-public' or regions.display_flag = false")
                          .distinct
                          .order('bioscore desc')
                          .page(search_params.page).per(20)
        Success(regions)
      end
    end

    class Sightings
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination
        optional(:region_id).filled(:integer, gt?: 0)
        optional(:get_property_sightings).filled(:string, included_in?: ['true', 'false'])
        optional(:get_locality_sightings).filled(:string, included_in?: ['true', 'false'])
        optional(:get_gr_sightings).filled(:string, included_in?: ['true', 'false'])
        optional(:get_total_sightings).filled(:string, included_in?: ['true', 'false'])
      end

      class Params < AppStruct::Pagination
        attribute? :region_id, Types::Params::Integer
        attribute? :search_text, Types::Params::String
        attribute? :month_filter, Types::Params::String
        attribute? :year_filter, Types::Params::String
        attribute? :get_property_sightings, Types::Params::String
        attribute? :get_locality_sightings, Types::Params::String
        attribute? :get_gr_sightings, Types::Params::String
        attribute? :get_total_sightings, Types::Params::String
      end

      def execute(params)
        search_params = Params.new(params)
        error_message = validate_parameters(search_params)
        return Failure(error_message) if error_message.present?

        taxonomy_ids = []
        if search_params.search_text.present?
          taxonomy_ids = ::RegionsObservationsMatview.get_taxonomy_ids(search_text: search_params.search_text)
        end
        region_id = search_params.region_id
        month_filter = search_params.month_filter
        year_filter  = search_params.year_filter
        sightings_count = if search_params.get_property_sightings == "true"
                            fetch_property_sightings_count(region_id, taxonomy_ids, month_filter, year_filter)
                          elsif search_params.get_locality_sightings == "true"
                            fetch_locality_sightings_count(region_id, taxonomy_ids, month_filter, year_filter)
                          elsif search_params.get_gr_sightings == "true"
                            fetch_greater_region_sightings_count(region_id, taxonomy_ids, month_filter, year_filter)
                          else
                            fetch_sightings_count(search_params, taxonomy_ids)
                          end
        Success(sightings_count)
      end



      private

      def validate_parameters(search_params)
        error_message = ''
        region = ::Region.find_by_id(search_params.region_id)
        error_message = 'Invalid region id provided.' if region.blank?

        return error_message
      end

      def fetch_sightings_count(search_params, taxonomy_ids)
        region_id = search_params.region_id
        region = ::Region.find_by_id(region_id)
        return Failure('Invalid region id provided.') if region.blank?

        month_filter = search_params.month_filter
        year_filter  = search_params.year_filter

        total_sightings_count = 0
        property_sightings_count       = fetch_property_sightings_count(region_id, taxonomy_ids, month_filter, year_filter)
        locality_sightings_count       = fetch_locality_sightings_count(region_id, taxonomy_ids, month_filter, year_filter)
        greater_region_sightings_count = fetch_greater_region_sightings_count(region_id, taxonomy_ids, month_filter, year_filter)

        total_sightings_count = property_sightings_count + locality_sightings_count + greater_region_sightings_count
        if search_params.get_total_sightings == "true"
          return total_sightings_count
        else
          sightings_count = {}
          sightings_count = {
            region_id: region_id,
            property_sightings_count: property_sightings_count,
            locality_sightings_count: locality_sightings_count,
            greater_region_sightings_count: greater_region_sightings_count,
            total_sightings_count: total_sightings_count
          }
          return sightings_count
        end
      end

      def fetch_property_sightings_count(region_id, taxonomy_ids, month_filter, year_filter)
        property_sightings_count = 0
        property_sightings_count = ::TaxonObservationsMonthlyCountMatview.get_species_count(region_id: region_id,
                                                                                            taxonomy_ids: taxonomy_ids,
                                                                                            month_filter: month_filter,
                                                                                            year_filter: year_filter)
        return property_sightings_count
      end

      def fetch_locality_sightings_count(region_id, taxonomy_ids, month_filter, year_filter)
        locality_sightings_count = 0
        locality = ::Region.find_by_id(region_id).get_neighboring_region(region_type: 'locality')
        if locality.present?
          locality_sightings_count = ::TaxonObservationsMonthlyCountMatview.get_species_count(region_id: locality.id,
                                                                                              taxonomy_ids: taxonomy_ids,
                                                                                              month_filter: month_filter,
                                                                                              year_filter: year_filter)
        end
        return locality_sightings_count
      end

      def fetch_greater_region_sightings_count(region_id, taxonomy_ids, month_filter, year_filter)
        greater_region_sightings_count = 0
        greater_region = ::Region.find_by_id(region_id).get_neighboring_region(region_type: 'greater_region')
        if greater_region.present?
          greater_region_sightings_count = ::TaxonObservationsMonthlyCountMatview.get_species_count(region_id: greater_region.id,
                                                                                                    taxonomy_ids: taxonomy_ids,
                                                                                                    month_filter: month_filter,
                                                                                                    year_filter: year_filter)
        end
        return greater_region_sightings_count
      end
    end
  end
end
