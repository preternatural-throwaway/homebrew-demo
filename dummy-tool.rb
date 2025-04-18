class DummyTool < Formula
  desc "DummyTool CLI Tool"
  homepage "https://github.com/preternatural-throwaway/homebrew-demo"
  url "https://github.com/preternatural-throwaway/homebrew-demo/releases/download/dummy-tool-0.0.1/final-artifact.zip"
  sha256 "01a8b126fba1f60f79e237d13fbc23b9b04c14d58c73f5b9d7a1cee0d6d009e7"
  version "0.0.1"

  def install
    # Unzip the main artifact bundle
    system "unzip", "-o", cached_download

    # Install executables and daemons
    [
      ["*-executable.zip", "-executable.zip"],
      ["*-daemon.zip", "-daemon.zip"]
    ].each do |glob_pattern, suffix|
      Dir.glob(glob_pattern).each do |zip_name|
        # Unzip the inner zip file directly
        system "unzip", "-o", zip_name
        
        # Extract tool name from the zip filename
        tool_name = File.basename(zip_name, suffix)

        # Install the binary
        binary_path = "#{tool_name}.artifactbundle/#{tool_name}/bin/#{tool_name}"
        bin.install binary_path if File.exist?(binary_path)
      end
    end
  end
end