require 'hirb'
require 'ansi/code'

class SimpleCov::Formatter::Console

  VERSION = File.new(File.join(File.expand_path(File.dirname(__FILE__)), "../VERSION")).read.strip

  ATTRIBUTES = [:table_options]
  class << self
    attr_accessor(*ATTRIBUTES)
  end

  def format(result)

    root = nil
    if Module.const_defined? :ROOT then
      root = ROOT
    elsif Module.const_defined?(:Rails) && Rails.respond_to?(:root) then
      root = Rails.root.to_s
    elsif ENV["BUNDLE_GEMFILE"] then
      root = File.dirname(ENV["BUNDLE_GEMFILE"])
    else
      root = Dir.pwd
    end

    puts
    print "COVERAGE: #{colorize(pct(result.covered_percent))} -- #{result.covered_lines}/#{result.total_lines} lines in #{result.files.size} files"

    if root.nil? then
      return
    end

    files = result.files.sort{ |a,b| a.covered_percent <=> b.covered_percent }

    covered_files = 0
    files.select!{ |file|
      if file.covered_percent == 100 then
        covered_files += 1
        false
      else
        true
      end
    }

    if files.nil? or files.empty? then
      return
    end

    hints = []
    if files.size > 0 then
      hints << ANSI.red { "#{files.size} file(s) with #{pct(files.map(&:covered_percent).sum.to_f / files.size)} avg coverage" }
    end
    if covered_files > 0 then
      hints <<  ANSI.green { "#{covered_files} file(s) with 100% coverage" }
    end
    if hints.any?
      print " (#{hints.join(" / ")})"
    end
  end

  def missed(missed_lines)
    groups = {}
    base = nil
    previous = nil
    missed_lines.each do |src|
      ln = src.line_number
      if base && previous && (ln - 1) == previous
        groups[base] += 1
        previous = ln
      else
        base = ln
        groups[base] = 0
        previous = base
      end
    end

    group_str = []
    groups.map do |starting_line, length|
      if length > 0
        group_str << "#{starting_line}-#{starting_line + length}"
      else
        group_str << "#{starting_line}"
      end
    end

    group_str
  end

  def pct(obj)
    sprintf("%6.2f%%", obj)
  end

  def colorize(s)
    s =~ /([\d.]+)/
    n = $1.to_f
    if n >= 90 then
      ANSI.green { s }
    elsif n >= 80 then
      ANSI.yellow { s }
    else
      ANSI.red { s }
    end
  end

end
