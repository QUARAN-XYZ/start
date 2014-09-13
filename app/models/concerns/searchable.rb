module Searchable
  extend ActiveSupport::Concern

  # Setup the index mappings
  def self.setup_index_mappings
    models = [Content::Translation, Content::Transliteration, Quran::Ayah]
    mappings = Hash.new

    models.each do |model|
      mappings = mappings.merge(model.mappings.to_hash)
    end
    
      models.first.__elasticsearch__.client.indices.create \
        index: "quran",
        body: { settings: models.first.settings.to_hash, mappings: mappings }
    # end
  end 


  # When this module is included, this callback function is called
  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    # Initial the paging gem, Kaminari
    Kaminari::Hooks.init
    Elasticsearch::Model::Response::Response.__send__ :include, Elasticsearch::Model::Response::Pagination::Kaminari

    class << self
        alias_method :importing, :import
        alias_method :searching, :search
    end

    self.settings index: { number_of_shards: 1 } do
        mappings dynamic: 'strict' do
        end
    end
    
    self.index_name 'quran'
    
    


    

    # Rails.logger.error Rails.root
    # YAML.load(File.read(File.expand_path("#{Rails.root}/config/elasticsearch/mappings.yml", __FILE__)))
    # 
    

  end
end