require "mkmf"

if RUBY_ENGINE != "ruby"
  STDERR.puts("\n\n***** This gem is MRI-specific. It does not support #{RUBY_ENGINE}. *****\n\n")
  exit(1)
end

if RUBY_VERSION < "2.3.0"
  STDERR.puts("\n\n***** Ruby version #{RUBY_VERSION} is no longer supported. Please upgrade to 2.3 or higher. *****\n\n")
  exit(1)
end

# For the love of bitfields...
$CFLAGS += ' -std=c99'

def add_define(name, value = nil)
  if value
    $defs.push("-D#{name}=#{value}")
  else
    $defs.push("-D#{name}")
  end
end

def windows?
  RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
end

add_define("RUBY_PROF_RUBY_VERSION", RUBY_VERSION.split('.')[0..2].inject(0){|v,d| v*100+d.to_i})
create_makefile("ruby_prof")
