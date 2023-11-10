# frozen_string_literal: true

require 'dry/validation'
require_relative './application'
require_relative '../structs/pagination'
require_relative '../schemas/pagination'

module Service
  module Participation
    class Base
      include Service::Application
      include Dry::Monads[:result, :do]

      def execute(params)
        get_participation(params.contest_id, params.region_id)
      end

      private

      def get_participation(contest_id, region_id)
        participation = ::Participation.where(contest_id: contest_id,
                                              region_id: region_id).first
        if participation.blank?
          return Failure("Invalid contest id (#{contest_id}) or region id (#{region_id}).")
        end
        Success(participation)
      end
    end

    # Class to encapsulate fetching participations request
    class Fetch
      include Service::Application

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination

        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:sort_by).filled(:string, included_in?: ['id', 'bioscore'])
        optional(:sort_order).filled(:string, included_in?: ['asc', 'desc'])
        optional(:intersecting_contest_id).filled(:integer, gt?: 0)
        optional(:ignore_display_and_subscription_filter).filled(:string, included_in?: ['true', 'false'])

      end
      
      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :sort_by, Types::Params::String.default('id')
        attribute? :sort_order, Types::Params::String.default('asc')
        attribute? :intersecting_contest_id, Types::Params::Integer
        attribute? :region_name, Types::Params::String
        attribute? :ignore_display_and_subscription_filter, Types::Params::String.default('false')


        def sort_key
          # Bioscore is not populated in participation model
          # If sort by bioscore, use corresponding region's bioscore
          sort_by == 'bioscore' ? "regions.bioscore" : sort_by
        end
      end

      def execute(params)
        search_params = Params.new(params)
        fetch_participations(search_params)
      end

      private

      def fetch_participations(search_params)
        participations = ::Participation.default_scoped.base_region_participations
        contest_id = search_params.contest_id
        intersecting_contest_id = search_params.intersecting_contest_id
        ignore_display_and_subscription_filter = search_params.ignore_display_and_subscription_filter
        region_name = search_params.region_name
        if contest_id.present?
          contest = ::Contest.find_by_id(contest_id)
          return Failure("Invalid contest_id (#{contest_id}).") if contest.blank?

          if intersecting_contest_id.present?
            intersecting_contest = ::Contest.find_by_id(intersecting_contest_id)
            return Failure("Invalid intersecting_contest_id (#{intersecting_contest_id}).") if intersecting_contest.blank?

            all_participations = participations.where(contest_id: contest_id)
                                               .where(
                                                 'region_id in (:region_ids)',
                                                 region_ids: participations.where(contest_id: intersecting_contest_id)
                                                                           .pluck(:region_id)
                                               )
                                               .where(
                                                 'region_id in (:region_ids)',
                                                 region_ids: ::Region.where.not("regions.subscription = 'seeded-public' or regions.display_flag = false")
                                                                     .where("lower(name) like '%#{region_name&.downcase}%'")
                                                                     .pluck(:id)
                                               )
          else
            if ignore_display_and_subscription_filter == 'true'
              all_participations = participations.where(contest_id: contest_id)
                                                 .where(
                                                   'region_id in (:region_ids)',
                                                   region_ids: ::Region.where("lower(name) like '%#{region_name&.downcase}%'")
                                                                       .pluck(:id)
                                                 )
            else
              all_participations = participations.where(contest_id: contest_id)
                                                 .where(
                                                   'region_id in (:region_ids)',
                                                   region_ids: ::Region.where.not("regions.subscription = 'seeded-public' or regions.display_flag = false")
                                                                       .where("lower(name) like '%#{region_name&.downcase}%'")
                                                                       .pluck(:id)
                                                 )
            end
          end
        end
        participations = all_participations.includes(:region)
                                           .offset(search_params.offset)
                                           .limit(search_params.limit)
                                           .order(search_params.sort_key => search_params.sort_order)
        participations_arr = []

        # Merge Participation and Region data
        participations.each do |p|
          region_hash = Hash.new([])
          p_hash = Hash.new([])

          region_hash = ::RegionSerializer.new(p.region).serializable_hash[:data][:attributes]
          p_hash = ::ParticipationSerializer.new(p).serializable_hash[:data][:attributes]
          region_hash.merge!(p_hash)
          participations_arr.push(region_hash)
        end

        # Need to calculate percentiles for species_diversity, monitoring and community scores of
        # all the regions in given contest and merge them with those regions' other data
        regions = []
        all_participations = ::Contest.find_by_id(search_params[:contest_id])&.participations.base_region_participations
        all_participations.each do |p|
          regions.push(p.region)
        end
        scores = ::Region.merge_intermediate_scores_and_percentiles(regions: regions)
        participations_arr.each do |p|
          p_scores_hash = scores.detect { |s| s[:id] == p[:id].to_i }
          p.merge!(p_scores_hash)
        end

        Success(participations_arr)
      end
    end
  end
end
