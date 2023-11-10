require_relative '../../../lib/common/utils.rb'

module CountableStatistics
  extend ActiveSupport::Concern
  included do

    #
    # this code deals with updating the counts of observations and other related information. 
    # since we want this information for regions, contests, and participants in a contest, the
    # code is here in a concern, so that the code can be used in those three models.
    #

    def add_and_compute_statistics obs
      self.observations << obs
      reset_statistics
    end

    # def add_observation region, obs
    #   region.observations << obs
    #   add_observation region.parent_region, obs unless region.parent_region_id.nil?
    # end

    def reset_statistics
      if self.is_a? Region
        update_column :observations_count, self.get_observations_count(include_gbif: true)
        update_column :people_count, self.get_people_count(include_gbif: true)
        update_column :species_count, self.get_species_count(include_gbif: true)
        update_column :identifications_count, self.get_identifications_count(include_gbif: true)
        region_scores = self.calculate_scores_to_store
        update_column :bioscore, region_scores[:bioscore]
        update_column :bio_value, region_scores[:bio_value]
        update_column :species_diversity_score, region_scores[:species_diversity_score]
        update_column :species_trend, region_scores[:species_trend]
        update_column :monitoring_score, region_scores[:monitoring_score]
        update_column :monitoring_trend, region_scores[:monitoring_trend]
        update_column :community_score, region_scores[:community_score]
        update_column :community_trend, region_scores[:community_trend]
        update_column :physical_health_score, get_physical_health_score()
        update_column :mental_health_score, get_mental_health_score()
      elsif self.is_a? Contest
        self.update_contest_scores
      end

      #
      # update_column :species_count, self.observations.pluck(:accepted_name).uniq.count
      #
      # the above count is not used because the species names are not normalized across
      # data sources. thus the same species will have multiple names, and counts of unique values
      # is not possible
      #
    end

    def get_physical_health_score
      get_score Constant.find_by_name('physical_health_score_constant').value,
                Constant.find_by_name('physical_health_score_constant_a').value,
                Constant.find_by_name('physical_health_score_constant_b').value
    end

    def get_mental_health_score
      get_score Constant.find_by_name('mental_health_score_constant').value,
                Constant.find_by_name('mental_health_score_constant_a').value,
                Constant.find_by_name('mental_health_score_constant_b').value
    end

    def get_score constant, constant_a, constant_b
      # if self.is_a? Region
      #   observations_count = RegionsObservationsMatview.get_observations_for_region(region_id: self.id).count
      #   people_count = get_people_count(include_gbif: true)
      # end
      observations_count = self.observations_count
      people_count = self.people_count
      total_hours = people_count.positive? ?
                    (Constant.find_by_name('average_hours_per_observation').value * observations_count) / (people_count * 24) : 0
      ( (total_hours < 5 ? constant_a : constant_b) * constant * people_count ).round
    end

    # Compute observations count for given region, optionally for given date range
    def get_observations_count(start_dt: nil, end_dt: nil, include_gbif: false)
      if start_dt.present? && end_dt.present?
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id, start_dt: start_dt, end_dt: end_dt)
      else
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id)
      end
      return obs.count
    end

    # Compute species count for given region, optionally for given date range
    def get_species_count(start_dt: nil, end_dt: nil, include_gbif: false)
      if start_dt.present? && end_dt.present?
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id, start_dt: start_dt, end_dt: end_dt)
      else
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id)
      end
       return obs.distinct.has_accepted_name.ignore_species_code.select(:accepted_name).distinct.count
    end

    # Compute people count for given region, optionally for given date range
    def get_people_count(start_dt: nil, end_dt: nil, include_gbif: false)
      if start_dt.present? && end_dt.present?
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id, start_dt: start_dt, end_dt: end_dt)
      else
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id)
      end
      return obs.distinct.select(:creator_name).where.not(creator_name: nil).distinct.count
    end

    # Compute identifications count for given region, optionally for given date range
    def get_identifications_count(start_dt: nil, end_dt: nil, include_gbif: false)
      if start_dt.present? && end_dt.present?
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id, start_dt: start_dt, end_dt: end_dt)
      else
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id)
      end
      return obs.sum(:identifications_count)
    end

    #
    # these functions compute the rankings of people and species
    # used on the regions and contest page.
    #

    def get_top_species n=nil, start_dt:nil, end_dt:nil
      if self.is_a? Region
        # get_ranking self.observations.uniq.pluck(:scientific_name), n
        if start_dt.present? && end_dt.present?
          obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id,
                                                                       start_dt: start_dt,
                                                                       end_dt: end_dt)
        else
          obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id)
        end
        get_ranking obs.pluck(:scientific_name), n
      elsif self.is_a? Participation
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.region.id,
                                                                     start_dt: self.starts_at,
                                                                     end_dt: self.ends_at)
        get_ranking obs.pluck(:scientific_name), n
      end
    end  

    def get_top_taxonomies n=nil, start_dt:nil, end_dt:nil
      if self.is_a? Region
        # get_ranking self.observations.uniq.pluck(:scientific_name), n
        if start_dt.present? && end_dt.present?
          obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id,
                                                                       start_dt: start_dt,
                                                                       end_dt: end_dt)
        else
          obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id)
        end
        get_ranking obs.pluck(:taxonomy_id).compact, n
      elsif self.is_a? Participation
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.region.id,
                                                                     start_dt: self.starts_at,
                                                                     end_dt: self.ends_at)
        get_ranking obs.pluck(:taxonomy_id).compact, n
      end
    end

    def get_top_people n=nil
      if self.is_a? Region
        # get_ranking self.observations.uniq.pluck(:creator_name), n
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.id)
        get_ranking obs.pluck(:creator_name), n
      elsif self.is_a? Participation
        obs = RegionsObservationsMatview.get_observations_for_region(region_id: self.region.id,
                                                                     start_dt: self.starts_at,
                                                                     end_dt: self.ends_at)
        get_ranking obs.pluck(:creator_name), n
      end
    end  

    def get_ranking arr, n
      #
      # rank by count, in descending order
      # when n is nil take all values, otherwise take the top n
      #
      arr.tally.sort_by { |k,v| -v }.first (n.nil? || n<1 ? arr.length : n)
    end

    # Calculate start date and end date which will be used to fetch different report scores
    def get_date_range_for_report(format: false)
      nr = get_neighboring_region(region_type: 'greater_region')
      end_dt = Time.now.utc
      start_dt = end_dt - Utils.convert_to_seconds(unit:'year', value: 3)

      region_id = nr.present? ? nr.id : self.id
      obs = RegionsObservationsMatview.get_observations_for_region(region_id: region_id)
      start_dt = obs&.order("observed_at")&.first&.observed_at || start_dt

      return format == true ? [start_dt.strftime("%Y-%m-%d"), end_dt.strftime("%Y-%m-%d")] : [start_dt, end_dt]

    end


    # Compute regions scores by comparing the counts with that of neighboring regions
    def get_regions_score(region_type: nil, score_type: , num_years: nil)
      if region_type.present?
        nr = get_neighboring_region(region_type: region_type)

        if nr.present?
          case score_type
          when 'observations_score'
            nr_obs_count = nr.observations_count
            base_region_obs_count = observations_count
            return nr_obs_count.present? && nr_obs_count != 0 ? sprintf('%.2f', base_region_obs_count * 100/nr_obs_count.to_f) : sprintf('%.2f', 0)
          when 'species_score'
            nr_species_count = nr.species_count
            base_region_species_count = species_count
            return nr_species_count.present? && nr_species_count != 0 ? sprintf('%.2f', base_region_species_count * 100/nr_species_count.to_f) : sprintf('%.2f', 0)
          when 'people_score'
            nr_people_count = nr.people_count
            base_region_people_count = people_count
            return nr_people_count.present? && nr_people_count != 0 ? sprintf('%.2f', base_region_people_count * 100/nr_people_count.to_f) : sprintf('%.2f', 0)
          end
        end
      end
    end


    # Compute yearly scores by comparing yearly counts for given no. of years vs total count
    def get_yearly_score(score_type: , num_years:)
      end_dt = Time.now.utc
      start_dt = end_dt - Utils.convert_to_seconds(unit:'year', value: num_years)

      total_count = yearly_count = 0
      case score_type
      when 'observations_score'
        yearly_count = get_observations_count(start_dt: start_dt, end_dt: end_dt, include_gbif: true)
        total_count = observations_count
      when 'species_score'
        yearly_count = get_species_count(start_dt: start_dt, end_dt: end_dt, include_gbif: true)
        total_count = species_count
      when 'people_score'
        yearly_count = get_people_count(start_dt: start_dt, end_dt: end_dt, include_gbif: true)
        total_count = people_count
      end
      return total_count != 0 ? sprintf('%.2f', yearly_count * 100 /total_count.to_f) : sprintf('%.2f', 0)
    end
  end

  def get_yearly_count(score_type: , num_years:)
    end_dt = Time.now.utc
    start_dt = end_dt - Utils.convert_to_seconds(unit:'year', value: num_years)
    yearly_count = 0
    case score_type
    when 'observations_score'
      yearly_count = get_observations_count(start_dt: start_dt, end_dt: end_dt, include_gbif: true)
    when 'species_score'
      yearly_count = get_species_count(start_dt: start_dt, end_dt: end_dt, include_gbif: true)
    when 'people_score'
      yearly_count = get_people_count(start_dt: start_dt, end_dt: end_dt, include_gbif: true)
    end
    return yearly_count
  end


  # For given list of species get common name and image
  def get_species_details(species: , offset: , limit: )
    observations_with_images = observations.where(taxonomy_id: species)
                                           .has_images
                                           .ignore_reserved_sightings
                                           .includes(:observation_images)
                                           .order('observed_at desc')
    total = 0
    idx = 0
    final_species = []
    species.map! do |s|
      obs = observations_with_images.detect{ |o| s == o.taxonomy_id }

      next unless obs.present?
      idx += 1
      next if idx <= offset
      total += 1
      break if total > limit
      species_hash = Hash.new([])
      species_hash[:image] = obs.observation_images.pluck(:url).first
      species_hash[:scientific_name] = obs.scientific_name
      species_hash[:common_name] = obs.common_name
      species_hash[:creator_name] = obs.creator_name
      final_species.push(species_hash)
    end

    return final_species.compact
  end
end


