class DummyToolWithDaemon < Formula
  desc "DummyToolWithDaemon CLI Tool"
  homepage "https://github.com/preternatural-throwaway/homebrew-demo"
  url "https://github.com/preternatural-throwaway/homebrew-demo/releases/download/dummy-tool-with-daemon-0.0.1/final-artifact.zip"
  sha256 "ca49e43fdf88960729fc6dbbafaa9c9d2b957e43c046095c3b072ae54a0c9456"
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

  def post_install
    # Skip service start in CI / non-interactive environments
    if ENV["CI"] || !$stdin.tty?
      ohai "Skipping dummy-tool-with-daemon daemon service startup in non-interactive environment"
      ohai "To start the service manually: sudo brew services start dummy-tool-with-daemon"
      return
    end

    ohai "Starting the dummy-tool-with-daemon daemon service..."
    ohai "Installation of the daemon requires sudo access. Please enter your password in the system popup."

    # Use AppleScript to prompt for admin rights safely
    script = <<~APPLESCRIPT
      do shell script "brew services start dummy-tool-with-daemon" with administrator privileges
    APPLESCRIPT
    
    system "osascript", "-e", script
    
    unless $?.success?
      opoo "Failed to start the dummy-tool-with-daemon daemon service."
      ohai "You can manually start it later with: sudo brew services start dummy-tool-with-daemon"
    else
      ohai "dummy-tool-with-daemon daemon service started successfully!"
      ohai "You can stop the daemon using `sudo brew services stop dummy-tool-with-daemon`"
      ohai "You can restart the daemon using `sudo brew services restart dummy-tool-with-daemon`"
    end
  end

  service do
    run [opt_bin/"simple-dummy-tool-d"]
    run_type :immediate
    keep_alive true
    run_at_load true
    require_root true
    log_path var/"log/simple-dummy-tool-d.log"
    error_log_path var/"log/simple-dummy-tool-d.err.log"
  end
end