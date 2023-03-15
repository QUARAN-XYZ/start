# frozen_string_literal: true
# == Schema Information
# Schema version: 20230313013539
#
# Table name: resource_contents
#
#  id                     :integer          not null, primary key
#  approved               :boolean
#  author_name            :string
#  cardinality_type       :string
#  description            :text
#  language_name          :string
#  name                   :string
#  records_count          :integer          default(0)
#  resource_type          :string
#  resource_type_name     :string
#  slug                   :string
#  sqlite_db              :string
#  sqlite_db_generated_at :datetime
#  sub_type               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  author_id              :integer
#  data_source_id         :integer
#  language_id            :integer
#  mobile_translation_id  :integer
#
# Indexes
#
#  index_resource_contents_on_approved               (approved)
#  index_resource_contents_on_author_id              (author_id)
#  index_resource_contents_on_cardinality_type       (cardinality_type)
#  index_resource_contents_on_data_source_id         (data_source_id)
#  index_resource_contents_on_language_id            (language_id)
#  index_resource_contents_on_mobile_translation_id  (mobile_translation_id)
#  index_resource_contents_on_resource_type_name     (resource_type_name)
#  index_resource_contents_on_slug                   (slug)
#  index_resource_contents_on_sub_type               (sub_type)
#

class ResourceContent < ApplicationRecord
  include LanguageFilterable
  include NameTranslateable

  scope :translations, -> { where sub_type: [SubType::Translation, SubType::Transliteration] }
  scope :media, -> { where sub_type: SubType::Video }
  scope :tafsirs, -> { where sub_type: SubType::Tafsir }
  scope :chapter_info, -> { where sub_type: SubType::Info }
  scope :one_verse, -> { where cardinality_type: CardinalityType::OneVerse }
  scope :one_chapter, -> { where cardinality_type: CardinalityType::OneChapter }
  scope :approved, -> { where approved: true }
  scope :recitations, -> { where sub_type: SubType::Audio }

  module CardinalityType
    OneVerse = '1_ayah'
    OneWord = '1_word'
    NVerse = 'n_ayah'
    OneChapter = '1_chapter'
  end

  module ResourceType
    Audio = 'audio'
    Content = 'content'
    Quran = 'quran'
    Media = 'media'
  end

  module SubType
    Translation = 'translation'
    Tafsir = 'tafsir'
    Transliteration = 'transliteration'
    Font = 'font'
    Image = 'image'
    Info = 'info'
    Video = 'video'
    Audio = 'audio'
    Data = 'data' # General data, ()Mushaf layout info for now)
  end

  belongs_to :author
  belongs_to :data_source
  has_one :resource_content_stat

  def self.filter_by(ids: nil, name: nil)
    if name.present?
      list = joins(:author)
      name_query = "%#{name.strip.downcase}%"
      by_name = list.where("LOWER(resource_contents.name) ilike ?", name_query)
      by_author_name = list.where("LOWER(authors.name) ilike ?", name_query)

      by_name.or(by_author_name)
    elsif ids.present?
      where(id: ids.split(',').map(&:to_i))
    end
  end

  def increment_download_count!
    stats = resource_content_stat || create_resource_content_stat
    stats.update_column :download_count, stats.download_count.to_i + 1
  end

  def self.change_log(before: nil, after: nil)
    list = self

    if before && after
      list.where("updated_at BETWEEN ? and ?", before, after)
    elsif before
      list.where("updated_at < ?", before)
    elsif after
      list.where("updated_at >= ?", after)
    else
      list
    end
  end

  def self.filter_subtype(type = nil)
    if type.present?
      where(sub_type: type)
    else
      self
    end
  end
end
