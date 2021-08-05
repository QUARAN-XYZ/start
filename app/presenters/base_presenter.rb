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

  protected

  def eager_load_translated_name(records)
    language = Language.find_by(iso_code: fetch_locale)

    defaults = records.where(
      translated_names: { language_id: Language.default.id }
    )

    records
      .where(
        translated_names: { language_id: language }
      ).or(defaults).order('translated_names.language_priority DESC')
  end

  def fetch_locale
    params[:language].presence || params[:locale].presence || 'en'
  end
end
