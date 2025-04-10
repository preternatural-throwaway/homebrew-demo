class DummyToolWithDaemonRestart < Formula
  desc "DummyToolWithDaemonRestart CLI Tool"
  homepage "https://github.com/preternatural-throwaway/homebrew-demo"
  url "https://github.com/preternatural-throwaway/homebrew-demo/releases/download/dummy-tool-with-daemon-restart-0.0.3/final-artifact.zip"
  sha256 "8ef0d79189878fab61478671464e297d1c725703cfbef5dbf2a6d0c00116c6b3"
  version "0.0.3"

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
      ohai "Skipping dummy-tool-with-daemon-restart daemon service startup in non-interactive environment"
      ohai "To start the service manually: sudo brew services start dummy-tool-with-daemon-restart"
      return
    end

    ohai "Checking if restart-dummy-tool-d is already running as root..."

    # Check if restart-dummy-tool-d is running as root
    running_as_root = `ps aux | grep restart-dummy-tool-d | grep -v grep | grep root`.strip.length > 0

    if running_as_root
      ohai "restart-dummy-tool-d is already running as root, restarting with bootstrap restart..."
      system "dummy-tool-with-daemon-restart bootstrap restart"
      ohai "dummy-tool-with-daemon-restart daemon restarted successfully!"
    else
      ohai "Starting the dummy-tool-with-daemon-restart daemon service..."
      ohai "Installation of the daemon requires sudo access. Please enter your password in the system popup."

      # Use AppleScript to prompt for admin rights safely
      script = <<~APPLESCRIPT
        do shell script "brew services start dummy-tool-with-daemon-restart" with administrator privileges
      APPLESCRIPT

      system "osascript", "-e", script

      unless $?.success?
        opoo "Failed to start the dummy-tool-with-daemon-restart daemon service."
        ohai "You can manually start it later with: sudo brew services start dummy-tool-with-daemon-restart"
      else
        ohai "dummy-tool-with-daemon-restart daemon service started successfully!"
        ohai "You can stop the daemon using `sudo brew services stop dummy-tool-with-daemon-restart`"
        ohai "You can restart the daemon using `sudo brew services restart dummy-tool-with-daemon-restart`"
      end
    end
  end

  service do
    run [opt_bin/"restart-dummy-tool-d"]
    run_type :immediate
    keep_alive true
    run_at_load true
    require_root true
    log_path var/"log/restart-dummy-tool-d.log"
    error_log_path var/"log/restart-dummy-tool-d.err.log"
  end
end