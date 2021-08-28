# frozen_string_literal: true

module Qdc
  module Search
    class NavigationClient < Qdc::Search::Client
      SOURCE_ATTRS = %w[key name result_type].freeze
      RESULT_SIZE = 20
      PREFIX_SLOP = 3

      def initialize(query, options = {})
        super(query, options)
      end

      def search
        response = Elasticsearch::Model.search(search_definition, [Chapter], index: Chapter.index_name)

        # For debugging, copy the query and paste in kibana for debugging
        if DEBUG_ES_QUERIES
          File.open("es_queries/last_navigational_query.json", "wb") do |f|
            f << search_definition.to_json
          end
        end

        Search::NavigationalResults.new(response)
      end

      protected

      def search_definition
        {
          _source: source_attributes,
          query: search_query,
          from: page * RESULT_SIZE,
          size: RESULT_SIZE,
          sort: sort_query
        }
      end

      def search_query
        {
          match_phrase_prefix: {
            text: {
              query: query.query,
              slop: PREFIX_SLOP
            }
          }
        }
      end

      def sort_query
        if query.has_ayah_key?
          #
          # Let ES decide the order if searching with ayah key
          #
          []
        else
          [{ id: { order: 'asc' } }]
        end
      end

      def source_attributes
        SOURCE_ATTRS
      end
    end
  end
end
