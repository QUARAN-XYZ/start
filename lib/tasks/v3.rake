namespace :v3 do
  task remove_v2_tables: :environment do
    ['file', 'recitation', 'reciter', 'style', 'author', 'resource', 'resource_api_version', 'source', 'surah_infos', 'tafsir',
     'tafsir_ayah', 'translation', 'transliteration', 'language', 'media.content', 'media.resource',
     'ayah', 'char_type', 'surah', 'text', 'text_font', 'word_font', 'word_transliteration', 'word_translation',
   ].each { |table| ActiveRecord::Migration.drop_table(table) }
  end

  task import_from_v2: :environment do
    #Migrate languages
    Locale::Language.find_each do |l|
      language = Language.find_or_initialize_by(name: l.english.to_s.strip)

      language.iso_code = l.language_code.to_s.strip
      language.native_name = l.unicode.to_s.strip
      language.direction = l.direction.to_s.strip
      language.es_analyzer_default = l.es_analyzer_default.to_s.strip
      language.save
    end

    language = Language.find_by_iso_code('en')
    arabic_lang = Language.find_by_iso_code('ar')

    #Migrate resource, authors
    Content::Author.find_each do |a|
      Author.where(name: a.name, url: a.url).first_or_create
    end

    data_source = DataSource.where(name: 'King Fahd Quran Printing Complex',  url: 'http://www.qurancomplex.org/').first_or_create
    r = Quran::WordFont.first.resource
    ResourceContent.where(name: r.name, data_source: data_source, language: language).first_or_create(cardinality_type: r.cardinality_type, resource_type: r.type, sub_type: r.sub_type, description: r.description)

    Content::Resource.find_each do |content|
      author = Author.where(name: content.author.name, url: content.author.url).first_or_create if content.author
      resource_content = ResourceContent.where(author: author, resource_type: content.type, sub_type: content.sub_type, name: content.name, cardinality_type: content.cardinality_type).first_or_create
      resource_content.description = content.description
      resource_content.language = Language.find_by_iso_code(content.language_code)
      resource_content.author_name = author.name
      if content.source
        data_source = DataSource.where(name: content.source.name,  url: content.source.url).first_or_create
        resource_content.data_source = data_source
      end
      resource_content.save
    end

    #Migrate chapters
    Quran::Surah.order('surah_id asc').each do |surah|
      chapter = Chapter.find_or_initialize_by(chapter_number: surah.id)

      chapter.bismillah_pre = surah.bismillah_pre
      chapter.revelation_place = surah.revelation_place
      chapter.revelation_order = surah.revelation_order
      chapter.pages = surah.page
      chapter.name_complex = surah.name_complex
      chapter.name_arabic = surah.name_arabic
      chapter.name_simple = surah.name_simple

      chapter.save

      puts "chapter #{chapter.id}"

      chapter.translated_names.where(language: Language.find_by_iso_code('en')).first_or_create.update_attributes name: surah.name_english
    end

    #CharType
    Quran::CharType.find_each do |char|
      char_type = CharType.where(name: char.name).first_or_create

      if char.parent
        char_type.parent = CharType.where(name: char.parent.name).first_or_create
      end

      char_type.description = char.description
      char_type.save
    end

    #Chapter info
    source = DataSource.where(name: "Tafhim al-Qur'an", url: "http://www.tafheem.net/").first_or_create
    author = Author.where(name: "Sayyid Abul Ala Maududi").first_or_create
    resource_content =  ResourceContent.where(name: "Chapter Info", author: author, language: language).first_or_create(author_name: author.name, cardinality_type: ResourceContent::CardinalityType::OneChapter, resource_type: ResourceContent::ResourceType::Content, sub_type: 'Chapter info')
    resource_content.data_source = source
    resource_content.description = "Sayyid Abul Ala Maududi - Tafhim al-Qur'an - The Meaning of the Quran"
    resource_content.save

    Content::SurahInfo.find_each do |info|
      chapter_info = ChapterInfo.where(language: language, chapter_id: info.surah_id).first_or_create
      chapter_info.short_text = info.short_description
      chapter_info.text = info.description
      chapter_info.source = info.content_source
      chapter_info.resource_content = resource_content
      chapter_info.language_name = language.name.downcase

      puts "verse info #{chapter_info.id}"

      chapter_info.save
    end

    sajdah_number = 1
    #Migrate verses
    Quran::Ayah.order("surah_id asc, ayah_num asc").each do |ayah|
      verse = Verse.find_or_initialize_by(verse_key: ayah.ayah_key)

      verse.chapter_id = ayah.surah_id
      verse.page_number = ayah.page_num
      verse.juz_number = ayah.juz_num
      verse.hizb_number = ayah.hizb_num
      verse.rub_number = ayah.rub_num
      verse.sajdah = ayah.sajdah
      if ayah.sajdah.present?
        verse.sajdah_number = sajdah_number
        sajdah_number += 1
      end
      verse.verse_number = ayah.ayah_num
      verse.verse_index = ayah.ayah_index
      verse.text_simple = ayah.text
      verse.text_madani = Quran::Text.find_by_ayah_key(ayah.ayah_key).text
      verse.text_root = ayah.text_root.text
      verse.text_stem = ayah.text_stem.text
      verse.text_token = ayah.text_token.text
      verse.text_lemma = ayah.text_lemma.text
      verse.image_url = ayah.images.first.url

      verse.save
      puts "verse #{verse.id}"
    end

    source = DataSource.where(name: 'Quran.com').first
    word_trans_resource = ResourceContent.where(data_source: source, language: language, cardinality_type: ResourceContent::CardinalityType::OneWord, resource_type: 'content', sub_type: 'translation').first_or_create()
    word_transliteration_resource = ResourceContent.where(data_source: source, language: language, cardinality_type: ResourceContent::CardinalityType::OneWord, resource_type: 'content', sub_type: 'transliteration').first_or_create()

    Verse.order('verse_number asc').each do |verse|
      Quran::WordFont.where(ayah_key: verse.verse_key).order('position asc').each do |word_font|
        word = Word.where(verse_id: verse.id, position: word_font.position).first_or_initialize
        char_type = CharType.where(name: word_font.char_type.name).first_or_create

        word.page_number = word_font.page_num
        word.line_number = word_font.line_num
        word.code_dec = word_font.code_dec
        word.code_hex = word_font.code_hex
        word.char_type_id = char_type.id
        word.verse_key = verse.verse_key

        word.text_stem = word_font.word.stems.first.value
        word.text_lemma = word_font.word.lemmas.first.value
        word.text_root = word_font.word.roots.first.value
        word.text_token = word_font.word.token.value
        corpus = word_font.word.corpus

        word.corpus = {
          description: corpus.description,
          image_src: corpus.image_src,
          segment: corpus.segment
        }

        word.save
        puts "word #{word.id}"

        if word_font.word
          if token = word_font.word.token
            word.text_madani =token.value
            word.text_simple =token.clean
          end

          word.translations.where(language: language, resource_content: word_trans_resource).first_or_create(text: word_font.word.translation, language_name: language.name.downcase)
          word.transliterations.where(language: language, resource_content: word_transliteration_resource).first_or_create(text: word_font.word.transliteration, language_name: language.name.downcase)
        end

        word.save
      end
    end

    #Tafsir
    Content::TafsirAyah.includes(:tafsir).order('').each do |tafsir|
      resource = tafsir.tafsir.resource
      language = Language.find_by_iso_code(resource.language_code)
      verse = Verse.find_by_verse_key(tafsir.ayah_key)
      data_source = DataSource.where(name: resource.source.name, url: resource.source.url).first_or_create if resource.source

      resource_content = ResourceContent.where(resource_type: resource.type, sub_type: resource.sub_type, author_name: resource.author.name, cardinality_type: resource.cardinality_type, language: language).first_or_create
      resource_content.data_source = data_source
      resource_content.save
      taf = verse.tafsirs.where(language: language, resource_content: resource_content).first_or_create(text: tafsir.tafsir.text )
      puts "ayah tafsir #{taf.id}"
    end

    #verse Translations
    Content::Translation.order('').each do |trans|
      resource = trans.resource
      language = Language.find_by_iso_code(resource.language_code)
      verse = Verse.find_by_verse_key(trans.ayah_key)

      resource_content = ResourceContent.where(resource_type: resource.type, sub_type: resource.sub_type, author_name: resource.author.name, cardinality_type: resource.cardinality_type, language: language).first_or_create
      translation = verse.translations.where(language: language, resource_content: resource_content).first_or_create(text: trans.text, language_name: language.name.downcase )

      puts "ayah translation #{translation.id}"
    end

    #verse Transliteration
    Content::Transliteration.order('').each do |trans|
      resource = trans.resource
      language = Language.find_by_iso_code(resource.language_code) || language
      verse = Verse.find_by_verse_key(trans.ayah_key)

      resource_content = ResourceContent.where(resource_type: resource.type, sub_type: resource.sub_type, author_name: resource.author.name, cardinality_type: resource.cardinality_type, language: language).first_or_create
      transliteration = verse.transliterations.where(language: language, resource_content: resource_content).first_or_create(text: trans.text )

      puts "ayah transliterations #{transliteration.id}"
    end

    ## HEre


    # create author and resource content for Bayyinah
    media_resource = Media::Resource.first

    author = Author.where(name: media_resource.name,  url: media_resource.url).first_or_create
    resource_content = ResourceContent.where(author: author, language: language, resource_type: 'media', sub_type: 'video').first_or_create(author_name: author.name, cardinality_type: ResourceContent::CardinalityType::OneVerse, approved: true)
    #Migrate media content
    Media::Content.all.each do |media|
      verse = Verse.find_by_verse_key(media.ayah_key)
      verse.media_contents.where(url: media.url, resource_content_id: resource_content.id).first_or_create
    end

    #Migrate audio files
    Audio::Style.find_each do |style|
      s = RecitationStyle.where(style: style.english).first_or_create
      s.translated_names.where(language: arabic_lang).first_or_create(name: style.arabic)
      s.translated_names.where(language: language).first_or_create(name: style.english)
    end

    Audio::Reciter.find_each do |r|
      reciter = Reciter.where(name: r.english).first_or_create
      reciter.translated_names.where(language: arabic_lang).first_or_create(name: r.arabic)
      reciter.translated_names.where(language: language).first_or_create(name: r.english)
    end

    Audio::Recitation.find_each do |r|
      resource_content = ResourceContent.where(language: arabic_lang, author_name: r.reciter.english, sub_type: 'audio', resource_type: 'media').first_or_create(cardinality_type: ResourceContent::CardinalityType::OneVerse)
      style = RecitationStyle.find_by_style(r.style.english) if r.style
      Recitation.where(resource_content: resource_content, reciter:  Reciter.find_by_name(r.reciter.english), recitation_style: style).first_or_create

      resource_content.approved = Audio::File.where(recitation_id: r.id, is_enabled: false).blank?
      resource_content.save
    end

    Audio::File.find_each do |file|
      reciter = Reciter.find_by_name(file.reciter.english)
      recitation_style = RecitationStyle.find_by_style(file.recitation.style.english) if file.recitation.style
      recitation = Recitation.where(reciter: reciter, recitation_style: recitation_style).first
      verse = Verse.find_by_verse_key(file.ayah_key)

      audio = AudioFile.where(resource: verse, recitation: recitation).first_or_create
      audio.segments = file.segments
      audio.url = file.url
      audio.duration = file.duration
      audio.mime_type = file.mime_type
      audio.format = file.format
      audio.save

      puts "audio #{audio.id}"
    end

    #last few steps to fix missing attributes
    MediaContent.find_each do |m|
      m.language = language
      m.language_name = language.name
      m.author_name = m.resource_content.author_name
      m.save
    end

    ResourceContent.find_each do |m|
      m.language_name = m.language.name.downcase
      m.save
    end

    TranslatedName.find_each do |t|
      t.language_name = t.language.name.downcase
      t.save
    end

    Recitation.find_each do |r|
      r.reciter_name = r.reciter.name
      r.style = r.recitation_style.style
      r.save
    end
  end
end

# Update content resource for image rename table to image
