namespace :db do
  desc 'Dump the database'
  task pg_dump: :environment do
    previous_version = Dir['db/dumps/**'].map{ |dir| dir.split('/').last }.sort_by{|version| version.to_i}.last.to_i
    sh "mkdir db/dumps/#{previous_version + 1}"
    sh "pg_dump quran_dev -U quran_dev > db/dumps/#{current_date}/quran_dev.psql"
    sh "bzip2 db/dumps/#{current_date}/quran_dev.psql"
  end

  task all_dump: :environment do
    current_date = Time.now.strftime('%F_%T')
    sh "env dir=/dumps/#{current_date} rake db:data:dump_dir"
    sh "rm -rf db/base"
    sh "cp -R db/dumps/#{current_date} db/base"
    sh "pg_dump quran_dev -U quran_dev > db/dumps/#{current_date}/quran_dev.psql"
    sh "bzip2 db/dumps/#{current_date}/quran_dev.psql"
  end

  task load_pg_dump: :environment do
    dir_name = Dir['db/dumps/**'].sort_by{|version| version.to_i}.last
    sh "bunzip2 #{dir_name}/quran_dev.psql.bz2"
    sh "psql -U quran_dev quran_dev < #{dir_name}/quran_dev.psql"
    sh "bzip2 #{dir_name}/quran_dev.psql"
  end
end
