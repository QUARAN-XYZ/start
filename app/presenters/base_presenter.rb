# frozen_string_literal: true

class BasePresenter
  include QuranUtils::StrongMemoize

  attr_reader :params

  def initialize(params)
    @params = params
  end

  delegate :next_page,
           :current_page,
           :per_page, :total_records, :total_pages, to: :finder

  def sanitize_query_fields(fields)
    fields.compact_blank.map do |field|
      field.underscore.strip
    end
  end

  def get_mushaf_id
    strong_memoize :mushaf do
      mushaf = Mushaf.find_by(id: params[:mushaf].to_s.strip) || Mushaf.default
      mushaf.id
    end
  end

  protected
  def include_in_response?(value)
    if value.presence
      !ActiveRecord::Type::Boolean::FALSE_VALUES.include?(value)
    end
  end

  def eager_load_translated_name(records)
    language = Language.find_by(iso_code: fetch_locale)

    defaults = records.where(
      translated_names: { language_id: Language.default.id }
    )

    if language
      records
        .where(
          translated_names: { language_id: language }
        ).or(defaults).order('translated_names.language_priority DESC')
    else
      defaults
    end
  end

  def fetch_locale
    strong_memoize :locale do
      params[:language].presence || params[:locale].presence || 'en'
    end
  end
end
