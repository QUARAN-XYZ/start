# frozen_string_literal: true

# == Schema Information
#
# Table name: audio_recitations
#
#  id                  :bigint           not null, primary key
#  approved            :boolean          default(FALSE)
#  arabic_name         :string
#  description         :text
#  file_formats        :string
#  files_size          :integer
#  home                :integer
#  name                :string
#  priority            :integer
#  relative_path       :string
#  torrent_filename    :string
#  torrent_info_hash   :string
#  torrent_leechers    :integer          default(0)
#  torrent_seeders     :integer          default(0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  qirat_type_id       :integer
#  recitation_style_id :integer
#  resource_content_id :integer
#  section_id          :integer
#
# Indexes
#
#  index_audio_recitations_on_approved             (approved)
#  index_audio_recitations_on_priority             (priority)
#  index_audio_recitations_on_qirat_type_id        (qirat_type_id)
#  index_audio_recitations_on_recitation_style_id  (recitation_style_id)
#
class Audio::Recitation < ApplicationRecord
  include NameTranslateable
  include Resourceable

  has_many :chapter_audio_files, class_name: 'Audio::ChapterAudioFile', foreign_key: :audio_recitation_id
  has_many :related, class_name: 'Audio::RelatedRecitation', foreign_key: :audio_recitation_id
  has_many :related_recitations, class_name: 'Audio::Recitation', through: :related, source: :related_audio_recitation
  belongs_to :section, class_name: 'Audio::Section'
  belongs_to :recitation_style, optional: true

  scope :approved, -> { where(approved: true) }
end
