if RUBY_PLATFORM =~ /linux/
  # Load JAVA env variables
  begin
    ENV['JAVA_HOME'] ||= `readlink -f /usr/bin/java | sed "s:/jre/bin/java::"`.strip
    architecture = `dpkg --print-architecture`.strip
    ENV['LD_LIBRARY_PATH'] = "#{ENV['LD_LIBRARY_PATH']}:#{ENV['JAVA_HOME']}/jre/lib/#{architecture}:#{ENV['JAVA_HOME']}/jre/lib/#{architecture}/client"
  rescue
    STDERR.puts "JAVA_HOME has not been set automatically because it's not Debian here."
  end
end

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

if ENV['RAILS_ENV'] != 'production'
  require 'dotenv'

  Dotenv.load(Pathname.new(__dir__).join('..', '.env'))
end
