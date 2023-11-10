# frozen_string_literal: true

require 'dry/validation'
require_relative './application'
require_relative '../structs/pagination'
require_relative '../schemas/pagination'

module Service
  module Contest
    # Class to encapsulate API requests
    class Base
      include Service::Application

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        required(:contest_id).filled(:integer, gt?: 0)
      end

      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
      end

      def execute(params)
        show_params = Params.new(params)
        fetch_contest(show_params.contest_id)
      end

      private

      def fetch_contest(contest_id)
        contest = ::Contest.find_by_id(contest_id)
        return Failure('Invalid contest id provided.') if contest.blank?
        Success(contest)
      end
    end


    class List
      include Service::Application

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        optional(:status).filled(:string, included_in?: ['in_progress', 'upcoming', 'past'])
      end

      class Params < AppStruct::Pagination
        attribute? :status, Types::Params::String
      end

      def execute(params)
        params = Params.new(params)
        list_contests(params)
      end

      private

      def list_contests(params)
        status = params.status
        if status.present?
          case status
          when 'in_progress'
            contests = ::Contest.in_progress
                                .online
                                .ordered_by_starts_at
                                .offset(params.offset)
                                .limit(params.limit)
          when 'upcoming'
            contests = ::Contest.upcoming
                                .online
                                .ordered_by_starts_at
                                .offset(params.offset)
                                .limit(params.limit)
          when 'past'
            contests = ::Contest.past
                                .online
                                .ordered_by_starts_at
                                .offset(params.offset)
                                .limit(params.limit)
          end
        else
          contests = ::Contest.ordered_by_starts_at
                              .offset(params.offset)
                              .limit(params.limit)
        end
        Success(contests)
      end
    end
  end
end
