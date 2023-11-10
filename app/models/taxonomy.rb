class Taxonomy < ApplicationRecord
    has_many :observations

    validates :taxon_id, presence: true
    validates :taxon_rank, exclusion: { in: %w[unranked] }

    def build_record(params:)
        obj = self
        obj.taxon_id = params['taxonID'] || ''
        obj.scientific_name = params['scientificName'] || ''
        obj.canonical_name = params['canonicalName'] || ''
        obj.accepted_name = params['accepted'] || params['canonicalName'] || params['scientificName'] || ''
        obj.accepted_name_usage_id = params['acceptedNameUsageID'] || ''
        obj.kingdom = params['kingdom']&.downcase || ''
        obj.phylum = params['phylum']&.downcase || ''
        obj.class_name = params['class']&.downcase || ''
        obj.taxonomic_status = params['taxonomicStatus'] || ''
        obj.taxon_rank = params['taxonRank'] || ''
        obj.generic_name = params['genericName'] || ''
        obj.source = params['source'] || 'gbif'
        obj.order = params['order']&.downcase || ''
        obj.family = params['family']&.downcase || ''
        obj.genus = params['genus']&.downcase || ''

        return obj
    end

    # Store taxonomy record using given params
    def self.store_taxonomy(params:)
      return nil unless params['taxonID'].present?
      taxon_id = params['taxonID']
      taxon_id = taxon_id.to_s.match(/(\d+)/).captures[0] if taxon_id.present? && taxon_id.to_s =~ /\d+/
      taxonomy = Taxonomy.find_by_taxon_id(taxon_id)
      taxonomy = Taxonomy.new() unless taxonomy.present?
      record   = taxonomy.build_record(params: params)

      if record.valid? && (record.new_record? || record.changed?)
        begin 
          record.save
        rescue => e
          Rails.logger.info ">>> Taxonomy::store_taxonomy - Error occured while saving taxonomy record #{e.full_message}"
          return nil
        end
        Rails.logger.info ">>> Taxonomy::store_taxonomy - Successfully stored record for taxon_id #{record.taxon_id}"

        return record
      else
        return nil
      end

    end

    # Some taxonomies have synonym taxonomy and have accepted_name_usage_id which matches with taxon_id
    # of that synonym.
    # We need to update those taxonomies' accepted_name with synonym taxonomy's accepted_name
    def update_accepted_name
        case taxonomic_status.downcase
        when 'accepted'
            taxon_updated = Taxonomy.where(accepted_name_usage_id: taxon_id).where.not(accepted_name: accepted_name).update_all(accepted_name: accepted_name) if accepted_name.present?
            Rails.logger.info ">>>>> Taxonomy::update_scientific_name/#{taxonomic_status} :: Updated accepted_name #{accepted_name} for taxonomies having accepted_name_usage_id as #{taxon_id},taxon_updated:#{taxon_updated}"
        else
            taxonomy = Taxonomy.find_by_taxon_id(accepted_name_usage_id)
            parent_accepted_name = taxonomy&.accepted_name
            taxon_updated = self.update(accepted_name: parent_accepted_name) if parent_accepted_name.present? && parent_accepted_name != accepted_name
            Rails.logger.info ">>>>> Taxonomy::update_scientific_name/#{taxonomic_status} :: Updated accepted_name #{accepted_name} for taxon_id-#{taxon_id}, taxon_updated:#{taxon_updated}"
        end   
    end

    # When fetching taxonomy from multiple gbif apis, there are some discrepencies which are resolved in transform_record
    def self.transform_record(record:)
      record['taxonID'] = record['key'] if record['key'].present?
      record['taxonID'] = record['usageKey'] if record['usageKey'].present?

      if record['taxonID'].present? && record['taxonID'].to_s =~ /\d+/
        record['taxonID'] = record['taxonID'].to_s.match(/(\d+)/).captures[0]
      else
        return nil
      end

      record['taxonomicStatus'] = record['status'] unless record['taxonomicStatus'].present?
      record['acceptedNameUsageID'] = record['acceptedKey'] || record['acceptedUsageKey'] || ''
      record['taxonRank'] = record['rank']

      return record
    end
                  
    # This function extracts taxonomy details from gbif using it's related apis
    def self.get_taxonomy_from_gbif(scientific_name:)
      parsed_url = Addressable::URI.parse("https://api.gbif.org/v1/species?name=#{scientific_name}").display_uri.to_s
      response = HTTParty.get(parsed_url)
      Delayed::Worker.logger.info "get_taxonomy_from_gbif::Source::api_url: #{response.request.last_uri.to_s}"
      record = nil
      if response.success? && !response.body.nil?
        result = JSON.parse(response.body)
        record = result['results'][0] || ''
        unless record.present?
          parsed_url = Addressable::URI.parse("https://api.gbif.org/v1/species/match?verbose=true&strict=false&name=#{scientific_name}").display_uri.to_s
          response = HTTParty.get(parsed_url)
          Delayed::Worker.logger.info "get_taxonomy_from_gbif::Source::api_url: #{response.request.last_uri.to_s}"
          if response.success? && !response.body.nil?
            record = JSON.parse(response.body)
          end
        end
      end
      return record
    end

    # This function extracts synonym taxonomy details from gbif using it's related apis
    def self.get_synonym_taxonomy_from_gbif(accepted_name_usage_id:)
      response = HTTParty.get("https://api.gbif.org/v1/species/#{accepted_name_usage_id}")
      Delayed::Worker.logger.info "get_synonym_taxonomy_from_gbif::Source::api_url: #{response.request.last_uri.to_s}"
      record = nil
      if response.success? && !response.body.nil?
        record = JSON.parse(response.body)
      end
      return record
    end

    def get_category_name
      file = File.open "#{Rails.root}/app/views/pages/_category_mapping.json"
      category_mapping = JSON.load file

      category_names = []
      category_name = ''

      category_mapping.each do |category|
        if category['kingdom'].present? && kingdom.present? && category['kingdom'].include?(kingdom)
          category_name = category['name']
        end
        if category['phylum'].present? && phylum.present? && category['phylum'].include?(phylum)
          category_name = category['name']
        end
        if category['class_name'].present? && class_name.present? && category['class_name'].include?(class_name)
          category_name = category['name']
        end
        if category['order'].present? && order.present? && category['order'].include?(order)
          category_name = category['name']
        end
      end
      return category_name
    end

    rails_admin do
        list do
            field :id
            field :taxon_id
            field :source
            field :scientific_name
            field :canonical_name
            field :accepted_name
            field :generic_name
            field :accepted_name_usage_id
            field :kingdom
            field :phylum
            field :class_name
            field :taxonomic_status
            field :taxon_rank
            field :created_at      
        end
        edit do 
            field :id
            field :taxon_id
            field :source
            field :scientific_name
            field :canonical_name
            field :accepted_name
            field :generic_name
            field :accepted_name_usage_id
            field :kingdom
            field :phylum
            field :class_name
            field :taxonomic_status
            field :taxon_rank
            field :created_at
        end
        show do
            field :id
            field :taxon_id
            field :source
            field :scientific_name
            field :canonical_name
            field :accepted_name
            field :generic_name
            field :accepted_name_usage_id
            field :kingdom
            field :phylum
            field :class_name
            field :taxonomic_status
            field :taxon_rank
            field :created_at      
            field :created_at
        end
    end
end
