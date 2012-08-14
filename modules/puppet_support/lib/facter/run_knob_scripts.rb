#
# Return script values based on contents of /var/puppet/fact_scripts.
# executable files will be run, and if they exit 0, a fact will be created
# named after the script with the fact value set to the last line of the script
# output.
#
# Author: jpb@ooyala.com
#
# Copyright 2009-2012 Ooyala
# License: BSD

# facts can only have one value. Ignore lines with shell style comments,
# and return the last valid line.

def run_script(scriptname)
  script_output = `#{scriptname}`
  # only parse output if script exited 0
  exit_value = $?.exitstatus
  if exit_value == 0
    value = ""
    script_output.each { |line|
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
    return value
  else
    Puppet.warning("#{__FILE__} #{scriptname} failed with exit code #{exit_value}")
    return nil
  end
end

def load_scripts(script_d)
  if ! File.directory?(script_d)
    Puppet.warning("#{__FILE__} Can't read #{script_d}!")
    return nil
  end
  Dir["#{script_d}/*"].each do |script|
    if File.file?(script)
      if File.executable?(script)
        script_name = script.split('/')[-1]
        Facter.add(script_name) do
          setcode do
            data = run_script(script)
            data
          end
        end
      else
        Puppet.warning("#{__FILE__} Can't execute #{script}!")
      end
    else
      Puppet.warning("#{__FILE__} #{script} not a file")
    end
  end
end

if File.directory?('/etc/knob_scripts')
  load_scripts('/etc/knob_scripts')
end
