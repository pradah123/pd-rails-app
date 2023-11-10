# frozen_string_literal: true

require 'dry/validation'
require 'dry/monads'
require 'dry/monads/do'

require_relative './application'
require_relative '../structs/pagination'
require_relative '../schemas/pagination'
require_relative './participation'
require_relative './region'
require_relative './contest'

module Service
  module Observation
    # Class to encapsulate fetching observations request
    class Fetch
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination

        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:region_id).filled(:integer, gt?: 0)
        optional(:sort_by).filled(:string, included_in?: ['observed_at'])
        optional(:sort_order).filled(:string, included_in?: ['asc', 'desc'])
        optional(:datasource_order).filled(:array)
        optional(:category).filled(:string)
        optional(:search_text).filled(:string)
        optional(:with_images).filled(:string, included_in?: ['true', 'false'])
        optional(:get_counts_only).filled(:string, included_in?: ['true', 'false'])
        optional(:ignore_data_sources).filled(:string)
      end
      
      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :region_id, Types::Params::Integer
        attribute? :sort_by, Types::Params::String.default('observed_at')
        attribute? :sort_order, Types::Params::String.default('desc')
        attribute? :datasource_order, Types::Params::Array
        attribute? :category, Types::Params::String
        attribute? :search_text, Types::Params::String
        attribute? :with_images, Types::Params::String.default('false')
        attribute? :get_counts_only, Types::Params::String.default('false')
        attribute? :ignore_data_sources, Types::Params::String
      end

      def execute(params)
        search_params = Params.new(params)
        fetch_observations(search_params)
      end

      private

      def fetch_observations(search_params)
        Rails.logger.debug "fetch_observations(#{search_params.inspect})"
        observations = ::Observation.default_scoped
        if search_params.contest_id.present? && search_params.region_id.present?
          observations = yield get_participation_observations_relation(
            search_params.contest_id,
            search_params.region_id,
            search_params.category,
            search_params.search_text
          )
        elsif search_params.contest_id.present?
          observations = yield get_contest_observations_relation(
            search_params.contest_id, search_params.category, search_params.search_text
          )
        elsif search_params.region_id.present?
          observations = yield get_region_observations_relation(
            search_params.region_id,
            search_params.category,
            search_params.search_text,
            search_params.ignore_data_sources
          )
        end
        if search_params.get_counts_only == 'false'
          license_codes = [nil, 'cc-0', 'cc-by', 'cc-by-nc', 'cc-by-sa', 'cc-by-nd', 'cc-by-nc-sa', 'cc-by-nc-nd']
          if search_params.with_images == 'true'
            observations = observations.includes(:observation_images)
                                       .includes(:data_source)
                                       .includes(:taxonomy)
                                       .where(license_code: license_codes)
                                       .has_images
                                       .offset(search_params.offset)
                                       .limit(search_params.limit)
                                       .order(search_params.sort_by => search_params.sort_order)
          else
            observations = observations.includes(:data_source)
                                       .includes(:taxonomy)
                                       .where.not(license_code: license_codes)
                                       .offset(search_params.offset)
                                       .limit(search_params.limit)
                                       .order(search_params.sort_by => search_params.sort_order)
          end
          if search_params.datasource_order.present?
            # https://guides.rubyonrails.org/active_record_querying.html#unscope
            observations = observations.unscope(:order)
            # https://edgeapi.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-in_order_of
            observations = observations.sort_by_data_source(search_params.datasource_order)
          end
          none_observation = ::Observation.where('1 = 0')
          observations = observations.uniq
          observations += none_observation
          Success(observations)
        else
          data = {}
          filtered_scientific_names = "'homo sapiens', 'Homo Sapiens', 'Homo sapiens'"
          data[:observations_count] = observations.distinct.count
          data[:species_count] = observations.distinct
                                             .select("observations.accepted_name")
                                             .where("observations.accepted_name not in (#{filtered_scientific_names})")
                                             .where("observations.accepted_name is not null")
                                             .where('observations.accepted_name != lower(observations.accepted_name)')
                                             .distinct
                                             .count
          data[:people_count] = observations.distinct
                                            .select("observations.creator_name")
                                            .where("observations.creator_name is not null")
                                            .distinct
                                            .count
          data[:identifications_count] = observations.sum(:identifications_count)
          Success(data)
        end

      end

      def get_region_observations_relation(region_id, category, search_text, ignore_data_sources)
        Rails.logger.debug "get_region_observations_relation(#{region_id})"
        region = ::Region.find_by_id(region_id)
        return Failure("Invalid region id (#{region_id}).") if region.blank?
        Rails.logger.debug "get_region_observations_relation::ignore_data_sources(#{ignore_data_sources})"

        # (start_dt, end_dt) = region.first.get_date_range_for_report()
        observations = yield filter_observations(region, category, search_text, ignore_data_sources)
        # observations = ::Observation.filter_observations(category: category, q: search_text, obj: region, start_dt: start_dt, end_dt:end_dt)

        Success(observations)
      end

      def get_contest_observations_relation(contest_id, category, search_text)
        Rails.logger.debug "get_contest_observations_relation(#{contest_id})"
        contest = ::Contest.find_by_id(contest_id)
        return Failure("Invalid contest id (#{contest_id}).") if contest.blank?
        # observations = yield ::Observation.filter_observations(category: category, q: search_text, obj: contest)
        observations = yield filter_observations(contest, category, search_text)
        Success(observations)
      end

      def get_participation_observations_relation(contest_id, region_id, category, search_text)
        participation = ::Participation.where(contest_id: contest_id, region_id: region_id).first
        if participation.blank?
          return Failure(
            "Invalid contest id (#{contest_id}) and region id (#{region_id})."
          )
        end
        observations = yield filter_observations(participation, category, search_text)
        # observations = ::Observation.filter_observations(category: category, q: search_text, obj: participation)

        return Success(observations)
      end

      def filter_observations(obj, category, search_text, ignore_data_sources = nil)
        if category.present?
          category_query = Utils.get_category_rank_name_and_value(category_name: category)
          if category_query.blank?
            return Failure(
              "Invalid category '#{category}'."
            )
          end
        end
        # For region page
        if obj.is_a? ::Region
          if ignore_data_sources.present?
            ignore_data_sources = ignore_data_sources.gsub(/\s+/, '')
            data_source_ids = DataSource.where(name: ignore_data_sources.split(",")).pluck(:id)
            filter_data_source_query = "observations.data_source_id not in (#{data_source_ids.join(', ')})"
          else
            filter_data_source_query = ""
          end
          observations = obj.observations.where("observed_at <= ?", Time.now).where(filter_data_source_query)
          if observations.present?
            if category.present? && search_text.present?
              observations = observations.joins(:taxonomy).where(category_query).search(search_text)
            elsif category.present?
              observations = observations.joins(:taxonomy).where(category_query)
            elsif search_text.present?
              observations = observations.search(search_text)
            end
          end
        else
          ends_at = obj.ends_at > Time.now ? Time.now : obj.ends_at
          if obj.is_a? ::Participation
            obs = obj.region.observations.where("observed_at BETWEEN ? and ?", obj.starts_at, ends_at)
          else
            region_ids = obj.participations.map { |p|
              !p.region.base_region_id.present? ? p.region.id : nil
            }.compact
            obs = ::Observation.joins(:observations_regions).where("observations_regions.region_id IN (?)", region_ids).where("observations.observed_at BETWEEN ? and ?", obj.starts_at, ends_at)
          end
          # For contest or participation page
          if category.present? && search_text.present?
            observations = obs.joins(:taxonomy).where(category_query).search(search_text)
          elsif category.present?
            observations = obs.joins(:taxonomy).where(category_query)
          elsif search_text.present?
            observations = obs.search(search_text)
          else
            observations = obs
            Rails.logger.info("observations: #{observations.count}")
          end
        end
        Success(observations)
      end
    end


    class FetchSpecies
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination

        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:region_id).filled(:integer, gt?: 0)
        optional(:with_images).filled(:string, included_in?: ['true', 'false'])
        optional(:category).filled(:string)
        optional(:observer).filled(:string)
      end

      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :region_id, Types::Params::Integer
        attribute? :with_images, Types::Params::String
        attribute? :category, Types::Params::String
        attribute? :observer, Types::Params::String
      end

      def execute(params)
        transformed_params = Params.new(params)
        fetch_top_species(transformed_params, params)
      end

      private

      def fetch_top_species(transformed_params, params)
        if transformed_params.contest_id.present? && transformed_params.region_id.present?
          result = Service::Participation::Base.call(transformed_params).to_result
        else
          return Failure(
            "Invalid contest id (#{transformed_params.contest_id}) or region id (#{transformed_params.region_id})."
          )
        end
        if transformed_params.category.present?
          category_query = Utils.get_category_rank_name_and_value(category_name: transformed_params.category)
          if category_query.blank?
            return Failure(
              "Invalid category '#{transformed_params.category}'."
            )
          end
        end
        if result&.success?
          top_species = []
          options = {
            region_id: transformed_params.region_id,
            offset: transformed_params.offset,
            limit: transformed_params.limit,
            category: category_query,
            observer: transformed_params.observer,
            start_dt: result.success.starts_at,
            end_dt: result.success.ends_at,
          }
          if transformed_params.with_images == 'true'
            if transformed_params.observer.present?
              top_species = ::ObserverSpeciesGroupedByDayMatview.get_top_species_with_images(**options)
              # top_species = ::ParticipationObserverSpeciesMatview.get_top_species_with_images(**options)
            else
              top_species = ::SpeciesGroupedByDayMatview.get_top_species_with_images(**options.except!(:observer))
            end
          else
            if transformed_params.observer.present?
              top_species = ::ObserverSpeciesGroupedByDayMatview.get_top_species(**options)

              # top_species = ::ParticipationObserverSpeciesMatview.get_top_species(**options)
            else
              top_species = ::SpeciesGroupedByDayMatview.get_top_species(**options.except!(:observer))
            end
          end
          return Success(top_species)
        end
        if result&.failure?
          return Failure(result.failure)
        end
      end
    end

    class FetchPeople
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination

        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:region_id).filled(:integer, gt?: 0)
        optional(:n).filled(:integer, gt?: 0)
      end

      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :region_id, Types::Params::Integer
        attribute? :n, Types::Params::Integer
      end

      def execute(params)
        transformed_params = Params.new(params)
        fetch_top_people(transformed_params, params)
      end

      private

      def fetch_top_people(transformed_params, params)
        n = transformed_params.n.present? ? transformed_params.n : 25

        if transformed_params.contest_id.present? && transformed_params.region_id.present?
          result = Service::Participation::Base.call(transformed_params).to_result
        elsif transformed_params.contest_id.present?
          result = Service::Contest::Base.call(params).to_result
        elsif transformed_params.region_id.present?
          result = Service::Region::Show.call(params).to_result
        else
          return Failure(
            "Invalid contest id (#{transformed_params.contest_id}) or region id (#{transformed_params.region_id})."
          )
        end
        if result&.success?
          return Success(result.success.get_top_people(n))
        end
        if result&.failure?
          return Failure(result.failure)
        end
      end

    end

    class FetchUndiscoveredSpecies
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination

        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:region_id).filled(:integer, gt?: 0)
        optional(:with_images).filled(:string, included_in?: ['true', 'false'])
      end

      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :region_id, Types::Params::Integer
        attribute? :with_images, Types::Params::String
      end

      def execute(params)
        search_params = Params.new(params)
        fetch_undiscovered_species(search_params, params)
      end

      private

      def fetch_undiscovered_species(search_params, params)
        if search_params.contest_id.present? && search_params.region_id.present?
          result = Service::Participation::Base.call(search_params).to_result
          if result&.success?
            undiscovered_species = result.success.region.get_undiscovered_species(offset: search_params.offset, limit: search_params.limit, participant: result.success)
          else
            return Failure(
              "Invalid contest id (#{search_params.contest_id}) or region id (#{search_params.region_id})."
            )
          end
        elsif search_params.region_id.present?
          result = Service::Region::Show.call(params).to_result
          if result&.success?
            undiscovered_species = result.success.get_undiscovered_species(offset: search_params.offset, limit: search_params.limit)
          else
            return Failure(
              "Invalid region id (#{search_params.region_id})."
            )
          end
        else
          return Failure(
            "Invalid contest id (#{search_params.contest_id}) or region id (#{search_params.region_id})."
          )
        end
        Success(undiscovered_species)
      end
    end
  end
end
