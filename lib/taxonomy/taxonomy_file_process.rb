require 'csv'

module TaxonomyFileProcess
    def self.process_file(file_name:, read_from_last_processed: false)
      total_processed_records = 0
      Rails.logger.info ">>> Started TaxonomyFileProcess::process_file for file #{file_name}"

      last_taxon_id = skip_row = nil
      if read_from_last_processed.present?
        last_taxon_id = Taxonomy.order(created_at: :desc).first&.taxon_id
        skip_row = true
      end

      begin 
        # CSV header 
        # taxonID, datasetID, parentNameUsageID, acceptedNameUsageID, originalNameUsageID,scientificName,scientificNameAuthorship,canonicalName,genericName,specificEpithet,infraspecificEpithet,taxonRank,nameAccordingTo,namePublishedIn,taxonomicStatus,nomenclaturalStatus,taxonRemarks,kingdom,phylum,class,order,family,genus
        CSV.foreach(file_name, headers: true, col_sep: "\t", skip_blanks: true, encoding: "bom|utf-8", quote_char: nil) do |row|
            if last_taxon_id.present? && skip_row.present?
              Rails.logger.info ">>> Skipping row with taxon id #{row['taxonID']} as it is already processed"
              next if last_taxon_id != row['taxonID']
              skip_row = false
            end
            row['source'] = 'gbif'
            taxonomy = Taxonomy.store_taxonomy(params: row) if row['taxonID'].present? && row['taxonRank'] != 'unranked'

            if taxonomy.present?
                begin
                  taxonomy.update_accepted_name()
                rescue => e
                    Rails.logger.info ">>> TaxonomyFileProcess::process_file Error occured while updating taxonomy scientific name - #{e.full_message}"
                end
                total_processed_records += 1
            end
        end
        Rails.logger.info "Total records processed : #{total_processed_records}"
      rescue => e
        Rails.logger.info ">>> TaxonomyFileProcess:: Failed to process the file becuase of an error #{e.full_message}"
      end

    end

    def self.taxonomy_vernacular_file_process(file_name:)
      total_processed_records = 0
      Rails.logger.info ">>> Started TaxonomyFileProcess::process_file for file #{file_name}"
      begin
        data_source_id = DataSource.find_by_name('gbif')
        CSV.foreach(file_name, headers: true, col_sep: "\t", skip_blanks: true, encoding: "bom|utf-8", quote_char: nil) do |row|
          next if row['language'] != 'en' || !row['taxonID'].present? || !row['vernacularName'].present?
          Rails.logger.info ">>> TaxonomyFileProcess::taxonomy_vernacular_file_process:: For taxonID: #{row['taxonID']}, vernacularName: #{row['vernacularName']}"
          taxonomy_updated = Observation.joins(:taxonomy)
                                        .where("taxonomies.taxon_id = ?", row['taxonID'].to_s)
                                        .where(data_source_id: data_source_id)
                                        .where.not(taxonomy_id: nil)
                                        .update_all(common_name: row['vernacularName'])
          if taxonomy_updated.positive?
            Rails.logger.info "Updated GBIF observations'common_name with #{row['vernacularName']}"
            total_processed_records += 1
          end
        end
        Rails.logger.info ">>> TaxonomyFileProcess::taxonomy_vernacular_file_process::Total records processed : #{total_processed_records}"
      rescue => e
        Rails.logger.info ">>> TaxonomyFileProcess::taxonomy_vernacular_file_process:: Failed to process the file becuase of an error #{e.full_message}"
      end
    end
end
