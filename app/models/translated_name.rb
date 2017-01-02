# == Schema Information
#
# Table name: translated_names
#
#  id            :integer          not null, primary key
#  resource_type :string
#  resource_id   :integer
#  language_id   :integer
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class TranslatedName < ApplicationRecord
  belongs_to :language
  belongs_to :resource, polymorphic: true
end