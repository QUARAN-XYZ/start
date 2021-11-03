# frozen_string_literal: true

class VerseFinder
  attr_reader :params, :results
  include QuranUtils::StrongMemoize

  def initialize(params)
    @params = params
  end

  def find(verse_number, language_code = 'en')
    load_verses(language_code).find_by(verse_number: verse_number) || raise_not_found("Ayah not found")
  end

  def load_verses(language_code)
    fetch_verses_range
    load_translations
    load_words(language_code)
    load_audio
    translations_order = valid_translations.present? ? ',translations.priority ASC' : ''

    @results.order("verses.verse_index ASC, words.position ASC, word_translations.priority ASC #{translations_order}".strip)
  end

  def per_page
    limit = (params[:limit] || 10).to_i.abs
    limit = 10 if limit.zero?

    limit <= 50 ? limit : 50
  end

  def next_page
    if last_page?
      return nil
    end

    current_page + 1
  end

  def prev_page
    current_page - 1 unless first_page?
  end

  def first_page?
    current_page == 1
  end

  def last_page?
    current_page == total_pages
  end

  def current_page
    @current_page ||= (params[:page].to_i <= 1 ? 1 : params[:page].to_i)
  end

  def total_pages
    (total_verses / per_page.to_f).ceil
  end

  def total_verses
    chapter.verses_count
  end

  protected

  def fetch_verses_range
    verse_start = verse_pagination_start
    verse_end = verse_pagination_end(verse_start)

    @results = Verse
                 .where(chapter_id: chapter.id)
                 .where('verses.verse_number >= ? AND verses.verse_number <= ?', verse_start.to_i, verse_end.to_i)
  end

  def load_words(word_translation_lang)
    language = Language.find_with_id_or_iso_code(word_translation_lang)

    words_with_default_translation = results.where(word_translations: { language_id: Language.default.id })

    if language
      @results = @results
                   .where(word_translations: { language_id: language.id })
                   .or(words_with_default_translation)
                   .eager_load(words: eager_load_words)
    else
      @results = words_with_default_translation
                   .eager_load(words: eager_load_words)
    end
  end

  def load_translations
    translations = valid_translations

    if translations.present?
      @results = @results
                   .where(translations: { resource_content_id: translations })
                   .eager_load(:translations)
    end
  end

  def load_audio
    if params[:recitation].present?
      @results = @results
                   .where(audio_files: { recitation_id: params[:recitation] })
                   .eager_load(:audio_file)
    end
  end

  def set_offset
    if offset.present?
      @results = @results.offset(offset)
    end
  end

  def valid_translations
    strong_memoize :translations do
      # user can get translation using ids or Slug
      translation = params[:translations].to_s.split(',')

      return [] if translation.blank?

      approved_translations = ResourceContent
                                .approved
                                .translations
                                .one_verse

      params[:translations] = approved_translations
                                .where(id: translation)
                                .or(approved_translations.where(slug: translation))
                                .pluck(:id)
    end
  end

  def offset
    params[:offset] ? params[:offset].to_i.abs : nil
  end

  def eager_load_words
    :word_translation
  end

  def verse_pagination_start
    if offset
      min(offset + 1, total_verses)
    else
      start = 1 + (current_page - 1) * per_page
      min(start, total_verses)
    end
  end

  def verse_pagination_end(start)
    if params[:id]
      # for show page, skip the pagination
      min(params[:id].to_i, chapter.verses_count)
    else
      min((start + per_page) - 1, chapter.verses_count)
    end
  end

  def chapter
    return @chapter if @chapter

    if @chapter = Chapter.find_using_slug(params[:chapter_id])
      params[:chapter_id] = @chapter.id
    else
      raise_not_found("Surah not found")
    end

    @chapter
  end

  def min(a, b)
    a < b ? a : b
  end

  def max(a, b)
    a > b ? a : b
  end

  def raise_not_found(message)
    raise RestApi::RecordNotFound.new(message)
  end
end
