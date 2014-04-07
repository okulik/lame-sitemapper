require_relative 'cli'

SiteMapper::Cli.new($stdout, ARGV, File.basename(__FILE__)).run
