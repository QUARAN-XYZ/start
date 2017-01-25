# == Schema Information
#
# Table name: verses
#
#  id            :integer          not null, primary key
#  chapter_id    :integer
#  verse_number  :integer
#  verse_index   :integer
#  verse_key     :string
#  text_madani   :text
#  text_indopak  :text
#  text_simple   :text
#  juz_number    :integer
#  hizb_number   :integer
#  rub_number    :integer
#  sajdah        :string
#  sajdah_number :integer
#  page_number   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Verse < ApplicationRecord
  include Searchable

  belongs_to :chapter, inverse_of: :verses, counter_cache: true
  has_many :tafsirs
  has_many :words
  has_many :media_contents, as: :resource
  has_many :translations, as: :resource
  has_many :transliterations, as: :resource
  has_many :audio_files, as: :resource
  has_many :recitations, through: :audio_files

  default_scope {order 'verse_number asc'}

  def chapter_name
    {arabic: chapter.name_arabic, english: chapter.name_complex}
  end

  def as_indexed_json(options)
    self.as_json(
        only: [:id, :verse_key, :text_madani, :text_indopak, :text_simple],
        methods: [:chapter_name]
    )
  end

  index_name 'verses'

  mapping dynamic: 'false' do
    indexes :id, type: 'integer', index: 'no'

    [:text_madani, :text_indopak, :text_simple].each do |text_type|
      indexes text_type, type: 'text' do
        indexes :text,
                type: 'text',
                similarity: 'my_bm25',
                term_vector: 'with_positions_offsets_payloads',
                analyzer: 'arabic_normalized'
        indexes :stemmed,
                type: 'text',
                similarity: 'my_bm25',
                term_vector: 'with_positions_offsets_payloads',
                search_analyzer: 'arabic_normalized',
                analyzer: 'arabic_ngram'
        indexes :autocomplete,
                type: 'string',
                analyzer: 'autocomplete_arabic',
                search_analyzer: 'arabic_normalized',
                index_options: 'offsets'
      end
    end

    indexes :verse_key
    indexes :chapter_name
  end
end
