# vim: ts=4 sw=4 expandtab
class Quran::Ayah < ActiveRecord::Base
    extend Quran

    self.table_name = 'ayah'
    self.primary_key = 'ayah_key'
    # Rails.logger.ap self.table_name
    #
    # relationships
    belongs_to :surah, class_name: 'Quran::Surah'

    has_many :words,  class_name: 'Quran::Word',  foreign_key: 'ayah_key'
    has_many :tokens, class_name: 'Quran::Token', through:     :words
    has_many :stems,  class_name: 'Quran::Stem',  through:     :words
    has_many :lemmas, class_name: 'Quran::Lemma', through:     :words
    has_many :roots,  class_name: 'Quran::Root',  through:     :words

    has_many :_tafsir_ayah, class_name: 'Content::TafsirAyah', foreign_key: 'ayah_key'
    has_many :tafsirs,      class_name: 'Content::Tafsir',     through:     :_tafsir_ayah

    has_many :translations,     class_name: 'Content::Translation',     foreign_key: 'ayah_key'
    has_many :transliterations, class_name: 'Content::Transliteration', foreign_key: 'ayah_key'

    has_many :audio,  class_name: 'Audio::File',     foreign_key: 'ayah_key'
    has_many :texts,  class_name: 'Quran::Text',     foreign_key: 'ayah_key'
    has_many :images, class_name: 'Quran::Image',    foreign_key: 'ayah_key'
    has_many :glyphs, class_name: 'Quran::WordFont', foreign_key: 'ayah_key'

    # NOTE the relationships below were created as database-side views for use with elasticsearch
    has_many :text_roots,  class_name: 'Quran::TextRoot',  foreign_key: 'ayah_key'
    has_many :text_lemmas, class_name: 'Quran::TextLemma', foreign_key: 'ayah_key'
    has_many :text_stems,  class_name: 'Quran::TextStem',  foreign_key: 'ayah_key'
    has_many :text_tokens, class_name: 'Quran::TextToken', foreign_key: 'ayah_key'

    def self.fetch_ayahs(surah_id, from, to)
        self.where("quran.ayah.surah_id = ? AND quran.ayah.ayah_num >= ? AND quran.ayah.ayah_num <= ?", surah_id, from, to)
            .order("quran.ayah.surah_id, quran.ayah.ayah_num")
    end

    ############### ES FUNCTIONS ################################################################# 

    # This function affects the indexed JSON for
    # Quran::Ayah.import
    # def as_indexed_json(options={})
    #   self.as_json(
    #     include: {
    #         translations: {
    #             only: [:resource_id, :ayah_key, :text],
    #             # methods: [:resource_info]
    #             # include: {
    #             #     resource: {
    #             #         only: [:slug, :name, :type]
    #             #     }
    #             # }
    #         }
    #     })
    # end

    # Get all the mappings!
    # curl -XGET 'http://localhost:9200/_all/_mapping'
    # curl -XGET 'http://localhost:9200/_mapping'
    #
    # Example: https://gist.github.com/karmi/3200212

    # NOTE / TODO I removed this function and refactored it into the matched_products and matched_children
    # methods below, but I'm leaving the stub here so that perhaps we can encapsulate the independent
    # searching of each set and subsequent merging of the two sets here instead of in SearchController.query
    # later on

    def self.search( query, page = 1, size = 20, types )
    end

    # NOTE I split these functions into matched_parents and matched_blah_query so that I could properly
    # debug them from the rails console

    def self.matched_parents( query, types )
        query_hash = self.matched_parents_query( query, types )
        # Matched parent ayahs
        # NOTE: we need to get all possible ayahs because the result set is not yet sorted by relevance,
        # which is apparently a limitation of 'has_child', so we'll set the pagination size to 6236 (the entire set of ayahs in the quran)
        matched_parents = self.__elasticsearch__.client.search( query_hash ) #.page( 1 ).per( 6236 )
        seen = {}
        results = []
        matched_parents['hits']['hits'].each do |r|
            source = r['_source']
            ayah_key = source['ayah_key']
            results.push( [ ayah_key, source ] ) if not seen.key? ayah_key
            seen[ ayah_key ] = true
        end
        return results
    end

    def self.matched_parents_query( query, types )
        should = Array.new

        should.push( {
            has_child: {
                type: 'data',
                query: {
                    multi_match: {
                        type: 'most_fields',
                        query: query,
                        fields: [ 'text', 'text.stemmed' ],
                        minimum_should_match: '3<62%'
                    }
                }
            }
        } )

        # The query hash
        query_hash = {
            explain: true,
            size: 6236,
            index: types,
            body: {
                query: {
                    bool: {
                        should: should,
                        minimum_number_should_match: 1
                    }
                }
            }
        }
    end

    def self.matched_children( query, types, ayat = [] )
        msearch_query = self.matched_children_query( query, types, ayat )
        self.__elasticsearch__.client.msearch( msearch_query )
    end

    def self.matched_children_query( query, types, ayat = [] )
        msearch = { body: [], index: types, type: [ 'data' ] }
        ayat.each do |ayah_key|
            search = {
                search: {
                    highlight: {
                        fields: {
                            text: {
                                type: 'fvh',
                                number_of_fragments: 1,
                                fragment_size: 1024
                            }
                        },
                        tags_schema: 'styled'
                    },
                    explain: true,
                    query: {
                        bool: {
                            must: [ {
                                term: {
                                    _parent: {
                                        value: ayah_key
                                    }
                                }
                            }, {
                                multi_match: {
                                    type: 'most_fields',
                                    query: query,
                                    fields: [ 'text^1.5', 'text.stemmed' ],
                                    minimum_should_match: '3<62%'
                                }
                            } ]
                        }
                    },
                    indices_boost: {
                        :"translation-en" => 3
                    },
                    size: 3 # limit number of child hits per ayah, i.e. bring back no more then 3 hits per ayah
                }
            }
            msearch[:body].push( search )
        end
        return msearch
    end

    def self.import_options ( options = {} )
        transform = lambda do |a|
            data = a.__elasticsearch__.as_indexed_json
            data.delete( 'text' ) # NOTE we exclude text because it serves no value in the parent mapping
            { index: { _id: "#{a.ayah_key}", data: data } }
        end
        options = { transform: transform, batch_size: 6236 }.merge( options )
        return options
    end

    def self.import ( options = {} )
        self.importing( self.import_options( options ) )
    end
end
