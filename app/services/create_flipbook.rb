require 'zip'
require 'fileutils'

class CreateFlipbook
  attr_accessor :zip_path

  def initialize(uploaded_file)
    @uploaded_file = uploaded_file
  end

  def run
    create_folder
    save_file
    extract_frames
    merge_frames
    create_zip
    self
  end

  private

  def create_folder(modifier = '')
    self.folder_path = Rails.root.join(
      'public',
      'uploads',
      "#{uploaded_file.original_filename}#{modifier}"
    )
    Dir.mkdir(folder_path)
  rescue Errno::EEXIST
    create_folder(SecureRandom.hex(2))
  end

  def save_file
    self.local_file_path = folder_path.join(uploaded_file.original_filename)
    File.open(local_file_path, 'wb') do |file|
      file.write(uploaded_file.read)
    end
  end

  def extract_frames
    Open3.capture3("convert #{convert_options}")
    files_to_delete = Dir.glob(folder_path.join('**', 'extracted-*.png')).select do |f|
      match = f.match(/(\d+).png$/)
      match && match[1].to_i.odd?
    end
    FileUtils.rm files_to_delete
  end

  def merge_frames
    count_files = (Dir[File.join(folder_path, '**', '*')].count { |file| File.file?(file) } - 1) * 2
    frames_array(count_files).each_with_index do |frames, i|
      Open3.capture3("montage #{montage_options(frames, i)}")
    end
  end

  def create_zip
    self.zip_path = folder_path.join('giftoflip.zip')
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      Dir.glob(folder_path.join('**', 'fullframe*')).sort.each_with_index do |filename, i|
        zipfile.add("#{i}.png", File.join(filename))
      end
    end
  end

  def frames_array(count)
    (0...count).step(2).to_a.each_slice(8).to_a
  end

  def convert_options
    [
      local_file_path, '-resize 400x200\!', '-background Green',
      '-gravity West', '-splice 50x0', '-annotate 0x0 "%p/%n"',
      folder_path.join('extracted.png')
    ].join(' ')
  end

  def montage_options(frames, index)
    [
      '-background White', '-geometry 1000', '-tile 2x4',
      frames.map { |f| folder_path.join("extracted-#{f}.png") }.join(' '),
      folder_path.join("fullframe-#{index}.png")
    ].join(' ')
  end

  attr_accessor :uploaded_file, :folder_path, :local_file_path
end
