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

class V3::VerseSerializer < V3::ApplicationSerializer
  attributes :id, :verse_number, :verse_key, :text_madani, :text_indopak, :text_simple, :juz_num, :hizb_num, :rub_num, :sajdah, :page_number
  has_one :chapter
end