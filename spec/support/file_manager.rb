# frozen_string_literal: true

require 'fileutils'

module FileManager
  def mkdir_locales
    return if File.directory?(LokaliseManager::GlobalConfig.locales_path)

    FileUtils.mkdir_p(LokaliseManager::GlobalConfig.locales_path)
  end

  def rm_translation_files
    FileUtils.rm_rf locales_dir
  end

  def locales_dir
    Dir["#{LokaliseManager::GlobalConfig.locales_path}/**/*"]
  end

  def count_translations
    locales_dir.count { |file| File.file?(file) }
  end

  def add_translation_files!(with_ru: false, additional: nil)
    FileUtils.mkdir_p "#{Dir.getwd}/locales/nested"
    open_and_write('locales/nested/en.yml') { |f| f.write en_data }

    return unless with_ru

    open_and_write('locales/ru.yml') { |f| f.write ru_data }

    return unless additional

    additional.times do |i|
      data = { 'en' => { "key_#{i}" => "value #{i}" } }

      open_and_write("locales/en_#{i}.yml") { |f| f.write data.to_yaml }
    end
  end

  def open_and_write(rel_path, &block)
    return unless block

    File.open("#{Dir.getwd}/#{rel_path}", 'w:UTF-8', &block)
  end

  private

  def en_data
    <<~DATA
      en:
        my_key: "My value"
        nested:
          key: "Value 2"
    DATA
  end

  def ru_data
    <<~DATA
      ru_RU:
        my_key: "Моё значение"
        nested:
          key: "Значение 2"
    DATA
  end
end
