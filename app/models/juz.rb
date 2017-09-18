# == Schema Information
#
# Table name: juzs
#
#  id            :integer          not null, primary key
#  juz_number    :integer
#  name_simple   :string
#  name_arabic   :string
#  verse_mapping :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Juz < ApplicationRecord
  validates :juz_number, uniqueness: true

  has_many :verses, foreign_key: :juz_number
  has_many :chapters, through: :verses

  serialize :verse_mapping, Hash
end
