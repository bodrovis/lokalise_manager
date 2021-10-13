# frozen_string_literal: true

module SpecAddons
  def allow_project_id(obj, value = '189934715f57a162257d74.88352370')
    allow(obj.config).to receive(:project_id).and_return(value)
    return unless block_given?

    yield
    expect(obj.config).to have_received(:project_id)
  end

  def expect_file_exist(path, file)
    file_path = File.join path, file
    expect(File.file?(file_path)).to be true
  end
end
