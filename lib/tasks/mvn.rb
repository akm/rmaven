# -*- coding: utf-8 -*-
require "fileutils"
require "yaml"
require File.join(File.dirname(__FILE__), "..", "maven")

def build_args_hash
  args = ARGV.dup
  args.shift
  args.inject({}) do |dest, arg|
    key, value = *arg.split("=", 2)
    dest[key] = value
    dest
  end
end

def show_file(*paths)
  open(File.join(File.dirname(__FILE__), '..', *paths)) do |f|
    puts f.read
  end
end


ARGV_HASH = build_args_hash
ARGV_KEY_IGNORED = ARGV_HASH.map{|key, value| value || key}

RAKEABLE_SETTING_YAML = 'rakeable.yml'

desc "show help about mvn task"
task :mvn do
  show_file('USAGE.txt')
end

namespace :mvn do
  desc "show usage"
  task :usage do
    show_file('USAGE.txt')
  end
  
  desc "generate example setting yaml for rakeable"
  task :generate_yaml do
    File.open(RAKEABLE_SETTING_YAML, 'w') do |f|
      YAML.dump(
        {'sub_project_name' => 
          {
            'pom_dir' => 'proj1', 
            'rake_prefix' => 'proj1', 
            'group_id' => 'your.organization.id',
            'artifact_id' => 'proj1'
          } 
        }, f)
    end
  end
end


poms = nil
if File.exist?('rakeable.yml')
  open('rakeable.yml') do |f|
    poms = YAML.load(f)
  end
end

if File.exist?('pom.xml')
  poms['java'] = {'pom' => 'pom.xml'}
end

(poms || {}).each do |project_name, settings|
  filename = settings['pom']
  filename ||= File.join(*(project_name.split('/') + ['pom.xml']))
  unless File.exist?(filename)
    project = Maven::Project.new(project_name, settings)
    namespace project.rake_prefix do
      desc "create mavenized java project in directory '#{project.pom_dir}'"
      task :create do
        project.execute_without_cd("archetype:create", project.archetype_create_args)
        FileUtils.mv(project.artifact_id, project.pom_dir, :verbose => project.verbose)
        open(project.plugin_setting_path, "w") do |f|
          YAML.dump(Maven::PLUGINS, f)
        end
      end
    end
    next
  end

  project = Maven.create_project(filename, settings)
  
  namespace project.rake_prefix do
    Maven::LIFECYCLES.each do |lifecycle|
      binding = lifecycle[:binding]
      binding = ". [binding] #{binding}" if binding
      desc "#{lifecycle[:desc]}#{binding}" unless lifecycle[:hidden]
      task lifecycle[:name].to_sym do
        project.execute(lifecycle[:name])
      end
    end
    
    desc "list mvn plugins. USAGE: rake mvn:plugins [any_key=<plugin_name>]"
    task :plugin do
      plugins = project.select_plugins(*ARGV_KEY_IGNORED)
      if plugins.empty?
        puts "No mvn plugin matched. "
      elsif plugins.length == 1
        plugin = plugins.first
        project.execute("help:describe", ["plugin=#{plugin}"])
        puts "you can get details more:"
        puts "  rake mvn:plugin:goal plugin=#{plugin}"
        puts "or"
        puts "  rake mvn:plugin:params plugin=#{plugin}"
      else
        puts "#{ARGV_KEY_IGNORED.empty? ? 'known' : 'matched'} plugins are:"
        puts plugins.join(" ")
      end
    end

    namespace :plugin do
      desc "execute mvn plugin. USAGE: rake mvn:plugins:execute plugin=<plugin_name> goal=<goal_name>"
      task :execute do
        hash = ARGV_HASH
        plugin = hash.delete("plugin")
        goal = hash.delete("goal")
        project.execute("#{plugin}:#{goal}", hash.map{|key, value| "#{key}=#{value}"})
      end

      desc "search remote plugin and show the help . USAGE: rake mvn:plugins:detect plugin=<plugin_name> [goal=<goal_name>]"
      task :detect do
        project.execute("help:describe", ARGV_HASH.map{|key, value| "#{key}=#{value}"})
      end

      desc "show mvn plugins medium help. USAGE: rake mvn:plugins:goals plugin=<plugin_name>"
      task :goals do
        plugins = project.select_plugins(*ARGV_KEY_IGNORED)
        if plugins.empty?
          puts "No mvn plugin found. if you know the exact name, rake mvn:plugins:detect plugin=<plugin_name>. or check your #{project.plugin_setting_path}"
        else
          plugins.each do |plugin|
            project.execute("help:describe", ["plugin=#{plugin}", "medium=true"])
            puts "- " * 20
          end
          puts "you can get details more:"
          puts "  rake mvn:plugin:params plugin=<plugin_name> goal=<goal_name>"
        end
      end

      desc "show mvn plugins full help. USAGE: rake mvn:plugins:goals plugin=<plugin_name>"
      task :params do
        plugins = project.select_plugins(*ARGV_KEY_IGNORED)
        if plugins.empty?
          puts "No mvn plugin found. if you know the exact name, rake mvn:plugins:detect plugin=<plugin_name>. or check your #{project.plugin_setting_path}"
        else
          plugins.each do |plugin|
            project.execute("help:describe", ["plugin=#{plugin}", "full=true"])
            puts "- " * 20
          end
        end
      end
    
    end
    
  end
end
