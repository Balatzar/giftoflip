class UploadController < ApplicationController
  def landing; end

  def create_flip
    send_file(
      CreateFlipbook.new(params[:moving_file]).run.zip_path,
      filename: "yourflipbook.zip",
      type: "application/zip"
    )
  end
end
