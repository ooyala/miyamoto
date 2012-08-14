#
# fact returns knob values based on contents of /etc/knobs.
#
# Author: jpb@ooyala.com
#
# Copyright 2009-2012 Ooyala, Inc.
# License: BSD

# facts can only have one value. Ignore lines with shell style comments,
# and return the last valid line.

def read_knob(filename)
  knob_name = filename.split('/')[-1]
  knob_file = File.open(filename)
  # an empty knob file must have been created for a reason, so set default
  # value to true
  value = true
  knob_file.each { |line|
    if line[0,1] != "#"
      if (line.downcase.chomp == "true") or (line.downcase.chomp == "t")
        value = true
      elsif (line.downcase.chomp == "false") or (line.downcase.chomp == "f")
        value = false
      else
        value = line.chomp
      end
    end
  }
  knob_file.close
  value
end

def load_knobs(knob_d)
  if ! File.directory?(knob_d)
    return nil
  end
  Dir["#{knob_d}/*"].each do |knob|
    if File.file?(knob)
      if File.readable?(knob)
        knob_name = knob.split('/')[-1]
        Facter.add("#{knob_name}") do
          setcode do
            data = read_knob(knob)
            data
          end
        end
      end
    end
  end
end

if File.directory?('/etc/knobs')
  load_knobs('/etc/knobs')
end

