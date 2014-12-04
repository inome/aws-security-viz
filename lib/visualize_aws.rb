require 'trollop'
require_relative 'ec2/security_groups'
require_relative 'provider/json'
require_relative 'provider/ec2'
require_relative 'graph'

class VisualizeAws
  def initialize(options={})
    provider = options[:source_file].nil? ? Ec2Provider.new(options) : JsonProvider.new(options)
    @security_groups = SecurityGroups.new(provider)
  end

  def unleash(output_file)
    g = build
    render(g, output_file)
  end

  def build
    g = Graph.new
    @security_groups.each { |group|
      g.add_node(group.name)
      group.traffic.each { |traffic|
        if traffic.ingress
#          if ["pingdom1", "pingdom2", "insights-lb1-usonly-group1", "insights-lb1-usonly-group2"].include(traffic.to)

          log("In To: " + traffic.to)
          log("In From: " + traffic.from)
          g.add_edge(traffic.from, traffic.to, :color => 'blue', :style => 'bold', :label => traffic.port_range) unless
             ["pingdom1", "pingdom2", "insights-lb1-usonly-group1", "insights-lb1-usonly-group2", "insights-lb1-usonly-group3"].include?(traffic.to)
        else
          log("Out To: " + traffic.to)
          log("Out From: " + traffic.from)
          g.add_edge(traffic.to, traffic.from, :color => 'red', :style => 'bold', :label => traffic.port_range)
        end
      }
    }
    g
  end

  def log(msg)
    puts msg if ENV["DEBUG"]
  end

  def render(g, output_file)
    extension = File.extname(output_file)
    g.output(extension[1..-1].to_sym => output_file, :use => 'circo', :scale => 40, :reduce => true)
    #g.output(extension[1..-1].to_sym => output_file, :use => 'dot', :scale => 40, :reduce => true)
  end
end

if __FILE__ == $0
  opts = Trollop::options do
    opt :access_key, 'AWS access key', :type => :string
    opt :secret_key, 'AWS secret key', :type => :string
    opt :region, 'AWS region to query', :default => 'us-east-1', :type => :string
    opt :source_file, 'JSON source file containing security groups', :type => :string
    opt :filename, 'Output file name', :type => :string, :default => 'aws-security-viz.png'
  end
  if opts[:source_file].nil?
    Trollop::die :access_key, 'is required' if opts[:access_key].nil?
    Trollop::die :secret_key, 'is required' if opts[:secret_key].nil?
  end

  VisualizeAws.new(opts).unleash(opts[:filename])
end
