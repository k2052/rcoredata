%w(datastore model).each do |c|
  begin
    require File.join(File.expand_path(File.dirname(__FILE__)), 'lib', c)
  rescue LoadError
    require c
  end
end